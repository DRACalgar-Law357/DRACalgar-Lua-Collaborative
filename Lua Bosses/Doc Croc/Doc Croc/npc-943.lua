local npcManager = require("npcManager")
local particles = require("particles")

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
	fireID = 527,
	fireSpeed = 5,
	initAngle = 65,
	angleInc = 25,
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
		for i=0,2 do
			local dir = -vector.right2:rotate(NPC.config[t.id].initAngle + (i * NPC.config[t.id].angleInc))
			local f = NPC.spawn(NPC.config[t.id].fireID, t.x + t.width/2, t.y + t.height / 2, t:mem(0x146, FIELD_WORD), false, true)
			f.speedX = dir.x * NPC.config[t.id].fireSpeed
			f.speedY = dir.y * NPC.config[t.id].fireSpeed
		end
	end
end

return star;
