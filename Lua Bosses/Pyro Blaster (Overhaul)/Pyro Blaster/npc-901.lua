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
    frames = 2,
    framestyle = 1,
	framespeed = 4, 
    nofireball=0,
	noblockcollision = 0,
	noiceball = true,
	nowaterphysics = true,
	jumphurt = true,
	npcblock = false,
	spinjumpsafe = false,
	noyoshi = true
}

npcManager.setNpcSettings(config)


function star.onInitAPI()
	npcManager.registerEvent(npcID, star, "onTickEndNPC")
end

function star.onTickEndNPC(t)
		--Don't act during time freeze
		t.collisionGroup = "PyroBlasterStuff"
		Misc.groupsCollide["PyroBlasterStuff"]["PyroBlasterStuff"] = false
	if Defines.levelFreeze then return end
	
	local data = t.data
	
	if t.collidesBlockLeft then
		Misc.doBombExplosion(t.x + t.width/2, t.y + t.height/2, 2)
		t:kill()
		end
	
		if t.collidesBlockUp then
			Misc.doBombExplosion(t.x + t.width/2, t.y + t.height/2, 2)
			t:kill()
			end
		
		if t.collidesBlockRight then
			Misc.doBombExplosion(t.x + t.width/2, t.y + t.height/2, 2)
			t:kill()
			end

	if t.collidesBlockBottom then
	Misc.doBombExplosion(t.x + t.width/2, t.y + t.height/2, 2)
	t:kill()
	end
end

return star;
