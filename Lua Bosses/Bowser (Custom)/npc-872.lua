--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
local playerStun = require("playerstun")
klonoa.UngrabableNPCs[NPC_ID] = true
local sprite

local STATE_IDLE = 0
local STATE_INTRO = 1
local STATE_FIRE = 2
local STATE_GROUNDED_HAMMER = 3
local STATE_GROUNDPOUND = 4
local STATE_RUN = 5
local STATE_SHELL = 6
local STATE_SCORCH = 7
local STATE_BARRAGE = 8
local STATE_FIERY = 9
local STATE_THROW = 10
local STATE_FLAMETHROWER = 11

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 102,
	gfxwidth = 102,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 4,
	--Frameloop-related
	frames = 42,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.
	staticdirection = true,
	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
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
	terminalvelocity = 16,
	effectOffsetSkid = {
		[-1] = 0,
		[1] = 56,
	},
	health=20,
	score = 8,
	scorchID = 875,
	fieryID = 876,
	walkSpeed = 2,
	walkRange = 160,
	walkTurnDelay = {min = 36, max = 120},
	idleDelay = {min=128,max=200},
	runRangeX = 6,
	runSpeed = 4,
	runDelay = 240,
	horizontalFlame = {
		readyDelay = 32,
		releaseDelay = 12,
		afterDelay = 30,
		amount = {
			[1] = {amount = 2, hpmin = 10, hpmax = 20},
			[2] = {amount = 3, hpmin = 0, hpmax = 20},
			[3] = {amount = 4, hpmin = 0, hpmax = 10},
		},
		fireKind = {
			[1] = {
				hpmin = 10,
				hpmax = 20,
				set = {[1] = {speedX = 2.5, speedY = 0, id = 874}},
			},
			[2] = {
				hpmin = 10,
				hpmax = 20,
				set = {[1] = {speedX = 2.5, speedY = 3, id = 874}},
			},
			[3] = {
				hpmin = 10,
				hpmax = 20,
				set = {[1] = {speedX = 2.5, speedY = -3, id = 874}},
			},
			[4] = {
				hpmin = 0,
				hpmax = 10,
				set = {[1] = {speedX = 3, speedY = 0, id = 874},
				[2] = {speedX = 3, speedY = 3, id = 874}},
			},
			[5] = {
				hpmin = 0,
				hpmax = 10,
				set = {[1] = {speedX = 3, speedY = -3, id = 874},
				[2] = {speedX = 3, speedY = -6, id = 874}},
			},
		},
	},
	groundedHammerSpawnIntervals = {interval = 18, onto = 12},
	groundedHammerAmount = {min = 4, max = 7},
	groundedHammerReadyDelay = 48,
	groundedHammerTrajectory = {
		[1] = {speedX = 1, speedY = -13, id = 873},
		[2] = {speedX = 2, speedY = -13, id = 873},
		[3] = {speedX = 3, speedY = -13, id = 873},
		[4] = {speedX = 4, speedY = -13, id = 873},
		[5] = {speedX = 5, speedY = -13, id = 873},
		[6] = {speedX = 6, speedY = -13, id = 873},
	},
	groundPoundStartUp1 = 40,
	groundPoundStartUp2 = 8,
	groundPoundReady = 12,
	groundPoundRiseXRate = 33,
	groundPoundRiseXLimit = 16,
	groundPoundRiseY = 9,
	groundPoundRiseDelay = 32,
	groundPoundAirDelay = 12,
	groundPoundFallAcc = 0.15,
	groundPoundStun = {stun = false, timer = 60},
	groundPoundTurnDelay = 28,
	groundPoundAmount = {
		[1] = {amount = 2, hpmin = 10, hpmax = 20},
		[2] = {amount = 3, hpmin = 0, hpmax = 20},
		[3] = {amount = 4, hpmin = 0, hpmax = 10},
	},
	shellReadyDelay = 32,
	shellSpeed = 5,
	shellSpinDelay = {min = 240, max = 360},
	shellOutDelay = 48,
	shellChargeJumpBack = {
		X = {min=3,max=5.5},
		Y = {min=11,max=13.5},
	},
	shellChargeSpeed = 8,
	shellChargeReadyDelay = 70,
	jumpBackBeforeFireDelay = 56,
	jumpBackStayAirDelay = 40,
	jumpBackSpawnFireDelay = 8,
	jumpBackFire = {xmin = 0, xmax = 0, ymin = 0, ymax = 0, id = 875},
	jumpBackFireInt = 6,
	jumpBackFireAmount = 6,
	shellBounceDelay = 240,
	shellBounceReadyDelay = 60,
	scorch1JumpReadyDelay = 64,
	scorch1JumpXRate = 80,
	scorch1JumpXLimit = 8,
	scorch1JumpY = 10.5,
	scorch1LandDelay = 16,
	scorch2JumpReadyDelay = 16,
	scorch2JumpX = {min=-3,max=-4},
	scorch2JumpY = {min=11.5,max=13},
	scorch2Fire = {
		[1] = {xmin = 4, xmax = 5.5, ymin = 4, ymax = 4, id = 876},
		[2] = {xmin = 2, xmax = 3.5, ymin = 4.5, ymax = 4.5, id = 876},
		[3] = {xmin = 1.5, xmax = 3, ymin = 5, ymax = 5, id = 876},
	},
	scorch2BeforeFireDelay = 50,
	scorch2StayAirDelay = 30,
	scorch2LandDelay = 16,
	barrageJumpReadyDelay = 64,
	barrageJumpX = {min=-1.5,max=-3},
	barrageJumpY = {min=10.5,max=11.5},
	barrageHammer = {
		[1] = {
			indicate = 1,
			set = {
				[1] = {xmin = 1.5, xmax = 1.5, ymin = -9, ymax = -9, id = 873},
				[2] = {xmin = 3, xmax = 3, ymin = -9, ymax = -9, id = 873},
				[3] = {xmin = 4.5, xmax = 4.5, ymin = -9, ymax = -9, id = 873},
				[4] = {xmin = 6, xmax = 6, ymin = -9, ymax = -9, id = 873},
				[5] = {xmin = 7.5, xmax = 7.5, ymin = -9, ymax = -9, id = 873},
			},
		},
		[2] = {
			indicate = 2,
			set = {
				[1] = {xmin = 0.75, xmax = 0.75, ymin = -9, ymax = -9, id = 873},
				[2] = {xmin = 2.25, xmax = 2.25, ymin = -9, ymax = -9, id = 873},
				[3] = {xmin = 3.75, xmax = 3.75, ymin = -9, ymax = -9, id = 873},
				[4] = {xmin = 5.25, xmax = 5.25, ymin = -9, ymax = -9, id = 873},
				[5] = {xmin = 6.75, xmax = 6.75, ymin = -9, ymax = -9, id = 873},
			},
		},
	},
	barrageBeforeHammerDelay = 40,
	barrageSpawnHammerDelay = 16,
	barrageLandDelay = 16,
	fieryReadyDelay = 64,
	fieryChaseDelay = {min=240,max=300},
	fieryShowerDelay = 200,
	fieryShowerSpawnDelay = 15,
	fieryShowerAmount = {min=8,max=10},
	fieryShowerFire = {
		[1] = {xmin = 0, xmax = 0, ymin = -8, ymax = -8, id = 877},
	},
	fieryBurstBeforeDelay = 90,
	fieryBurstAfterDelay = 48,
	fieryTurnDelay = 16,
	fieryBurstFire = {
		[1] = {
			indicate = 1,
			set = {
				[1] = {xmin = 6, xmax = 6, ymin = 0, ymax = 0, id = 706},
				[2] = {xmin = -6, xmax = -6, ymin = 0, ymax = 0, id = 706},
				[3] = {xmin = -4.5, xmax = -4.5, ymin = -4.5, ymax = -4.5, id = 706},
				[4] = {xmin = 4.5, xmax = 4.5, ymin = -4.5, ymax = -4.5, id = 706},
			},
		},
	},
	holdX = 24,
	holdY = 32,
	throwAmount = {
		[1] = {amount = 1, hpmin = 0, hpmax = 20},
	},
	throwTable = {
		[1] = {xmin = 3, xmax = 3, ymin = -6, ymax = -6, id = 368, hpmin = 10, hpmax = 20},
		[2] = {xmin = 3, xmax = 3, ymin = -6, ymax = -6, id = 408, hpmin = 0, hpmax = 10},
	},
	courtesyNPC = {speedX = 6, speedY = -8, id = 9},
	courtesyStyle = 1, --0 throw one npc when starting a fight, 1 throw one or two npcs based on player's state and item box when starting a fight, 2 don't throw an npc when starting a fight
	flamethrowerDelay = {min=150,max=240},
	flameThrowerID = 878,

	attackStyleSet = 0, --0 depends on pure rng but can be restricted based on the number of hp it has and the attack entry's hp condition, 1 is the same as 0 but also makes decisions from the 3 distance thresholds based on the player's horizontal position to the boss' horizontal position
	
	independantAttackTable = {
		attackTable = {
			[1] = {state = STATE_FIRE, hpmin = 0, hpmax = 20},
			[2] = {state = STATE_GROUNDED_HAMMER, hpmin = 10, hpmax = 20},
			[3] = {state = STATE_RUN, hpmin = 0, hpmax = 20},
			[4] = {state = STATE_SHELL, hpmin = 10, hpmax = 20},
			[5] = {state = STATE_GROUNDPOUND, hpmin = 0, hpmax = 20},
			[6] = {state = STATE_FIERY, hpmin = 0, hpmax = 10},
			[7] = {state = STATE_BARRAGE, hpmin = 0, hpmax = 10},
			[8] = {state = STATE_SCORCH, hpmin = 0, hpmax = 10},
			[9] = {state = STATE_THROW, hpmin = 0, hpmax = 20},
			[10] = {state = STATE_FLAMETHROWER, hpmin = 0, hpmax = 10},
		},
	},

	distanceThreshold = {
		short = {
			distance = 160,
			attackTable = {
				[1] = {state = STATE_FIRE, hpmin = 0, hpmax = 20},
				[2] = {state = STATE_GROUNDED_HAMMER, hpmin = 0, hpmax = 20},
				[3] = {state = STATE_RUN, hpmin = 0, hpmax = 20},
				[4] = {state = STATE_SHELL, hpmin = 0, hpmax = 20},
				[5] = {state = STATE_GROUNDPOUND, hpmin = 0, hpmax = 20},
				[6] = {state = STATE_FIERY, hpmin = 0, hpmax = 20},
				[7] = {state = STATE_BARRAGE, hpmin = 0, hpmax = 20},
				[8] = {state = STATE_SCORCH, hpmin = 0, hpmax = 20},
				[9] = {state = STATE_SHELL, hpmin = 0, hpmax = 20},
				[10] = {state = STATE_BARRAGE, hpmin = 0, hpmax = 20},
				[11] = {state = STATE_FIERY, hpmin = 0, hpmax = 20},
				[12] = {state = STATE_FIERY, hpmin = 0, hpmax = 20},
				[13] = {state = STATE_FIERY, hpmin = 0, hpmax = 20},
				[14] = {state = STATE_SHELL, hpmin = 0, hpmax = 20},
				[15] = {state = STATE_BARRAGE, hpmin = 0, hpmax = 20},
				[16] = {state = STATE_THROW, hpmin = 0, hpmax = 20},
				[17] = {state = STATE_THROW, hpmin = 0, hpmax = 20},
				[18] = {state = STATE_FLAMETHROWER, hpmin = 0, hpmax = 10},
			},
		},
		mid = {
			attackTable = {
				[1] = {state = STATE_FIRE, hpmin = 0, hpmax = 20},
				[2] = {state = STATE_GROUNDED_HAMMER, hpmin = 0, hpmax = 20},
				[3] = {state = STATE_RUN, hpmin = 0, hpmax = 20},
				[4] = {state = STATE_SHELL, hpmin = 0, hpmax = 20},
				[5] = {state = STATE_GROUNDPOUND, hpmin = 0, hpmax = 20},
				[6] = {state = STATE_FIERY, hpmin = 0, hpmax = 20},
				[7] = {state = STATE_BARRAGE, hpmin = 0, hpmax = 20},
				[8] = {state = STATE_SCORCH, hpmin = 0, hpmax = 20},
				[9] = {state = STATE_RUN, hpmin = 0, hpmax = 20},
				[10] = {state = STATE_BARRAGE, hpmin = 0, hpmax = 20},
				[11] = {state = STATE_FIRE, hpmin = 0, hpmax = 20},
				[12] = {state = STATE_FIRE, hpmin = 0, hpmax = 20},
				[13] = {state = STATE_FIERY, hpmin = 0, hpmax = 20},
				[14] = {state = STATE_SHELL, hpmin = 0, hpmax = 20},
				[15] = {state = STATE_SCORCH, hpmin = 0, hpmax = 20},
				[16] = {state = STATE_THROW, hpmin = 0, hpmax = 20},
				[17] = {state = STATE_FLAMETHROWER, hpmin = 0, hpmax = 20},
			},
		},
		long = {
			distance = 288,
			attackTable = {
				[1] = {state = STATE_FIRE, hpmin = 0, hpmax = 20},
				[2] = {state = STATE_GROUNDED_HAMMER, hpmin = 0, hpmax = 20},
				[3] = {state = STATE_RUN, hpmin = 0, hpmax = 20},
				[4] = {state = STATE_SHELL, hpmin = 0, hpmax = 20},
				[5] = {state = STATE_GROUNDPOUND, hpmin = 0, hpmax = 20},
				[6] = {state = STATE_FIERY, hpmin = 0, hpmax = 20},
				[7] = {state = STATE_BARRAGE, hpmin = 0, hpmax = 20},
				[8] = {state = STATE_SCORCH, hpmin = 0, hpmax = 20},
				[9] = {state = STATE_GROUNDPOUND, hpmin = 0, hpmax = 20},
				[10] = {state = STATE_GROUNDED_HAMMER, hpmin = 0, hpmax = 20},
				[11] = {state = STATE_GROUNDPOUND, hpmin = 0, hpmax = 20},
				[12] = {state = STATE_GROUNDED_HAMMER, hpmin = 0, hpmax = 20},
				[13] = {state = STATE_FIRE, hpmin = 0, hpmax = 20},
				[14] = {state = STATE_SCORCH, hpmin = 0, hpmax = 20},
				[15] = {state = STATE_THROW, hpmin = 0, hpmax = 20},
				[16] = {state = STATE_THROW, hpmin = 0, hpmax = 20},
				[17] = {state = STATE_FLAMETHROWER, hpmin = 0, hpmax = 20},
			},
		},
	},


	spawnOffset = {
		x = {[-1] = -32, [1] = 32},
		y = -12,
	},
	hammerOffset = {
		x = {[-1] = -0, [1] = 0},
		y = -36,
	},
	fieryOffset = {
		x = {[-1] = -0, [1] = 0},
		y = 0,
	},
	holdOffset = {
		x = {[-1] = -0, [1] = 0},
		y = -36,
	},
	shellSize = {width = 56, height = 32},
	dontGetJumpedOn = false,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=872,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

local destroyColliderOffset = {
	[-1] = -1,
	[1] = sampleNPCSettings.width/2+1
}

local function SFXPlayTable(sfx)
	--Uses a table variable to choose one of the listed entries and produces a sound of it; if not, then don't play a sound.
	if sfx then
		local sfxChoice = RNG.irandomEntry(sfx)
		if sfxChoice then
			SFX.play(sfxChoice)
		end
	end
end

local function SFXPlay(sfx)
	--Checks a variable if it has a sound and produces a sound of it; if not, then don't play a sound.
	if sfx then
		SFX.play(sfx)
	end
end

local function decideAttack(v,data,config,settings)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local px = plr.x + plr.width / 2
	local vx = v.x + v.width / 2
	local options = {}
	local specifiedThreshold
	if config.attackStyleSet == 0 then
		specifiedThreshold = config.independantAttackTable.attackTable
	else
		if math.abs(px - vx) <= config.distanceThreshold.short.distance then
			specifiedThreshold = config.distanceThreshold.short.attackTable
		elseif math.abs(px - vx) >= config.distanceThreshold.long.distance then
			specifiedThreshold = config.distanceThreshold.long.attackTable
		else
			specifiedThreshold = config.distanceThreshold.mid.attackTable
		end
	end
    if specifiedThreshold and #specifiedThreshold > 0 then
        for i in ipairs(specifiedThreshold) do
            if  data.health > specifiedThreshold[i].hpmin and data.health <= specifiedThreshold[i].hpmax then
                if specifiedThreshold[i].state ~= data.selectedAttack then
					table.insert(options,specifiedThreshold[i].state)
				end
            end
        end
    end
    if #options > 0 then
        data.state = RNG.irandomEntry(options)
    	data.selectedAttack = data.state
    end
	data.timer = 0
	v.ai1 = 0
end

local function setDir(dir, v)
	if (dir and v.data._basegame.direction == 1) or (v.data._basegame.direction == -1 and not dir) then return end
	if dir then
		v.data._basegame.direction = 1
	else
		v.data._basegame.direction = -1
	end
end

local function getDistance(k,p)
	return k.x + k.width/2 < p.x + p.width/2
end

local function chasePlayers(v)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local dir1 = getDistance(v, plr)
	setDir(dir1, v)
end

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local settings = v.data._settings
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		data.hurtTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true

		if settings.intro == nil then settings.intro = false end

		data.timer = data.timer or 0
		data.hurtTimer = data.hurtTimer or 0
		data.iFrames = false
		data.health = NPC.config[v.id].health
		if settings.intro == true then
			data.state = STATE_INTRO
			v.y = camera.y - v.height - 4
			v.nogravity = true
			v.noblockcollision = true
		else
			if config.courtesyStyle < 2 then
				data.state = STATE_THROW
			else
				data.state = STATE_IDLE
			end
		end
        data.frametimer = 0
        --v.walkingtimer is how much Bowser walks before turning around
		v.walkingtimer = 0
		--v.walkingdirection is the direction Bowser is moving
		v.walkingdirection = v.direction
		--v.initialdirection is Bowser's initial direction. If the player is beyond their initial direction then they'll chase the player
		v.initialdirection = v.direction
        v.ai2 = RNG.randomInt(config.idleDelay.min,config.idleDelay.max)
		data.useShell = false
		data.stayAir = false
		data.turnDelay = RNG.randomInt(config.walkTurnDelay.min,config.walkTurnDelay.max)
		data.fireP = 0
		data.fireB = false
		data.fireA = nil
		data.poundA = nil
		data.poundB = false
		data.fieryA = 0
		data.selectedAttack = -1
		data.heldNPC = 0
		data.throwA = nil
		data.throwP = 0
		data.throwB = false
		data.flameY = 0
		if config.courtesyStyle ~= 2 then
			data.courtesy = true
		else
			data.courtesy = false
		end
		data.displayHeldNPC = false
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_IDLE
        v.animationFrame = 0
		data.timer = 0
        return
	end
	
	data.timer = data.timer + 1
	data.flameY = math.cos(lunatime.tick() / 8)*14 / 8

	if data.stayAir == false then
		data.keepXSpeed = v.speedX
		data.keepYSpeed = v.speedY
	else
		v.speedX = 0
		v.speedY = -defines.npc_grav
	end

	if (data.state == STATE_SHELL and ((v.ai1 == 0 and data.timer >= 40) or v.ai1 == 1 or v.ai1 == 2 or (v.ai1 == 3 and data.timer < 48) or v.ai1 == 4 or v.ai1 == 6)) or (data.state == STATE_FIERY and ((v.ai1 == 0 and data.timer >= 40) or v.ai1 == 1 or v.ai1 == 2 or (v.ai1 == 3 and data.timer <= config.fieryBurstBeforeDelay) or (v.ai1 == 4 and data.timer < 48))) then
		data.useShell = true
	else
		data.useShell = false
	end

	if data.state == STATE_IDLE then
		v.ai4 = v.ai4 + 1
		if config.walkSpeed ~= 0 then
			if data.timer == 1 then v.walkingtimer = 0 end
			data.frametimer = data.frametimer + 1
			if v.walkingdirection == -1 then
				if data.frametimer < 8 then
					v.animationFrame = 3
				elseif data.frametimer < 16 then
					v.animationFrame = 4
				elseif data.frametimer < 24 then
					v.animationFrame = 5
				else
					v.animationFrame = 3
					data.frametimer = 0
				end
			else
				if data.frametimer < 8 then
					v.animationFrame = 5
				elseif data.frametimer < 16 then
					v.animationFrame = 4
				elseif data.frametimer < 24 then
					v.animationFrame = 3
				else
					v.animationFrame = 5
					data.frametimer = 0
				end
			end

			v.speedX = config.walkSpeed * v.walkingdirection
				
			v.walkingtimer = v.walkingtimer - v.walkingdirection
				
			if v.walkingtimer == config.walkRange or v.walkingtimer == -config.walkRange or v.ai4 >= data.turnDelay then
				v.walkingdirection = v.walkingdirection * -1
				v.ai4 = 0
				data.turnDelay = RNG.randomInt(config.walkTurnDelay.min,config.walkTurnDelay.max)
			end
		else
			v.speedX = 0
			if data.timer % 48 > 36 then
				v.animationFrame = 0
			else
				v.animationFrame = 21
			end
			if data.timer % 48 == 0 and v.collidesBlockBottom then v.speedY = -3 end
		end
        if data.timer >= v.ai2 and v.collidesBlockBottom then
			data.timer = 0
			decideAttack(v,data,config,settings)
            v.ai2 = RNG.randomInt(config.walkTurnDelay.min,config.walkTurnDelay.max)
			npcutils.faceNearestPlayer(v)
        end
	elseif data.state == STATE_INTRO then
		v.speedX = 0
		if v.ai1 == 0 then
			v.friendly = true
			v.y=v.y+3
			v.animationFrame = 29
			if v.y >= v.spawnY then
				SFX.play(37)
				v.y=v.spawnY
				data.timer = 0
				v.ai1 = 1
				defines.earthquake = 10
				v.noblockcollision = false
				v.nogravity = false
				local a = Animation.spawn(10,v.x+v.width/5-16,v.y+v.height-16)
				a.speedX = -3
				local a = Animation.spawn(10,v.x+v.width*4/5-16,v.y+v.height-16)
				a.speedX = 3
				npcutils.faceNearestPlayer(v)
			end
		elseif v.ai1 == 1 then
			if data.timer < 8 then
				v.animationFrame = 30
			elseif data.timer < 56 then
				v.animationFrame = 31
			elseif data.timer < 64 then
				v.animationFrame = 32
			else
				v.animationFrame = 33
			end
			if data.timer >= 72 then
				data.timer = 0
				v.ai1 = 0
				if data.courtesy == true then
					data.state = STATE_THROW
				else
					data.state = STATE_IDLE
					v.friendly = false
				end
			end
		else
			v.ai1 = 0
			data.timer = 0
		end
	elseif data.state == STATE_BARRAGE then
		if v.ai1 == 0 then
			v.animationFrame = 18
			v.speedX = 0
			if data.timer >= config.barrageJumpReadyDelay then
				v.speedX = RNG.randomInt(config.barrageJumpX.min,config.barrageJumpX.max) * v.direction
				v.speedY = -RNG.randomInt(config.barrageJumpY.min,config.barrageJumpY.max)
				data.timer = 0
				v.ai1 = 1
				SFX.play(1)
			end
		elseif v.ai1 == 1 then
			if data.timer >= config.barrageBeforeHammerDelay then
				v.animationFrame = math.clamp(math.floor((data.timer - config.barrageBeforeHammerDelay) / 8) + 25, 25, 27)
			else
				if v.speedY <= 0 then
					v.animationFrame = 20
				else
					v.animationFrame = 19
				end
			end
			if data.timer == config.barrageBeforeHammerDelay + config.barrageSpawnHammerDelay then
				local options = {}
				local selectedSet
				if options and config.barrageHammer then
					for i in ipairs(config.barrageHammer) do
						table.insert(options,config.barrageHammer[i].indicate)
					end
					if #options > 0 then
						selectedSet = RNG.irandomEntry(options)
					end
				end
				if selectedSet and config.barrageHammer[selectedSet] and config.barrageHammer[selectedSet].set then
					SFX.play(25)
					for i in ipairs(config.barrageHammer[selectedSet].set) do
						local n = NPC.spawn(config.barrageHammer[selectedSet].set[i].id, v.x + v.width / 2 + config.spawnOffset.x[v.direction], v.y + v.height / 2 + config.spawnOffset.y, v.section, false, true)
						n.direction = v.direction
						n.speedX = RNG.random(config.barrageHammer[selectedSet].set[i].xmin,config.barrageHammer[selectedSet].set[i].xmax) * v.direction
						n.speedY = RNG.random(config.barrageHammer[selectedSet].set[i].ymin,config.barrageHammer[selectedSet].set[i].ymax)
					end
				end
			end
			if v.collidesBlockBottom then
				data.timer = 0
				v.ai1 = 2
				v.speedX = 0
			end
		elseif v.ai1 == 2 then
			v.animationFrame = 18
			v.speedX = 0
			if data.timer >= config.barrageLandDelay then
				npcutils.faceNearestPlayer(v)
				v.ai1 = 0
				data.timer = 0
				data.state = STATE_IDLE
			end
		else
			v.ai1 = 0
			data.timer = 0
		end
	elseif data.state == STATE_SCORCH then
		if v.ai1 == 0 then
			if data.timer < config.scorch1JumpReadyDelay then
				v.animationFrame = 18
				npcutils.faceNearestPlayer(v)
				v.speedX = 0
			else
				if v.speedY <= 0 then
					v.animationFrame = 20
				else
					v.animationFrame = 19
				end
			end
			if data.timer == config.scorch1JumpReadyDelay then
				npcutils.faceNearestPlayer(v)
				SFX.play(1)
				local bombxspeed = vector.v2(Player.getNearest(v.x + v.width/2, v.y + v.height).x + 0.5 * Player.getNearest(v.x + v.width/2, v.y + v.height).width - (v.x + 0.5 * v.width))
				v.speedX = bombxspeed.x / config.scorch1JumpXRate
				if v.speedX >  config.scorch1JumpXLimit then v.speedX = config.scorch1JumpXLimit end
				if v.speedX < -config.scorch1JumpXLimit then v.speedX = -config.scorch1JumpXLimit end
				v.speedY = -config.scorch1JumpY
			end
			if data.timer > config.scorch1JumpReadyDelay and v.collidesBlockBottom then
				v.speedX = 0
				v.ai1 = 1
				data.timer = 0
				npcutils.faceNearestPlayer(v)
			end
		elseif v.ai1 == 1 then
			if data.timer < config.scorch1LandDelay then
				v.animationFrame = 0
				npcutils.faceNearestPlayer(v)
			else
				v.animationFrame = 18
			end
			v.speedX = 0
			if data.timer >= config.scorch1LandDelay + config.scorch2JumpReadyDelay then
				v.speedX = RNG.randomInt(config.scorch2JumpX.min,config.scorch2JumpX.max) * v.direction
				v.speedY = -RNG.randomInt(config.scorch2JumpY.min,config.scorch2JumpY.max)
				data.timer = 0
				v.ai1 = 2
				SFX.play(1)
			end
		elseif v.ai1 == 2 then
			if data.timer >= config.scorch2BeforeFireDelay and data.timer < config.scorch2BeforeFireDelay + config.scorch2StayAirDelay then
				v.animationFrame = math.clamp(math.floor((data.timer - config.scorch2BeforeFireDelay) / 8) + 22, 22, 24)
				data.stayAir = true
			else
				data.stayAir = false
				if v.speedY <= 0 then
					v.animationFrame = 20
				else
					v.animationFrame = 19
				end
			end
			if data.timer == config.jumpBackBeforeFireDelay + config.jumpBackSpawnFireDelay then
				SFX.play(42)
					for i in ipairs(config.scorch2Fire) do
						local n = NPC.spawn(config.scorch2Fire[i].id, v.x + v.width / 2 + config.spawnOffset.x[v.direction], v.y + v.height / 2 + config.spawnOffset.y, v.section, false, true)
						n.direction = v.direction
						n.speedX = RNG.random(config.scorch2Fire[i].xmin,config.scorch2Fire[i].xmax) * v.direction
						n.speedY = RNG.random(config.scorch2Fire[i].ymin,config.scorch2Fire[i].ymax)
					end
			end
			if data.timer == config.scorch2BeforeFireDelay + config.scorch2StayAirDelay then
				v.speedX = data.keepXSpeed
				v.speedY = data.keepYSpeed
			end
			if v.collidesBlockBottom then
				data.timer = 0
				v.ai1 = 3
				v.speedX = 0
			end
		elseif v.ai1 == 3 then
			v.animationFrame = 18
			v.speedX = 0
			if data.timer >= config.scorch2LandDelay then
				npcutils.faceNearestPlayer(v)
				v.ai1 = 0
				data.timer = 0
				data.state = STATE_IDLE
			end
		else
			v.ai1 = 0
			data.timer = 0
		end
	elseif data.state == STATE_GROUNDPOUND then
		if v.ai1 == 0 then
			if data.timer >= config.groundPoundStartUp1 or data.timer % 16 < 8 then
				v.animationFrame = 18
			else
				v.animationFrame = 21
			end
			if data.timer == 1 then
				if data.poundB == false then
					local options = {}
	
					for i in ipairs(config.groundPoundAmount) do
						if data.health >= config.groundPoundAmount[i].hpmin and data.health <= config.groundPoundAmount[i].hpmax then
							table.insert(options,config.groundPoundAmount[i].amount)
						end
					end
					if #options > 0 then
						data.poundA = RNG.irandomEntry(options)
						data.poundB = true
						SFX.play(13)
					else
						data.poundA = nil
						data.timer = 0
						data.state = STATE_IDLE
						v.ai1 = 0
					end
				end
			end
			v.speedX = 0
			if data.timer >= config.groundPoundStartUp1 + config.groundPoundStartUp2 then
				data.timer = 0
				v.ai1 = 1
			end
		elseif v.ai1 == 1 then
			if data.timer < config.groundPoundReady then
				v.animationFrame = 18
			else
				if v.speedY <= 0 then
					v.animationFrame = 20
				else
					v.animationFrame = 19
				end
				v.speedY = -config.groundPoundRiseY - defines.npc_grav
			end
			if data.timer == config.groundPoundReady then
				npcutils.faceNearestPlayer(v)
				local bombxspeed = vector.v2(Player.getNearest(v.x + v.width/2, v.y + v.height).x + 0.5 * Player.getNearest(v.x + v.width/2, v.y + v.height).width - (v.x + 0.5 * v.width))
				v.speedX = bombxspeed.x / config.groundPoundRiseXRate
				if v.speedX >  config.groundPoundRiseXLimit then v.speedX = config.groundPoundRiseXLimit end
				if v.speedX < -config.groundPoundRiseXLimit then v.speedX = -config.groundPoundRiseXLimit end
			end
			if data.timer >= config.groundPoundReady + config.groundPoundRiseDelay then
				data.timer = 0
				v.ai1 = 2
				data.stayAir = true
			end
		elseif v.ai1 == 2 then
			v.animationFrame = math.clamp(math.floor((data.timer) / 12) + 28, 28, 29)
			data.stayAir = true
			if data.timer >= config.groundPoundAirDelay then
				data.stayAir = false
				data.timer = 0
				v.ai1 = 3
			end
		elseif v.ai1 == 3 then
			v.speedY = v.speedY + config.groundPoundFallAcc
			v.speedX = 0
			v.animationFrame = 29
			if v.collidesBlockBottom then
				data.timer = 0
				v.ai1 = 4
				npcutils.faceNearestPlayer(v)
				SFX.play(37)
				defines.earthquake = 8
				if config.groundPoundStun.stun == true then
					for k, p in ipairs(Player.get()) do --Section copypasted from the Sledge Bros. code
						if p:isGroundTouching() and not playerStun.isStunned(k) and v:mem(0x146, FIELD_WORD) == player.section then
							playerStun.stunPlayer(k, config.groundPoundStun.timer)
						end
					end
				end
				data.destroyCollider = data.destroyCollider or Colliders.Box(v.x - 1, v.y + 1, v.width + 1, v.height - 1);
				data.destroyCollider.x = v.x + 0.5 * (2/v.width) * v.direction;
				data.destroyCollider.y = v.y + 8;
				local list = Colliders.getColliding{
					a = data.destroyCollider,
					btype = Colliders.BLOCK,
					filter = function(other)
						if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
							return false
						end
						return true
					end
					}
				for _,b in ipairs(list) do
					if (Block.config[b.id].smashable ~= nil and Block.config[b.id].smashable == 3) or b.id == 186 then
						b:remove(true)
					else
						b:hit(true)
					end
				end
			end
		elseif v.ai1 == 4 then
			if data.timer < 4 then
				v.animationFrame = 30
			elseif data.timer < 20 then
				v.animationFrame = 31
			elseif data.timer < 24 then
				v.animationFrame = 32
			elseif data.timer < 28 then
				v.animationFrame = 33
			else
				v.animationFrame = 18
			end
			if data.timer >= config.groundPoundTurnDelay then
				data.timer = 0
				data.poundA = data.poundA - 1
				npcutils.faceNearestPlayer(v)
				if data.poundA <= 0 then
					data.state = STATE_IDLE
					data.poundB = false
					v.ai1 = 0
				else
					v.ai1 = 1
				end
			end
		end
	elseif data.state == STATE_RUN then
		if v.ai1 == 0 then
			v.speedX = 0
			if data.timer >= 8 and data.timer < 16 then
				v.animationFrame = 0
			else
				v.animationFrame = 21
			end
			if data.timer == 16 and v.collidesBlockBottom then
				v.speedY = -4
				SFX.play(26)
				data.locatex = plr.x + plr.width / 2
			end
			if data.timer > 16 and v.collidesBlockBottom then
				data.timer = 0
				v.ai1 = 1
			end
		elseif v.ai1 == 1 then
			v.animationFrame = math.floor((data.timer) / 6) % 4 + 12
			v.speedX = config.runSpeed * v.direction
			if (v.collidesBlockLeft and v.direction == -1) or (v.collidesBlockRight and v.direction == 1) then
				data.timer = 0
				v.ai1 = 2
				SFX.play(3)
				SFX.play(38)
				if v.collidesBlockLeft then
					Animation.spawn(75,v.x-16,v.y+v.height/2-16)
				elseif v.collidesBlockRight then
					Animation.spawn(75,v.x+v.width-16,v.y+v.height/2-16)
				end
				v.speedX = v.speedX * -0.6
				v.speedY = -5
			end
			if data.timer % 8 == 0 then SFX.play(Misc.resolveSoundFile("chuck-stomp")) end
			if data.timer >= config.runDelay or math.abs((v.x + v.width / 2) - (data.locatex)) <= config.runRangeX then
				v.speedX = 0
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_IDLE
			end
		elseif v.ai1 == 2 then
			if data.timer < 90 then
				v.animationFrame = math.floor((data.timer) / 6) % 4 + 34
			else
				v.animationFrame = 21
			end
			if v.collidesBlockBottom then v.speedX = 0 end
			if data.timer >= 120 and v.collidesBlockBottom then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_IDLE
			end
		else
			v.ai1 = 0
			data.timer = 0
		end


	elseif data.state == STATE_FIRE then
		v.speedX = 0
		if v.ai1 == 0 then
			v.animationFrame = math.clamp(math.floor((data.timer) / 10) + 7, 7, 8)
			if data.timer == 1 then
				local options = {}

				for i in ipairs(config.horizontalFlame.fireKind) do
					if data.health >= config.horizontalFlame.fireKind[i].hpmin and data.health <= config.horizontalFlame.fireKind[i].hpmax then
						table.insert(options,config.horizontalFlame.fireKind[i].set)
					end
				end
				if #options > 0 then
					data.fireP = RNG.irandomEntry(options)
				else
					data.fireP = nil
					data.timer = 0
					data.state = STATE_IDLE
					v.ai1 = 0
				end
				if data.fireB == false then
					local options = {}

					for i in ipairs(config.horizontalFlame.amount) do
						if data.health >= config.horizontalFlame.amount[i].hpmin and data.health <= config.horizontalFlame.amount[i].hpmax then
							table.insert(options,config.horizontalFlame.amount[i].amount)
						end
					end
					if #options > 0 then
						data.fireA = RNG.irandomEntry(options)
						data.fireB = true
					else
						data.fireA = nil
						data.timer = 0
						data.state = STATE_IDLE
						v.ai1 = 0
					end
				end

			end
			if data.timer >= config.horizontalFlame.readyDelay then
				data.timer = 0
				v.ai1 = 1
			end
		elseif v.ai1 == 1 then
			if data.timer < config.horizontalFlame.releaseDelay then
				v.animationFrame = 7
			else
				v.animationFrame = 9
			end
			if data.timer == config.horizontalFlame.releaseDelay then
				if data.fireP then
					SFX.play(42)
					for i in ipairs(data.fireP) do
						local n = NPC.spawn(data.fireP[i].id, v.x + v.width / 2 + config.spawnOffset.x[v.direction], v.y + v.height / 2 + config.spawnOffset.y, v.section, false, true)
						n.direction = v.direction
						n.speedX = data.fireP[i].speedX * v.direction
						n.speedY = data.fireP[i].speedY
					end
				end
			end
			if data.timer >= config.horizontalFlame.releaseDelay + config.horizontalFlame.afterDelay then
				data.timer = 0
				v.ai1 = 0
				data.fireA = data.fireA - 1
				npcutils.faceNearestPlayer(v)
				if data.fireA <= 0 then
					data.state = STATE_IDLE
					data.fireB = false
				end
			end
		else
			v.ai1 = 0
			data.timer = 0
		end
	elseif data.state == STATE_FIERY then
		if v.ai1 == 0 then
			v.speedX = 0
			if data.timer < 8 then
				v.animationFrame = 18
			elseif data.timer < 40 then
				v.animationFrame = 19
			else
				local ptl = Animation.spawn(265, math.random(v.x, v.x + v.width)-8, math.random(v.y, v.y + v.height)-8)
				ptl.speedY = -2
				v.animationFrame = 38
			end
			if data.timer == 8 then v.speedY = -5 SFX.play(35) end
			if data.timer >= 40 + config.fieryReadyDelay and v.collidesBlockBottom then
				data.timer = 0
				v.ai1 = 1
				npcutils.faceNearestPlayer(v)
				v.ai5 = RNG.randomInt(config.fieryChaseDelay.min,config.fieryChaseDelay.max)
			end
		elseif v.ai1 == 1 then
			v.animationFrame = math.floor(data.timer / 6) % 4 + 38
			npcutils.faceNearestPlayer(v)
			chasePlayers(v)
			local ptl = Animation.spawn(265, math.random(v.x, v.x + v.width)-8, math.random(v.y, v.y + v.height)-8)
			ptl.speedY = -2
			v.speedX = math.clamp(v.speedX + 0.25 * v.data._basegame.direction, -6, 6)
			if v.collidesBlockBottom and data.timer >= v.ai5 then
				data.timer = 0
				v.ai5 = 0
				v.ai1 = RNG.irandomEntry{3,2}
				v.direction = v.data._basegame.direction
				v.speedX = 0
			end
			if v.collidesBlockLeft or v.collidesBlockRight then
				SFX.play(3)
				v.speedX = -v.speedX
				if v.collidesBlockLeft then
					Animation.spawn(75,v.x-16,v.y+v.height/2-16)
				elseif v.collidesBlockRight then
					Animation.spawn(75,v.x+v.width-16,v.y+v.height/2-16)
				end
			end
			if data.timer % 3 == 0 then
				local a = Effect.spawn(74, v.x + config.effectOffsetSkid[-v.data._basegame.direction], v.y + v.height)
				a.x=a.x-a.width/2
				a.y=a.y-a.height/2
			end
			if data.timer % 16 == 1 then
				SFX.play("spin.ogg")
			end
			-- Interact with blocks
			data.destroyCollider = data.destroyCollider or Colliders.Box(v.x, v.y, v.width / 2, v.height);
			data.destroyCollider.x = v.x + destroyColliderOffset[v.direction]
			data.destroyCollider.y = v.y;
			local tbl = Block.SOLID .. Block.PLAYER
			local list = Colliders.getColliding{
			a = data.destroyCollider,
			b = tbl,
			btype = Colliders.BLOCK,
			filter = function(other)
				if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
					return false
				end
				return true
			end
			}
			for _,b in ipairs(list) do
				if (Block.config[b.id].smashable == nil and Block.config[b.id].smashable ~= 3) then
					b:hit(true)
				end
			end
		elseif v.ai1 == 3 then
			v.speedX = 0
			if data.timer < config.fieryBurstBeforeDelay then
				v.animationFrame = math.floor(data.timer / 3) % 4 + 38
				npcutils.faceNearestPlayer(v)
				if data.timer % 4 == 0 then
					SFX.play("spin.ogg")
				end
				local ptl = Animation.spawn(265, math.random(v.x, v.x + v.width)-8, math.random(v.y, v.y + v.height)-8)
				ptl.speedY = -2
			else
				v.animationFrame = 29
			end
			if data.timer == config.fieryBurstBeforeDelay then
				v.speedY = -4
				local options = {}
				local selectedSet
				if options and config.fieryBurstFire then
					for i in ipairs(config.fieryBurstFire) do
						table.insert(options,config.fieryBurstFire[i].indicate)
					end
					if #options > 0 then
						selectedSet = RNG.irandomEntry(options)
					end
				end
				if selectedSet and config.fieryBurstFire[selectedSet] and config.fieryBurstFire[selectedSet].set then
					SFX.play(42)
					for i in ipairs(config.fieryBurstFire[selectedSet].set) do
						local n = NPC.spawn(config.fieryBurstFire[selectedSet].set[i].id, v.x + v.width / 2 + config.fieryOffset.x[v.direction], v.y + v.height / 2 + config.fieryOffset.y, v.section, false, true)
						n.direction = v.direction
						n.speedX = RNG.random(config.fieryBurstFire[selectedSet].set[i].xmin,config.fieryBurstFire[selectedSet].set[i].xmax)
						n.speedY = RNG.random(config.fieryBurstFire[selectedSet].set[i].ymin,config.fieryBurstFire[selectedSet].set[i].ymax)
					end
				end
			end
			if data.timer > config.fieryBurstBeforeDelay and v.collidesBlockBottom then
				data.timer = 0
				v.ai1 = 5
			end
		elseif v.ai1 == 2 then
			if data.timer == 1 and config.fieryShowerAmount and config.fieryShowerAmount.min and config.fieryShowerAmount.max then data.fieryA = RNG.randomInt(config.fieryShowerAmount.min,config.fieryShowerAmount.max) end 
			v.animationFrame = math.floor(data.timer / 6) % 4 + 38
			v.speedX = 0
			local ptl = Animation.spawn(265, math.random(v.x, v.x + v.width)-8, math.random(v.y, v.y + v.height)-8)
			ptl.speedY = -2
			if data.timer % config.fieryShowerSpawnDelay == 0 and data.fieryA > 0 then
				data.fieryA = data.fieryA - 1
				local options = {}
				local selectedSet = nil
				if config.fieryShowerFire then
					for i in ipairs(config.fieryShowerFire) do
						table.insert(options,i)
					end
					if #options > 0 then
						selectedSet = RNG.irandomEntry(options)
					end
				end
				if selectedSet and config.fieryShowerFire[selectedSet] then
					SFX.play(42)
					local n = NPC.spawn(config.fieryShowerFire[selectedSet].id, v.x + v.width / 2 + config.fieryOffset.x[v.direction], v.y + v.height / 2 + config.fieryOffset.y, v.section, false, true)
					n.direction = v.direction
					n.speedX = RNG.random(config.fieryShowerFire[selectedSet].xmin,config.fieryShowerFire[selectedSet].xmax) * v.direction
					n.speedY = RNG.random(config.fieryShowerFire[selectedSet].ymin,config.fieryShowerFire[selectedSet].ymax)
				end
			end
			if data.timer >= config.fieryShowerDelay then
				data.timer = 0
				v.ai1 = 4
				data.fieryA = 0
			end
		elseif v.ai1 == 4 then
			if data.timer == 16 then v.speedY = -5 SFX.play(35) end
			v.speedX = 0
			if data.timer < 48 then
				v.animationFrame = 38
			else
				if not v.collidesBlockBottom then
					v.animationFrame = 20
				else
					v.animationFrame = 21
				end
			end
			if data.timer >= 48 + 48 and v.collidesBlockBottom then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_IDLE
			end
		elseif v.ai1 == 5 then
			if data.timer < config.fieryBurstAfterDelay then
				v.animationFrame = math.clamp(math.floor((data.timer) / 8) + 30, 30, 31)
			else
				v.animationFrame = math.clamp(math.floor((data.timer - config.fieryBurstAfterDelay) / 8) + 32, 32, 33)
				if math.floor((data.timer - config.fieryBurstAfterDelay) / 8) + 32 > 33 then
					v.animationFrame = 21
				end
			end
			v.speedX = 0
			if data.timer >= config.fieryTurnDelay + config.fieryBurstAfterDelay then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_IDLE
			end
		end
	elseif data.state == STATE_SHELL then
		if v.ai1 == 0 then
			v.speedX = 0
			if data.timer < 8 then
				v.animationFrame = 18
			elseif data.timer < 40 then
				v.animationFrame = 19
			else
				v.animationFrame = 38
			end
			if data.timer == 8 then v.speedY = -5 SFX.play(35) end
			if data.timer >= 40 + config.shellReadyDelay and v.collidesBlockBottom then
				data.timer = 0
				v.ai1 = 1
				npcutils.faceNearestPlayer(v)
				v.ai5 = RNG.randomInt(config.shellSpinDelay.min,config.shellSpinDelay.max)
			end
		elseif v.ai1 == 1 then
			v.animationFrame = math.floor(data.timer / 6) % 4 + 38
			v.speedX = config.shellSpeed * v.direction
			if v.collidesBlockLeft or v.collidesBlockRight then
				SFX.play(3)
				if v.collidesBlockLeft then
					Animation.spawn(75,v.x-16,v.y+v.height/2-16)
					v.direction = 1
				elseif v.collidesBlockRight then
					Animation.spawn(75,v.x+v.width-16,v.y+v.height/2-16)
					v.direction = -1
				end
			end
			if data.timer >= v.ai5 then
				v.ai5 = 0
				data.timer = 0
				v.ai1 = RNG.irandomEntry{4,6}
			end
			if data.timer % 3 == 0 then
				local a = Effect.spawn(74, v.x + config.effectOffsetSkid[-v.direction], v.y + v.height)
				a.x=a.x-a.width/2
				a.y=a.y-a.height/2
			end
			if data.timer % 16 == 1 then
				SFX.play("spin.ogg")
			end
			-- Interact with blocks
			data.destroyCollider = data.destroyCollider or Colliders.Box(v.x, v.y, v.width / 2, v.height);
			data.destroyCollider.x = v.x + destroyColliderOffset[v.direction]
			data.destroyCollider.y = v.y;
			local tbl = Block.SOLID .. Block.PLAYER
			local list = Colliders.getColliding{
			a = data.destroyCollider,
			b = tbl,
			btype = Colliders.BLOCK,
			filter = function(other)
				if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
					return false
				end
				return true
			end
			}
			for _,b in ipairs(list) do
				if (Block.config[b.id].smashable == nil and Block.config[b.id].smashable ~= 3) then
					b:hit(true)
				end
			end
		elseif v.ai1 == 2 then
			v.animationFrame = 39
			if v.collidesBlockBottom then
				v.speedX = v.speedX * 0.96
				local a = Effect.spawn(74, v.x + config.effectOffsetSkid[v.direction], v.y + v.height)
				a.x=a.x-a.width/2
				a.y=a.y-a.height/2
				if data.timer % 8 == 0 then
					SFX.play(10)
				end
			end
			if v.collidesBlockLeft or v.collidesBlockRight then
				SFX.play(3)
				if v.collidesBlockLeft then
					Animation.spawn(75,v.x-16,v.y+v.height/2-16)
					v.direction = 1
				elseif v.collidesBlockRight then
					Animation.spawn(75,v.x+v.width-16,v.y+v.height/2-16)
					v.direction = -1
				end
				v.speedX = -v.speedX
			end
			if math.abs(v.speedX) <= 0.3 then
				v.speedX = 0
				data.timer = 0
				v.ai1 = 3
				npcutils.faceNearestPlayer(v)
			end
		elseif v.ai1 == 3 then
			if data.timer == 16 then v.speedY = -5 SFX.play(35) end
			v.speedX = 0
			if data.timer < 48 then
				v.animationFrame = 38
			else
				if not v.collidesBlockBottom then
					v.animationFrame = 20
				else
					v.animationFrame = 21
				end
			end
			if data.timer >= 48 + config.shellOutDelay and v.collidesBlockBottom then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_IDLE
			end
		elseif v.ai1 == 4 then
			v.animationFrame = math.floor(data.timer / 3) % 4 + 38
			if data.timer < config.shellChargeReadyDelay then
				v.speedX = 0
				npcutils.faceNearestPlayer(v)
				if data.timer % 4 == 0 then
					SFX.play("spin.ogg")
				end
			else
				v.speedX = config.shellChargeSpeed * v.direction
				if v.collidesBlockLeft or v.collidesBlockRight then
					if (v.collidesBlockLeft and v.direction == -1) or (v.collidesBlockRight and v.direction == 1) then
						data.timer = 0
						v.ai1 = 5
						defines.earthquake = 9
						SFX.play(37)
						v.speedY = -RNG.randomInt(config.shellChargeJumpBack.Y.min,config.shellChargeJumpBack.Y.max)
						v.direction = -v.direction
						v.speedX = RNG.randomInt(config.shellChargeJumpBack.X.min,config.shellChargeJumpBack.X.max) * v.direction
					end
					if v.collidesBlockLeft or v.collidesBlockRight then
						SFX.play(3)
						if v.collidesBlockLeft then
							Animation.spawn(75,v.x-16,v.y+v.height/2-16)
						elseif v.collidesBlockRight then
							Animation.spawn(75,v.x+v.width-16,v.y+v.height/2-16)
						end
					end
				end
			end
			-- Interact with blocks
			data.destroyCollider = data.destroyCollider or Colliders.Box(v.x, v.y, v.width / 2, v.height);
			data.destroyCollider.x = v.x + destroyColliderOffset[v.direction]
			data.destroyCollider.y = v.y;
			local tbl = Block.SOLID .. Block.PLAYER
			local list = Colliders.getColliding{
			a = data.destroyCollider,
			b = tbl,
			btype = Colliders.BLOCK,
			filter = function(other)
				if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
					return false
				end
				return true
			end
			}
			for _,b in ipairs(list) do
				if (Block.config[b.id].smashable == nil and Block.config[b.id].smashable ~= 3) then
					b:hit(true)
				end
			end
		elseif v.ai1 == 5 then
			if data.timer >= config.jumpBackBeforeFireDelay and data.timer < config.jumpBackBeforeFireDelay + config.jumpBackStayAirDelay then
				v.animationFrame = math.clamp(math.floor((data.timer - config.jumpBackBeforeFireDelay) / 8) + 22, 22, 24)
				data.stayAir = true
			else
				data.stayAir = false
				if v.speedY <= 0 then
					v.animationFrame = 20
				else
					v.animationFrame = 19
				end
			end
			if data.timer == config.jumpBackBeforeFireDelay + config.jumpBackSpawnFireDelay then
				Routine.setFrameTimer(config.jumpBackFireInt, (function() 
					local n = NPC.spawn(config.jumpBackFire.id, v.x + v.width / 2 + config.spawnOffset.x[v.direction], v.y + v.height / 2 + config.spawnOffset.y, v.section, false, true)
					n.direction = v.direction
					n.speedX = RNG.random(config.jumpBackFire.xmin,config.jumpbackFire.xmax)
					n.speedY = RNG.random(config.jumpBackFire.ymin,config.jumpBackFire.ymax)
					end), config.jumpBackFireAmount, false)
			end
			if data.timer == config.jumpBackBeforeFireDelay + config.jumpBackStayAirDelay then
				v.speedX = data.keepXSpeed
				v.speedY = data.keepYSpeed
			end
			if v.collidesBlockBottom then
				npcutils.faceNearestPlayer(v)
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_IDLE
				v.speedX = 0
			end
		elseif v.ai1 == 6 then
			if data.timer < config.shellBounceReadyDelay then
				v.speedX = 0
				v.animationFrame = 38
				if v.collidesBlockBottom then v.speedY = -4 SFX.play(24) end
			else
				v.animationFrame = math.floor(data.timer / 6) % 4 + 38
				npcutils.faceNearestPlayer(v)
				chasePlayers(v)
				v.speedX = math.clamp(v.speedX + 0.2 * v.data._basegame.direction, -5, 5)
				if v.collidesBlockBottom and data.timer >= config.shellBounceReadyDelay + config.shellBounceDelay then
					data.timer = 0
					v.ai1 = 2
					v.direction = v.data._basegame.direction
				end
				if v.collidesBlockBottom then v.speedY = -9 SFX.play(37) defines.earthquake = 8 end
				if v.collidesBlockLeft or v.collidesBlockRight then
					SFX.play(3)
					v.direction = v.data._basegame.direction
					v.speedX = -v.speedX
					if v.collidesBlockLeft then
						Animation.spawn(75,v.x-16,v.y+v.height/2-16)
					elseif v.collidesBlockRight then
						Animation.spawn(75,v.x+v.width-16,v.y+v.height/2-16)
					end
				end
				-- Interact with blocks
				data.destroyCollider = data.destroyCollider or Colliders.Box(v.x, v.y, v.width / 2, v.height);
				data.destroyCollider.x = v.x + destroyColliderOffset[v.direction]
				data.destroyCollider.y = v.y;
				local tbl = Block.SOLID .. Block.PLAYER
				local list = Colliders.getColliding{
				a = data.destroyCollider,
				b = tbl,
				btype = Colliders.BLOCK,
				filter = function(other)
					if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
						return false
					end
					return true
				end
				}
				for _,b in ipairs(list) do
					if (Block.config[b.id].smashable == nil and Block.config[b.id].smashable ~= 3) then
						b:hit(true)
					end
				end
			end
		else
			v.ai1 = 0
			data.timer = 0
		end
    elseif data.state == STATE_GROUNDED_HAMMER then
        if data.timer < config.groundedHammerReadyDelay then
			v.animationFrame = 11
		else
			v.animationFrame = math.floor((data.timer - config.groundedHammerReadyDelay) / 6) % 3 + 11
			if (data.timer - config.groundedHammerReadyDelay) % config.groundedHammerSpawnIntervals.interval == config.groundedHammerSpawnIntervals.onto then
				local traj
				local options = {}
				if config.groundedHammerTrajectory and #config.groundedHammerTrajectory > 0 then
					for i in ipairs(config.groundedHammerTrajectory) do
						table.insert(options,config.groundedHammerTrajectory[i])
					end
					if #options > 0 then
						traj = RNG.irandomEntry(options)
					end
				end
				if traj then
					h = NPC.spawn(traj.id, v.x + v.width / 2 + config.hammerOffset.x[v.direction], v.y + v.height / 2 + config.hammerOffset.y, v.section, false, true)
					h.direction = v.direction
					h.speedX = traj.speedX * v.direction
					h.speedY = traj.speedY
					SFX.play{sound=25, delay=7}
				end
			end
		end
        v.speedX = 0
        if data.timer == 1 then v.ai3 = RNG.randomInt(config.groundedHammerAmount.min,config.groundedHammerAmount.max) end
        if data.timer >= (18 * v.ai3) + 6 + config.groundedHammerReadyDelay then
            data.timer = 0
			data.state = STATE_IDLE
        end
	elseif data.state == STATE_THROW then
		v.speedX = 0
		if data.timer == 1 then
			if data.courtesy == true then
				if not (player.powerup == 1 or player:mem(0x158,FIELD_WORD) <= 0) then
					data.timer = 0
					if data.courtesy == true then data.courtesy = false v.friendly = false end
					data.state = STATE_IDLE
					return
				end
				data.heldNPC = config.courtesyNPC.id
				if data.throwB == false then
					if config.courtesyStyle == 0 then
						data.throwA = 1
					else
						if player.powerup == 1 and player:mem(0x158,FIELD_WORD) <= 0 then
							data.throwA = 2
						elseif player.powerup == 1 or player:mem(0x158,FIELD_WORD) <= 0 then
							data.throwA = 1
						end
					end
					data.throwB = true
				end
			else
				local options = {}
				if config.throwTable and #config.throwTable > 0 then 
					for i in ipairs(config.throwTable) do
						if data.health >= config.throwTable[i].hpmin and data.health <= config.throwTable[i].hpmax then
							table.insert(options,i)
						end
					end
				end
				if #options > 0 then
					data.throwP = RNG.irandomEntry(options)
					data.heldNPC = config.throwTable[data.throwP].id
				else
					data.throwP = nil
					data.timer = 0
					data.state = STATE_IDLE
				end
				if data.throwB == false then
					local options = {}

					for i in ipairs(config.throwAmount) do
						if data.health >= config.throwAmount[i].hpmin and data.health <= config.throwAmount[i].hpmax then
							table.insert(options,config.throwAmount[i].amount)
						end
					end
					if #options > 0 then
						data.throwA = RNG.irandomEntry(options)
						data.throwB = true
					else
						data.throwA = nil
						data.timer = 0
						data.state = STATE_IDLE
					end
				end
			end
		end
		if data.timer < 64 then
			v.animationFrame = 11
		else
			v.animationFrame = math.clamp(math.floor((data.timer - 64) / 8) + 11,11,13)
		end
		if data.timer < 80 then
			data.displayHeldNPC = true
		else
			data.displayHeldNPC = false
		end
		if data.timer == 80 and data.heldNPC then
			local n = NPC.spawn(data.heldNPC, v.x + v.width / 2 + config.hammerOffset.x[v.direction], v.y + v.height / 2 + config.hammerOffset.y, v.section, false, true)
			n.direction = v.direction
			if data.courtesy == true then
				n.speedX = config.courtesyNPC.speedX * v.direction
				n.speedY = config.courtesyNPC.speedY
			else
				n.speedX = RNG.random(config.throwTable[data.throwP].xmin,config.throwTable[data.throwP].xmax) * v.direction
				n.speedY = RNG.random(config.throwTable[data.throwP].ymin,config.throwTable[data.throwP].ymax)
			end
			SFX.play{sound=25, delay=7}
		end
		if data.timer >= 128 then
			data.heldNPC = 0
			data.timer = 0
			data.throwA = data.throwA - 1
			if data.throwA <= 0 then
				data.state = STATE_IDLE
				data.throwB = false
				if data.courtesy == true then data.courtesy = false v.friendly = false end
			end
		end
	elseif data.state == STATE_FLAMETHROWER then
		if v.ai1 == 0 then
			v.speedX = 0
			if data.timer < 8 then
				v.animationFrame = 18
			else
				if v.speedY <= 0 then
					v.animationFrame = 20
				else
					v.animationFrame = 19
				end
				local ptl = Animation.spawn(265, math.random(v.x, v.x + v.width)-8, math.random(v.y, v.y + v.height)-8)
				ptl.speedY = -2
			end
			if data.timer == 8 then v.speedY = -5 SFX.play(35) end
			if data.timer >= 40 and v.collidesBlockBottom then
				data.timer = 0
				v.ai1 = 1
				npcutils.faceNearestPlayer(v)
				v.ai5 = RNG.randomInt(config.flamethrowerDelay.min,config.flamethrowerDelay.max)
				SFX.play(37)
				defines.earthquake = 8
				local a = Animation.spawn(10,v.x+v.width/5-16,v.y+v.height-16)
				a.speedX = -3
				local a = Animation.spawn(10,v.x+v.width*4/5-16,v.y+v.height-16)
				a.speedX = 3
			end
		elseif v.ai1 == 1 then
			v.animationFrame = math.floor(data.timer / 8) % 3 + 3
			v.speedX = 2.5 * v.direction
			local ptl = Animation.spawn(265, math.random(v.x, v.x + v.width)-8, math.random(v.y, v.y + v.height)-8)
			ptl.speedY = -2
			if (v.collidesBlockLeft and v.direction == -1) or (v.collidesBlockRight and v.direction == 1) then v.direction = -v.direction end
			if data.timer % 4 == 0 then
				SFX.play(16)
				local n = NPC.spawn(config.flameThrowerID, v.x + v.width / 2 + config.spawnOffset.x[v.direction], v.y + v.height / 2 + config.spawnOffset.y, v.section, false, true)
				n.direction = v.direction
				n.speedX = 3.75 * v.direction
				n.speedY = data.flameY
			end
			if data.timer >= v.ai5 then
				data.timer = 0
				v.ai5 = 0
				v.ai1 = 2
				v.speedX = 0
			end
		elseif v.ai1 == 2 then
			v.speedX = 0
			v.animationFrame = 21
			if data.timer >= 60 then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_IDLE
			end
		end
	end
	
	--Give Bowser some i-frames to make the fight less cheesable
	if data.iFrames then
		v.friendly = true
		data.hurtTimer = data.hurtTimer + 1
		
		if data.hurtTimer == 1 then SFX.play(39) end
		
		if data.hurtTimer % 8 <= 4 and data.hurtTimer > 8 then
			v.animationFrame = -50
		end
		if data.hurtTimer >= 80 then
			v.friendly = false
			data.iFrames = false
			data.hurtTimer = 0
		end
	end

	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
	end
	
	--Prevent Bowser from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	
	if Colliders.collide(plr, v) and not v.friendly and not Defines.cheat_donthurtme then
		plr:harm()
	end

	if (data.state == STATE_RAM or data.state == STATE_SPINOUT) and v.ai1 ~= 0 and v.ai1 ~= 3 then
		for k, n in  ipairs(Colliders.getColliding{a = v, b = NPC.HITTABLE, btype = Colliders.NPC, filter = npcFilter}) do
			if n.id ~= v.id then
				if n:mem(0x156,FIELD_WORD) <= 0 then
					n:harm()
					Animation.spawn(75,n.x,n.y)
				end
			end
		end
	end

		--Part of code by Marioman2007
	local oldHeight = v.height
	local oldWidth = v.width
	if data.useShell == false then
		if oldHeight ~= config.height then v.height = config.height end
		if oldWidth ~= config.width then v.width = config.width end
	elseif data.useShell == true then
		if oldHeight ~= config.shellSize.height then v.height = config.shellSize.height end
		if oldWidth ~= config.shellSize.width then v.width = config.shellSize.width end
	end
	v.x = v.x + oldWidth / 2 - v.width / 2
	v.y = v.y + oldHeight - v.height
	
		--If the player is ground pounding, do all this
		if (player.character == CHARACTER_WARIO and player.keys.altJump and player.powerup > 1) then
			player.data.isGroundPounding = true
		end
		
		if player:isGroundTouching() then player.data.isGroundPounding = nil end
		
	--Handle interactions with ground pounds
	for _, npc in ipairs(NPC.getIntersecting(player.x, player.y + player.height, player.x + player.width, player.y + player.height + 30)) do
		if player.speedY > 0 and npc.id == v.id and player.data.isGroundPounding then
			if data.useShell == false then
				npc:harm(HARM_TYPE_JUMP)
			else
				player:harm()
			end
		end
	end
end

function sampleNPC.onDrawNPC(v)
	local data = v.data
	local settings = v.data._settings
	if data.state == nil then npcutils.hideNPC(v) return end
	if data.heldNPC ~= 0 and data.displayHeldNPC then
		local heldNPC = data.heldNPC
		local config = NPC.config[heldNPC]
		local gfxwidth = config.gfxwidth
		local gfxheight = config.gfxheight

		if gfxwidth == 0 then gfxwidth = config.width end
		if gfxheight == 0 then gfxheight = config.height end
		if v.direction == 1 then
			if NPC.config[heldNPC].framestyle ~= 0 then
				data.thrownFrames = NPC.config[heldNPC].frames
			else
				data.thrownFrames = 0
			end

		else
			data.thrownFrames = 0
		end
		Graphics.drawImageToSceneWP(
			Graphics.sprites.npc[heldNPC].img,
			v.x + v.width / 2 + NPC.config[v.id].holdOffset.x[v.direction] - config.width / 2,
			v.y + v.height / 2 + NPC.config[v.id].holdOffset.y - config.height / 2,
			0, 
			gfxheight * data.thrownFrames, 
			gfxwidth,
			gfxheight,
			1,
			-44
		)
	end
end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	local config = NPC.config[v.id]
	if v.id ~= npcID then return end

		if reason ~= HARM_TYPE_LAVA and reason ~= HARM_TYPE_OFFSCREEN then
			if reason == HARM_TYPE_JUMP or killReason == HARM_TYPE_SPINJUMP or killReason == HARM_TYPE_FROMBELOW then
				if config.dontGetJumpedOn == false then
					if reason == HARM_TYPE_JUMP and data.useShell == true  then
						if culprit and culprit.__type == "Player" then
							if not culprit:mem(0x50,FIELD_BOOL) then
								culprit:harm()
							else
								SFX.play(2)
							end
						end
					else
						SFX.play(2)
						data.iFrames = true
						data.health = data.health - 1
					end
				else
					if reason == HARM_TYPE_JUMP and data.useShell == true  then
						if culprit and culprit.__type == "Player" then
							if not culprit:mem(0x50,FIELD_BOOL) then
								culprit:harm()
							else
								SFX.play(2)
							end
						end
					else
						if reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP then
							if culprit and culprit.__type == "Player" then culprit:harm() end
						else
							SFX.play(2)
							data.iFrames = true
							data.health = data.health - 1
						end
					end
				end
			elseif reason == HARM_TYPE_SWORD then
				if data.useShell == false then
					if v:mem(0x156, FIELD_WORD) <= 0 then
						data.health = data.health - 1
						data.iFrames = true
						SFX.play(89)
						v:mem(0x156, FIELD_WORD,20)
					end
				else
					SFX.play("zeldaenemyshield.wav")
					local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
					plr.speedX = ((plr.x-v.x)/math.abs(plr.x-v.x))*4
				end
				if Colliders.downSlash(player,v) then
					player.speedY = -6
				end
			elseif reason == HARM_TYPE_NPC then
				if data.useShell == false then
					if culprit then
						if type(culprit) == "NPC" then
							if culprit.id == 13  then
								SFX.play(9)
								data.health = data.health - 0.25
							else
								data.health = data.health - 1
								data.iFrames = true
							end
						else
							data.health = data.health - 1
							data.iFrames = true
						end
					else
						data.health = data.health - 1
						data.iFrames = true
					end
				else
					if v:mem(0x156, FIELD_WORD) <= 0 then
						SFX.play("zeldaenemyshield.wav")
						if culprit then
							Animation.spawn(75, culprit.x, culprit.y)
							culprit.speedX = -(culprit.speedX + 2)
							culprit.speedY = -8
							if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
								culprit:kill(HARM_TYPE_NPC)
							end
						end
						v:mem(0x156, FIELD_WORD,3)
					end
				end
			elseif reason == HARM_TYPE_LAVA and v ~= nil then
				v:kill(HARM_TYPE_OFFSCREEN)
			elseif v:mem(0x12, FIELD_WORD) == 2 then
				v:kill(HARM_TYPE_OFFSCREEN)
			else
				if data.useShell == false then
					data.iFrames = true
					data.health = data.health - 1
				else
					if v:mem(0x156, FIELD_WORD) <= 0 then
						SFX.play("zeldaenemyshield.wav")
						if culprit then
							Animation.spawn(75, culprit.x, culprit.y)
							culprit.speedX = -(culprit.speedX + 2)
							culprit.speedY = -8
							if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
								culprit:kill(HARM_TYPE_NPC)
							end
						end
						v:mem(0x156, FIELD_WORD,3)
					end
				end
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
                SFX.play(44)
                v:kill(HARM_TYPE_NPC)
			elseif data.health > 0 then
				v:mem(0x156,FIELD_WORD,60)
			end
		else
            if reason == HARM_TYPE_LAVA then
                SFX.play(44)
			    v:kill(HARM_TYPE_LAVA)
            elseif reason == HARM_TYPE_OFFSCREEN then
                SFX.play(44)
                v:kill(9)
            end
		end
	eventObj.cancelled = true
end

--Gotta return the library table!
return sampleNPC