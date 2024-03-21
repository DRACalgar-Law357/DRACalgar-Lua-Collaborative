local npcManager = require("npcManager")
local particles = require("particles")

local Rock = {}

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
	framespeed = 6, 
    nofireball=1,
	nogravity=1,
	noblockcollision = 0,
	ignorethrownnpcs = true,
	noiceball = true,
	nowaterphysics = true,
	jumphurt = true,
	npcblock = false,
	spinjumpsafe = false,
	noyoshi = true
}

npcManager.setNpcSettings(config)

function Rock.onInitAPI()
	npcManager.registerEvent(npcID, Rock, "onTickNPC")
end

function Rock.onTickNPC(v)
		--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
    local stateTimer = v.timer

	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end
	
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
	end

	v.speedY = 6
    if v.collidesBlockBottom or v.collidesBlockUp or v.collidesBlockLeft or v.collidesBlockRight then
        Animation.spawn(1, v.x, v.y)
        v:kill()
        SFX.play(4)
    end
     
end

return Rock;