local npcManager = require("npcManager")
local particles = require("particles")

local star = {}

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

local config = {
	id = npcID,
	gfxheight = 32,
    gfxwidth = 32,
	width = 32,
	height = 32,
    frames = 1,
    framestyle = 0,
	framespeed = 4, 
    nofireball=1,
	noblockcollision = 0,
	noiceball = true,
	nowaterphysics = true,
	jumphurt = true,
	npcblock = false,
	spinjumpsafe = false,
	noyoshi = true,
	ignorethrownnpcs = true,
	shockwaveID = npcID + 1,
	shockwaveSpeed = 5,
}

npcManager.setNpcSettings(config)


function star.onInitAPI()
	npcManager.registerEvent(npcID, star, "onTickEndNPC")
end

function star.onTickEndNPC(t)
		--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = t.data
	
	if t.collidesBlockBottom then
		Explosion.spawn(t.x + t.width/2, t.y + t.height/2, 3)
		t:kill()
		for i=1,2 do
			local f = NPC.spawn(NPC.config[t.id].shockwaveID, t.x + t.width/2, t.y + t.height - NPC.config[NPC.config[t.id].shockwaveID].height/2, t:mem(0x146, FIELD_WORD), false, true)
			if i == 1 then
				f.speedX = -NPC.config[t.id].shockwaveSpeed
			else
				f.speedX = NPC.config[t.id].shockwaveSpeed
			end 
		end
	end
end

return star;
