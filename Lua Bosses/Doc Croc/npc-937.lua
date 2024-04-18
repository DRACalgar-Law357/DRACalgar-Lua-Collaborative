--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
--Create the library table
local docCroc = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
--A list of states Doc Croc can take in
local STATE = {
	--Stays in place briefly before making an attack
	IDLE = 0,
	--Teleports to specific spots placed from specified BGOs
	TELEPORT = 1,
	--Comes down to his position from the top of the screen and starts to click a button to open his machine's mouth
	INTRO = 2,
	--Spawns fireball vials that spew fireball upon block collision; uses sets to determine their velocity
	VIAL = 3,
	--Spawns a bomb that spawns shockwaves
	SHOCKWAVE = 4,
	--Spawns an aerial drone that chases the player briefly before disappearing.
	DRONE = 5,
	--Shoots homing energy balls in specified sets of velocity
	ENERGY1 = 6,
	--Shoots straightforward energy balls in specified sets of velocity; can shoot two simultaneously if his set is configured
	ENERGY2 = 7,
	--"Oops, I dropped a mushroom vial." -- Doc Croc
	MUSHROOM = 8,
	--Drops specified NPCs; one, usually a Springboard, that disappears after some time or after the boss has been hit; the other, usually a Bob-Omb, that doesn't have to disappear
	DROP = 9,
	--Self-explanatory
	KILL = 10,
	HURT = 11,
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
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

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
	--This decreases the hp when hit by strong attacks
	hpDecStrong = 4,
	--This decreases the hp when hit by a fireball
	hpDecWeak = 1,
	--The drone chases the player and disappears after a set of frames; used in STATE.DRONE
	droneID = 298,--944,
	--The vials spout SMW Fireballs after a collision; used in STATE.VIAL
	vialID = 363,--943,
	--Spreads shockwaves and explodes after a collision; used in STATE.SHOCKWAVE
	shockwaveBombID = 361,--941,
	--This Energy Ball after a set amount of frames will target at the player's position and turn into a different Energy Ball; used in STATE.ENERGY2
	energyBall1ID = 210,--938,
	--This Energy Ball is just a straight projectile; used in STATE.ENERGY1
	energyBall2ID = 699,--940,
	--A vial that spawns a non-moving mushroom; used in STATE.MUSHROOM
	mushroomID = 250,--946,
	--These are the NPCs that Doc Croc will drop after each attack generally used in dropPatternTable and dropPinchTable
	--This npcID can be spawned continuously on screen without a limit.
	bombID = 136,
	--This npcID can be spawned once and other cannot be spawned until this despawns. It'd disappear after the boss is hit or after some time.
	springID = 26,
	--A config component in which is used in a non-pinch state, he goes over the procedures in certain attacks what to spawn after each
	dropPatternTable = {
		[STATE.ENERGY1] = 136,
		[STATE.SHOCKWAVE] = 26,
		[STATE.ENERGY2] = 136,
		[STATE.VIAL] = 26,
		[STATE.DRONE] = 0,
	},
	--A config component in which is used in a pinch state, he goes over a randomized selection of what NPC to drop (may put 0 to have him not drop anything)
	dropRandomTable = {
		0,
		136,
		26,
	},
	dropRandomTableWithoutSpring = {
		0,
		136,
	},
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
	--Coordinate offset when spawning NPCs; starts at 0 on the physical center coordinate
	spawnX = 0,
	spawnY = 12,
	pulsex = false, -- controls the scaling of the sprite when firing
	pulsey = false,
	teleportx = true, --controls the scaling of the sprite when teleporting
	teleporty = true,
	cameraOffsetY = -32,
	idleDelay = 72,
	--Each specific timers will run a cooldown until they disappear
	springDelayUntilDisappear = 480,
	droneDelayUntilDisappear = 300,
	--Goes over sets with each primary sets going over how the projectiles' velocity is made
	energyBall1Sets = {
		[0] = {
			[0] = {
				speed = 2,
				angle = 18,
			},
			[1] = {
				speed = 2,
				angle = 50,
			},
			[2] = {
				speed = 2,
				angle = 82,
			},
		},
		[1] = {
			[0] = {
				speed = 2,
				angle = -18,
			},
			[1] = {
				speed = 2,
				angle = -50,
			},
			[2] = {
				speed = 2,
				angle = -82,
			},
		},
	},
	energyBall1DelayBefore = 16,
	energyBall1DelayAfter = 72,
	energyBall1DelayBetweenRound = 10,
	energyBall1Consecutive = 3, --Increments over to use sets

	energyBall2Speed = 3,
	energyBall2InitAngle = 180,
	energyBall2InitAngleDirOffset = 10,
	energyBall2AngleIncrement = 20,
	energyBall2Consecutive = 3,
	energyBall2Style = 0, --0 - Shoots 2 volleys on each increment and direction; 1 - Shoots 1 volley on a random init direction and increments on an angle.
	energyBall2DelayBefore = 16,
	energyBall2DelayAfter = 72,
	energyBall2DelayBetweenRound = 10,
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
	vialDelayAfter = 72,
	vialDelayBetweenRound = 12,
	shockwaveDelayBefore = 16,
	shockwaveDelayAfter = 64,
	droneDelayBefore = 16,
	droneDelayAfter = 160,
	dropDelayBefore = 16,
	dropDelayAfter = 32,
	hurtDelay = 64,
	teleportBGOID = 937, --Uses these BGOs to teleport there
	teleportToSpawnPoint = true,
	--SFX List
	sfx_energyBall1 = 16,
	sfx_energyBall2 = 16,
	sfx_droneDeploy = 18,
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
	--If set to 0, plays an audio at the first instance of the energy ball attack; if set to 1, plays an audio every instance of the energy balls spawned.
	energyBall1VoiceSet = 0,
	energyBall2VoiceSet = 0,

	mushroomFrequency = 3, --Uses this config in a pinch state to throw a mushroom vial. Can only be used once when used.
	mushroomHP = 8, --As the hp goes over this config, Doc Croc will have a chance to drop a mushroom vial.
	iFramesDelay = 60,
	pinchHP = 8, --As the hp goes over this config, Doc Croc shifts into pinch mode; used in pinchSet 0
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

local function SFXPlay(sfx)
	if sfx then
		SFX.play(sfx)
	end
end

local function SFXPlayTable(sfx)
	if sfx then
		local sfxChoice = RNG.irandomEntry(sfx)
		if sfxChoice and sfxChoice.id then
			SFX.play(sfxChoice.id, sfxChoice.volume)
		end
	end
end

local function pressButtonAnimate(v,data,config,chooseNewAnimation)
	if data.timer == 1 and chooseNewAnimation then data.pressButtonAnimate = RNG.randomInt(0,1) end
	v.animationFrame = 1 + data.pressButtonAnimate
end

local function decideAttack(v,data,config,settings,pinch)
	local options = {}
	local mushroomChance = {}
	if data.health <= config.mushroomHP and settings.mushroom then
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
			if data.pattern > #config.patternTable - 1 then
				data.pattern = 0
			else
				data.pattern = data.pattern + 1
			end
		end
	end
	if #options > 0 then
		data.state = RNG.irandomEntry(options)
		data.selectedAttack = data.state
	end
	data.timer = 0
end

function docCroc.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height/2)
	local config = NPC.config[v.id]
	local settings = v.data._settings
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
		settings.intro = settings.intro or true
		settings.mushroom = settings.mushroom or true

		data.w = math.pi/65
		data.timer = data.timer or 0
		data.hurtTimer = data.hurtTimer or 0
		data.iFrames = false
		data.health = config.hp
		if not settings.intro then
			data.state = STATE.IDLE
		else
			data.state = STATE.INTRO
			v.y = camera.y + config.cameraOffsetY - v.height/2
		end
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
		data.selectedAttack = 0
		data.springTimer = 0
		data.droneTimer = 0
		data.bgoTable = BGO.get(NPC.config[v.id].teleportBGOID)
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
	if data.spring then
		if data.spring.isValid then
			data.springTimer = data.springTimer - 1
			if data.springTimer <= 0 then
				data.spring:kill(HARM_TYPE_NPC)
				data.spring = nil
			end
		else
			data.sprng:kill(HARM_TYPE_NPC)
			data.spring = nil
		end
	else
		data.springTimer = 0
	end
	if data.drone then
		if data.drone.isValid then
			data.droneTimer = data.droneTimer - 1
			if data.droneTimer <= 0 then
				data.drone:kill(HARM_TYPE_NPC)
				data.drone = nil
			end
		else
			data.drone:kill(HARM_TYPE_NPC)
			data.drone = nil
		end
	else
		data.droneTimer = 0
	end
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
			decideAttack(v,data,config,settings,data.pinch)
		end
	elseif data.state == STATE.MUSHROOM then
		pressButtonAnimate(v,data,config,true)
		if data.timer == 1 then
			SFXPlay(config.sfx_dropMushroomVial)
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
		if data.timer == config.droneDelayBefore and not data.drone then
			SFXPlay(config.sfx_droneDeploy)
			SFXPlayTable(config.sfx_voiceAttackTable)
			data.drone = NPC.spawn(config.droneID, v.x + v.width / 2 + config.spawnX, v.y + v.height/2 + config.spawnY, v.section, true, true)
			data.droneTimer = config.droneDelayUntilDisappear
		end
		if data.timer >= config.droneDelayAfter + config.droneDelayBefore then
			data.timer = 0
			data.state = STATE.DROP
		end
	elseif data.state == STATE.DROP then
		pressButtonAnimate(v,data,config,true)
		if data.timer == config.dropDelayBefore then
			SFXPlay(config.sfx_dropNPC)
			local npcChoice = 0
			
			if (data.pinch and config.dropNPCStylePinchRandomly) or (not data.pinch and config.dropNPCStyleNonPinchRandomly) then
				npcChoice = RNG.irandomEntry(config.dropRandomTable)
				if npcChoice == config.springID and data.spring then
					npcChoice = RNG.irandomEntry(config.dropRandomTableWithoutSpring)
				end
			else
				npcChoice = config.dropPatternTable[data.selectedAttack]
				if npcChoice == config.springID and data.spring then
					npcChoice = 0
				end
			end
			if npcChoice == config.springID and not data.spring then
				data.spring = NPC.spawn(npcChoice, v.x + v.width / 2 + config.spawnX, v.y + v.height/2 + config.spawnY, v.section, true, true)
				data.springTimer = config.springDelayUntilDisappear
			elseif npcChoice ~= 0 then
				local n = NPC.spawn(npcChoice, v.x + v.width / 2 + config.spawnX, v.y + v.height/2 + config.spawnY, v.section, true, true)
			end
		end
		if data.timer >= config.dropDelayAfter + config.dropDelayBefore then
			data.timer = 0
			data.state = STATE.TELEPORT
		end
	elseif data.state == STATE.SHOCKWAVE then
		pressButtonAnimate(v,data,config,true)
		if data.timer == config.shockwaveDelayBefore then
			SFXPlay(config.sfx_bombDeploy)
			SFXPlayTable(config.sfx_voiceAttackTable)
			local n = NPC.spawn(config.shockwaveBombID, v.x + v.width / 2 + config.spawnX, v.y + v.height/2 + config.spawnY, v.section, true, true)
			n.ai1 = config.droneDelayUntilDisappear
		end
		if data.timer >= config.shockwaveDelayAfter + config.shockwaveDelayBefore then
			data.timer = 0
			data.state = STATE.DROP
		end
	elseif data.state == STATE.VIAL then
		pressButtonAnimate(v,data,config,true)
		if data.timer == 1 then v.ai2 = 0 v.ai1 = RNG.randomInt(0,#config.vialSet-1) end
		if data.timer == config.vialDelayBefore + config.vialDelayBetweenRound then
			SFXPlay(config.sfx_vialDrop)
			local dir = -vector.right2:rotate(90 + config.vialSet[v.ai1][v.ai2].angle)
			local n = NPC.spawn(config.vialID, v.x + v.width/2 + config.spawnX, v.y + v.height/2 + config.spawnY, v.section, true, true)
			n.speedX = dir.x * config.vialSet[v.ai1][v.ai2].speed
			n.speedY = dir.y * config.vialSet[v.ai1][v.ai2].speed
			if v.ai2 < #config.vialSet[v.ai1] then
				data.timer = config.vialDelayBefore
				v.ai2 = v.ai2 + 1
			else
				v.ai2 = 0
			end
		end
		if data.timer >= config.vialDelayBefore + config.vialDelayBetweenRound + config.vialDelayAfter then
			data.timer = 0
			data.state = STATE.DROP
		end
	elseif data.state == STATE.ENERGY1 then
		pressButtonAnimate(v,data,config,true)
		Text.print(v.ai1,110,110)
		Text.print(v.ai2,110,126)
		Text.print(v.ai3,110,142)
		if data.timer == 1 then v.ai3 = 0 end
		if data.timer == config.energyBall1DelayBefore + config.energyBall1DelayBetweenRound then
			SFXPlay(config.sfx_energyBall1)
			v.ai2 = 0
			v.ai1 = RNG.randomInt(0,#config.energyBall1Sets)
			for i=0,#config.energyBall1Sets[v.ai1] do
				local dir = -vector.right2:rotate(90 + config.energyBall1Sets[v.ai1][v.ai2].angle)
				local n = NPC.spawn(config.energyBall1ID, v.x + v.width/2 + config.spawnX, v.y + v.height/2 + config.spawnY, v.section, true, true)
				n.speedX = dir.x * config.energyBall1Sets[v.ai1][v.ai2].speed
				n.speedY = dir.y * config.energyBall1Sets[v.ai1][v.ai2].speed
				v.ai2 = v.ai2 + 1
			end
			if v.ai3 == 0 then
				SFXPlayTable(config.sfx_voiceAttackTable)
			end
			if v.ai3 < config.energyBall1Consecutive then
				data.timer = config.energyBall1DelayBetweenRound
				v.ai3 = v.ai3 + 1
			else
				v.ai3 = 0
			end
		end
		if data.timer >= config.energyBall1DelayBefore + config.energyBall1DelayBetweenRound + config.energyBall1DelayAfter then
			data.timer = 0
			data.state = STATE.DROP
		end
	elseif data.state == STATE.ENERGY2 then
		pressButtonAnimate(v,data,config,true)
		if data.timer == 1 then
			v.ai2 = 0
			if config.energyBall2Style == 0 then
				v.ai1 = 0
			else
				v.ai1 = RNG.randomInt(1,2)
			end
		end
		if data.timer == config.energyBall2DelayBefore + config.energyBall2DelayBetweenRound then
			SFXPlay(config.sfx_energyBall2)
			local set = 0
			if v.ai1 == 0 then
				set = 1
			end
			local angleDir = 1
			if v.ai1 == 1 then angleDir = -1 end
			for i=0,set do
				if i == 1 then angleDir = -1 end
				local dir = -vector.right2:rotate(90 + config.energyBall2InitAngle + (config.energyBall2InitAngleDirOffset + v.ai2 * config.energyBall2AngleIncrement) * angleDir)
				local n = NPC.spawn(config.energyBall2ID, v.x + v.width/2 + config.spawnX, v.y + v.height/2 + config.spawnY, v.section, true, true)
				n.speedX = dir.x * config.energyBall2Speed
				n.speedY = dir.y * config.energyBall2Speed
			end
			if (v.ai2 == 0 and config.energyBall2VoiceSet == 0) or config.energyBall2VoiceSet == 1 then
				SFXPlayTable(config.sfx_voiceAttackTable)
			end
			if v.ai2 < config.energyBall2Consecutive then
				data.timer = config.energyBall2DelayBetweenRound
				v.ai2 = v.ai2 + 1
			else
				v.ai2 = 0
			end
		end
		if data.timer >= config.energyBall2DelayBefore + config.energyBall2DelayBetweenRound + config.energyBall2DelayAfter then
			data.timer = 0
			data.state = STATE.DROP
		end
	elseif data.state == STATE.TELEPORT then
		if data.timer == 1 then
			SFXPlay(config.sfx_teleportDisappear)
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
				SFXPlay(config.sfx_teleportAppear)
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
	elseif data.state == STATE.INTRO then
		v.friendly = true
		v.speedX = 0
		v.speedY = 0
		if v.ai1 == 0 then
			v.animationFrame = 6
			if v.y >= v.spawnY then
				v.y = v.spawnY
				data.timer = 0
				v.ai1 = 1
			else
				v.y = v.y + 2
				--v:mem(0x12C, FIELD_WORD) = 6
			end
			if data.timer == 1 then SFXPlay(config.sfx_introFlyIn) end
		else
			if data.timer < 36 then
				v.animationFrame = 6
			elseif data.timer < 42 then
				v.animationFrame = 7
			else
				v.animationFrame = 0
			end
			if data.timer == 32 then SFXPlay(config.sfx_introClick) end
			if data.timer == 12 then SFXPlay(config.sfx_voiceIntro) end
			if data.timer >= 56 then data.state = STATE.IDLE v.ai1 = 0 data.timer = 0 v.friendly = false end
		end
	elseif data.state == STATE.HURT then
		v.speedX = 0
		v.speedY = 0
		v.friendly = true
		v.animationFrame = math.floor(data.timer / 8) % 2 + 3
		if data.timer >= config.hurtDelay then
			data.timer = 0
			data.state = STATE.TELEPORT
			v.friendly = false
			v.ai1 = 0
			v.ai2 = 0
			v.ai3 = 0
		end
    else
		v.speedX = 0
		v.speedY = 0
		v.friendly = true
		v.animationFrame = 5
		if data.timer == 1 then SFXPlay(config.sfx_voiceDefeat1) end
		if data.timer % 8 == 0 then
			local a = Animation.spawn(config.effectExplosion1ID, math.random(v.x, v.x + v.width), math.random(v.y, v.y + v.height))
			a.x=a.x-a.width/2
			a.y=a.y-a.height/2
			SFXPlay(config.sfx_smallExplosion)
		end
		if data.timer >= 240 then
			v:kill(HARM_TYPE_NPC)
			SFXPlay(config.sfx_bigExplosion)
			SFXPlay(config.sfx_voiceDefeat2)
		end
	end
	Text.print(data.health,110,110)
	--Give Doc Croc some i-frames to make the fight less cheesable
	--iFrames System made by MegaDood & DRACalgar Law
	if data.iFrames then
		v.friendly = true
		data.hurtTimer = data.hurtTimer + 1
		
		if data.hurtTimer == 1 and data.health > 0 then
		    SFXPlay(config.sfx_hurt)
			SFXPlayTable(config.sfx_voiceHurtTable)
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
	if config.pinchSet == 0 and not data.pinch and data.health <= config.pinchHP then
		data.pinch = true
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
			else
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