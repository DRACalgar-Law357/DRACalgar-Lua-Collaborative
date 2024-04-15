--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local easing = require("ext/easing")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
--Create the library table
local docCroc = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
--A list of states Doc Croc can take in
local STATE = {
	IDLE = 0,
	TELEPORT = 1,
	INTRO = 2,
	VIAL = 3,
	SHOCKWAVE = 4,
	DRONE = 5,
	ENERGY1 = 6,
	ENERGY2 = 7,
	MUSHROOM = 8,
	KILL = 9,
	HURT = 10,
}
--Defines NPC config for our NPC. You can remove superfluous definitions.
local docCrocSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 96,
	gfxwidth = 96,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 80,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 8,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop re= false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
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
	hp = 24,
	hpDecStrong = 4,
	hpDecWeak = 1,
	--The drone chases the player and disappears after a set of frames; used in STATE.DRONE
	droneID = 944,
	--The vials spout SMW Fireballs after a collision; used in STATE.VIAL
	vialID = 943,
	--Spreads shockwaves and explodes after a collision; used in STATE.SHOCKWAVE
	shockwaveBombID = 941,
	--This Energy Ball after a set amount of frames will target at the player's position and turn into a different Energy Ball; used in STATE.ENERGY2
	energyBall1ID = 938,
	--This Energy Ball is just a straight projectile; used in STATE.ENERGY1
	energyBall2ID = 940,
	--A vial that spawns a non-moving mushroom; used in STATE.MUSHROOM
	mushroomID = 946,
	--These are the NPCs that Doc Croc will drop after each attack generally used in dropTable and dropPinchTable
	bombID = 136,
	springID = 26,
	--A config component in which is used in a non-pinch state, he goes over the procedures in certain attacks what to spawn after each
	dropTable = {
		[STATE.ENERGY1] = bombID,
		[STATE.SHOCKWAVE] = springID,
		[STATE.ENERGY2] = bombID,
		[STATE.VIAL] = springID,
	},
	--A config component in which is used in a pinch state, he goes over a randomized selection of what NPC to drop (may put 0 to have him not drop anything)
	dropPinchTable = {
		0,
		bombID,
		springID,
	}
	--A config component in which sets the patterns in order for Doc Croc to follow in
	patternTable = {
		[0] = STATE.ENERGY1,
		[1] = STATE.SHOCKWAVE,
		[2] = STATE.ENERGY2,
		[3] = STATE.VIAL,
	},
	--A config component in which Doc Croc will randomly choose. He'll still have a chance to choose to throw  mushroom vial.
	alloutTable = {
		[0] = STATE.ENERGY1,
		[1] = STATE.SHOCKWAVE,
		[2] = STATE.ENERGY2,
		[3] = STATE.VIAL,
		[4] = STATE.DRONE
	},
	effectExplosion1ID = 10,
	effectExplosion2ID = 937,
	spawnX = 0,
	spawnY = 12,
	pulsex = false, -- controls the scaling of the sprite when firing
	pulsey = false,
	teleportx = true,
	teleporty = true,
	idleDelay = 70,
	springDelayUntilDisappear = 330,
	droneDelayUntilDisappear = 240,
	energyBall1Sets = {
		[0] = {
			speed = 4,
			initAngle = 18,
			angleIncrement = 18,
		},
		[1] = {
			speed = 4,
			initAngle = -18,
			angleIncrement = -18,
		},
	}
	energyBall1DelayBefore = 16,
	energyBall1DelayAfter = 8,
	energyBall2Speed = 4,
	energyBall2InitAngle = 180,
	energyBall2InitAngleDirOffset = 10,
	energyBall2AngleIncrement = 40,
	energyBall2Consecutive = 3,
	energyBall2Style = 0, --0 - Shoots 2 volleys on each increment and direction; 1 - Shoots 1 volley on a random init direction and increments on an angle.
	energyBall2DelayBefore = 16,
	energyBall2DelayAfter = 8,
	vialSet = {
		--From left to right
		[0] = {
			[0] = {
				speed = 4,
				angle = 245,
			},
			[1] = {
				speed = 4,
				angle = 180,
			},
			[2] = {
				speed = 4,
				angle = 115,
			},
		},
		--From right to left
		[1] = {
			[0] = {
				speed = 4,
				angle = 115,
			},
			[1] = {
				speed = 4,
				angle = 180,
			},
			[2] = {
				speed = 4,
				angle = 245,
			},
		},
	},
	vialDelayBefore = 16,
	vialDelayAfter = 8,
	shockwaveDelayBefore = 16,
	shockwaveDelayAfter = 8,
	droneDelayBefore = 16,
	droneDelayAfter = 8,
	hurtDelay = 56,
	teleportBGOID = 937, --Uses these BGOs to teleport there
	teleportToSpawnPoint = true,
	--SFX List
	sfx_energyBall1 = 16,
	sfx_energyBall2 = 16,
	sfx_androidDeploy = 18,
	sfx_vialDrop = 18,
	sfx_bombDeploy = 18,
	sfx_dropNPC = 18,
	sfx_dropMushroomVial = 18,
	sfx_hurt = 39,
	sfx_smallExplosion = 22,
	sfx_bigExplosion = 43,
	sfx_teleportDisappear = nil,
	sfx_teleportAppear = nil,
	sfx_introClick = nil,
	sfx_introFlyIn = nil,
	--For appealing SFX voices
	sfx_voiceAttackTable = {
		nil,
		nil,
	},
	sfx_voiceHurtTable = {
		nil,
		nil,
	},
	sfx_voiceIntro = nil,
	sfx_voiceDefeat1 = nil,
	sfx_voiceDefeat2 = nil,

	mushroomFrequency = 1, --Uses this config in a pinch state to throw a mushroom vial. Can only be used once when used.
	mushroomHP = 16, --As the hp goes over this config, Doc Croc will have a chance to drop a mushroom vial.
	iFramesDelay = 60,
	pinchHP = 16, --As the hp goes over this config, Doc Croc shifts into pinch mode; used in pinchSet 0
	pinchSet = 0, --0 - initially becomes in a non-pinch state and then until Doc Croc's hp goes over a set of pinchHP, he'll become in a pinch state, becoming more aggressive (he can also drop a mushroom vial by chance); 1 - initially becomes in a non-pinch state, following a pattern table; 2 - initially becomes in a pinch state, will not volley a mushroom vial, will follow randomized attacks
	--Configs to either drop a randomized choice or a specified choice in either of the pinch states (if true, uses an rng table to help decide what to drop or not; if false, uses a specified state from a table to help what to drop)
	dropNPCStyleNonPinchRandomly = false,
	dropNPCStylePinchRandomly = true,
}

--Applies NPC settings
npcManager.setNpcSettings(docCrocSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
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
		--[HARM_TYPE_NPC]=docCrocSettings.effectExplosion2ID,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Register events
function docCroc.onInitAPI()
	npcManager.registerEvent(npcID, docCroc, "onTickEndNPC")
	npcManager.registerEvent(npcID, docCroc, "onDrawNPC")
	registerEvent(docCroc, "onNPCHarm")
end

local function pressButtonAnimate(v,data,config,chooseNewAnimation)
	if data.timer == 1 and chooseNewAnimation then data.pressButtonAnimate = RNG.randomInt(0,1) end
	v.animationFrame = 1 + data.pressButtonAnimate
end

local function decideAttack(v,data,config,pinch)
	local options = {}
	local mushroomChance = {}
	if data.health >= config.mushroomHP then
		if config.mushroomFrequency > 0 then
			for i=1,config.mushroomFrequency do
				table.insert(mushroomChance,0) --0 indicates a rate for dropping a mushroom vial
			end
		end
		if pinch then
			if config.alloutTable and #config.alloutTable > 0 then
				for i=1,#config.alloutTable do
					table.insert(mushroomChance,1) --1 indicates a rate of choosing an attack
				end
			end
		else
			if config.patternTable and #config.patternTable > 0 then
				for i=1,#config.patternTable do
					table.insert(mushroomChance,1) --1 indicates a rate of choosing an attack
				end
			end
		end
		if RNG.irandomEntry(mushroomChance) == 0 then
			table.insert(options,STATE.MUSHROOM)
		end
	end
	if pinch then
		if config.alloutTable and #config.alloutTable > 0 then
			for i=1,#config.alloutTable do
				table.insert(options,config.alloutTable[i-1])
			end
		end
	else
		if config.patternTable and #config.patternTable > 0 then
			table.insert(options,config.patternTable[data.pattern])
			if data.pattern >= #config.patternTable - 1 then
				data.pattern = 0
			else
				data.pattern = data.pattern + 1
			end
		end
	end
	if #options > 0 then
		data.state = RNG.irandomEntry(options)
	end
	data.timer = 0
end

function docCroc.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height/2)
	local config = NPC.config[v.id]
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initalized = false
		data.timer = 0
		return
	end
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.w = math.pi/65
		data.timer = data.timer or 0
		data.hurtTimer = data.hurtTimer or 0
		data.iFrames = false
		data.health = config.hp
		data.state = STATE.IDLE
		data.iFramesDelay = config.iFramesDelay
		data.pattern = 0
		v.ai1 = 0
		v.ai2 = 0
		v.ai3 = 0
		data.sprSizex = 1
		data.sprSizey = 1
		data.pinch = false
		data.img = data.img or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = docCrocSettings.frames, texture = Graphics.sprites.npc[v.id].img}
		data.angle = 0
		data.bgoTable = BGO.get(NPC.config[v.id].positionPointBGO)
		if config.teleportToSpawnPoint then table.insert(data.bgoTable,vector.v2(v.spawnX + v.width/2, v.spawnY + v.height/2)) end
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
	if not data.teleporting then
		data.sprSizex = math.max(data.sprSizex - 0.05, 1)
		data.sprSizey = math.max(data.sprSizey - 0.05, 1)
	else
		if config.teleportx == false then data.sprSizex = 1 end
		if config.teleporty == false then data.sprSizey = 1 end
	end
	if data.state == STATE.IDLE then
		v.animationFrame = 0
		v.speedX =  0
		v.speedY = 0
		if data.timer >= config.idleDelay then
			data.timer = 0
			data.state = STATE.TELEPORT
			--decideAttack(v,data,config,data.pinch)
		end
	elseif data.state == STATE.MUSHROOM then
		pressButtonAnimate(v,data,config,true)
		if data.timer == 1 then
			if config.sfx_dropMushroomVial then SFX.play(config.sfx_dropMushroomVial) end
			local n = NPC.spawn(config.mushroomID, v.x + v.width / 2 + config.spawnX, v.y + v.height/2 + config.spawnY, v.section, true, true)
			n.speedX = 0
			n.speedY = 1
		end
		if data.timer >= 64 then
			data.timer = 0
			data.state = STATE.TELEPORT
		end
	elseif data.state == STATE.DRONE then
		pressButtonAnimate(v,data,config,true)
		if data.timer == 1 then
			if config.sfx_androidDeploy then SFX.play(config.sfx_androidDeploy) end
			local n = NPC.spawn(config.mushroomID, v.x + v.width / 2 + config.spawnX, v.y + v.height/2 + config.spawnY, v.section, true, true)
			n.speedX = 0
			n.speedY = 1
		end
		if data.timer >= 64 then
			data.timer = 0
			data.state = STATE.TELEPORT
		end
	elseif data.state == STATE.TELEPORT then
		if data.timer == 1 then
			if sfx_teleportDisappear then SFX.play(sfx_teleportDisappear) end
			v.friendly = true
		end
		pressButtonAnimate(v,data,config,true)
		v.speedX = 0
		v.speedY = 0
		data.teleporting = true
		if data.teleporting then
			if data.timer <= 64 then
				if config.teleportx then data.sprSizex = math.max(data.sprSizex - 0.05, 0) end
				if config.teleporty then data.sprSizey = math.max(data.sprSizey - 0.05, 0) end
			else
				if config.teleportx then data.sprSizex = math.min(data.sprSizex + 0.05, 1) end
				if config.teleporty then data.sprSizey = math.min(data.sprSizey + 0.05, 1) end
			end
			if data.timer == 64 then
				if sfx_teleportAppear then SFX.play(sfx_teleportAppear) end
				data.location = RNG.irandomEntry(data.bgoTable)
				v.x = data.location.x + BGO.config[config.teleportBGOID].width/2 - v.width/2
				v.y = data.location.y + BGO.config[config.teleportBGOID].height/2 - v.height/2
			end
		end
		if data.timer >= 128 then
			data.teleporting = false
			v.friendly = false
			data.timer = 0
			data.state = STATE.IDLE
		end
	elseif data.state == STATE.LASER then
		v.animationFrame = 0
		if data.timer == 1 and v.ai1 == 0 then
			SFX.play("Play_age_471_A4 [1].wav")
			v.speedY = -6
		end
		if v.ai1 == 0 then
			v.speedX = 0
			v.speedY = math.clamp(v.speedY + 0.4, -6, 8)
			if v.collidesBlockBottom then
				v.ai1 = 1
				data.timer = 0
				data.spotLimit = v.y + v.height/2
				data.spotY = v.y + v.height/2
				v.speedY = 0
				v.speedX = 0
				Defines.earthquake = 5
				SFX.play("Mech Stomp.wav")
				for i=0,1 do
					local a = Animation.spawn(10,v.x+v.width/2,v.y+v.height*7/8)
					a.x=a.x-a.width/2
					a.y=a.y-a.height/2
					a.speedX = -2 + 4 * i
				end
			end
		elseif v.ai1 == 1 then
			if data.timer % 40 == 10 then
				if config.pulsex then
					data.sprSizex = 1.5
				end
		
				if config.pulsey then
					data.sprSizey = 1.5
				end
				npcutils.faceNearestPlayer(v)
				SFX.play("OOZLaser.wav")
				if v.direction == -1 then
					local n = NPC.spawn(NPC.config[v.id].laserID, v.x + v.width/2 + config.cannonLeftX, v.y + v.height/2 + config.cannonLeftY, v.section, false, true)
						
					n.speedX = 4 * v.direction
					Effect.spawn(10, v.x + v.width/2 + config.cannonLeftX, v.y + v.height/2 + config.cannonLeftY)
				else
					local n = NPC.spawn(NPC.config[v.id].laserID, v.x + v.width/2 + config.cannonRightX, v.y + v.height/2 + config.cannonRightY, v.section, false, true)
						
					n.speedX = 4 * v.direction
					Effect.spawn(10, v.x + v.width/2 + config.cannonRightX, v.y + v.height/2 + config.cannonRightY)
				end
			end
			if data.timer % 40 == 39 then
				data.spotY = data.spotLimit - RNG.irandomEntry{0,10,20,30,40,50,60}
			end
			v.speedX = 0
			if data.timer % 40 < 39 then
				data.spotVectr = vector.v2(
					(v.x+v.width/2) - (v.x+v.width/2),
					(data.spotY) - (v.y+v.height/2)
				):normalize() * 3
				if math.abs(v.y + 0.5 * v.height) - data.spotY > 4 then
					v.speedY = data.spotVectr.y
				else
					v.speedY = 0
				end
			end
			if data.timer >= 240 then
				data.timer = 0
				v.ai1 = 2
			end
		elseif v.ai1 == 2 then
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
				v.speedY = -3
				data.movementSet = 1
				data.movementTimer = 0
			end
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
			local gfxw = NPC.config[v.id].gfxwidth
			local gfxh = NPC.config[v.id].gfxheight
			if gfxw == 0 then gfxw = v.width end
			if gfxh == 0 then gfxh = v.height end
			local frames = Graphics.sprites.npc[v.id].img.height / gfxh
			local framestyle = NPC.config[v.id].framestyle
			local frame = v.animationFrame
			local framesPerSection = frames
			if framestyle == 1 then
				framesPerSection = framesPerSection * 0.5
				if direction == 1 then
					frame = frame + frames
				end
				frames = frames * 2
			elseif framestyle == 2 then
				framesPerSection = framesPerSection * 0.25
				if direction == 1 then
					frame = frame + frames
				end
				frame = frame + 2 * frames
			end
			local p = priority or -46
			afterimages.addAfterImage{
				x = v.x + 0.5 * v.width - 0.5 * gfxw + NPC.config[v.id].gfxoffsetx,
				y = v.y + 0.5 * v.height - 0.5 * gfxh + NPC.config[v.id].gfxoffsety - v.height,
				texture = Graphics.sprites.npc[v.id].img,
				priority = p,
				lifetime = lifetime or 65,
				width = gfxw,
				height = gfxh,
				texOffsetX = 0,
				texOffsetY = frame / frames,
				animWhilePaused = animWhilePaused or false,
				color = color or (Color.cyan .. 0)
			}
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
				v.speedY = -3
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
		local prop1rotator = 0
		local prop1rotatedirection = v.direction
		local prop2rotator = 0
		local prop2rotatedirection = -v.direction
		if data.timer == 1 then v.ai1 = 0 v.ai2 = 0 SFX.play("Machine Noise.wav") end
		prop1rotator = 5
		prop2rotator = 5
		data.prop1rotation = data.prop1rotation + prop1rotator * prop1rotatedirection
		data.prop2rotation = data.prop2rotation + prop2rotator * prop2rotatedirection
		if data.timer == 80 then
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
		if data.timer >= 96 + config.shardIncrement * config.shardTimer then
			data.timer = 0
			v.ai1 = 0
			data.state = STATE.IDLE
			data.prop1rotation = 0
			data.prop2rotation = 0
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
				local n = NPC.spawn(NPC.config[v.id].crystalProjectileID, plr.x + plr.width/2 - 128 + 32 * RNG.randomInt(0,6), plr.y - 128, player.section, false)
				n.animationFrame = -50
			end
		else
			if data.timer >= 160 then
				data.state = STATE.IDLE
				data.timer = 0
			end
		end
    else
		v.speedX = 0
		v.speedY = 0
		v.friendly = true
		v.animationFrame = 0
		if data.timer % 12 == 0 then
			local a = Animation.spawn(config.effectExplosion1ID, math.random(v.x, v.x + v.width), math.random(v.y, v.y + v.height))
			a.x=a.x-a.width/2
			a.y=a.y-a.height/2
			SFX.play(43)
		end
		if data.timer >= 250 then
			v:kill(HARM_TYPE_NPC)
		end
	end
	
	--Give Doc Croc some i-frames to make the fight less cheesable
	--iFrames System made by MegaDood & DRACalgar Law
	if data.iFrames then
		v.friendly = true
		data.hurtTimer = data.hurtTimer + 1
		
		if data.hurtTimer == 1 then
		    if config.sfx_hurt then SFX.play(sfx_hurt) end
			data.state = STATE.HURT
			data.timer = 0
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
			frames = docCrocSettings.frames
		});
	end
	
	--Prevent Doc Croc from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	if Colliders.collide(plr, v) and not v.friendly and data.state ~= STATE.KILL and data.state ~= STATE.HURT and not Defines.cheat_donthurtme then
		plr:harm()
	end
end
function docCroc.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	local config = NPC.config[v.id]
	if v.id ~= npcID then return end

			if data.iFrames == false and data.state ~= STATE.KILL and data.state ~= STATE.HURT then
				local fromFireball = (culprit and culprit.__type == "NPC" and culprit.id == 13 )
				local hpd = 10
				if fromFireball then
					hpd = config.hpDecWeak
					SFX.play(9)
				elseif reason == HARM_TYPE_LAVA then
					v:kill(HARM_TYPE_LAVA)
				else
					hpd = config.hpDecStrong
					data.iFrames = true
					if reason == HARM_TYPE_SWORD then
						if v:mem(0x156, FIELD_WORD) <= 0 then
							SFX.play(89)
							hpd = config.hpDecStrong
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
						hpd = config.hpDecStrong
					end
					if data.iFrames then
						data.hurting = true
						
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
			elseif data.health > 0 then
				v:mem(0x156,FIELD_WORD,60)
			end
	eventObj.cancelled = true
end
local lowPriorityStates = table.map{1,3,4}
function docCroc.onDrawNPC(v)
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]
	data.w = math.pi/65

	--Setup code by Mal8rk
	local pivotOffsetX = 0
	local pivotOffsetY = 0

	local opacity = 1

	local priority = 1
	if lowPriorityStates[v:mem(0x138,FIELD_WORD)] then
		priority = -75
	elseif v:mem(0x12C,FIELD_WORD) > 0 then
		priority = -30
	end

	--Text.print(v.x, 8,8)
	--Text.print(data.timer, 8,32)

	if data.iFrames then
		opacity = math.sin(lunatime.tick()*math.pi*0.25)*0.75 + 0.9
	end

	if data.img then
		-- Setting some properties --
		data.img.x, data.img.y = v.x + 0.5 * v.width + config.gfxoffsetx, v.y + 0.5 * v.height --[[+ config.gfxoffsety]]
		data.img.transform.scale = vector(data.sprSizex, data.sprSizey)
		data.img.rotation = data.angle

		local p = -45

		-- Drawing --
		data.img:draw{frame = v.animationFrame + 1, sceneCoords = true, priority = p, color = Color.white..opacity}
		npcutils.hideNPC(v)
	end
end

--Gotta return the library table!
return docCroc