local npcManager = require("npcManager")
local particles = require("particles")
local npcutils = require("npcs/npcutils")
local star = {}

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

local config = {
	id = npcID,
	gfxheight = 24,
    gfxwidth = 24,
	width = 24,
	height = 24,
	gfxoffsety = 0,
    frames = 4,
    framestyle = 1,
	framespeed = 6, 
    nofireball=0,
	noblockcollision = 0,
	noiceball = true,
	nowaterphysics = true,
	jumphurt = true,
	npcblock = false,
	spinjumpsafe = false,
	noyoshi = true,
	mushroomID = 185,
}

npcManager.setNpcSettings(config)


function star.onInitAPI()
	npcManager.registerEvent(npcID, star, "onTickEndNPC")
end

function star.onTickEndNPC(t)
		--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = t.data
	
	if t.collidesBlockLeft or t.collidesBlockRight or t.collidesBlockUp or t.collidesBlockBottom then
		SFX.play(55)
		t:kill(9)
		local n = NPC.spawn(NPC.config[t.id].mushroomID,t.x+t.width/2,t.y+t.height-NPC.config[NPC.config[t.id].mushroomID].height/2,t.section,true,true)
		npcutils.faceNearestPlayer(n)
	end
end

return star;