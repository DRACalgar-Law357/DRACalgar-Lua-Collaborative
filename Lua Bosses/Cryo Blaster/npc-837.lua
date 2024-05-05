local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local star = {}

local npcID = NPC_ID

local config = {
	id = npcID,
	gfxheight = 28,
    gfxwidth = 72,
	width = 72,
	height = 20,
	gfxoffsety = 4,
    frames = 2,
    framestyle = 0,
	framespeed = 4, 
    nofireball=0,
	nogravity=1,
	noblockcollision = 1,
	linkshieldable = false,
	noshieldfireeffect = true,
	noiceball = true,
	nowaterphysics = true,
	jumphurt = true,
	npcblock = false,
	spinjumpsafe = false,
	noyoshi = true,
	ignorethrownnpcs = true,
	iscold = true,
	lightradius = 120,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.cyan,
}

npcManager.setNpcSettings(config)

return star;