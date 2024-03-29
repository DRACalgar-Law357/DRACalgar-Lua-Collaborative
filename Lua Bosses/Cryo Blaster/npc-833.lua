--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local easing = require("ext/easing")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
local freeze = require("freezeHighlight")
local afterimages = require("afterimages")
--Create the library table
local cryoBlaster = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
--Defines NPC config for our NPC. You can remove superfluous definitions.
local cryoBlasterSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 192,
	gfxwidth = 192,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 64,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = true,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	staticdirection = true,
	crystalProjectileID = 911,
	diamondSawID = 912,
	iceRockID = 906,
	iceShardID = 850,
	snowBallID = 834,
	shurikenID = 836,
	bombID = 134,
	flurryID = 374,
	iceSpikeID = 837,
	prop1Image = Graphics.loadImageResolved("npc-"..npcID.."-prop1.png"),
	prop2Image = Graphics.loadImageResolved("npc-"..npcID.."-prop2.png"),
	prop1OffsetX = 32,
	prop1OffsetY = -32,
	prop2OffsetX = 32,
	prop2OffsetY = -32,
	prop1Height = 192,
	prop2Height = 192,
	effectExplosion1ID = 950,
	effectExplosion2ID = 952,
	cannonUpX = 0,
	cannonUpY = -64,
	cannonDownX = 0,
	cannonDownY = 64,
	cannonLeftX = -64,
	cannonLeftY = 0,
	cannonRightX = 64,
	cannonRightY = 0,
	pulsex = true, -- controls the scaling of the sprite when firing
	pulsey = true,
	shardSpeed = 4,
	shardIncrement = 6,
	shardTimer = 10,
	snowSpeed = 5,
	spinHitboxWidth = 72,
	spinHitboxHeight = 72,
	spinHitboxX = 0,
	spinHitboxY = 0,
	iFramesSet = 0,
	--An iFrame system that has the boss' frame be turned invisible from the set of frames periodically.
	--Set 0 defines its hurtTimer until it is at its iFramesDelay
	--Set 1 defines the same from Set 0 but whenever the boss has been harmed, it stacks up the iFramesDelay the more. The catch is that when the boss has been left alone after getting harmed, it resets the iFramesStacks so that the player can be able to jump on the boss for some time again.
	iFramesDelay = 32,
	iFramesDelayStack = 48,
	
	--A config that uses Enjil's/Emral's freezeHighlight.lua; if set to true the lua file of it needs to be in the local or episode folder.
	useFreezeHightLight = true,
	debug = false,
}

--Applies NPC settings
npcManager.setNpcSettings(cryoBlasterSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=cryoBlasterSettings.effectExplosion2ID,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

local STATE = {
	IDLE = 0,
	BARRAGE = 1,
	DASH = 2,
	LOB = 3,
	ICICLE = 4,
	FROST = 5,
	SNOWTRAP = 6,
	TRAPPED_PLAYER = 7,
	DIAMOND_SAW = 8,
	ICE = 9,
	SHURIKEN = 10,
	KILL = 12,
	KAMIKAZE = 13,
	RETURN = 14,
}

local function handleFlyAround(v,data,config,settings)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height/2)
	if data.movementSet == 0 then
		local horizontalDistance = settings.flyAroundHorizontalDistance*0.5*v.spawnDirection
		local verticalDistance = settings.flyAroundVerticalDistance*0.5
		local horizontalTime = settings.flyAroundHorizontalTime / math.pi / 2
		local verticalTime   = settings.flyAroundVerticalTime   / math.pi / 2

		v.speedX = math.cos(data.flyAroundTimer / horizontalTime)*horizontalDistance / horizontalTime
		v.speedY = math.sin(data.flyAroundTimer / verticalTime  )*verticalDistance   / verticalTime

		data.flyAroundTimer = data.flyAroundTimer + 1
		if (v.x + v.width/2 <= Camera.get()[1].x - 96) or (v.x + v.width/2 >= Camera.get()[1].x + Camera.get()[1].width + 96) or (v.y + v.height/2 <= Camera.get()[1].y - 96) or (v.y + v.height/2 >= Camera.get()[1].y + Camera.get()[1].height + 96) then
			data.timer = 0
			data.state = STATE.RETURN
		end
	elseif data.movementSet == 1 then
		local ydirection
		if v.y > v.spawnY then
			ydirection = -1
		else
			ydirection = 1
		end

		v.speedX = math.clamp(v.speedX + 0.05 * v.direction, -4, 4)
		v.speedY = math.clamp(v.speedY +0.1 * ydirection, -3, 3)
	end

	npcutils.faceNearestPlayer(v)
end

local function getDistance(k,p)
	return k.x + k.width/2 < p.x + p.width/2
end

local function getDistanceY(k,p)
	return k.y + k.height/2 < p.y + p.height/2
end

local function setDir(dir, v)
	if (dir and v.data._basegame.direction == 1) or (v.data._basegame.direction == -1 and not dir) then return end
	if dir then
		v.data._basegame.direction = 1
	else
		v.data._basegame.direction = -1
	end
end

local function setDirY(dir, v)
	if (dir and v.data._basegame.verticalDirection == 1) or (v.data._basegame.verticalDirection == -1 and not dir) then return end
	if dir then
		v.data._basegame.verticalDirection = 1
	else
		v.data._basegame.verticalDirection = -1
	end
end

local function chasePlayers(v)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local dir1 = getDistance(v, plr)
	setDir(dir1, v)
end
local function chasePlayersY(v)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local dir1 = getDistanceY(v, plr)
	setDirY(dir1, v)
end

local hurtCooldown = 160

local hpboarder = Graphics.loadImage("hpconboss.png")
local hpfill = Graphics.loadImage("hpfillboss.png")
--Register events
function cryoBlaster.onInitAPI()
	npcManager.registerEvent(npcID, cryoBlaster, "onTickEndNPC")
	npcManager.registerEvent(npcID, cryoBlaster, "onDrawNPC")
	registerEvent(cryoBlaster, "onNPCHarm")
end

function cryoBlaster.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height/2)
	local config = NPC.config[v.id]
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initalized = false
		data.timer = 0
		data.hurtTimer = 0
		return
	end
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true

		settings.hp = settings.hp or 120
		data.w = math.pi/65
		data.timer = data.timer or 2
		data.hurtTimer = data.hurtTimer or 0
		data.iFrames = false
		data.health = settings.hp
		data.state = STATE.IDLE
		data.hurtCooldownTimer = 0
		data.hurting = false
		data.iFramesDelay = NPC.config[v.id].iFramesDelay
		data.iFramesStack = 0
		data.statelimit = 0
		data.flyAroundTimer = 0
		data.moving = true
		data.shurikenDisplay = true
		v.ai1 = 0
		v.ai2 = 0
		v.ai3 = 0
		data.rndTimer = RNG.randomInt(80,144)
		data.frameTimer = 0
		data.movementTimer = 0
		data.movementSet = 0
		data.movementDelay = RNG.randomInt(360,600)
		data.sprSizex = 1
		data.sprSizey = 1
		data.img = data.img or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = frames, texture = Graphics.sprites.npc[v.id].img}
		data.angle = 0
		data.prop1rotation = 0
		data.prop2rotation = 0
		data.prop1Timer = 0
		data.prop2Timer = 0
		data.verticalDirection = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE.IDLE
		v.ai1 = 0
		data.timer = 0
	end
	data.timer = data.timer + 1
	data.movementTimer = data.movementTimer + 1
	data.sprSizex = math.max(data.sprSizex - 0.05, 1)
	data.sprSizey = math.max(data.sprSizey - 0.05, 1)
	data.dirVectr = vector.v2(
		(v.spawnX + 32) - (v.x + v.width * 0.5),
		(v.spawnY + 48) - (v.y + v.height * 0.5)
		):normalize() * 5
	if data.moving and data.state ~= STATE.KILL and data.state ~= STATE.RETURN and data.state ~= STATE.DASH then
		handleFlyAround(v,data,config,settings)
		if data.movementTimer >= data.movementDelay then
			data.movementDelay = RNG.randomInt(360,600)
			local options = {}
			if data.movementSet ~= 0 then table.insert(options,0) end
			if data.movementSet ~= 1 then table.insert(options,1) end
			if #options > 0 then
				data.movementSet = RNG.irandomEntry(options)
			end
			data.movementTimer = 0
		end
	end
	if data.state == STATE.IDLE then
		v.animationFrame = 0
		if data.timer == 1 then
			data.rndTimer = RNG.randomInt(80,144)
			if RNG.randomInt(0,1) == 0 then
				if config.pulsex then
					data.sprSizex = 1.5
				end
		
				if config.pulsey then
					data.sprSizey = 1.5
				end
				SFX.play("Air Bullet.wav")
				local n = NPC.spawn(RNG.irandomEntry{config.flurryID,config.bombID}, v.x + v.width/2 + config.cannonDownX, v.y + v.height/2 + config.cannonDownY, v.section, false, true)
				
				n.speedX = 0
				n.speedY = 3
				Effect.spawn(10, v.x + v.width/2 + config.cannonDownX, v.y + v.height/2 + config.cannonDownY)
			end
		end
		if data.timer >= data.rndTimer then
			data.timer = 0
			local options = {}
			table.insert(options,STATE.ICE)
			table.insert(options,STATE.TRAPPED_PLAYER)
			table.insert(options,STATE.DIAMOND_SAW)
			table.insert(options,STATE.BARRAGE)
			table.insert(options,STATE.SHURIKEN)
			table.insert(options,STATE.SNOWTRAP)
			table.insert(options,STATE.DASH)
			if #options > 0 then
				data.state = RNG.irandomEntry(options)
			end
			data.statelimit = data.state

		end
	elseif data.state == STATE.DASH then
		v.animationFrame = 0
		local prop1rotator = 0
		local prop1rotatedirection = v.direction
		local prop2rotator = 0
		local prop2rotatedirection = -v.direction
		if data.timer == 1 and v.ai1 == 0 then
			SFX.play("PU-Glaceon-Ice-Shard-Activate.wav")
		end
		if v.ai1 == 0 then
			v.speedX = 0
			v.speedY = 0
			prop1rotator = easing.inQuad(data.timer, prop1rotator, 12 - prop1rotator, 56)
			prop2rotator = easing.inQuad(data.timer, prop2rotator, 12 - prop2rotator, 56)
			if data.timer > 64 then
				v.x = v.x + 45 * -data.w * math.sin(math.pi/4*data.timer)
				v.y = v.y - 56 * -data.w * math.sin(math.pi/2*data.timer)
			end
			if data.timer == 120 then
				SFX.play("powerup1.ogg")
			end
			if data.timer >= 128 then
				v.ai1 = 1
				data.timer = 0
				v.speedY = -3
				v.speedX = 0
			end
		elseif v.ai1 == 1 then
			data.spinBox = Colliders.Box(v.x - (v.width * 1.2), v.y - (v.height * 1), config.spinHitboxWidth, config.spinHitboxHeight)
			data.spinBox.x = v.x + v.width/2 - data.spinBox.width/2 + config.spinHitboxX
			data.spinBox.y = v.y + v.height/2 - data.spinBox.height/2 + config.spinHitboxY
			
			if config.debug == true then
				data.spinBox:Debug(true)
			end
			prop1rotator = 12
			prop2rotator = 12
			chasePlayers(v)
			chasePlayersY(v)
			afterimages.create(v, 24, Color.cyan, true, 0)
			if data.timer >= 360 then
				data.timer = 0
				v.ai1 = 2
			end
			if v.collidesBlockBottom or v.collidesBlockUp then
				if v.collidesBlockBottom then v.speedY = -2 elseif v.collidesBlockUp then v.speedY = 2 end
				SFX.play("s3k_shoot.ogg")
				Defines.earthquake = 5
			end
			if v.collidesBlockLeft or v.collidesBlockRight then
				if v.collidesBlockLeft then v.speedX = 2 elseif v.collidesBlockRight then v.speedX = -2 end
				SFX.play("s3k_shoot.ogg")
				Defines.earthquake = 5
			end
			v.speedX = math.clamp(v.speedX + 0.1 * v.data._basegame.direction, -5, 5)
			v.speedY = math.clamp(v.speedY + 0.1 * v.data._basegame.verticalDirection, -5, 5)
			if Colliders.collide(plr,data.spinBox) then
				plr:harm()
			end
			for k, n in  ipairs(Colliders.getColliding{a = data.spinBox, b = NPC.HITTABLE, btype = Colliders.NPC, filter = npcFilter}) do
				if n.id ~= v.id then
					if n:mem(0x156,FIELD_WORD) <= 0 then
						n:harm()
						Animation.spawn(75,n.x,n.y)
					end
				end
			end
		elseif v.ai1 == 2 then
			prop1rotator = easing.outQuad(data.timer, prop1rotator, 0 - prop1rotator, 56)
			prop2rotator = easing.outQuad(data.timer, prop2rotator, 0 - prop2rotator, 56)
			local stopX = false
			local stopY = false
			if math.abs(v.speedX) <= 0.1 then
				v.speedX = 0
				stopX = true
			else
				v.speedX = v.speedX * 0.97
			end
			if math.abs(v.speedY) <= 0.1 then
				v.speedY = 0
				stopY = true
			else
				v.speedY = v.speedY * 0.97
			end
			if stopX and stopY then
				v.speedX = 0
				v.speedY = 0
				data.prop1rotation = 0
				data.prop2rotation = 0
				v.ai1 = 0
				data.timer = 0
				data.state = STATE.IDLE
				data.movementSet = 1
				data.movementTimer = 0
			end
		end
		data.prop1rotation = data.prop1rotation + prop1rotator * prop1rotatedirection
		data.prop2rotation = data.prop2rotation + prop2rotator * prop2rotatedirection

	elseif data.state == STATE.SHURIKEN then
		v.animationFrame = 0
		local prop1rotator = 0
		local prop1rotatedirection = v.direction
		local prop2rotator = 0
		local prop2rotatedirection = -v.direction
		if data.timer == 1 and data.shurikenDisplay then
			SFX.play("PU-Glaceon-Ice-Shard-Activate.wav")
		end
		if data.shurikenDisplay then
			prop1rotator = easing.inQuad(data.timer, prop1rotator, 3 - prop1rotator, 56)
			prop2rotator = easing.inQuad(data.timer, prop2rotator, 3 - prop2rotator, 56)
			data.prop1rotation = data.prop1rotation + prop1rotator * prop1rotatedirection
			data.prop2rotation = data.prop2rotation + prop2rotator * prop2rotatedirection
			if data.timer >= 120 then
				data.shurikenDisplay = false
				data.timer = 0
				SFX.play("PU-AlolanNinetales-Blizzard-Activate.wav")
				data.shuriken = NPC.spawn(NPC.config[v.id].shurikenID, v.x + v.width/2, v.y + v.height/2 - 64, v.section, false, true)
				data.shuriken.speedY = -8
				data.shuriken.speedX = RNG.random(-3,3)
				data.shuriken.parent = v
				npcutils.faceNearestPlayer(data.shuriken)
			end
		else
			if data.timer >= 12 then
				if data.shuriken then
					if data.shuriken and data.shuriken.isValid then
						if Colliders.collide(data.shuriken, v) and data.shuriken.data.state >= 3 then
							data.shuriken:kill(9)
							data.shuriken = nil
							data.state = STATE.IDLE
							data.timer = 0
							data.shurikenDisplay = true
							data.prop1rotation = 0
							data.prop2rotation = 0
						end
					else
						data.shuriken = nil
						data.state = STATE.IDLE
						data.timer = 0
						data.shurikenDisplay = true
						data.prop1rotation = 0
						data.prop2rotation = 0
					end
				end
			end
		end
	elseif data.state == STATE.BARRAGE then
		v.animationFrame = 0
		if data.timer == 1 then v.ai1 = 0 v.ai2 = 0 end
		if data.timer == 8 then
			Routine.setFrameTimer(config.shardTimer, (function() 
				if config.pulsex then
					data.sprSizex = 1.5
				end
		
				if config.pulsey then
					data.sprSizey = 1.5
				end
				SFX.play("PU-Glaceon-Ice-Shard1.wav")
				if v.ai1 == 0 then
					v.ai2 = 0
					for i=0,3 do
						local dir = -vector.right2:rotate(90 * (v.ai2 + 1) + (v.ai1 * 10))
						local dirl = -vector.right2:rotate(90 * (v.ai2 + 1) + (v.ai1 * 10))
						local dirr = -vector.right2:rotate(90 * (v.ai2 + 1) - (v.ai1 * 10))
						if i == 0 then
							local n = NPC.spawn(NPC.config[v.id].iceShardID, v.x + v.width/2 + config.cannonUpX, v.y + v.height/2 + config.cannonUpY, v.section, false, true)
						
							n.speedX = dir.x * config.shardSpeed
							n.speedY = dir.y * config.shardSpeed
							Effect.spawn(10, v.x + v.width/2 + config.cannonUpX, v.y + v.height/2 + config.cannonUpY)
						elseif i == 1 then
							local n = NPC.spawn(NPC.config[v.id].iceShardID, v.x + v.width/2 + config.cannonRightX, v.y + v.height/2 + config.cannonRightY, v.section, false, true)
						
							n.speedX = dir.x * config.shardSpeed
							n.speedY = dir.y * config.shardSpeed
							Effect.spawn(10, v.x + v.width/2 + config.cannonRightX, v.y + v.height/2 + config.cannonRightY)
						elseif i == 2 then
							local n = NPC.spawn(NPC.config[v.id].iceShardID, v.x + v.width/2 + config.cannonDownX, v.y + v.height/2 + config.cannonDownY, v.section, false, true)
						
							n.speedX = dir.x * config.shardSpeed
							n.speedY = dir.y * config.shardSpeed
							Effect.spawn(10, v.x + v.width/2 + config.cannonDownX, v.y + v.height/2 + config.cannonDownY)
						elseif i == 3 then
							local n = NPC.spawn(NPC.config[v.id].iceShardID, v.x + v.width/2 + config.cannonLeftX, v.y + v.height/2 + config.cannonLeftY, v.section, false, true)
						
							n.speedX = dir.x * config.shardSpeed
							n.speedY = dir.y * config.shardSpeed
							Effect.spawn(10, v.x + v.width/2 + config.cannonLeftX, v.y + v.height/2 + config.cannonLeftY)
						end
						v.ai2 = v.ai2 + 1
					end
				else
					v.ai2 = 0
					for i=0,3 do
						local dir = -vector.right2:rotate(90 * (v.ai2 + 1) + (v.ai1 * 10))
						local dirl = -vector.right2:rotate(90 * (v.ai2 + 1) + (v.ai1 * 10))
						local dirr = -vector.right2:rotate(90 * (v.ai2 + 1) - (v.ai1 * 10))
						if i == 0 then
							local n = NPC.spawn(NPC.config[v.id].iceShardID, v.x + v.width/2 + config.cannonUpX, v.y + v.height/2 + config.cannonUpY, v.section, false, true)
						
							n.speedX = dirl.x * config.shardSpeed
							n.speedY = dirl.y * config.shardSpeed
							Effect.spawn(10, v.x + v.width/2 + config.cannonUpX, v.y + v.height/2 + config.cannonUpY)
						elseif i == 1 then
							local n = NPC.spawn(NPC.config[v.id].iceShardID, v.x + v.width/2 + config.cannonRightX, v.y + v.height/2 + config.cannonRightY, v.section, false, true)
						
							n.speedX = dirl.x * config.shardSpeed
							n.speedY = dirl.y * config.shardSpeed
							Effect.spawn(10, v.x + v.width/2 + config.cannonRightX, v.y + v.height/2 + config.cannonRightY)
						elseif i == 2 then
							local n = NPC.spawn(NPC.config[v.id].iceShardID, v.x + v.width/2 + config.cannonDownX, v.y + v.height/2 + config.cannonDownY, v.section, false, true)
						
							n.speedX = dirl.x * config.shardSpeed
							n.speedY = dirl.y * config.shardSpeed
							Effect.spawn(10, v.x + v.width/2 + config.cannonDownX, v.y + v.height/2 + config.cannonDownY)
						elseif i == 3 then
							local n = NPC.spawn(NPC.config[v.id].iceShardID, v.x + v.width/2 + config.cannonLeftX, v.y + v.height/2 + config.cannonLeftY, v.section, false, true)
						
							n.speedX = dirl.x * config.shardSpeed
							n.speedY = dirl.y * config.shardSpeed
							Effect.spawn(10, v.x + v.width/2 + config.cannonLeftX, v.y + v.height/2 + config.cannonLeftY)
						end
						v.ai2 = v.ai2 + 1
					end
					for i=0,3 do
						local dir = -vector.right2:rotate(90 * (v.ai2 + 1) + (v.ai1 * 10))
						local dirl = -vector.right2:rotate(90 * (v.ai2 + 1) + (v.ai1 * 10))
						local dirr = -vector.right2:rotate(90 * (v.ai2 + 1) - (v.ai1 * 10))
						if i == 0 then
							local n = NPC.spawn(NPC.config[v.id].iceShardID, v.x + v.width/2 + config.cannonUpX, v.y + v.height/2 + config.cannonUpY, v.section, false, true)
						
							n.speedX = dirr.x * config.shardSpeed
							n.speedY = dirr.y * config.shardSpeed
							Effect.spawn(10, v.x + v.width/2 + config.cannonUpX, v.y + v.height/2 + config.cannonUpY)
						elseif i == 1 then
							local n = NPC.spawn(NPC.config[v.id].iceShardID, v.x + v.width/2 + config.cannonRightX, v.y + v.height/2 + config.cannonRightY, v.section, false, true)
						
							n.speedX = dirr.x * config.shardSpeed
							n.speedY = dirr.y * config.shardSpeed
							Effect.spawn(10, v.x + v.width/2 + config.cannonRightX, v.y + v.height/2 + config.cannonRightY)
						elseif i == 2 then
							local n = NPC.spawn(NPC.config[v.id].iceShardID, v.x + v.width/2 + config.cannonDownX, v.y + v.height/2 + config.cannonDownY, v.section, false, true)
						
							n.speedX = dirr.x * config.shardSpeed
							n.speedY = dirr.y * config.shardSpeed
							Effect.spawn(10, v.x + v.width/2 + config.cannonDownX, v.y + v.height/2 + config.cannonDownY)
						elseif i == 3 then
							local n = NPC.spawn(NPC.config[v.id].iceShardID, v.x + v.width/2 + config.cannonLeftX, v.y + v.height/2 + config.cannonLeftY, v.section, false, true)
						
							n.speedX = dirr.x * config.shardSpeed
							n.speedY = dirr.y * config.shardSpeed
							Effect.spawn(10, v.x + v.width/2 + config.cannonLeftX, v.y + v.height/2 + config.cannonLeftY)
						end
						v.ai2 = v.ai2 + 1
					end
				end
				v.ai1 = v.ai1 + 1
				end), config.shardIncrement, false)
		end
		if data.timer >= 16 + config.shardIncrement * config.shardTimer then
			data.timer = 0
			v.ai1 = 0
			data.state = STATE.IDLE
		end
	elseif data.state == STATE.SNOWTRAP then
		--[[				local n = NPC.spawn(npcID + 1, v.x + 8 * v.direction, v.y + 4, player.section, false)
				n.speedX = settings.xangle * v.direction
				n.speedY = -settings.yangle
				n.data._settings.spread = settings.spread]]
				v.animationFrame = 0
		if data.timer == 1 then v.ai1 = 0 end
		if data.timer == 8 then
			if config.pulsex then
				data.sprSizex = 1.5
			end
		
			if config.pulsey then
				data.sprSizey = 1.5
			end
			SFX.play(22)
			v.ai1 = 0
			for i=0,6 do
				local dir = -vector.right2:rotate(6 + (v.ai1 * 28))

				local n = NPC.spawn(NPC.config[v.id].snowBallID, v.x + v.width/2 + config.cannonUpX, v.y + v.height/2 + config.cannonUpY, v.section, false, true)
				
				n.speedX = dir.x * config.snowSpeed
				n.speedY = dir.y * config.snowSpeed
				n.data._settings.spread = 3
				Effect.spawn(10, v.x + v.width/2 + config.cannonUpX, v.y + v.height/2 + config.cannonUpY)
				v.ai1 = v.ai1 + 1
			end
			v.ai1 = 0
		end
		if data.timer >= 32 then
			data.timer = data.rndTimer
			data.state = STATE.IDLE
			v.ai1 = 0
		end
	elseif data.state == STATE.ICE then
		v.animationFrame = 0
		if data.timer % 30 == 2 and data.timer <= 192 then
			if config.pulsex then
				data.sprSizex = 1.5
			end
	
			if config.pulsey then
				data.sprSizey = 1.5
			end
			local n = NPC.spawn(NPC.config[v.id].iceRockID, v.x + v.width/2 + config.cannonUpX, v.y + v.height/2 + config.cannonUpY, v.section, false, true)
			
			if data.timer == 2 then SFX.play("smrpg_enemy_crystalcrusher.wav") end
		
			n.speedX = RNG.random(-4,4)
				
			n.speedY = -8
			Effect.spawn(10, v.x + v.width/2 + config.cannonUpX, v.y + v.height/2 + config.cannonUpY)
		end
		
		if data.timer >= 224 then
			data.state = STATE.IDLE
			data.timer = 0
		end
	elseif data.state == STATE.DIAMOND_SAW then
		v.animationFrame = 0
		if data.timer == 1 then
			for i = 0,1 do
				local n = NPC.spawn(NPC.config[v.id].diamondSawID, v.x + v.width/2, v.y + v.height/2 - 64, v.section, false, true)
				n.direction = i
				n.speedX = -2
			end
		end
		if data.timer >= 128 then
			data.state = STATE.IDLE
			data.timer = 0
		end
	elseif data.state == STATE.TRAPPED_PLAYER then
		v.animationFrame = 0
		if data.timer <= 80 then
			if data.timer % 16 == 2 then
				if data.timer == 2 then SFX.play("smrpg_enemy_crystal.wav") end
				local n = NPC.spawn(NPC.config[v.id].crystalProjectileID, plr.x, plr.y - 128, player.section, false)
				n.animationFrame = -50
			end
		else
			if data.timer >= 96 then
				data.state = STATE.IDLE
				data.timer = 0
			end
		end
	elseif data.state == STATE.RETURN then
		if math.abs(v.spawnX - v.x) <= 12 and math.abs(v.spawnY - v.y) <= 64 then
			v.x = v.spawnX
			v.y = v.spawnY
			v.speedX = 0
			v.speedY = 0
			--When enough time has passed, go into an attack phase
			if data.timer >= 96 then
				if data.shuriken and data.shuriken.isValid then
					data.state = STATE.SHURIKEN
				else
					data.state = STATE.IDLE
				end
				data.timer = 0
			end
			npcutils.faceNearestPlayer(v)
		else
			v.speedX = data.dirVectr.x
			v.speedY = data.dirVectr.y
			data.timer = 0
		end
		v.animationFrame = 0
    else
		v.speedX = 0
		v.speedY = 0
		v.friendly = true
		if lunatime.tick() % 64 > 4 then 
			v.animationFrame = 0
		else
			v.animationFrame = -50
		end
		if data.timer % 24 == 0 then
			local a = Animation.spawn(sampleNPCSettings.effectExplosion1ID, math.random(v.x, v.x + v.width), math.random(v.y, v.y + v.height))
			a.x=a.x-a.width/2
			a.y=a.y-a.height/2
			SFX.play(sfx_explode)
		end
		if data.timer >= 250 then
			v:kill(HARM_TYPE_NPC)
		end
	end
	
	--Give Cryo Blaster some i-frames to make the fight less cheesable
	--iFrames System made by MegaDood & DRACalgar Law
	if NPC.config[v.id].iFramesSet == 1 then
        if data.hurting == false then
            data.hurtCooldownTimer = 0
            data.iFramesStack = -1
        else
            data.hurtCooldownTimer = data.hurtCooldownTimer + 1
            local stacks = (NPC.config[v.id].iFramesDelayStack * data.iFramesStack)
            if stacks < 0 then
                stacks = 0
            end
            data.iFramesDelay = NPC.config[v.id].iFramesDelay + stacks
            if data.hurtCooldownTimer >= hurtCooldown then
                data.hurtCooldownTimer = 0
                data.hurting = false
                data.iFramesStack = -1
            end
        end
    end
	if data.iFrames then
		v.friendly = true
		data.hurtTimer = data.hurtTimer + 1
		
		if data.hurtTimer == 1 then
		    SFX.play("s3k_damage.ogg")
		end
		if data.hurtTimer >= data.iFramesDelay then
			v.friendly = false
			data.iFrames = false
			data.hurtTimer = 0
		end
	end
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = cryoBlasterSettings.frames
		});
	end
	
	--Prevent Cryo Blaster from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	if Colliders.collide(plr, v) and not v.friendly and data.state ~= STATE.KILL and not Defines.cheat_donthurtme then
		plr:harm()
	end
end
function cryoBlaster.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end

			if data.iFrames == false and data.state ~= STATE.KILL and data.state ~= STATE.KAMIKAZE then
				local fromFireball = (culprit and culprit.__type == "NPC" and culprit.id == 13 )
				local hpd = 10
				if fromFireball then
					hpd = 4
					SFX.play(9)
				elseif reason == HARM_TYPE_LAVA then
					v:kill(HARM_TYPE_LAVA)
				else
					hpd = 10
					data.iFrames = true
					if reason == HARM_TYPE_SWORD then
						if v:mem(0x156, FIELD_WORD) <= 0 then
							SFX.play(89)
							hpd = 8
							v:mem(0x156, FIELD_WORD,20)
						end
						if Colliders.downSlash(player,v) then
							player.speedY = -6
						end
					elseif reason == HARM_TYPE_LAVA and v ~= nil then
						v:kill(HARM_TYPE_OFFSCREEN)
					elseif v:mem(0x12, FIELD_WORD) == 2 then
						v:kill(HARM_TYPE_OFFSCREEN)
					else
						if reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP or reason == HARM_TYPE_FROMBELOW then
							SFX.play(2)
						end
						data.iFrames = true
						hpd = 10
					end
					if data.iFrames then
						data.hurting = true
						data.iFramesStack = data.iFramesStack + 1
						data.hurtCooldownTimer = 0
					end
				end
				
				data.health = data.health - hpd
			end
			if culprit then
				if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
					culprit:kill(HARM_TYPE_NPC)
				elseif culprit.__type == "Player" then
					--Bit of code taken from the basegame chucks
					if (culprit.x + 0.5 * culprit.width) < (v.x + v.width*0.5) then
						culprit.speedX = -5
					else
						culprit.speedX = 5
					end
				elseif type(culprit) == "NPC" and (NPC.HITTABLE_MAP[culprit.id] or culprit.id == 45) and culprit.id ~= 50 and v:mem(0x138, FIELD_WORD) == 0 then
					culprit:kill(HARM_TYPE_NPC)
				end
			end
			if data.health <= 0 then
				data.state = STATE.KILL
				data.timer = 0
				if NPC.config[v.id].useFreezeHightLight == true then
					freeze.set(48)
				end
				--[[for _,n in ipairs(NPC.get()) do
					if n.id == NPC.config[v.id].shockwaveID or n.id == NPC.config[v.id].bombArray or n.id == NPC.config[v.id].phantoNormalID or n.id == NPC.config[v.id].phantoAggroID or n.id == NPC.config[v.id].phantoFuriousID or n.id == NPC.config[v.id].orbID or n.id == NPC.config[v.id].projectileID then
						if n.x + n.width > camera.x and n.x < camera.x + camera.width and n.y + n.height > camera.y and n.y < camera.y + camera.height then
							n:kill(9)
							Animation.spawn(10, n.x, n.y)
						end
					end
				end]]
			elseif data.health > 0 then
				v:mem(0x156,FIELD_WORD,60)
			end
	eventObj.cancelled = true
end
local lowPriorityStates = table.map{1,3,4}
function cryoBlaster.onDrawNPC(v)
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]
	data.w = math.pi/65
	if hpboarder and hpfill and v.legacyBoss == true and data.state ~= STATE.KILL and data.state ~= STATE.KAMIKAZE and data.health then
		Graphics.drawImage(hpboarder, 740, 120)
		local healthoffset = 126
		healthoffset = healthoffset-(126*(data.health/settings.hp))
		Graphics.drawImage(hpfill, 748, 128+healthoffset, 0, 0, 12, 126-healthoffset)
	end

	--Setup code by Mal8rk
	local pivotOffsetX = 0
	local pivotOffsetY = 0

	local opacity = 1

	local priority = 1
	if lowPriorityStates[v:mem(0x138,FIELD_WORD)] then
		priority = -75
	elseif v:mem(0x12C,FIELD_WORD) > 0 then
		priority = -30
	elseif config.foreground then
		priority = -125
	end

	--Text.print(v.x, 8,8)
	--Text.print(data.timer, 8,32)

	if data.iFrames then
		opacity = math.sin(lunatime.tick()*math.pi*0.25)*0.1 + 0.9
	end
	if data.shurikenDisplay then
		local img = config.prop1Image

		Graphics.drawBox{
			texture = img,
			x = v.x+config.prop1OffsetX + config.gfxoffsetx,
			y = v.y+config.prop1OffsetY + config.gfxoffsety,
			width = -img.width,
			sourceY = 0,
			sourceHeight = config.prop1Height,
			sceneCoords = true,
			centered = true,
			priority = priority,
			rotation = data.prop1rotation,
		}

		local img = config.prop2Image
		
		Graphics.drawBox{
			texture = img,
			x = v.x+config.prop2OffsetX + config.gfxoffsetx,
			y = v.y+config.prop2OffsetY + config.gfxoffsety,
			width = -img.width,
			sourceY = 0,
			sourceHeight = config.prop2Height,
			sceneCoords = true,
			centered = true,
			priority = priority-45,
			rotation = data.prop2rotation,
		}
	end
	if data.img then
		-- Setting some properties --
		data.img.x, data.img.y = v.x + 0.5 * v.width + config.gfxoffsetx, v.y + 0.5 * v.height --[[+ config.gfxoffsety]]
		data.img.transform.scale = vector(data.sprSizex, data.sprSizey)
		data.img.rotation = data.angle

		local p = -45
		if config.foreground then
			p = -15
		end

		-- Drawing --
		data.img:draw{frame = v.animationFrame, sceneCoords = true, priority = priority, opacity = opacity}
	end
end

--Gotta return the library table!
return cryoBlaster
