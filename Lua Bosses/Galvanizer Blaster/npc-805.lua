local npcManager = require("npcManager")
local particles = require("particles")

local Rock = {}

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

local config = {
	id = npcID,
	gfxheight = 128,
    gfxwidth = 128,
	width = 96,
	height = 96,
    gfxoffsetx = 0,
	gfxoffsety = 16,
    frames = 4,
    framestyle = 0,
	framespeed = 6, 
    nofireball=1,
	nogravity=0,
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
	npcManager.registerEvent(npcID, Rock, "onTickEndNPC")
end

function Rock.onTickEndNPC(v)
		--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data

	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
        data.timer = 0
		data.initialized = true
	end
    data.timer = data.timer + 1
    if data.timer % 8 == 0 then
        Animation.spawn(950, math.random(v.x - v.width / 2, v.x + v.width / 2), math.random(v.y - v.height / 2, v.y + v.height / 2))
    end

    if v.collidesBlockBottom or v.collidesBlockUp or v.collidesBlockLeft or v.collidesBlockRight then
        Defines.earthquake = 9
        for i = 1,12 do
            local n = NPC.spawn(803, v.x + v.width / 3, v.y)
            n.direction = v.direction
            n.speedX = RNG.random(-5.5,5.5)
            n.speedY = -RNG.random(8,12.5)
        end
        for i = 1,30 do
            local ptl = Animation.spawn(950, math.random(v.x - v.width / 2, v.x + v.width / 2), math.random(v.y - v.height / 2, v.y + v.height / 2))
            ptl.speedX = RNG.random(-10,10)
            ptl.speedY = RNG.random(-10,10)
        end
        v:kill()
        SFX.play(43)
    end
     
end

return Rock;