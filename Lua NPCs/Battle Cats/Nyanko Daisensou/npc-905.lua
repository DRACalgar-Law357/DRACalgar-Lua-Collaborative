--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local utils = require("npcs/npcutils")
local BattleCats = require("BattleCatsBodyguards")
local effectconfig = require("game/effectconfig")
--Create the library table
local basicCat = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local basicCatSettings = {
	id = npcID,
	--Sprite size
	gfxwidth = 80,
	gfxheight = 80,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 60,
	height = 54,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 23,
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
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	nohurt = true,

	--If Dont Move is set to true, they'll immediately go to chasing state to attack. It's recommended to not use melee attacks.

	--Detect Range (Idling)
	provokeRangeX = 32*22,
	provokeRangeY = 32*14,

	--Detect Range (Attacking)
	attackRangeX = 32*16,
	attackRangeY = 32*12,

	--Melee Range (For Punch and Rush)
	meleeRangeX = 32*8,
	meleeRangeY = 32*8,
	
	--NPC ID Attack Config
	smokeGrenade = 348,
	fragGrenade = 617,
	lowShot = 133,
	highShot = 40,

	--Idle Config
	walkSpeed = 1.5,

	--Provoked State Config
	provokeDelay = 48,
	cooldownTimer = 160,

	--Approach Config
	chaseSpeed = 2,
	jumpHeight = 8,

	--Rush Config
	rushSpeed = 2.5,
	rushDelay = 48,
	rushDuration = 64,
	rushLag = 48,

	--Smoke Grenade Config
	smokeDelay = 40,
	smokeLag = 80,
	smokeSpeedY = 9,
	smokeSpeedXRestrict = 85,

	--Fragmentation Grenade Config
	fragDelay = 80,
	fragLag = 64,
	fragSpeedY = 9,
	fragSpeedXRestrict = 85,

	--Spawn Config
	throwXL = 14,
	throwXR = 14,
	throwY = -59,
	lowShootY = 0,
	highShootY = 0,
	lowShootXL = -24,
	lowShootXR = 10,
	highShootXL = -24,
	highShootXR = 10,

	--Shot Config
	--Shoot Set [0 = Both High And Low, 1 = High, 2 = Low]
	lowShootDuration = 3,
	lowShootBefore = 40,
	lowShootDelayBetweenShots = 10,
	lowShootLag = 70,
	lowShootSpeedXMin = 4,
	lowShootSpeedXMax = 4,
	lowShootSpeedYMin = 0,
	lowShootSpeedYMax = 0,
	lowShotSpawnConsecutive = 1,

	highShootDuration = 3,
	highShootBefore = 40,
	highShootDelayBetweenShots = 10,
	highShootLag = 70,
	highShootSpeedXMin = 4,
	highShootSpeedXMax = 4,
	highShootSpeedYMin = 0,
	highShootSpeedYMax = 0,
	highShotSpawnConsecutive = 1,

	--Punch Config
	--Punch Set [0 = Both Grounded and Midair, 1 = Grounded, 2 = Midair]
	punchXSpeedGrounded = 7,
	punchFriction = 0.15,
	punchYSpeed = 8.5,
	punchDelay = 48,
	punchLag = 64,
	--A config to start jumping while punching
	punchXSpeedMidair = 5.5,
	punchMidairDelay = 24,

	--Backup Config
	backupDelay = 128,
	backupLag = 64,

	--Patch Up Config
	patchDelay = 80,
	patchRestore = 1/3,
	patchActivePortion = 1/2,

	--I-Frames Config
	harmDelay = 48,
	
	--SFX ID Config (if you are not gonna use the specified sounds then just put a -- on them)
	noticeSoundID = Misc.resolveSoundFile("chuck-whistle"),
	rushSoundID = 86,
	fragGrenadeSoundID = 25,
	smokeGrenadeSoundID = 25,
	lowShotSoundID = Misc.resolveSoundFile("BC SFX/BC-baseattack.ogg"),
	highShotSoundID = Misc.resolveSoundFile("BC SFX/BC-baseattack.ogg"),
	telegraphSoundID = 14,
	punchSoundID = Misc.resolveSoundFile("BC SFX/BC-attack2.ogg"),
	backupSoundID = Misc.resolveSoundFile("BC SFX/BC-meow.ogg"),
	spawnSoundID = Misc.resolveSoundFile("BC SFX/BC-bossshockwave.ogg"),
	stunSoundID = Misc.resolveSoundFile("BC SFX/BC-attack1.ogg"),
	hurtSoundID = 39,
	killSoundID = Misc.resolveSoundFile("BC SFX/BC-death.ogg"),
	
	--Frames Config
	walkFrames = 4,
	holdFrames = 1,
	throwFrames = 1,
	--throwFrames will also be used for Punching
	highShotFrames = 1,
	lowShotFrames = 1,
	backupFrames = 2,
	patchFrames = 1,

	frameStates = {
		--Idle
		[0] = {
			frames = {0,1,2,3,4,5,6},
			framespeed = 6,
			loopFrames = true,
		},
		--Walk
		[1] = {
			frames = {7,8,9,10,11,12,13},
			framespeed = 6,
			loopFrames = true,
		},
		--Jump
		[2] = {
			frames = {9,4,6},
			framespeed = 6,
			loopFrames = false,
		},
		--Pick Up Frag
		[3] = {
			frames = {21,20,19,18,19,20,21},
			framespeed = 4,
			loopFrames = false,
		},
		--Throw Frag
		[4] = {
			frames = {16},
			framespeed = 4,
			loopFrames = false,
		},
		--Pick Up Smoke
		[5] = {
			frames = {21,20,19,18,19,20,21},
			framespeed = 4,
			loopFrames = false,
		},
		--Throw Smoke
		[6] = {
			frames = {16},
			framespeed = 4,
			loopFrames = false,
		},
		--High Shot
		[7] = {
			frames = {14,15,16},
			framespeed = 6,
			loopFrames = false,
		},
		--Low Shot
		[8] = {
			frames = {21,20,19,18},
			framespeed = 4,
			loopFrames = false,
		},
		--Calling Backup
		[9] = {
			frames = {14,15,16,15},
			framespeed = 4,
			loopFrames = true,
		},
		--Healing with patch
		[10] = {
			frames = {21,20,19,18},
			framespeed = 4,
			loopFrames = false,
		},
		--Stunned
		[11] = {
			frames = {22},
			framespeed = 6,
			loopFrames = false,
		},
		--Ready Punch
		[12] = {
			frames = {0,1,2,3,4,5,6},
			framespeed = 4,
			loopFrames = true,
		},
		--Punch on ground
		[13] = {
			frames = {14,15,16,17},
			framespeed = 6,
			loopFrames = false,
		},
		--Punch midair
		[14] = {
			frames = {14,15,16,17},
			framespeed = 6,
			loopFrames = false,
		},
		--Punch Lag
		[15] = {
			frames = {18,19,20,21,0},
			framespeed = 6,
			loopFrames = false,
		},
		--Rush
		[16] = {
			frames = {7,8,9,10,11,12,13},
			framespeed = 4,
			loopFrames = true,
		},
		--Backup Lag
		[17] = {
			frames = {18,19,20,21,0},
			framespeed = 6,
			loopFrames = false,
		},
		--Rush Lag
		[18] = {
			frames = {18,19,20,21,0},
			framespeed = 6,
			loopFrames = false,
		},

	},
	
	--Stat Configs
	hpHardHit = 1,
	hpSoftHit = 1/2

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(basicCatSettings)

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
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=905,
		[HARM_TYPE_FROMBELOW]=905,
		[HARM_TYPE_NPC]=905,
		[HARM_TYPE_PROJECTILE_USED]=905,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=905,
		[HARM_TYPE_TAIL]=905,
		--[HARM_TYPE_SPINJUMP]=905,
		--[HARM_TYPE_OFFSCREEN]=905,
		[HARM_TYPE_SWORD]=905,
	}
);

function effectconfig.onTick.TICK_BCDEATH(v)
	v.effectDirection = v.effectDirection or RNG.irandomEntry{-1,1}
	local horizontalDistance = 32*0.5*v.effectDirection
	local horizontalTime = 32 / math.pi / 2

	v.speedX = math.cos(lunatime.tick() / horizontalTime)*horizontalDistance / horizontalTime
	v.speedY = -4
end

BattleCats.register(npcID)

--Gotta return the library table!
return basicCat