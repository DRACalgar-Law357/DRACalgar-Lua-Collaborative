--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
local sync = require("blocks/ai/synced")

--Create the library table
local sampleNPC = {}
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
local sampleNPCSettings = {
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
    --NPC ID stuff
    frosteeID = 751, --Chases the player
    fireEnemyID = 758, --Hops at the player
    ballID = 752, --An object that can be carried by the player and depending on its temperature state, it can be used to attack Frank depending on his temperature state
    pillarID = 754, --Sliding pillars that'll disappear for a brief time
    debrisID = 755 --Spawns at specified BGOs and falls down. Can be killed from strong attacks except jumps.
    flameID = 756,
    crystalID = 757,
    fireballID = 511,
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
    shootFireball = {
        delay = 30,
        cord = {
            [-1] = {x = -24, y = 0},
            [1] = {x = 24, y = 0},
        },
        speedX = {min = 4.5, max = 4.5},
        speedY = {min = -2.2, max = 2.2},
        amountOnly = 6,
    },
    groundPound = {
        amount = 3,
        jumpHeight = -9,
        speedXRestrictRate = 40,
        speedXMax = 10,
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





}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]={id=npcID, speedX=0, speedY=0},
		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
	end
	
	--React to switch block states
	if sync.state == false then
		v.animationFrame = 0 + ((1 + v.direction) * 1.5)
		v.friendly = false
		local tbl = Block.SOLID
		local list = Colliders.getColliding{
		a = v,
		b = tbl,
		btype = Colliders.BLOCK,
		filter = function(other)
			if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
				return false
			end
			v:kill(HARM_TYPE_OFFSCREEN)
			Explosion.spawn(v.x + 0.5 * v.width, v.y + 0.5 * v.height, 3)
			return true
		end
		}
	else
		v.animationFrame = math.floor(lunatime.tick() / 8) % 2 + 1 + ((1 + v.direction) * 1.5)
		v.friendly = true
	end
end

--Gotta return the library table!
return sampleNPC