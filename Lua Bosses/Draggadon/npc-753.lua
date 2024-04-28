local npcManager = require("npcManager")
local debrisAI = require("draggadonvolcanicdebris")

local debris = {}
local npcID = NPC_ID

local debrisSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	speed = 0,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	jumphurt = true,
	spinjumpsafe = true,
	noblockcollision = true,
	score = 0,
	ishot = true,
	durability = -1,
	lightradius = 75,
	lightbrightness = 1,
	lightcolor = Color.orange,
	rotationspeed = 4,
	smokeid = 755,
	destroycontainerblocks = true,
	destroyblockcontents = true,
	maxbrokenblocks = 1
}

npcManager.setNpcSettings(debrisSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_VANISH,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=753,
		[HARM_TYPE_NPC]=753,
		[HARM_TYPE_PROJECTILE_USED]=753,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=753,
		[HARM_TYPE_TAIL]=753,
		[HARM_TYPE_SWORD]=753,
	}
)

debrisAI.register(npcID)

return debris