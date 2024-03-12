local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local star = {}

local npcID = NPC_ID

local config = {
	id = npcID,
	gfxheight = 16,
    gfxwidth = 32,
	width = 32,
	height = 16,
    frames = 4,
    framestyle = 1,
	framespeed = 4, 
    nofireball=0,
	nogravity=1,
	noblockcollision = 1,
	linkshieldable = true,
	noshieldfireeffect = true,
	noiceball = true,
	nowaterphysics = true,
	jumphurt = true,
	npcblock = false,
	spinjumpsafe = false,
	noyoshi = true,
	ishot = true,
	lightradius = 100,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.orange,
}

npcManager.setNpcSettings(config)

return star;