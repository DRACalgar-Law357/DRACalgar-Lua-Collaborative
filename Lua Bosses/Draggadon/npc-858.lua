--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local bulletBills = require("bulletBills_ai")
--NPCutils for rendering
local npcutils = require("npcs/npcutils")

--Create the library table
local draggadonBoss = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

local STATE = {
	IDLE = 0,
	RAIN = 1,
	SUMMON = 2,
	METEOR = 3,
	STREAMOFFIRE = 4,
	DASH = 5,
	GOBACK = 6,
	HURT = 7,
	CONSUME = 8,
	KILL = 9,
}

local maxHP = 3
-- The Shooting SFX File --
sfx_fire = 42

--Defines NPC config for our NPC. You can remove superfluous definitions.
local draggadonBossSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 320,
	gfxwidth = 320,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 128,
	height = 160,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 48,
	--Frameloop-related
	frames = 8,
	framestyle = 1,
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
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Define custom properties below
	summonEnemyTable = {
		800,
		773,
	},
	neckHitbox = {
		width = 96,
		height = 80,
		x = {
			[-1] = -128,
			[1] = 32,
		},
		y = -96,
	},
	headHitbox = {
		width = 96,
		height = 96,
		x = {
			[-1] = -224,
			[1] = 128,
		},
		y = -128,
	},
	mouthHitbox = {
		width = 96,
		height = 96,
		x = {
			[-1] = -272,
			[1] = 172,
		},
		y = -96,
	},
	totalHP = maxHP,
	attackTable = {
		[1] = {
			state = STATE.RAIN,
			availableHPMin = 0,
			availableHPMax = 3,
		},
		[2] = {
			state = STATE.SUMMON,
			availableHPMin = 0,
			availableHPMax = 3,
		},
		[3] = {
			state = STATE.STREAMOFFIRE,
			availableHPMin = 0,
			availableHPMax = 3,
		},
		[4] = {
			state = STATE.METEOR,
			availableHPMin = 1,
			availableHPMax = 1,
		},
		[5] = {
			state = STATE.DASH,
			availableHPMin = 2,
			availableHPMax = 2,
		},
	},
	streamoffireID=861,
	fireRainID=859,
	waveX = {
		[-1] = -192,
		[1] = 192,
	},
	waveY = -32,
	headOffset = {
		[-1] = {
			x = -192,
			y = -72,
		},
		[1] = {
			x = 192,
			y = -72,
		}
	},
	spawnOffset = {
		[-1] = {
			x = -58,
			y = -48,
		},
		[1] = {
			x = 58,
			y = -48,
		}
	},
	bodyFrames = 8,
	bodyFrameStyle = 1,
	headImg = Graphics.loadImageResolved("npc-"..npcID.."-head.png"),
	headFrames = 16,
	headFrameStyle = 1,
	waveImg = Graphics.loadImageResolved("draggadonflightdashwave.png"),
	waveFrames = 4,
	waveFrameStyle = 1,
	
	--Whenever Draggadon opens its mouth to charge a stream of fire attack, players can throw certain NPCs into its mouth and damage it.
	consumeNPCTable = {
		896,
		434,
		135,
		134,
		136,
		137,
		697,
		408,
		409,
	},
	priority = 15,
	hpDecWeak= 0.25,
	hpDecStrong= 1,
	iFramesDelay = 80,
	fireRainConfig = {
		speedXMax = 18,
		speedY = 7,
		speedXMin = 2,
	},
	summonBGO = 858,
	summonIndicatorID = 860,
	summonSpawnDelay = 80,
	summonEnemyConsecutive = 3,
	roarSummonDelay = 90,
	startSummoningDelay = 80,
	meteorDelay = 150,
	startMeteoringDelay = 120,
	meteorTable = {
		753,
		754,
	},
	meteorSpawnDelay = 24,
	meteorConsecutive = 12,
	streamoffire = {
		overallDelay = 540,
		beginBreathingDelay = 300,
		barrageDelay = 6,
		barrageSpeedX = 10,
		barrageSpeedY = 0,
	},
	position1BGO = 859, --To use a raining fireball attack
	position2BGO = 861, --To use a dash attack
	position3BGO = 860, --To charge a stream of fire attack
	positionRangeX = 12,
	positionRangeY = 12,
	dash = {
		charge = {
			waitDelay = 180,
			initiateDelay = 30,
			effect = {
				id = 80,
				x = {
					[-1] = -29,
					[1] = 29,
				},
				y = -64,
			},
		},
		flight = {
			speedX = 6,
			speedY = 0,
			stopDelay = 120,
		},
	},
	deathFallDelay = 480,
	consumeDelay = 150,
	smokeEffectID = 787,
	smokeOffsetX = {
		[-1] = {
			[0] = -48,
			[1] = -32,
		},
		[1] = {
			[0] = 48,
			[1] = 32,
		},
	},
	smokeOffsetY = 8,
	smokeSpeedX = 2,
	smokeSpeedY = 0.5,
	

	laserColor     = Color.orange, 

	sfx_hurt = 39,
	sfx_fireRain = 42,
	sfx_lavadrop = Misc.resolveFile("sfx_draggadonlavadrop.ogg"),
	sfx_streamoffireflare = Misc.resolveFile("sfx_draggadonfirebreath.wav"),
	sfx_debrisfall = Misc.resolveFile("S3K_51.wav"),
	sfx_summonRoar = Misc.resolveFile("sfx_draggadonroar1.wav"),
	sfx_meteorRoar = Misc.resolveFile("sfx_draggadonroarmeteor.wav"),
	sfx_breath = Misc.resolveFile("sfx_draggadonbreathing.wav"),
	sfx_flightflap = Misc.resolveFile("sfx_draggadonflightflap.wav"),
	sfx_flightcharge = Misc.resolveFile("sfx_draggadonflightcharge.wav"),
	sfx_flightdo = Misc.resolveFile("sfx_draggadonflightdo.wav"),
	sfx_gobble = Misc.resolveFile("sfx_draggadongobble.wav"),
	sfx_gulpbackfire = Misc.resolveFile("sfx_draggadongulpbackfire.wav"),
	sfx_gulpreact = Misc.resolveFile("sfx_draggadongulpreact.wav"),
	sfx_flighthrm = Misc.resolveFile("sfx_draggadonflightchargehrm.wav"),
	sfxTable_grunt = {
		Misc.resolveFile("sfx_draggadongrunt1.wav"),
		Misc.resolveFile("sfx_draggadongrunt2.wav"),
		Misc.resolveFile("sfx_draggadongrunt3.wav"),
		Misc.resolveFile("sfx_draggadonlaugh1.wav"),
		Misc.resolveFile("sfx_draggadonlaugh2.wav"),
		Misc.resolveFile("sfx_draggadonlaugh3.wav"),
	},
	sfxTable_defeated = {
		Misc.resolveFile("sfx_draggadondefeated1.wav"),
		Misc.resolveFile("sfx_draggadondefeated2.wav"),
	},
	sfxTable_hurt = {
		Misc.resolveFile("sfx_draggadonhurt1.wav"),
		Misc.resolveFile("sfx_draggadonhurt2.wav"),
	},

	TRAMPLEIMMUNE = true,
	onlyAttackMouth = true,
	streamoffirelimit = {
		min = 2,
		max = 4,
		dolimit = true,
	},
}

--Applies NPC settings

local draggadonConfig = npcManager.setNpcSettings(draggadonBossSettings)
--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function draggadonBoss.onInitAPI()
	npcManager.registerEvent(npcID, draggadonBoss, "onTickEndNPC")
	npcManager.registerEvent(npcID, draggadonBoss, "onStartNPC")
	npcManager.registerEvent(npcID, draggadonBoss, "onDrawNPC")
	registerEvent(draggadonBoss, "onNPCHarm")
end


local function SFXPlay(sfx)
	if sfx then
		SFX.play(sfx)
	end
end

local function SFXPlayTable(sfx)
	if sfx then
		local sfxChoice = RNG.irandomEntry(sfx)
		if sfxChoice then
			SFX.play(sfxChoice)
		end
	end
end

local laserSpeed = 20
local function doLaserLogic(v,dangerous)
    local config = NPC.config[v.id]
    local data = v.data

    data.laserProgress = data.laserProgress or 0

    local maxMoves = 48
    if dangerous then
        data.laserProgress = math.min(maxMoves,data.laserProgress + 1)
        maxMoves = data.laserProgress
    end

    data.laserProgress = maxMoves

    -- Hurt players
    if dangerous then
        local width,height = (data.laserProgress*laserSpeed),(v.height*0.75)
        local x,y = v.x+(v.width/2)-(width/2)+((width/2)*v.direction),v.y+(v.height/2)-(v.height*0.375)

        for _,w in ipairs(Player.getIntersecting(x,y,x+width,y+height)) do
            w:harm()
        end
    end

    return false
end

local bgoTable
local position1Table
local position2Table
local position3Table
function draggadonBoss.onStartNPC(v)
	bgoTable = BGO.get(NPC.config[v.id].summonBGO)
	position1Table = BGO.get(NPC.config[v.id].position1BGO)
	position2Table = BGO.get(NPC.config[v.id].position2BGO)
	position3Table = BGO.get(NPC.config[v.id].position3BGO)
end
local function decideAttack(v,data,config,settings)
	local options = {}
	if config.streamoffirelimit.dolimit == false then
		if config.attackTable and #config.attackTable > 0 then
			for i in ipairs(config.attackTable) do
				if data.health >= config.attackTable[i].availableHPMin and data.health <= config.attackTable[i].availableHPMax then
					table.insert(options,config.attackTable[i].state)
				end
			end
		end
		if #options > 0 then
			data.state = RNG.irandomEntry(options)
			if data.state == STATE.RAIN then
				data.positionLocation = RNG.irandomEntry(position1Table)
				data.psuedoState = 0
				data.positionState = 0
			elseif data.state == STATE.STREAMOFFIRE then
				data.positionLocation = RNG.irandomEntry(position3Table)
				data.psuedoState = 0
				data.positionState = 0
			elseif data.state == STATE.DASH then
				data.positionLocation = RNG.irandomEntry(position2Table)
				data.psuedoState = 0
				data.positionState = 0
			end
		end
	else
		if data.streamoffirelimit > 0 then
			if config.attackTable and #config.attackTable > 0 then
				for i in ipairs(config.attackTable) do
					if data.health >= config.attackTable[i].availableHPMin and data.health <= config.attackTable[i].availableHPMax then
						if config.attackTable[i].state ~= STATE.STREAMOFFIRE then
							table.insert(options,config.attackTable[i].state)
						end
					end
				end
			end
			if #options > 0 then
				data.state = RNG.irandomEntry(options)
				if data.state == STATE.RAIN then
					data.positionLocation = RNG.irandomEntry(position1Table)
					data.psuedoState = 0
					data.positionState = 0
				elseif data.state == STATE.STREAMOFFIRE then
					data.positionLocation = RNG.irandomEntry(position3Table)
					data.psuedoState = 0
					data.positionState = 0
				elseif data.state == STATE.DASH then
					data.positionLocation = RNG.irandomEntry(position2Table)
					data.psuedoState = 0
					data.positionState = 0
				end
			end
			data.streamoffirelimit = data.streamoffirelimit - 1
		else
			data.state = STATE.STREAMOFFIRE
			data.positionLocation = RNG.irandomEntry(position3Table)
			data.psuedoState = 0
			data.positionState = 0
			data.streamoffirelimit = RNG.randomInt(config.streamoffirelimit.min,config.streamoffirelimit.max)
		end
	end
	data.timer = 0
end
function draggadonBoss.onTickEndNPC(v)
	--Don't act during time freeze --
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	local cfg = v.data._settings
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height/2)
	v.data._basegame.direction = v.data._basegame.direction or v.direction
	data.neckBox = Colliders.Box(v.x - (v.width * 2), v.y - (v.height * 1.5), config.neckHitbox.width, config.neckHitbox.height)
	data.neckBox.x = v.x + v.width/2 + config.neckHitbox.x[v.data._basegame.direction]
	data.neckBox.y = v.y + v.height/2 + config.neckHitbox.y

	data.headBox = Colliders.Box(v.x - (v.width * 2), v.y - (v.height * 1.5), config.headHitbox.width, config.headHitbox.height)
	data.headBox.x = v.x + v.width/2 + config.headHitbox.x[v.data._basegame.direction]
	data.headBox.y = v.y + v.height/2 + config.headHitbox.y

	data.mouthBox = Colliders.Box(v.x - (v.width * 2), v.y - (v.height * 1.5), config.mouthHitbox.width, config.mouthHitbox.height)
	data.mouthBox.x = v.x + v.width/2 + config.mouthHitbox.x[v.data._basegame.direction]
	data.mouthBox.y = v.y + v.height/2 + config.mouthHitbox.y
	--If despawned --
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary --
		data.initialized = false
		return
	end

	--Initialize --
	if not data.initialized then
		--Initialize necessary data. --
		data.initialized = true
		data.bodyimg = data.bodyimg or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = draggadonConfig.bodyFrames * (1 + draggadonConfig.bodyFrameStyle), texture = Graphics.sprites.npc[v.id].img}
		data.headimg = data.headimg or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = draggadonConfig.headFrames * (1 + draggadonConfig.headFrameStyle), texture = config.headImg}
		data.waveimg = data.waveimg or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = draggadonConfig.waveFrames * (1 + draggadonConfig.headFrameStyle), texture = config.waveImg}
	end

	--Depending on the NPC, these checks must be handled differently --
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		v.spawnY = v.y
		return
	end

	-- Custom Animations: Variables --
	data.attacking = data.attacking or false
	data.flyAroundTimer = data.flyAroundTimer or 1
	data.headcurrentFrame = data.headcurrentFrame or 1
	data.headframeTimer = data.headframeTimer or 8
	data.headcurrentAnim = data.headcurrentAnim or 0
	data.currentFrame = data.currentFrame or 1
	data.frameTimer = data.frameTimer or 8
	data.currentAnim = data.currentAnim or 1
	data.selectedAttack = data.selectedAttack or nil
	data.psuedoState = data.psuedoState or 0
	data.rainTimer = data.rainTimer or 0
	data.headOffsetY = data.headOffsetY or 0
	data.state = data.state or 0
	data.health = data.health or 0
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	data.iFrames = data.iFrames or false
	data.hurtTimer = data.hurtTimer or 0
	data.iFramesDelay = data.iFramesDelay or config.iFramesDelay
	data.shootTimer = data.shootTimer or 0
	data.shootsFired = data.shootsFired or 0
	data.rotation = data.rotation or 0
	data.rotationTick = data.rotationTick or 0
	data.laserProgress = data.laserProgress or nil -- Used by zappa mechakoopas
	data.laserOpacity = data.laserOpacity or nil
	data.laserHeight = data.laserHeight or nil
	data.positionState = data.positionState or 0
	data.drawWave = data.drawWave or false
	data.streamoffirelimit = data.streamoffirelimit or RNG.randomInt(config.streamoffirelimit.min,config.streamoffirelimit.max)
	
	-- Custom Animations: Handling --
	data.frameTimer = data.frameTimer + 1
	if data.state ~= STATE.GOBACK or data.state ~= STATE.HURT or data.state ~= STATE.KILL or data.state ~= STATE.CONSUME then
		data.currentFrame = math.floor(data.frameTimer / 6) % 8
	else
		data.currentFrame = math.floor(data.frameTimer / 4) % 8
	end
	data.waveFrames = math.floor(lunatime.tick() / 4) % 4
	
	-- Custom Animations: Handling Head--
	data.headframeTimer = data.headframeTimer + 1
	if data.headcurrentAnim == 0 then
		if data.headframeTimer < 40 then
			data.headcurrentFrame = 0
		elseif data.headframeTimer < 48 then
			data.headcurrentFrame = 1
		else
			data.headframeTimer = 0
			data.headcurrentFrame = 0
		end
	elseif data.headcurrentAnim == 1 then
		if data.headframeTimer < 4 then
			data.headcurrentFrame = 3
		elseif data.headframeTimer < 8 then
			data.headcurrentFrame = 4
		elseif data.headframeTimer < 12 then
			data.headcurrentFrame = 5
		elseif data.headframeTimer < 16 then
			data.headcurrentFrame = 4
		elseif data.headframeTimer < 20 then
			data.headcurrentFrame = 3
		else
			data.headframeTimer = 0
			data.headcurrentFrame = 3
			data.headcurrentAnim = 0
		end
	elseif data.headcurrentAnim == 2 then
		if data.headframeTimer < 10 then
			data.headcurrentFrame = 1
		elseif data.headframeTimer < 70 then
			data.headcurrentFrame = math.floor((data.headframeTimer - 10) / 8) % 2 + 6
		elseif data.headframeTimer < 80 then
			data.headcurrentFrame = 1
		else
			data.headframeTimer = 0
			data.headcurrentFrame = 1
			data.headcurrentAnim = 0
		end
	elseif data.headcurrentAnim == 3 then
		if data.headframeTimer < 4 then
			data.headcurrentFrame = 3
		elseif data.headframeTimer < 8 then
			data.headcurrentFrame = 4
		elseif data.headframeTimer < 12 then
			data.headcurrentFrame = 5
		else
			data.headframeTimer = 0
			data.headcurrentFrame = 5
			data.headcurrentAnim = 4
		end
	elseif data.headcurrentAnim == 4 then
		data.headcurrentFrame = 5
	elseif data.headcurrentAnim == 5 then
		if data.headframeTimer < 4 then
			data.headcurrentFrame = 5
		elseif data.headframeTimer < 8 then
			data.headcurrentFrame = 4
		elseif data.headframeTimer < 12 then
			data.headcurrentFrame = 3
		else
			data.headframeTimer = 0
			data.headcurrentFrame = 3
			data.headcurrentAnim = 0
		end
	elseif data.headcurrentAnim == 6 then
		if data.headframeTimer < 10 then
			data.headcurrentFrame = 1
		else
			data.headcurrentFrame = math.floor((data.headframeTimer - 10) / 8) % 2 + 6
		end
	elseif data.headcurrentAnim == 7 then
		data.headcurrentFrame = math.floor((data.headframeTimer - 10) / 8) % 2 + 14
	elseif data.headcurrentAnim == 8 then
		data.headcurrentFrame = 1
	end
	-- Let's set custom settings --
	--Shooting stuff --
	data.rotation = data.rotation or 0
	data.rotationTick = data.rotationTick or 0
	if data.state == STATE.IDLE then
		v.speedY = math.cos(lunatime.tick() / 8) * 1.3
		--[[if not data.attacking then
			if v.speedX < 0 then
				v.data._basegame.direction = -1
			elseif v.speedX > 0 then
				v.data._basegame.direction = 1
			end
		else
	
		end]]
	    if data.timer > 70 then
			v.speedX = cfg.flyAroundSpeed * v.direction
		end
		if data.timer == 70 then
			npcutils.faceNearestPlayer(v)
			v.data._basegame.direction = v.direction
			SFXPlayTable(config.sfxTable_grunt)
		end

		if data.timer >= 250 then
			data.attacking = true
			decideAttack(v,data,config,settings) --decide attack function
			data.timer = 0
			v.speedY = 0
			v.speedX = 0
		end
	elseif data.state == STATE.GOBACK then
		if v.y > v.spawnY then
			v.speedY = -2
		elseif v.y < v.spawnY then
			v.speedY = 2
		end
		v.speedX = 0
		data.drawWave = false
		data.positionState = 0
		if math.abs(v.y - v.spawnY) < 2 then
			data.state = STATE.IDLE
			v.y = v.spawnY
			v.speedY = 0
			data.timer = 0
			data.headframeTimer = 0
			data.headcurrentFrame = 3
			data.headcurrentAnim = 0
		end
	elseif data.state == STATE.DASH then
		if data.psuedoState == 0 then
			if data.positionState == 0 then
				if cfg.preDash ~= "" and data.timer == 1 then
					triggerEvent(cfg.preDash)
				end
				data.dirVectr = vector.v2(
					(data.positionLocation.x + 16) - (v.x + v.width * 0.5),
					(v.y + v.height * 0.5) - (v.y + v.height * 0.5)
					):normalize() * cfg.positionSpeed
				v.speedX = data.dirVectr.x
				v.speedY = math.cos(lunatime.tick() / 8) * 1.3
				if math.abs((data.positionLocation.x + 16) - (v.x + v.width * 0.5)) <= config.positionRangeX then
					v.x = data.positionLocation.x + 16 - v.width/2
					data.positionState = 1
					data.timer = 0
				end
			else
				data.dirVectr = vector.v2(
					(v.x + v.width * 0.5) - (v.x + v.width * 0.5),
					(data.positionLocation.y + 16) - (v.y + v.height * 0.5)
					):normalize() * cfg.positionSpeed
				v.speedX = 0
				v.speedY = data.dirVectr.y
				if math.abs((data.positionLocation.y + 16) - (v.y + v.height * 0.5)) <= config.positionRangeY then
					v.y = data.positionLocation.y + 16 - v.height/2
					data.psuedoState = 1
					npcutils.faceNearestPlayer(v)
					v.data._basegame.direction = v.direction
					v.speedX = 0
					v.speedY = 0
					data.timer = 0
					data.positionState = 0
				end
			end
		elseif data.psuedoState == 1 then
			v.speedY = math.cos(lunatime.tick() / 8) * 1.3
			if data.timer < config.dash.charge.waitDelay then
				v.speedX = 0
				if data.timer % 25 == 0 then
					SFXPlay(config.sfx_flightflap)
				end
			else
				v.speedX = 1.5 * -v.data._basegame.direction
			end
			if data.timer == config.dash.charge.waitDelay then
				SFXPlay(config.sfx_flightdo)
				if config.dash.charge.effect.id > 0 then
					local a = Animation.spawn(config.dash.charge.effect.id, v.x + 0.5 * v.width + config.gfxoffsetx + config.headOffset[v.data._basegame.direction].x + config.spawnOffset[v.data._basegame.direction].x, v.y + 0.5 * v.height + config.headOffset[v.data._basegame.direction].y + config.dash.charge.effect.x[v.data._basegame.direction])
					a.x=a.x-a.width/2
					a.y=a.y-a.height/2
				end
			end
			if data.timer >= config.dash.charge.initiateDelay + config.dash.charge.waitDelay then
				data.timer = 0
				data.psuedoState = 2
				v.speedX = 0
				v.speedY = 0
				SFXPlay(config.sfx_flighthrm)
				SFXPlay(config.sfx_flightcharge)
			end
		elseif data.psuedoState == 2 then
			if data.timer <= config.dash.flight.stopDelay then
				v.speedX = config.dash.flight.speedX * v.data._basegame.direction
				v.speedY = config.dash.flight.speedY
				data.drawWave = true
			else
				data.drawWave = false
				v.speedX = v.speedX * 0.97
				v.speedY = v.speedY * 0.97
				if data.timer % 8 == 0 then
					SFX.play(10)
				end
				if math.abs(v.speedX) + math.abs(v.speedY) < 1.5 then
					v.speedX = 0
					v.speedY = 0
					data.timer = 0
					data.psuedoState = 0
					data.state = STATE.GOBACK
					if cfg.postDash ~= "" then
						triggerEvent(cfg.postDash)
					end
				end
			end
		end
	elseif data.state == STATE.STREAMOFFIRE then
		if data.psuedoState == 0 then

			if data.positionState == 0 then
				data.dirVectr = vector.v2(
					(data.positionLocation.x + 16) - (v.x + v.width * 0.5),
					(v.y + v.height * 0.5) - (v.y + v.height * 0.5)
					):normalize() * cfg.positionSpeed
				v.speedX = data.dirVectr.x
				v.speedY = math.cos(lunatime.tick() / 8) * 1.3
				if math.abs((data.positionLocation.x + 16) - (v.x + v.width * 0.5)) <= config.positionRangeX then
					v.x = data.positionLocation.x + 16 - v.width/2
					data.positionState = 1
					data.timer = 0
				end
			else
				data.dirVectr = vector.v2(
					(v.x + v.width * 0.5) - (v.x + v.width * 0.5),
					(data.positionLocation.y + 16) - (v.y + v.height * 0.5)
					):normalize() * cfg.positionSpeed
				v.speedX = 0
				v.speedY = data.dirVectr.y
				if math.abs((data.positionLocation.y + 16) - (v.y + v.height * 0.5)) <= config.positionRangeY then
					v.y = data.positionLocation.y + 16 - v.height/2
					data.psuedoState = 1
					npcutils.faceNearestPlayer(v)
					v.data._basegame.direction = v.direction
					data.headframeTimer = 0
					data.headcurrentFrame = 3
					data.headcurrentAnim = 3
					v.speedX = 0
					v.speedY = 0
					data.timer = 0
					data.positionState = 0
				end
			end
		elseif data.psuedoState == 1 then
            if data.timer > config.streamoffire.overallDelay then
                data.state = STATE.GOBACK
                data.timer = 0
				data.psuedoState = 0
				data.headframeTimer = 0
				data.headcurrentFrame = 5
				data.headcurrentAnim = 5
                data.laserProgress = nil
                data.laserOpacity = nil
                data.laserHeight = nil
				data.attacking = false
            elseif data.timer == config.streamoffire.beginBreathingDelay then
                data.laserProgress = 0
            elseif data.timer > config.streamoffire.beginBreathingDelay then
                if data.timer % config.streamoffire.barrageDelay == 0 then
					local n = NPC.spawn(config.streamoffireID, data.mouthBox.x + 0.5 * data.mouthBox.width, data.mouthBox.y + 0.5 * data.mouthBox.height, v.section, false, true)
					n.direction = v.direction
					n.speedX = config.streamoffire.barrageSpeedX * n.direction
					n.briefSpeedY = config.streamoffire.barrageSpeedY
					SFXPlay(config.sfx_streamoffireflare)
				end
            else
				doLaserLogic(v,false)
                data.laserHeight = math.max(0,(data.laserHeight or (data.mouthBox.height*0.75))-((data.timer/data.mouthBox.height)*0.15))
                data.laserOpacity = math.min(0.65,(data.laserOpacity or 0) + 0.1)
            end
			for k, n in  ipairs(Colliders.getColliding{a = data.mouthBox, b = NPC.HITTABLE and NPC.POWERUP and NPC.UNHITTABLE and NPC.SHELL and NPC.VEGETABLE and NPC.INTERACTABLE, btype = Colliders.NPC, filter = npcFilter}) do
				if n.id ~= v.id then
					for i in ipairs(config.consumeNPCTable) do
						if n.id == config.consumeNPCTable[i] then
							n:kill(9)
							data.laserProgress = nil
							data.laserOpacity = nil
							data.laserHeight = nil
							data.attacking = false
							data.timer = 0
							data.state = STATE.CONSUME
							SFX.play(55)
							v.speedX = 0
							v.speedY = 0
						end
					end
				end
			end
		end

	elseif data.state == STATE.RAIN then
		data.shootTimer = data.shootTimer - 1
		if data.shootTimer <= 0 and data.attacking then
			if data.psuedoState == 0 then
				if data.positionState == 0 then
					data.dirVectr = vector.v2(
						(data.positionLocation.x + 16) - (v.x + v.width * 0.5),
						(v.y + v.height * 0.5) - (v.y + v.height * 0.5)
						):normalize() * cfg.positionSpeed
					v.speedX = data.dirVectr.x
					v.speedY = math.cos(lunatime.tick() / 8) * 1.3
					if math.abs((data.positionLocation.x + 16) - (v.x + v.width * 0.5)) <= config.positionRangeX then
						v.x = data.positionLocation.x + 16 - v.width/2
						data.positionState = 1
						data.timer = 0
					end
				else
					data.dirVectr = vector.v2(
						(v.x + v.width * 0.5) - (v.x + v.width * 0.5),
						(data.positionLocation.y + 16) - (v.y + v.height * 0.5)
						):normalize() * cfg.positionSpeed
					v.speedX = 0
					v.speedY = data.dirVectr.y
					if math.abs((data.positionLocation.y + 16) - (v.y + v.height * 0.5)) <= config.positionRangeY then
						v.y = data.positionLocation.y + 16 - v.height/2
						data.psuedoState = 1
						npcutils.faceNearestPlayer(v)
						v.data._basegame.direction = v.direction
						data.headframeTimer = 0
						data.headcurrentFrame = 3
						data.headcurrentAnim = 3
						v.speedX = 0
						v.speedY = 0
						data.timer = 0
						data.positionState = 0
					end
				end
			elseif data.psuedoState == 1 then
				data.rotation = data.rotation + 2
				data.rotationTick = data.rotationTick + 2
				data.headOffsetY = data.headOffsetY + 4/5
				if data.rotationTick >= 50 then
					data.rotation = 50
					data.psuedoState = 2
					data.shootTimer = 30
					data.headOffsetY = 20
				end
				v.speedX = 0
				v.speedY = 0
			elseif data.psuedoState == 2 then
				data.headcurrentAnim = 1
				data.headcurrentFrame = 3
				data.headframeTimer = 0
				local n = NPC.spawn(config.fireRainID, v.x + 0.5 * v.width + config.gfxoffsetx + config.headOffset[v.data._basegame.direction].x + config.spawnOffset[v.data._basegame.direction].x, v.y + 0.5 * v.height + config.headOffset[v.data._basegame.direction].y + config.spawnOffset[v.data._basegame.direction].y, v.section, false, true)
				n.direction = v.data._basegame.direction
				n.speedX = RNG.random(config.fireRainConfig.speedXMin,config.fireRainConfig.speedXMax) * n.direction
				n.speedY = -config.fireRainConfig.speedY
				SFXPlay(config.sfx_fireRain)
				SFXPlay(config.sfx_breath)
				if data.shootsFired >= 6 - 1 then
					data.shootsFired = 0
					data.psuedoState = 3
				else
					data.shootTimer = lunatime.toTicks(0.5)
					data.shootsFired = data.shootsFired + 1
					data.attacking = true
				end
				v.speedX = 0
				v.speedY = 0
			elseif data.psuedoState == 3 then
				data.rotation = data.rotation - 2
				data.rotationTick = data.rotationTick - 2
				data.headOffsetY = data.headOffsetY - 4/5
				v.speedX = 0
				v.speedY = 0
				if data.rotationTick <= 0 then
					data.rotation = 0
					data.rotationTick = 0
					data.psuedoState = 0
					data.shootTimer = 0
					data.shootsFired = 0
					data.attacking = false
					data.headOffsetY = 0
					data.timer = 0
					data.state = STATE.GOBACK
				end
			end
		end
	elseif data.state == STATE.SUMMON then
		if data.timer == 1 then
			data.headframeTimer = 0
			data.headcurrentFrame = 3
			data.headcurrentAnim = 3
		end
		v.speedX = 0
		v.speedY = 0
		if data.timer >= config.roarSummonDelay then
			data.timer = 0
			data.state = STATE.GOBACK
			data.headframeTimer = 0
			data.headcurrentFrame = 5
			data.headcurrentAnim = 5
			data.attacking = false
		end
		if data.timer == config.startSummoningDelay then
			Routine.setFrameTimer(config.summonSpawnDelay, (function() 
				data.location = RNG.irandomEntry(bgoTable)
				local n = NPC.spawn(NPC.config[v.id].summonIndicatorID, data.location.x, data.location.y, v.section, true, true)
				n.x=n.x+16
				n.y=n.y+16
				n.ai1 = 60
				n.ai2 = RNG.irandomEntry(config.summonEnemyTable)
				n.ai3 = 0
			end), config.summonEnemyConsecutive, false)
		end
		if data.timer == 12 then
			SFXPlay(config.sfx_summonRoar)
		end
		if data.timer >= 12 and data.timer < config.startSummoningDelay then
			Defines.earthquake = 7
		end
	elseif data.state == STATE.METEOR then
		if data.timer == 1 then
			data.headframeTimer = 0
			data.headcurrentFrame = 3
			data.headcurrentAnim = 3
		end
		v.speedX = 0
		v.speedY = 0
		if data.timer >= config.meteorDelay then
			data.timer = 0
			data.state = STATE.GOBACK
			data.headframeTimer = 0
			data.headcurrentFrame = 5
			data.headcurrentAnim = 5
			data.attacking = false
		end
		if data.timer == config.startMeteoringDelay then
			Routine.setFrameTimer(config.meteorSpawnDelay, (function() 
				data.location = RNG.irandomEntry(bgoTable)
				local n = NPC.spawn(RNG.irandomEntry(config.meteorTable), camera.x + 16 + RNG.randomInt(0,camera.width-32), camera.y - 32, v.section, true, true)
				SFXPlay(config.sfx_debrisfall)
			end), config.meteorConsecutive, false)
		end
		if data.timer == 12 then
			SFXPlay(config.sfx_meteorRoar)
		end
		if data.timer >= 12 and data.timer < config.startMeteoringDelay then
			Defines.earthquake = 10
		end
	elseif data.state == STATE.CONSUME then
		if data.timer == 1 then
			SFXPlay(config.sfx_gobble)
			data.headframeTimer = 0
			data.headcurrentFrame = 1
			data.headcurrentAnim = 8
		elseif data.timer >= config.consumeDelay then
			data.timer = 0
			if data.health >= maxHP then
				data.state = STATE.KILL
				data.timer = 0
			else
				v:mem(0x156,FIELD_WORD,60)
				data.timer = 0
				data.state = STATE.KILL
			end
			data.iFrames = true
			data.headcurrentAnim = 2
			data.headcurrentFrame = 1
			data.headframeTimer = 0
			data.health = data.health + 1
			SFXPlay(config.sfx_gulpbackfire)
			SFXPlay(config.sfx_gulpreact)
			if config.smokeEffectID then
				for i=0,1 do
					local a = Animation.spawn(config.smokeEffectID,data.headBox.x + data.headBox.width/2 + config.smokeOffsetX[v.data._basegame.direction][i], data.headBox.y + data.headBox.height/2 + config.smokeOffsetY)
					a.x=a.x-a.width/2
					a.y=a.y-a.height/2
					a.speedX = -config.smokeSpeedX + i * 2 * config.smokeSpeedX
					a.speedY = config.smokeSpeedY
				end
			end
		end
	elseif data.state == STATE.HURT then
		if data.timer >= 80 then
			data.timer = 0
			data.state = STATE.GOBACK
			data.headframeTimer = 0
			data.headcurrentFrame = 3
			data.headcurrentAnim = 0
		end
		data.rotation = 0
		data.rotationTick = 0
		data.psuedoState = 0
		data.shootTimer = 0
		data.shootsFired = 0
		data.attacking = false
		data.headOffsetY = 0
		data.attacking = false
		data.laserProgress = nil
		data.laserOpacity = nil
		data.laserHeight = nil
		data.drawWave = false
		data.positionState = 0
		v.speedX = 0
		v.speedY = 0
	elseif data.state == STATE.KILL then
		v.speedX = 0
		v.speedY = 0
		data.lavaMult = data.lavaMult or 1.5
		if data.timer == 1 then
			data.headcurrentAnim = 6
			data.headcurrentFrame = 1
			data.headframeTimer = 0
			data.rotation = 0
			data.rotationTick = 0
			data.psuedoState = 0
			data.shootTimer = 0
			data.shootsFired = 0
			data.attacking = false
			data.headOffsetY = 0
			data.attacking = false
			data.laserProgress = nil
			data.laserOpacity = nil
			data.laserHeight = nil
			data.drawWave = false
			data.positionState = 0
			if cfg.death ~= "" then
				triggerEvent(cfg.death)
			end
		elseif data.timer == 100 then
			data.headcurrentAnim = 7
			data.headcurrentFrame = 1
			data.headframeTimer = 0
			SFX.play(38)
		end
		if data.timer == 190 then SFXPlayTable(config.sfxTable_defeated) end
		if data.timer >= 190 then
			v.y = v.y + 1*data.lavaMult
		end
		if data.timer >= 190 + config.deathFallDelay then v:kill(HARM_TYPE_VANISH) end
		for _,blck in Block.iterateIntersecting(v.x, v.y, v.x + v.width, v.y + v.height*3/4) do
			if Block.LAVA_MAP[blck.id] then
				if data.lavaMult == 1.5 then --since this can only happen once when bowsy is dead i thought might as well spawn the sound here
					SFXPlay(config.sfx_lavadrop)
				end
				data.lavaMult = 0.75
			end
		end
	end
		--iFrames System made by MegaDood & DRACalgar Law
		if data.iFrames then
			v.friendly = true
			data.hurtTimer = data.hurtTimer + 1
			
			if data.hurtTimer == 1 and data.health < maxHP then
				SFXPlay(config.sfx_hurt)
				SFXPlayTable(config.sfxTable_hurt)
				data.state = STATE.HURT
				data.timer = 0
			end
			if data.hurtTimer >= data.iFramesDelay then
				v.friendly = false
				data.iFrames = false
				data.hurtTimer = 0
			end
		end
	if (Colliders.collide(plr, v) or Colliders.collide(plr, data.neckBox) or Colliders.collide(plr, data.headBox) or (Colliders.collide(plr, data.mouthBox) and data.state == STATE.IDLE)) and not v.friendly and data.state ~= STATE.KILL and data.state ~= STATE.HURT and not Defines.cheat_donthurtme then
		plr:harm()
	end
end
function draggadonBoss.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	local config = NPC.config[v.id]
	if v.id ~= npcID then return end

			if data.iFrames == false and data.state ~= STATE.KILL and data.state ~= STATE.HURT and data.state ~= STATE.CONSUME and not config.onlyAttackMouth then
				local fromFireball = (culprit and culprit.__type == "NPC" and culprit.id == 13 )
				local hpd = config.hpDecStrong
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
						data.state = STATE.HURT
						data.timer = 0
						data.headcurrentAnim = 2
						data.headcurrentFrame = 1
						data.headframeTimer = 0
					end
				end
				
				data.health = data.health + hpd
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
			if not config.onlyAttackMouth then
				if data.health >= maxHP then
					data.state = STATE.KILL
					data.timer = 0
				else
					v:mem(0x156,FIELD_WORD,60)
					data.timer = 0
					data.state = STATE.KILL
				end
			end
	eventObj.cancelled = true
end
function draggadonBoss.onDrawNPC(v)
	local data = v.data
	local config = NPC.config[v.id]
	local opacity = 1
	if data.iFrames then
		opacity = math.sin(lunatime.tick()*math.pi*0.25)*0.75 + 0.9
	end
	if data.waveimg and data.drawWave then
		-- Setting some properties --
		data.waveimg.x, data.waveimg.y = v.x + 0.5 * v.width + draggadonConfig.gfxoffsetx + draggadonConfig.waveX[v.data._basegame.direction], v.y + 0.5 * v.height + draggadonConfig.waveY --[[+ draggadonConfig.gfxoffsety]]
		if config.waveFrameStyle == 1 then
			data.waveimg.transform.scale = vector(-v.data._basegame.direction, 1)
		else
			data.waveimg.transform.scale = vector(1, 1)
		end

		local p = -config.priority + 0.1

		-- Drawing --
		data.waveimg:draw{frame = data.waveFrames + 1, sceneCoords = true, priority = p, color = Color.white..opacity}
	end
	if data.headimg then
		-- Setting some properties --
		data.headimg.x, data.headimg.y = v.x + 0.5 * v.width + draggadonConfig.gfxoffsetx + draggadonConfig.headOffset[v.data._basegame.direction].x, v.y + 0.5 * v.height + draggadonConfig.headOffset[v.data._basegame.direction].y - data.headOffsetY --[[+ draggadonConfig.gfxoffsety]]
		if config.headFrameStyle == 1 then
			data.headimg.transform.scale = vector(-v.data._basegame.direction, 1)
		else
			data.headimg.transform.scale = vector(1, 1)
		end
		data.headimg.rotation = data.rotation * -v.data._basegame.direction

		local p = -config.priority

		-- Drawing --
		data.headimg:draw{frame = data.headcurrentFrame + 1, sceneCoords = true, priority = p, color = Color.white..opacity}
	end
	if data.bodyimg then
		-- Setting some properties --
		data.bodyimg.x, data.bodyimg.y = v.x + 0.5 * v.width + draggadonConfig.gfxoffsetx, v.y + 0.5 * v.height --[[+ draggadonConfig.gfxoffsety]]
		if config.bodyFrameStyle == 1 then
			data.bodyimg.transform.scale = vector(-v.data._basegame.direction, 1)
		else
			data.bodyimg.transform.scale = vector(1, 1)
		end

		local p = -config.priority - 0.1

		-- Drawing --
		data.bodyimg:draw{frame = data.currentFrame + 1, sceneCoords = true, priority = p, color = Color.white..opacity}
	end
	npcutils.hideNPC(v)

	if not data.laserProgress then return end -- If the laser isn't out yet
	local laserSpeed = 16
    -- Get priority for the laser
    local priority = config.priority

    local color = config.laserColor or Color.white
    if type(color) == "number" then
        color = Color.fromHexRGBA(color)
    end

    -- Laser beam
    local laserWidth = (data.laserProgress*laserSpeed)

	Graphics.drawBox{x = data.mouthBox.x+(data.mouthBox.width/2)-(laserWidth/2)+((laserWidth/2)*v.direction),y = (data.mouthBox.y+(data.mouthBox.height/2))-(data.laserHeight/2),width = laserWidth,height = data.laserHeight,color = color.. data.laserOpacity,priority = priority-0.01,sceneCoords = true}

	-- Weird little specs and stuff
	local rng = RNG.new(2)
	for i=1,(laserWidth/6) do
		local height = data.laserHeight/(v.height*0.15)
		Graphics.drawBox{
			--x = v.x+(v.width/2)+(((rng:random(0,laserWidth)*v.direction)+data.timer-1)%laserWidth),
			x = data.mouthBox.x+(data.mouthBox.width/2)+(((rng:random(0,laserWidth)-data.timer)%laserWidth)*v.direction)-1,
			y = data.mouthBox.y+(data.mouthBox.height/2)+(rng:random(-data.laserHeight/2,data.laserHeight/2))-(height/2),
			width = 2,height = height,color = Color(color.r*1.25,color.g*1.25,color.b*1.25,data.laserOpacity),priority = priority-0.01,sceneCoords = true,
		}
	end
end

--Gotta return the library table!
return draggadonBoss