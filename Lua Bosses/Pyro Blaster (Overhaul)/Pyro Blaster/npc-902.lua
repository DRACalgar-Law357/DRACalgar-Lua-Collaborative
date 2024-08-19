local npcManager = require("npcManager")
local sinewave = require("npcs/ai/sinewave")

local gasBubble = {}

npcID = NPC_ID;

local bubbleData = {}

npcManager.setNpcSettings({
	id = npcID, 
	gfxoffsety = 0,
	gfxwidth = 32, 
	gfxheight = 32, 
	width = 32, 
	height = 32, 
	frames = 2,
	framespeed = 8, 
	framestyle = 1,
	score = 0,
	nofireball = 1,
	noiceball = -1,
	nogravity = 1,
	noblockcollision = 1,
	jumphurt = 1,
	noyoshi = 1,
	speed = 1.9,
	ignorethrownnpcs = true,
	harmlessgrab = true,
	spinjumpsafe = false,
	--lua only
	frequency = 20,
	amplitude = 1,
    wavestart = -1,
    chase = false
})

function gasBubble.onInitAPI()
	sinewave.register(npcID)
	npcManager.registerEvent(npcID, gasBubble, "onTickNPC")
end

function gasBubble.onTickNPC(v)
	v.collisionGroup = "PyroBlasterStuff"
	Misc.groupsCollide["PyroBlasterStuff"]["PyroBlasterStuff"] = false
end

return gasBubble;