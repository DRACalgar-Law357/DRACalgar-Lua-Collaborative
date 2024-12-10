--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local bucketHead = require("bucketHead")
local wario = require("warioLand1NPC")

--Create the library table
local bucketHeadNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

local STATE_WALKING = 0
local STATE_IDLE = 1
local STATE_FALL = 2

--Defines NPC config for our NPC. You can remove superfluous definitions.
local bucketHeadNPCSettings = {
	id = npcID,
	gfxheight = 50,
	gfxwidth = 50,
	width = 38,
	height = 44,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 6,
	framestyle = 1,
	framespeed = 8,
	speed = 1,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = true,
	noyoshi= false,
	nowaterphysics = false,
	cliffturn = true,
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,

	lightradius = 100,
	lightbrightness = 1,
	lightcolor = Color.white,

	shootRadius = 192, --The radius that detects how close a player is to spit at them. Only activates when useRadius is true.
	spawnid = npcID + 2, --The projectile the NPC will spit.
	transformID = npcID + 1, --The NPC to transform into when either getting stunned or transfortming back.
	bigEnemy = false, --If big, you move slower when holding it and it dies when it hits a wall when thrown.
	spitCharge = 6, --How long does the NPC charge before spitting?
	spitTime = 7, --When does the NPC spit?
	spitShine = 17, --When does the NPC spit again?
	exitInRange = 55, --When the does the NPC resume walking?
	projectileSpeedX = 1, --How fast is the projectile?
	projectileSpeedY = 1, --How high is the projectile thrown?
	spawnOffsetY = 6, --The Y-Offset for the spawned NPC. Useful for larger NPCs.
	spitSFX = 38, --Spit SFX. You can also use custom sound effects!
}

npcManager.setNpcSettings(bucketHeadNPCSettings)

wario.register(npcID)

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
		[HARM_TYPE_JUMP]=npcID,
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

--Custom local definitions below
bucketHead.register(npcID)

--Register events
function bucketHeadNPC.onInitAPI()
	npcManager.registerEvent(npcID, bucketHeadNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, bucketHeadNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, bucketHeadNPC, "onDrawNPC")
	--registerEvent(bucketHeadNPC, "onNPCKill")
end

--Should the projectile turn when colliding with other npcs?
return bucketHeadNPC