--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local wario = require("warioLand1NPC")

--Create the library table
local goom = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local goomSettings = {
	id = npcID,
	gfxwidth = 42,
	gfxheight = 34,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 2,
	--Frameloop-related
	frames = 4,
	framestyle = 1,
	framespeed = 6, -- number of ticks (in-game frames) between animation frame changes
	
	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = false, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = false, -- The player can walk on the NPC.

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	
	grabside = true,
	
	--Wario Land specific
	transformID = npcID - 1, --The NPC to transform into when either getting stunned or transfortming back
	bigEnemy = false, --If big, you move slower when holding it and it dies when it hits a wall when thrown
	
	--Stun Specific
	stunned = true, --If true, the enemy transforms into transformID after a set number of seconds
	stunTime = 128, --Resets if hit about
	score = 0,
	
}

--Applies NPC settings
npcManager.setNpcSettings(goomSettings)

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
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=npcID - 1,
		[HARM_TYPE_NPC]=npcID - 1,
		[HARM_TYPE_PROJECTILE_USED]=npcID - 1,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID - 1,
		[HARM_TYPE_TAIL]=npcID - 1,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

wario.register(npcID)

--Gotta return the library table!
return goom