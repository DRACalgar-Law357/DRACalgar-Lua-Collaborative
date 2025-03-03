--[[
	
	CARRYABLE TORPEDO
	Custom SMBX2 NPC by KING DRACalgar Law
	Original GFX by Dr. Tapeworm

	-------------------------------
	BEHAVIOR
	- A carryable block that allows the player to swim through the water (and maybe the air) seamlessly (being able to stay afloat and move at a direction in a momentum).

	NPC CONFIG
	- floatSet = 0, -- 0 (able to float in the water), 1 (able to float in the air), 2 (able to float in both the air and the water)
	- maxswimspeedx = 5, -- The max speed at which the player should swim horizontally in the water
	- maxswimspeedy = 5, -- The max speed at which the player should swim vertically in the water
	- accelerationx = 0.1, -- How fast should the player be able to accelerate in the water horizontally
	- accelerationy = 0.1, -- How fast should the player be able to accelerate in the water vertically
	- frictionx = 0.1, -- The deacceleration the player should slow down horizontally when no keys has been held
	- frictiony = 0.1, -- The deacceleration the player should slow down vertically when no keys has been held
]]

--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local carryableTorpedo = require("carryabletorpedo_ai")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 48,
	gfxheight = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 2,
	framestyle = 1,
	framespeed = 6, -- number of ticks (in-game frames) between animation frame changes

	foreground = false, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- LOGIC
	--Movement speed. Only affects speedX by default.
	speed = 1,
	luahandlesspeed = false, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = false,
	cliffturn = false, -- Makes the NPC turn on ledges
	staticdirection = false, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = false, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = false, -- The player can walk on the NPC.

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = false,
	noiceball = false,
	noyoshi= false, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC

	score = 0, -- Score granted when killed
	--  1 = 10,    2 = 100,    3 = 200,  4 = 400,  5 = 800,
	--  6 = 1000,  7 = 2000,   8 = 4000, 9 = 8000, 10 = 1up,
	-- 11 = 2up,  12 = 3up,  13+ = 5-up, 0 = 0

	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false
	nowalldeath = true, -- If true, the NPC will not die when released in a wall

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=true,
	grabtop=false,

	ignorethrownnpcs=true,
	isstationary = true,

	floatSet = 0, -- 0 (able to float in the water), 1 (able to float in the air), 2 (able to float in both the air and the water)
	maxswimspeedx = 5, -- The max speed at which the player should swim horizontally in the water
	maxswimspeedy = 5, -- The max speed at which the player should swim vertically in the water
	accelerationx = 0.1, -- How fast should the player be able to accelerate in the water horizontally
	accelerationy = 0.1, -- How fast should the player be able to accelerate in the water vertically
	frictionx = 0.1, -- The deacceleration the player should slow down horizontally when no keys has been held
	frictiony = 0.1, -- The deacceleration the player should slow down vertically when no keys has been held
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
carryableTorpedo.register(npcID)

--Gotta return the library table!
return sampleNPC