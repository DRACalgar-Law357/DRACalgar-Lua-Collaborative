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

    --HP stuff
    hp = 5,
    beInPinch = true,
    pinchHP = 2,
    --This decreases the hp when hit by strong attacks
	hpDecStrong = 1,
	--This decreases the hp when hit by a fireball
	hpDecWeak = 1,
    --NPC ID stuff
    frosteeID = 751, --Chases the player
    fireEnemyID = 758, --Hops at the player
    ballID = 752, --An object that can be carried by the player and depending on its temperature state, it can be used to attack Frank depending on his temperature state
    pillarID = 754, --Sliding pillars that'll disappear for a brief time
    debrisID = 755, --Spawns at specified BGOs and falls down. Can be killed from strong attacks except jumps.
    flameID = 756,
    crystalID = 757,
    fireballID = 706,
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
        [1] = {index = 1, state = STATE.WALK, availableHPMin = 0, availableHPMax = 5, conditionSet = 0},
        [2] = {index = 2, state = STATE.QUAKE, availableHPMin = 0, availableHPMax = 5, conditionSet = 0},
        [3] = {index = 3, state = STATE.SHOOT, availableHPMin = 0, availableHPMax = 5, conditionSet = 0},
        [4] = {index = 4, state = STATE.PILLAR, availableHPMin = 0, availableHPMax = 5, conditionSet = 0},
        [5] = {index = 5, state = STATE.HOTATTACK, availableHPMin = 0, availableHPMax = 2, conditionSet = 1},
        [6] = {index = 6, state = STATE.COLDATTACK, availableHPMin = 0, availableHPMax = 2, conditionSet = 2},
        [7] = {index = 7, state = STATE.GROUNDPOUND, availableHPMin = 0, availableHPMax = 2, conditionSet = 0},
    },

    beforeWalkDelay = 14,
    walkSpeed = 3.5,
    beforeJumpDelay = 10,
    jumpHeight = -8.5,
    debrisFallDelay = 12,
    debrisDelay = 240,
    idleDelay = 50,
    shootDelay = 200,
    beforeShootFireballDelay = 8,
    shootFireball = {
        delay = 30,
        cord = {
            [-1] = {x = -24, y = 0},
            [1] = {x = 24, y = 0},
        },
        speedX = {min = 4.5, max = 4.5},
        speedY = {min = -0.25, max = 0.25},
        amountOnly = 6,
    },
    groundPound = {
        amount = 3,
        jumpHeight = -9,
        speedXRestrictRate = 5,
        speedXMax = 18,
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
        flameDelay = 16,
    },
    coldExclusiveAttack = {
        hopAmount = 2,
        hopHeight = -3.5,
        hopDelay = 8,
        beforeShootDelay = 16,
        afterShootDelay = 50,
        shootSpeedX = {min = 2, max = 5},
        shootSpeedY = {min = -6, max = 0.5},
        shootAmount = 2,
    },
    pillar = {
        amount = {nonpinch = 1, pinch = 2},
        speedX = 4.5,
        delay = 40,
    },
    hurtDelay = 90,
    selfdestructDelay = 48,
    meltDelay = 48,
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
	if data.state == STATE.IDLE then
		v.animationFrame = math.floor(data.timer / 8) % 2
		v.speedX =  0
		if data.timer >= config.idleDelay then
			data.timer = 0
			data.state = STATE.GROUNDPOUND
            data.shootConsecutive = 0
            data.jumpConsecutive = 0
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
                v.speedX = v.speedX * 0.9
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
                end
            end
        else
            v.speedX = 0
            v.animationFrame = 8
            if data.timer >= config.groundPound.landDelay then
                if data.jumpConsecutive < config.groundPound.amount then
                    data.timer = config.groundPound.beforeAllJumpsDelay
                    v.ai1 = 0
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
        if temperaturesync.state == 1 then

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
	if Colliders.collide(plr, v) and not v.friendly and data.state ~= STATE.HURT and data.state ~= STATE.MELT and data.state ~= STATE.SELFDESTRUCT and not Defines.cheat_donthurtme then
		plr:harm()
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