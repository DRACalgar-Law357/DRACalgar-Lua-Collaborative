--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local easing = require("ext/easing")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
local freeze = require("freezeHighlight")
local afterimages = require("afterimages")
local playerStun = require("playerstun")
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
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

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
	chasingIceID = 841,
	bombID = 134,
	flurryID = 374,
	iceSpikeID = 838,
	laserID = 837,
	frostID = 839,
	prop1Image = Graphics.loadImageResolved("npc-"..npcID.."-prop1.png"),
	prop2Image = Graphics.loadImageResolved("npc-"..npcID.."-prop2.png"),
	icicleImage = Graphics.loadImageResolved("npc-"..npcID.."-icicle.png"),
	prop1OffsetX = 32,
	prop1OffsetY = -32,
	prop2OffsetX = 32,
	prop2OffsetY = -32,
	prop1Height = 192,
	prop2Height = 192,
	icicleHorizontalWidth = 64,
	icicleHorizontalHeight = 32,
	icicleVerticalWidth = 32,
	icicleVerticalHeight = 64,
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
	terminalvelocity = 16,
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
	LASER = 11,
	KILL = 12,
	KAMIKAZE = 13,
	RETURN = 14,
}
local flashColour = Color.white
local flashPriority = -85
local slowTimer = 0

--The onTick function here just makes it so when slowTimer is above 0, it causes the player's movement to be reduced both vertically and horizontally
function cryoBlaster.onTick()
	if slowTimer <= 0 then
		Defines.jumpheight = 20
		Defines.player_walkspeed = 3
		Defines.player_runspeed = 6
	else
		slowTimer = slowTimer - 1
		Defines.jumpheight = 10
		Defines.player_walkspeed = 1.5
		Defines.player_runspeed = 3
	end
end

--If for some reason the player finishes the level while slowed from the Blizzard attack, then reset their movement stuff
function cryoBlaster.onExitLevel(winType)
	Defines.jumpheight = 20
	Defines.player_walkspeed = 3
	Defines.player_runspeed = 6
end

--Code to manually draw the afterimage
local function drawAfterimage(v)
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
		lifetime = 32,
		width = gfxw,
		height = gfxh,
		texOffsetX = 0,
		texOffsetY = frame / frames,
		animWhilePaused = false,
		color = (Color.cyan .. 0)
	}
end

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
			data.icicling = false
			v.ai1 = 0
			v.ai2 = 0
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
	registerEvent(cryoBlaster, "onTick")
	registerEvent(cryoBlaster, "onExitLevel")
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
		data.phase = 0
		data.rndTimer = RNG.randomInt(80,144) + 32
		data.frameTimer = 0
		data.movementTimer = 0
		data.movementSet = 0
		data.movementDelay = RNG.randomInt(360,600)
		data.sprSizex = 1
		data.sprSizey = 1
		data.sprSizex1 = 1
		data.sprSizey1 = 1
		data.sprSizex2 = 1
		data.sprSizey2 = 1
		data.img = data.img or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = config.frames * (1 + config.framestyle), texture = Graphics.sprites.npc[v.id].img}
		data.prop1img = data.prop1img or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = 1, texture = config.prop1Image}
		data.prop2img = data.prop2img or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = 1, texture = config.prop2Image}
			data.icicleimg = data.icicleimg or {
				--Set icicle drawings
				[0] = Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = 4, texture = config.icicleImage},
				[1] = Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = 4, texture = config.icicleImage},
				[2] = Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = 4, texture = config.icicleImage},
			}
		data.angle = 0
		data.prop1rotation = 0
		data.prop2rotation = 0
		data.prop1Timer = 0
		data.prop2Timer = 0
		data.verticalDirection = 0
		data.spotLimit = data.spotLimit or v.y + v.height/2
		data.spotY = data.spotY or v.y + v.height/2
		data.icicling = false
		data.dropTick = 1
		data.icicleHitbox = {
			[0] = Colliders.Box(v.x - (v.width * 1.2), v.y - (v.height * 1), config.icicleHorizontalWidth, config.icicleHorizontalHeight),
			[1] = Colliders.Box(v.x - (v.width * 1.2), v.y - (v.height * 1), config.icicleVerticalWidth, config.icicleVerticalHeight),
			[2] = Colliders.Box(v.x - (v.width * 1.2), v.y - (v.height * 1), config.icicleHorizontalWidth, config.icicleHorizontalHeight)
		}
		data.kamikaze = false
		data.battleOpacity = 0
		if data.weather == nil then
			data.weather = Section(player.section).effects.weather
			data.screenEffect = Section(player.section).effects.screenEffect
		end
	end
	local oldIcicling = data.icicling
	for i=0,2 do
		if data.icicleHitbox[i] then
			if i == 0 then
				data.icicleHitbox[i].x = v.x + v.width/2 - data.icicleHitbox[i].width/2 + config.cannonLeftX
				data.icicleHitbox[i].y = v.y + v.height/2 - data.icicleHitbox[i].height/2 + config.cannonLeftY
			elseif i == 1 then
				data.icicleHitbox[i].x = v.x + v.width/2 - data.icicleHitbox[i].width/2 + config.cannonUpX
				data.icicleHitbox[i].y = v.y + v.height/2 - data.icicleHitbox[i].height/2 + config.cannonUpY
			else
				data.icicleHitbox[i].x = v.x + v.width/2 - data.icicleHitbox[i].width/2 + config.cannonRightX
				data.icicleHitbox[i].y = v.y + v.height/2 - data.icicleHitbox[i].height/2 + config.cannonRightY
			end
			if config.debug then
				data.icicleHitbox[i]:Debug(true)
			end
			if Colliders.collide(plr,data.icicleHitbox[i]) and data.icicling then
				plr:harm()
			end
		end
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
	v.animationFrame = 0
	if (data.health <= settings.hp*2/3 and data.phase == 0) or (data.health <= settings.hp*1/3 and data.phase == 1) then
		data.phase = data.phase + 1
		if settings.mushroom == true then
			SFX.play(7)
			local n = NPC.spawn(9, v.x + v.width / 2, v.y + v.height/2)
			n.dontMove = true
			n.speedY = -5
		end
	end
	if not data.teleporting then
		data.sprSizex = math.max(data.sprSizex - 0.05, 1)
		data.sprSizey = math.max(data.sprSizey - 0.05, 1)
	else
		data.sprSizey = 1
	end
	data.dirVectr = vector.v2(
		(v.spawnX + 32) - (v.x + v.width * 0.5),
		(v.spawnY + 48) - (v.y + v.height * 0.5)
		):normalize() * 5
	if data.moving and data.state ~= STATE.KILL and data.state ~= STATE.KAMIKAZE and data.state ~= STATE.RETURN and data.state ~= STATE.DASH and data.state ~= STATE.LASER and data.state ~= STATE.FROST and data.state ~= STATE.ICICLE then
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
		if data.timer == 32 then
			data.rndTimer = RNG.randomInt(80,144) + 32
			if data.dropTick <= 0 then
				local npctable = {}
				table.insert(npctable,config.bombID)
				if data.phase >= 1 then table.insert(npctable,config.flurryID) end
				if data.phase >= 2 then table.insert(npctable,config.iceSpikeID) end
				if #npctable > 0 then
					if config.pulsex then
						data.sprSizex = 1.5
					end
			
					if config.pulsey then
						data.sprSizey = 1.5
					end
					SFX.play("Air Bullet.wav")
					local n = NPC.spawn(RNG.irandomEntry(npctable), v.x + v.width/2 + config.cannonDownX, v.y + v.height/2 + config.cannonDownY, v.section, false, true)
					
					n.speedX = 0
					n.speedY = 3
					Effect.spawn(10, v.x + v.width/2 + config.cannonDownX, v.y + v.height/2 + config.cannonDownY)
				end
				data.dropTick = RNG.randomInt(0,1)
			else
				data.dropTick = data.dropTick - 1
			end
		end
		if data.timer >= data.rndTimer then
			data.timer = 0
			local options = {}
			if data.phase == 0 and data.statelimit ~= STATE.ICE then table.insert(options,STATE.ICE) end
			if data.phase == 0 and data.statelimit ~= STATE.DIAMOND_SAW  then table.insert(options,STATE.DIAMOND_SAW) end
			if data.phase >= 1 and data.statelimit ~= STATE.BARRAGE  then table.insert(options,STATE.BARRAGE) end
			if data.phase == 0 and data.statelimit ~= STATE.SHURIKEN  then table.insert(options,STATE.SHURIKEN) end
			if data.phase >= 2 and data.statelimit ~= STATE.SNOWTRAP  then table.insert(options,STATE.SNOWTRAP) table.insert(options,STATE.SNOWTRAP) table.insert(options,STATE.SNOWTRAP) end
			if data.phase >= 2 and data.statelimit ~= STATE.DASH  then table.insert(options,STATE.DASH) end
			if data.phase >= 2 and data.statelimit ~= STATE.LASER  then table.insert(options,STATE.LASER) end
			if data.phase >= 1 and data.statelimit ~= STATE.FROST  then table.insert(options,STATE.FROST) end
			if data.phase >= 1 and data.statelimit ~= STATE.ICICLE  then table.insert(options,STATE.ICICLE) end
			if #options > 0 then
				data.state = RNG.irandomEntry(options)
			end
			data.statelimit = data.state

		end
	elseif data.state == STATE.ICICLE then
		v.animationFrame = 0
		if data.timer == 1 and v.ai1 == 0 then
			SFX.play("Missile.wav")
			v.speedY = -6
		end
		if v.ai1 == 0 then
			v.speedX = 0
			v.speedY = math.clamp(v.speedY + 0.4, -6, 8)
			if v.collidesBlockBottom then
				v.ai1 = 1
				data.timer = 0
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
			drawAfterimage(v)
		elseif v.ai1 == 1 then
			v.speedX = 0
			v.speedY = 0
			if data.timer <= 60 and data.timer % 10 == 5 then
				for i=0,2 do
					local ptl = Animation.spawn(80, math.random(v.x, v.x + v.width) - 4, math.random(v.y, v.y + v.height) - 4)
					ptl.speedY = -2
					ptl.x=ptl.x-ptl.width/2
					ptl.y=ptl.y-ptl.height/2
				end
				SFX.play(59)
			end
			if data.timer == 60 then
				data.icicling = true
				SFX.play("ffvi_stun.wav")
			end
			if data.timer >= 120 then
				data.timer = 0
				v.ai1 = 2
			end
		elseif v.ai1 == 2 then
			chasePlayers(v)
			v.speedX = math.clamp(v.speedX + 0.2 * v.data._basegame.direction, -7, 7)
			v.speedY = math.clamp(v.speedY + 0.2, -6, 8)
			if v.direction == -v.data._basegame.direction then
				v.direction = -v.direction
				SFX.play("swipe.ogg")
			end
			if data.timer >= 300 then
				data.timer = 0
				v.ai1 = 3
				data.icicling = false
			end
			drawAfterimage(v)
		elseif v.ai1 == 3 then
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
	elseif data.state == STATE.FROST then
		v.animationFrame = 0
		if data.timer == 1 and v.ai1 == 0 then
			SFX.play("CryoFrostStart.wav")
			v.friendly = true
		end
		if v.ai1 == 0 then
			v.speedX = 0
			v.speedY = 0
			data.teleporting = true
			if data.teleporting then
				if data.timer <= 64 then
					data.sprSizex = math.max(data.sprSizex - 0.05, 0)
					data.sprSizey = math.max(data.sprSizey - 0.05, 1)
					data.sprSizex1 = data.sprSizex
					data.sprSizey1 = data.sprSizey
					data.sprSizex2 = data.sprSizex
					data.sprSizey2 = data.sprSizey
				else
					data.sprSizex = math.min(data.sprSizex + 0.05, 1)
					data.sprSizey = math.min(data.sprSizey + 0.05, 1)
					data.sprSizex1 = data.sprSizex
					data.sprSizey1 = data.sprSizey
					data.sprSizex2 = data.sprSizex
					data.sprSizey2 = data.sprSizey
				end
				if data.timer == 64 then
					v.x,v.y = plr.x + plr.width/2 - v.width/2, plr.y + plr.height/2 - v.height/2 - 160
					v.friendly = false
				end
			end
			if data.timer >= 128 then
				data.teleporting = false
				v.ai1 = 1
				v.friendly = false
				data.timer = 0
			end
		elseif v.ai1 == 1 then
			if data.timer % 6 == 3 and data.timer <= 100 then
				if config.pulsex then
					data.sprSizex = 1.5
				end
		
				if config.pulsey then
					data.sprSizey = 1.5
				end
				SFX.play("CryoFrostEmit.wav")
				local n = NPC.spawn(NPC.config[v.id].frostID, v.x + v.width/2 + config.cannonDownX, v.y + v.height/2 + config.cannonDownY, v.section, false, true)
				n.speedX = RNG.randomInt(-3,3)
				n.speedY = 6
				Effect.spawn(10, v.x + v.width/2 + config.cannonDownX, v.y + v.height/2 + config.cannonDownY)
			end
			chasePlayers(v)
			v.speedX = math.clamp(v.speedX + 0.15 * v.data._basegame.direction, -6, 6)
			v.speedY = math.sin(-data.timer/12)*6 / 3.5
			if data.timer >= 120 then
				data.timer = 0
				v.ai1 = 2
			end
			for k, p in ipairs(Player.get()) do --Section copypasted from the Sledge Bros. code
				if playerStun.isStunned(k) then
					data.timer = 0
					v.speedX = 0
					v.speedY = 0
					v.ai1 = 0
					data.state = STATE.TRAPPED_PLAYER
				end
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
			if data.timer >= 64 then
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
			drawAfterimage(v)
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
			drawAfterimage(v)
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
	elseif data.state == STATE.RETURN then
		if math.abs(v.spawnX - v.x) <= 12 and math.abs(v.spawnY - v.y) <= 64 then
			v.x = v.spawnX
			v.y = v.spawnY
			v.speedX = 0
			v.speedY = 0
			--When enough time has passed, go into an attack phase
			if data.timer >= 96 then
				if data.kamikaze == false then
					if data.shuriken and data.shuriken.isValid then
						data.state = STATE.SHURIKEN
					else
						data.state = STATE.IDLE
					end
				else
					data.state = STATE.KAMIKAZE
				end
				data.prop1rotation = 0
				data.prop2rotation = 0
				data.icicling = false
				v.ai1 = 0
				v.ai2 = 0
				data.timer = 0
			end
			npcutils.faceNearestPlayer(v)
		else
			v.speedX = data.dirVectr.x
			v.speedY = data.dirVectr.y
			data.timer = 0
		end
		v.animationFrame = 0
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
				data.shurikenDisplay = true
				data.prop1rotation = 0
				data.prop2rotation = 0
			end
		end
	elseif data.state == STATE.KAMIKAZE then
		if v.ai1 == 0 then
			--Blizzard
			
			--Cause a snow effect
			Section(player.section).effects.weather = 2
			--Drop Icicles
			if data.timer % 8 == 2 then
				local n = NPC.spawn(NPC.config[v.id].chasingIceID, Camera.get()[1].x + RNG.randomInt(14, Camera.get()[1].width-14), Camera.get()[1].y + 1 * 10 - 60, player.section, true, true)
				n.ai1 = 36
				n.ai2 = 0
				n.ai3 = 1
				n.ai4 = 1.5
				n.ai5 = 0.1
				Defines.earthquake = 2
			end
			if data.timer <= 32 then
				if data.timer == 1 then
					--Draw it here
					data.screenFlash = true
					flashColour = Color.darkgrey
					flashPriority = -20
					SFX.play("smrpg_mallow_snowy.wav")
				end
				data.battleOpacity = data.battleOpacity + 0.02
			else
				--At the end of the attack, cause the player to be slow
				if data.timer >= 428 then
					data.battleOpacity = data.battleOpacity - 0.02
					if data.timer == 460 then
						v.ai1 = 1
						data.battleOpacity = 0
						data.timer = 0
						data.screenFlash = false
						Section(player.section).effects.weather = data.weather
						slowTimer = 384
					end
				end
			end
		elseif v.ai1 == 1 then
			if data.timer % 40 == 24 then
				SFX.play(RNG.irandomEntry{"s500_shot.wav","s501_shot.wav"})
				local n = NPC.spawn(NPC.config[v.id].chasingIceID, v.x + v.width/2, v.y + v.height/2 - 64, v.section, false, true)
				n.speedX = RNG.random(-6,6) * 2
				n.speedY = RNG.random(-6,6) * 1.5
				n.ai1 = 0
				n.ai2 = 0
				n.ai3 = 0
				n.ai4 = 1.5
				n.ai5 = 0.1
				n.noblockcollision = true
			end
			if data.timer >= 420 then
				data.timer = 0
				v.ai1 = 2
				v.ai2 = 0
				v.speedY = -6
				SFX.play("espeon_psyshock.wav")
			end
		elseif v.ai1 == 2 then
			if v.ai2 > 0 then
				chasePlayers(v)
				v.speedX = math.clamp(v.speedX + 0.1 * v.data._basegame.direction, -6.5, 6.5)
			end
			v.speedY = v.speedY + Defines.npc_grav
			if data.timer % 4 == 0 then
				for i=0,2 do
					local ptl = Animation.spawn(80, math.random(v.x, v.x + v.width) - 4, math.random(v.y, v.y + v.height) - 4)
					ptl.speedY = -2
					ptl.x=ptl.x-ptl.width/2
					ptl.y=ptl.y-ptl.height/2
				end
			end
			if v.collidesBlockBottom then
				if v.ai2 > 0 then
					if v.ai2 < 5 then
						local id = config.iceRockID
						SFX.play("smrpg_enemy_crystal.wav")
						for i=0,4 do
							local f = NPC.spawn(id, v.x + 0.5 * v.width, v.y + v.height - 0.5 * NPC.config[id].height, v:mem(0x146, FIELD_WORD), false, true)
							f.speedY = -11
							f.speedX = -3 + (1.5 * i)
						end
					else
						local id = config.iceRockID
						SFX.play("smrpg_enemy_crystal.wav")
						for i=0,8 do
							local f = NPC.spawn(id, v.x + 0.5 * v.width, v.y + v.height - 0.5 * NPC.config[id].height, v:mem(0x146, FIELD_WORD), false, true)
							f.speedY = -13
							f.speedX = -4 + (1 * i)
						end
					end
				end
				if v.ai2 == 4 then
					v.ai2 = v.ai2 + 1
					v.speedY = -13.5
					SFX.play("cryogigajump.wav")
				elseif v.ai2 >= 5 then
					data.timer = 0
					data.state = STATE.KILL
					v.ai1 = 0
					v.ai2 = 0
					v.speedX = 0
					v.speedY = 0
					Defines.earthquake = 9
					for i = 1,40 do
						local ptl = Animation.spawn(950, math.random(v.x - v.width / 2, v.x + v.width / 2), math.random(v.y - v.height / 2, v.y + v.height / 2))
						ptl.speedX = RNG.random(-10,10)
						ptl.speedY = RNG.random(-10,10)
						ptl.x=ptl.x-ptl.width/2
						ptl.y=ptl.y-ptl.height/2
					end
					SFX.play("Small Explosion.wav")
				else
					v.ai2 = v.ai2 + 1
					v.speedY = -10
				end
				SFX.play("Mech Stomp.wav")
			end
		end
    else
		v.speedX = 0
		v.speedY = 0
		v.friendly = true
		if lunatime.tick() % 64 > 4 then 
			v.animationFrame = 0
		else
			v.animationFrame = -50
		end
		if data.timer % 12 == 0 then
			local a = Animation.spawn(config.effectExplosion1ID, math.random(v.x, v.x + v.width), math.random(v.y, v.y + v.height))
			a.x=a.x-a.width/2
			a.y=a.y-a.height/2
			SFX.play("s3k_detonate.ogg")
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
	local newIcicling = data.icicling
	if oldIcicling ~= newIcicling then
		for i=0,2 do
			if data.icicleHitbox[i] then
				if newIcicling == true then
					Animation.spawn(80, math.random(data.icicleHitbox[i].x, data.icicleHitbox[i].x + data.icicleHitbox[i].width) - 4, math.random(data.icicleHitbox[i].y, data.icicleHitbox[i].y + data.icicleHitbox[i].height) - 4)
					Animation.spawn(80, math.random(data.icicleHitbox[i].x, data.icicleHitbox[i].x + data.icicleHitbox[i].width) - 4, math.random(data.icicleHitbox[i].y, data.icicleHitbox[i].y + data.icicleHitbox[i].height) - 4)
					Animation.spawn(80, math.random(data.icicleHitbox[i].x, data.icicleHitbox[i].x + data.icicleHitbox[i].width) - 4, math.random(data.icicleHitbox[i].y, data.icicleHitbox[i].y + data.icicleHitbox[i].height) - 4)
					Animation.spawn(80, math.random(data.icicleHitbox[i].x, data.icicleHitbox[i].x + data.icicleHitbox[i].width) - 4, math.random(data.icicleHitbox[i].y, data.icicleHitbox[i].y + data.icicleHitbox[i].height) - 4)
					Animation.spawn(80, math.random(data.icicleHitbox[i].x, data.icicleHitbox[i].x + data.icicleHitbox[i].width) - 4, math.random(data.icicleHitbox[i].y, data.icicleHitbox[i].y + data.icicleHitbox[i].height) - 4)
					Animation.spawn(80, math.random(data.icicleHitbox[i].x, data.icicleHitbox[i].x + data.icicleHitbox[i].width) - 4, math.random(data.icicleHitbox[i].y, data.icicleHitbox[i].y + data.icicleHitbox[i].height) - 4)
					Animation.spawn(80, math.random(data.icicleHitbox[i].x, data.icicleHitbox[i].x + data.icicleHitbox[i].width) - 4, math.random(data.icicleHitbox[i].y, data.icicleHitbox[i].y + data.icicleHitbox[i].height) - 4)
					Animation.spawn(80, math.random(data.icicleHitbox[i].x, data.icicleHitbox[i].x + data.icicleHitbox[i].width) - 4, math.random(data.icicleHitbox[i].y, data.icicleHitbox[i].y + data.icicleHitbox[i].height) - 4)
				else
					SFX.play(4)
					Effect.spawn(751, data.icicleHitbox[i].x + data.icicleHitbox[i].width / 2, data.icicleHitbox[i].y - data.icicleHitbox[i].height/2)
				end
			end
		end
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
				if v.data._settings.kamikaze == false then
					data.state = STATE.KILL
				else
					data.state = STATE.RETURN
					data.kamikaze = true
				end
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

	if v.legacyBoss == true and data.state ~= STATE.KILL and data.state ~= STATE.KAMIKAZE and data.health then
		Graphics.drawImage(hpboarder, 740, 120)
		local healthoffset = 126
		healthoffset = healthoffset-(126*(data.health/settings.hp))
		Graphics.drawImage(hpfill, 748, 128+healthoffset, 0, 0, 12, 126-healthoffset)
	end
	if data.screenFlash then
		Graphics.drawScreen{
		color = flashColour .. data.battleOpacity,
		priority = flashPriority,
		}
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
	end

	--Text.print(v.x, 8,8)
	--Text.print(data.timer, 8,32)

	if data.iFrames then
		opacity = math.sin(lunatime.tick()*math.pi*0.25)*0.75 + 0.9
	end
	if data.icicling then
		for i=0,2 do
			if data.icicleimg[i] then
				-- Setting some properties --
				local offsetX
				local offsetY
				local frameSet
				if i == 0 then
					offsetX = config.cannonLeftX
					offsetY = config.cannonLeftY
					frameSet = 2
				elseif i == 1 then
					offsetX = config.cannonUpX
					offsetY = config.cannonUpY
					frameSet = 1
				else
					offsetX = config.cannonRightX
					offsetY = config.cannonRightY
					frameSet = 3
				end
				data.icicleimg[i].x, data.icicleimg[i].y = v.x + 0.5 * v.width + config.gfxoffsetx + offsetX, v.y + 0.5 * v.height + offsetY
				data.icicleimg[i].transform.scale = vector(1, 1)
		
				local p = -44.9
		
				-- Drawing --
				data.icicleimg[i]:draw{frame = frameSet + 1, sceneCoords = true, priority = p, color = Color.white..opacity}
			end
		end
	end
	if data.shurikenDisplay then
		if data.prop1img then
			-- Setting some properties --
			data.prop1img.x, data.prop1img.y = v.x + 0.5 * v.width + config.gfxoffsetx, v.y + 0.5 * v.height --[[+ config.gfxoffsety]]
			data.prop1img.transform.scale = vector(data.sprSizex1, data.sprSizey1)
			data.prop1img.rotation = data.prop1rotation
	
			local p = -45.1
	
			-- Drawing --
			data.prop1img:draw{frame = 0, sceneCoords = true, priority = p, color = Color.white..opacity}
		end
		if data.prop2img then
			-- Setting some properties --
			data.prop2img.x, data.prop2img.y = v.x + 0.5 * v.width + config.gfxoffsetx, v.y + 0.5 * v.height --[[+ config.gfxoffsety]]
			data.prop2img.transform.scale = vector(data.sprSizex2, data.sprSizey2)
			data.prop2img.rotation = data.prop2rotation
	
			local p = -45.2
	
			-- Drawing --
			data.prop2img:draw{frame = 0, sceneCoords = true, priority = p, color = Color.white..opacity}
		end
	end

	if data.img then
		-- Setting some properties --
		data.img.x, data.img.y = v.x + 0.5 * v.width + config.gfxoffsetx, v.y + 0.5 * v.height --[[+ config.gfxoffsety]]
		if config.framestyle == 1 then
			data.img.transform.scale = vector(data.sprSizex * -v.direction, data.sprSizey)
		else
			data.img.transform.scale = vector(data.sprSizex, data.sprSizey)
		end
		data.img.rotation = data.angle

		local p = -45

		-- Drawing --
		
		data.img:draw{frame = v.animationFrame, sceneCoords = true, priority = p, color = Color.white..opacity}
		npcutils.hideNPC(v)
	end
end

--Gotta return the library table!
return cryoBlaster
