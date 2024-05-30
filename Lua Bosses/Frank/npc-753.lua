--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
local temperaturesync = require("temperaturesynced")
local playerStun = require("playerstun")
--Create the library table
local frank = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

local STATE = {
    IDLE = 0,
    WALK = 1,
    SHOOT = 2,
    QUAKE = 3,
    PILLAR = 4,
    HOTATTACK = 5,
    COLDATTACK = 6,
    GROUNDPOUND = 7,
    HURT = 8,
    SELFDESTRUCT = 9,
    MELT = 10,
}

--Defines NPC config for our NPC. You can remove superfluous definitions.
local frankSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 128,
	gfxwidth = 128,
    gfxoffsety = 32,
    gfxoffsetx = 0,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 48,
	height = 64,
	--Frameloop-related
	frames = 26,
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
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
    luahandlespeed = true,
    nohurt = true,

    --HP stuff
    hp = 5,
    beInPinch = true,
    pinchHP = 2,
    --This decreases the hp when hit by strong attacks
	hpDecStrong = 1,
	--This decreases the hp when hit by a fireball
	hpDecWeak = 1,
    --NPC ID stuff
    frosteeID = 761, --Chases the player
    fireEnemyID = 762, --Hops at the player
    magmaballID = 759, --A hot object that can be carried by the player and it can be used to attack Frank if he is cold
    iceballID = 760, --A cold object that can be carried by the player and it can be used to attack Frank if he is hot
    pillarID = 754, --Sliding pillars that'll disappear for a brief time
    debrisID = 755, --Spawns at specified BGOs and falls down. Can be killed from strong attacks except jumps.
    flameID = 756,
    crystalID = 757,
    fireballID = 752,
    --Sprite stuff for hurt animation
    sweatImg = {
        texture = Graphics.loadImageResolved("npc-"..npcID.."-sweat.png"),
        cord = {
            [-1] = {x=0,y=-40},
            [1] = {x=0,y=-40},
        },
    },
    --Sprite stuff only for cold state defeat animation
    puddleImg = {
        texture = Graphics.loadImageResolved("npc-"..npcID.."-sweat.png"),
        cord = {
            [-1] = {x=0,y=32},
            [1] = {x=0,y=32},
        },
    },
    --[[ Attack Table
    index: just to make sure the decision is made properly
    state: what state it will be in
    availableHP: determine if it should use it depending on its HP
    conditionSet: 0 regardless, 1 hot state, 2 cold state
    ]]
    attackTable = {
        [1] = {state = STATE.WALK, availableHPMin = 2, availableHPMax = 5, conditionSet = 0},
        [2] = {state = STATE.SHOOT, availableHPMin = 0, availableHPMax = 5, conditionSet = 0},
        [3] = {state = STATE.PILLAR, availableHPMin = 0, availableHPMax = 5, conditionSet = 0},
        [4] = {state = STATE.HOTATTACK, availableHPMin = 0, availableHPMax = 2, conditionSet = 1},
        [5] = {state = STATE.COLDATTACK, availableHPMin = 0, availableHPMax = 2, conditionSet = 2},
        [6] = {state = STATE.GROUNDPOUND, availableHPMin = 0, availableHPMax = 2, conditionSet = 0},
    },
    necessaryQuake = true,
    quakeTick = {min = 3, max = 5,},

    beforeWalkDelay = 14,
    walkSpeed = 3.5,
    beforeJumpDelay = 10,
    jumpHeight = -10,
    debrisFallDelay = 12,
    debrisDelay = 200,
    debrisAmount = 16,
    debrisBGOID = 755,
    idleDelay = 72,
    shootDelay = 250,
    beforeShootFireballDelay = 8,
    shootFireball = {
        delay = 36,
        cord = {
            [-1] = {x = -24, y = 0},
            [1] = {x = 24, y = 0},
        },
        speedX = {min = 4.5, max = 5},
        speedY = {min = -0.125, max = 0.125},
        amountOnly = 6,
    },
    groundPound = {
        amount = 3,
        jumpHeight = -10,
        speedXRestrictRate = 30,
        speedXMax = 12,
        causeStun = false,
        stunDelay = 24,
        landDelay = 8,
        beforeJumpDelay = 8,
        beforeAllJumpsDelay = 48,
    },
    hotExclusiveAttack = {
        hopAmount = 2,
        hopHeight = -3.5,
        hopDelay = 8,
        beforeWalkDelay = 12,
        walkSpeed = 4,
        flameDelay = 32,
    },
    coldExclusiveAttack = {
        hopAmount = 2,
        hopHeight = -3.5,
        hopDelay = 8,
        beforeShootDelay = 16,
        afterShootDelay = 50,
        shootDelay = 32,
        shootSpeedX = {min = 3, max = 5},
        shootSpeedY = {min = -6, max = 1},
        amountOnly = 2,
        cord = {
            [-1] = {x = -24, y = 0},
            [1] = {x = 24, y = 0},
        },
    },
    pillar = {
        amount = {nonpinch = 1, pinch = 2},
        speedX = 5,
        delay = 40,
    },
    hurtDelay = 90,
    selfdestructDelay = 48,
    meltDelay = 48,
    freezeDelay = 48,
    freezeCooldown = 72,
    harmNPCsOnJump = true,
    temperatureStateChngeSet = 0,
    --0 change temperature state based on temperature states usually switched by temperature blocks
    --1 change temperature state based on basegame ON/OFF switch states
    --2 don't change temperature state at all but initially become cold state
    --3 don't change temperature state at all but initially become hot state



	flipSpriteWhenFacingDirection = false, --flips the sprite by a scale
	priority = -45,
	spriteoffsetx = 0,
	spriteoffsety = 0,

    iFramesDelay = 48,
}

--Applies NPC settings
npcManager.setNpcSettings(frankSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]={id=npcID, speedX=0, speedY=0},
		--[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=npcID,
		--[HARM_TYPE_TAIL]=npcID,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Register events
function frank.onInitAPI()
	npcManager.registerEvent(npcID, frank, "onTickEndNPC")
	npcManager.registerEvent(npcID, frank, "onDrawNPC")
	registerEvent(frank, "onNPCHarm")
	registerEvent(frank, "onNPCKill")
end

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
	local options = {}
    if config.necessaryQuake == true then
        data.quakeTick = data.quakeTick + 1
        if data.quakeTick >= data.quakeThreshold then
            data.quakeTick = 0
            data.quakeThreshold = RNG.randomInt(config.quakeTick.min,config.quakeTick.max)
            data.state = STATE.QUAKE
        else
            if config.attackTable and #config.attackTable > 0 then
                for i in ipairs(config.attackTable) do
                    if ((config.attackTable[i].conditionSet == 0) or (config.attackTable[i].conditionSet == 1 and data.temperatureState == 1) or (config.attackTable[i].conditionSet == 2 and data.temperatureState == 2)) and data.health > config.attackTable[i].availableHPMin and data.health <= config.attackTable[i].availableHPMax then
                        if config.attackTable[i].state ~= data.selectedAttack then table.insert(options,config.attackTable[i].state) end
                    end
                end
            end
            if #options > 0 then
                data.state = RNG.irandomEntry(options)
                data.selectedAttack = data.state
            end
        end
    else
        if config.attackTable and #config.attackTable > 0 then
            for i in ipairs(config.attackTable) do
                if ((config.attackTable[i].conditionSet == 0) or (config.attackTable[i].conditionSet == 1 and data.temperatureState == 1) or (config.attackTable[i].conditionSet == 2 and data.temperatureState == 2)) and data.health > config.attackTable[i].availableHPMin and data.health <= config.attackTable[i].availableHPMax then
                    if config.attackTable[i].state ~= data.selectedAttack then table.insert(options,config.attackTable[i].state) end
                end
            end
        end
        if #options > 0 then
            data.state = RNG.irandomEntry(options)
            data.selectedAttack = data.state
        end
    end
	data.timer = 0
end

function isNearPit(v)
	--This function either returns false, or returns the direction the npc should go to. numbers can still be used as booleans.
	local testblocks = Block.SOLID.. Block.SEMISOLID.. Block.PLAYER

	local centerbox = Colliders.Box(v.x + 8, v.y, 8, v.height + 10)
	local l = centerbox
	if v.direction == DIR_RIGHT then
		l.x = l.x + 38
	end
	
	for _,centerbox in ipairs(
	  Colliders.getColliding{
		a = testblocks,
		b = l,
		btype = Colliders.BLOCK
	  }) do
		return false
	end
	
	return true
end

function frank.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height/2)
	local config = NPC.config[v.id]
	local settings = v.data._settings
    v.collisionGroup = "FrankBoss"
    Misc.groupsCollide["FrankBoss"]["FrankProjectile"] = false
    Misc.groupsCollide["FrankBoss"]["FrankBoss"] = false
    Misc.groupsCollide["FrankProjectile"]["FrankProjectile"] = false
    Misc.groupsCollide["FrankBoss"]["FrankEnemy"] = false
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
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
		v.ai1 = 0
		v.ai2 = 0
		v.ai3 = 0
		v.ai4 = 0
		data.sprSizex = 1
		data.sprSizey = 1
		data.pinch = false
		data.img = data.img or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = frankSettings.frames * (1 + frankSettings.framestyle), texture = Graphics.sprites.npc[v.id].img}
		data.angle = 0
		data.selectedAttack = 0
        data.shootConsecutive = 0
        data.jumpConsecutive = 0
        data.temperatureState = temperaturesync.state
        data.bgoTable = BGO.get(config.debrisBGOID)
        data.freezeCooldown = 0
        data.selectedAttack = -1
        data.quakeTick = 0
        data.quakeThreshold = RNG.randomInt(config.quakeTick.min,config.quakeTick.max)
	end
    Text.print(data.selectedAttack,110,110)
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
    data.freezeCooldown = data.freezeCooldown - 1
    data.temperatureState = temperaturesync.state
	if data.state == STATE.IDLE then
		v.animationFrame = math.floor(data.timer / 8) % 2
		v.speedX =  0
		if data.timer >= config.idleDelay then
            npcutils.faceNearestPlayer(v)
			data.timer = 0
            decideAttack(v,data,config,settings)
            data.shootConsecutive = 0
            data.jumpConsecutive = 0
            v.ai1 = 0
		end
    elseif data.state == STATE.WALK then
        if data.timer < config.beforeWalkDelay then
            v.speedX = 0
            v.animationFrame = 2
        else
            v.speedX = config.walkSpeed * v.direction
            v.animationFrame = math.floor((data.timer - config.beforeWalkDelay) / 8) % 4 + 3
            if isNearPit(v) and v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockRight then
                v.direction = -v.direction
                data.timer = 0
                data.state = STATE.IDLE
            end
        end
    elseif data.state == STATE.HOTATTACK then
        if v.ai1 == 0 then
            v.speedX = 0
            if data.timer == config.hotExclusiveAttack.hopDelay-1 then
                if not v.collidesBlockBottom then
                    data.timer = 0
                else
                    v.speedY = config.hotExclusiveAttack.hopHeight
                end
            end
            if data.timer < config.hotExclusiveAttack.hopDelay then
                v.animationFrame = 8
            else
                if data.temperatureState == 2 and Colliders.collide(plr, v) and not v.friendly and not Defines.cheat_donthurtme and data.temperatureState == 2 then
                    plr:harm()
                end
                if v.speedY < 0 then
                    v.animationFrame = 9
                else
                    v.animationFrame = 10
                end
                if v.collidesBlockBottom then
                    data.timer = 0
                    data.jumpConsecutive = data.jumpConsecutive + 1
                    if data.jumpConsecutive >= config.hotExclusiveAttack.hopAmount then
                        v.ai1 = 1
                    end
                end
            end
        elseif v.ai1 == 1 then
            if data.timer < config.hotExclusiveAttack.beforeWalkDelay then
                v.speedX = 0
                v.animationFrame = 2
            else
                v.speedX = config.hotExclusiveAttack.walkSpeed * v.direction
                v.animationFrame = math.floor((data.timer - config.hotExclusiveAttack.beforeWalkDelay) / 8) % 4 + 3
                if (data.timer - config.hotExclusiveAttack.beforeWalkDelay) % config.hotExclusiveAttack.flameDelay == 0 then
                    SFX.play(16)
                    local n = NPC.spawn(config.flameID, v.x + v.width/2 - NPC.config[config.flameID].width/2, v.y + v.height - NPC.config[config.flameID].height, v.section, false, false)
                end
                if isNearPit(v) and v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockRight then
                    v.direction = -v.direction
                    data.timer = 0
                    data.state = STATE.IDLE
                end
            end
        else
            v.ai1 = 0
        end
    elseif data.state == STATE.COLDATTACK then
        if v.ai1 == 0 then
            v.speedX = 0
            if data.timer == config.coldExclusiveAttack.hopDelay-1 then
                if not v.collidesBlockBottom then
                    data.timer = 0
                else
                    v.speedY = config.coldExclusiveAttack.hopHeight
                end
            end
            if data.timer < config.coldExclusiveAttack.hopDelay then
                v.animationFrame = 8
            else
                if data.temperatureState == 2 and Colliders.collide(plr, v) and not v.friendly and not Defines.cheat_donthurtme and data.temperatureState == 2 then
                    plr:harm()
                end
                if v.speedY < 0 then
                    v.animationFrame = 9
                else
                    v.animationFrame = 10
                end
                if v.collidesBlockBottom then
                    data.timer = 0
                    data.jumpConsecutive = data.jumpConsecutive + 1
                    if data.jumpConsecutive >= config.coldExclusiveAttack.hopAmount then
                        v.ai1 = 1
                    end
                end
            end
        elseif v.ai1 == 1 then
            v.speedX = 0
            if data.timer < config.coldExclusiveAttack.beforeShootDelay then
                v.animationFrame = 2
            else
                v.animationFrame = 7
            end
            if data.timer % config.coldExclusiveAttack.shootDelay == 1 + config.coldExclusiveAttack.beforeShootDelay and data.shootConsecutive < config.coldExclusiveAttack.amountOnly then
                local n = NPC.spawn(config.crystalID,v.x+v.width/2+config.coldExclusiveAttack.cord[v.direction].x,v.y+v.height/2+config.coldExclusiveAttack.cord[v.direction].y,v.section,false,true)
                n.speedX = RNG.random(config.coldExclusiveAttack.shootSpeedX.min,config.coldExclusiveAttack.shootSpeedX.max) * v.direction
                n.speedY = RNG.random(config.coldExclusiveAttack.shootSpeedY.min,config.coldExclusiveAttack.shootSpeedY.max)
                SFX.play(18)
                data.shootConsecutive = data.shootConsecutive + 1
            end
            if data.timer >= config.coldExclusiveAttack.afterShootDelay + config.coldExclusiveAttack.beforeShootDelay then
                data.timer = 0
                data.state = STATE.IDLE
            end
        else
            v.ai1 = 0
        end
    elseif data.state == STATE.PILLAR then
        if data.timer < 8 then
            v.animationFrame = 2
        else
            v.animationFrame = math.floor((data.timer - 8) / 4) % 4 + 3
        end
        v.speedX = 0
        if data.timer >= 8 + config.pillar.delay then
            data.shootConsecutive = data.shootConsecutive + 1
            SFX.play(Misc.resolveSoundFile("magikoopa-magic"))
            local n = NPC.spawn(config.pillarID,v.x+v.width/2-NPC.config[config.pillarID].width/2,v.y+v.height-NPC.config[config.pillarID].height,v.section,false,false)
            n.ai1 = data.temperatureState - 1
            n.direction = v.direction
            n.data.speedX = config.pillar.speedX
            n.speedX = n.data.speedX * n.direction
            if (data.shootConsecutive >= config.pillar.amount.nonpinch and data.health > config.pinchHP) or (data.shootConsecutive >= config.pillar.amount.pinch and data.health <= config.pinchHP) then
                data.timer = 0
                data.state = STATE.IDLE
            else
                data.timer = 0
            end
        end
    elseif data.state == STATE.QUAKE then
        if v.ai1 == 0 then
            v.speedX = 0
            if data.timer == config.beforeJumpDelay-1 then
                if not v.collidesBlockBottom then
                    data.timer = 0
                else
                    v.speedY = config.jumpHeight
                end
            end
            if data.timer < config.beforeJumpDelay then
                v.animationFrame = 8
            else
                if data.temperatureState == 2 and Colliders.collide(plr, v) and not v.friendly and not Defines.cheat_donthurtme and data.temperatureState == 2 then
                    plr:harm()
                end
                if v.speedY < 0 then
                    v.animationFrame = 9
                else
                    v.animationFrame = 10
                end
                if v.collidesBlockBottom then
                    data.timer = 0
                    v.ai1 = 1
                    SFX.play(37)
                    Routine.setFrameTimer(config.debrisFallDelay, (function() 
                        if #data.bgoTable > 0 then
                            local relocate = RNG.irandomEntry(data.bgoTable)
                            local spawnNPC = config.debrisID
                            local n = NPC.spawn(spawnNPC,relocate.x+16-NPC.config[spawnNPC].width/2,relocate.y-NPC.config[spawnNPC].height/2,v.section,false,false)
        
                            n.forcedState = 4
                            n.forcedCounter1 = n.spawnY + n.height/2
                            n.forcedCounter2 = 3
                        end
                    end), config.debrisAmount, false)
                    if config.groundPound.causeStun == true then
                        for k, p in ipairs(Player.get()) do --Section copypasted from the Sledge Bros. code
                            if p:isGroundTouching() and not playerStun.isStunned(k) and v:mem(0x146, FIELD_WORD) == player.section then
                                playerStun.stunPlayer(k, config.groundPound.stunDelay )
                            end
                        end
                    end
                    if config.harmNPCsOnJump then
                        for _,n in ipairs(NPC.getIntersecting(v.x - 5, v.y - 5, v.x + v.width + 5, v.y + v.height + 5)) do
                            if Colliders.collide(n,v) and not NPC.config[n.id].hp and not NPC.config[n.id].isCoin and not NPC.config[n.id].isInteractable and NPC.HITTABLE_MAP[n.id] and n.idx ~= v.idx then
                                n:harm(HARM_TYPE_NPC)
                            end
                        end
                    end
                end
            end
        elseif v.ai1 == 1 then
            v.animationFrame = math.floor(data.timer / 8) % 2
            if data.timer >= config.debrisDelay then
                v.ai1 = 0
                data.timer = 0
                data.state = STATE.WALK
                --Spawn two NPCs based on his temperature state
                local orbNPC = 0
                local enemyNPC = 0
                if data.temperatureState == 1 then
                    orbNPC = config.magmaballID
                    enemyNPC = config.fireEnemyID
                elseif data.temperatureState == 2 then
                    orbNPC = config.iceballID
                    enemyNPC = config.frosteeID
                end
                if orbNPC > 0 then local orb = NPC.spawn(orbNPC,v.x+v.width/2,v.y+v.height-NPC.config[orbNPC].height,v.section,false,true) end
                if enemyNPC > 0 then local enemy = NPC.spawn(enemyNPC,v.x+v.width/2,v.y+v.height-NPC.config[enemyNPC].height,v.section,false,true) end
            end
        else
            v.ai1 = 0
            data.timer = 0
        end
    elseif data.state == STATE.SHOOT then
        v.speedX = 0
        if data.timer < config.beforeShootFireballDelay then
            v.animationFrame = 2
        else
            v.animationFrame = 7
        end
        if data.timer % config.shootFireball.delay == 1 + config.beforeShootFireballDelay and data.shootConsecutive < config.shootFireball.amountOnly then
            local n = NPC.spawn(config.fireballID,v.x+v.width/2+config.shootFireball.cord[v.direction].x,v.y+v.height/2+config.shootFireball.cord[v.direction].y,v.section,false,true)
            n.speedX = RNG.random(config.shootFireball.speedX.min,config.shootFireball.speedX.max) * v.direction
            n.speedY = RNG.random(config.shootFireball.speedY.min,config.shootFireball.speedY.max)
            SFX.play(18)
            data.shootConsecutive = data.shootConsecutive + 1
        end
        if data.timer >= config.shootDelay + config.beforeShootFireballDelay then
            data.timer = 0
            data.state = STATE.IDLE
        end
    elseif data.state == STATE.GROUNDPOUND then
        if v.ai1 == 0 then
            if data.timer < config.groundPound.beforeAllJumpsDelay then
                v.speedX = 0
                v.animationFrame = 8
            elseif data.timer < config.groundPound.beforeJumpDelay + config.groundPound.beforeAllJumpsDelay then
                v.speedX = 0
                v.animationFrame = 8
            else
                v.speedX = v.speedX * 0.97
                if data.timer == config.groundPound.beforeJumpDelay + config.groundPound.beforeAllJumpsDelay then
                    local bombxspeed = vector.v2(Player.getNearest(v.x + v.width/2, v.y + v.height).x + 0.5 * Player.getNearest(v.x + v.width/2, v.y + v.height).width - (v.x + 0.5 * v.width))
                    v.speedX = math.abs(bombxspeed.x / config.groundPound.speedXRestrictRate) * v.direction
                    if v.speedX > config.groundPound.speedXMax then v.speedX = config.groundPound.speedXMax end
                    if v.speedX < -config.groundPound.speedXMax then v.speedX = -config.groundPound.speedXMax end
                    v.speedY = config.groundPound.jumpHeight
                    SFX.play(1)
                end
                if v.speedY < 0 then
                    v.animationFrame = 9
                else
                    v.animationFrame = 10
                end
                if data.temperatureState == 2 and Colliders.collide(plr, v) and not v.friendly and not Defines.cheat_donthurtme and data.temperatureState == 2 then
                    plr:harm()
                end
                if data.timer > config.groundPound.beforeJumpDelay + config.groundPound.beforeAllJumpsDelay and v.collidesBlockBottom then
                    SFX.play(37)
                    defines.earthquake = 3
                    v.ai1 = 1
                    data.timer = 0
                    data.jumpConsecutive = data.jumpConsecutive + 1
                    if config.groundPound.causeStun == true then
                        for k, p in ipairs(Player.get()) do --Section copypasted from the Sledge Bros. code
                            if p:isGroundTouching() and not playerStun.isStunned(k) and v:mem(0x146, FIELD_WORD) == player.section then
                                playerStun.stunPlayer(k, config.groundPound.stunDelay )
                            end
                        end
                    end
                    if config.harmNPCsOnJump then
                        for _,n in ipairs(NPC.getIntersecting(v.x - 5, v.y - 5, v.x + v.width + 5, v.y + v.height + 5)) do
                            if Colliders.collide(n,v) and not NPC.config[n.id].hp and not NPC.config[n.id].isCoin and not NPC.config[n.id].isInteractable and NPC.HITTABLE_MAP[n.id] and n.idx ~= v.idx then
                                n:harm(HARM_TYPE_NPC)
                            end
                        end
                    end
                end
            end
        else
            v.speedX = 0
            v.animationFrame = 8
            if data.timer >= config.groundPound.landDelay then
                if data.jumpConsecutive < config.groundPound.amount then
                    data.timer = config.groundPound.beforeAllJumpsDelay
                    v.ai1 = 0
                    npcutils.faceNearestPlayer(v)
                else
                    v.ai1 = 0
                    data.timer = 0
                    data.state = STATE.WALK
                    v.direction = RNG.irandomEntry{-1,1}
                end
            end
        end
    elseif data.state == STATE.HURT then
        v.animationFrame = 11
        v.speedX = 0
        if data.timer >= config.hurtDelay then
            data.timer = 0
            data.state = STATE.IDLE
        end
    elseif data.state == STATE.SELFDESTRUCT then
        v.speedX = 0
        v.animationFrame = 12
        if data.timer >= config.selfdestructDelay then
			Misc.doBombExplosion(v.x + v.width/2, v.y + v.height/2, 3)
            v:kill(9)
        end
	end
	--Give Frank some i-frames to make the fight less cheesable
	--iFrames System made by MegaDood & DRACalgar Law
	if data.iFrames then
		v.friendly = true
		data.hurtTimer = data.hurtTimer + 1
		
		if data.hurtTimer == 1 and data.health > 0 then
		    SFXPlay(39)
			data.state = STATE.HURT
			data.timer = 0
		end
		if data.hurtTimer >= data.iFramesDelay then
			v.friendly = false
			data.iFrames = false
			data.hurtTimer = 0
		end
	end

    if data.state ~= STATE.SELFDESTRUCT and data.state ~= STATE.MELT then
        if data.temperatureState == 1 then

        else
            v.animationFrame = v.animationFrame + 13
        end
    else
        if data.state == STATE.MELT then

        elseif data.state == STATE.SELFDESTRUCT then
            if data.timer % 12 < 6 then
                v.animationFrame = v.animationFrame + 13 
            end
        end
    end
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = frankSettings.frames
		});
	end
	if config.beInPinch == true and not data.pinch and data.health <= config.pinchHP then
		data.pinch = true
	end
	
	--Prevent Frank from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	if Colliders.collide(plr, v) and not v.friendly and data.state ~= STATE.HURT and data.state ~= STATE.MELT and data.state ~= STATE.SELFDESTRUCT and not Defines.cheat_donthurtme and data.temperatureState == 1 then
		plr:harm()
    end
    if Colliders.collide(plr, v) and not v.friendly and data.state ~= STATE.HURT and data.state ~= STATE.MELT and data.state ~= STATE.SELFDESTRUCT and not Defines.cheat_donthurtme and data.temperatureState == 2 and data.freezeCooldown <= 0 then
        for k, p in ipairs(Player.get()) do --Section copypasted from the Sledge Bros. code
            if not playerStun.isStunned(k) and v:mem(0x146, FIELD_WORD) == plr.section then
                playerStun.stunPlayer(k, config.freezeDelay)
                SFX.play(59)
                data.freezeCooldown = config.freezeCooldown
            end
        end
	end
end
function frank.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	local config = NPC.config[v.id]
	if v.id ~= npcID then return end

			if data.iFrames == false and data.state ~= STATE.MELT and data.state ~= STATE.SELFDESTRUCT and data.state ~= STATE.HURT then
				local hpd = config.hpDecStrong
				if reason == HARM_TYPE_LAVA then
					v:kill(HARM_TYPE_LAVA)
				else
					hpd = 0
					if reason == HARM_TYPE_LAVA and v ~= nil then
						v:kill(HARM_TYPE_OFFSCREEN)
					elseif v:mem(0x12, FIELD_WORD) == 2 then
						v:kill(HARM_TYPE_OFFSCREEN)
					else
                        if culprit and ((temperaturesync.state == 1 and NPC.config[culprit.id].iscold) or (temperaturesync.state == 2 and NPC.config[culprit.id].ishot)) then
                            data.iFrames = true
                            hpd = config.hpDecStrong

                        end
					end
					if data.iFrames then
						data.hurting = true
                        data.health = data.health - hpd
                        data.state = STATE.HURT
                        data.timer = 0
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
				data.state = STATE.SELFDESTRUCT
				data.timer = 0
			else
				v:mem(0x156,FIELD_WORD,60)
			end
	eventObj.cancelled = true
end
local lowPriorityStates = table.map{1,3,4}
function frank.onDrawNPC(v)
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
		data.img.x, data.img.y = v.x + 0.5 * v.width + config.spriteoffsetx, v.y + 0.5 * v.height + config.spriteoffsety
		if config.flipSpriteWhenFacingDirection then
			data.img.transform.scale = vector(data.sprSizex * -v.direction, data.sprSizey)
		else
			data.img.transform.scale = vector(data.sprSizex, data.sprSizey)
		end
		data.img.rotation = data.angle

		local p = config.priority

		-- Drawing --
		data.img:draw{frame = v.animationFrame + 1, sceneCoords = true, priority = p, color = Color.white..opacity}
		npcutils.hideNPC(v)
	end
end

--Gotta return the library table!
return frank