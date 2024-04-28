local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local star = {}

local npcID = NPC_ID

local config = {
	id = npcID,
	gfxheight = 128,
    gfxwidth = 128,
	width = 128,
	height = 128,
    frames = 2,
    framestyle = 1,
	framespeed = 4, 
    nofireball=0,
	nogravity=1,
	noblockcollision = 1,
	linkshieldable = false,
	noshieldfireeffect = false,
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

function star.onInitAPI()
	npcManager.registerEvent(npcID, star, "onTickNPC")
end

function star.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	local data = v.data
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		v:kill(9)
		return
	end
	if not data.initialized then
		--Initialize necessary data.
		v.ai1 = 0
		data.amplitudeDelay = RNG.randomInt(4,12)
		data.amplitude = RNG.randomInt(6,16)
		data.amplitudeRate = RNG.randomInt(2,4)
		data.initialized = true
	end
	v.ai1 = v.ai1 + 1
	v.speedY = math.cos(-v.ai1/data.amplitudeDelay)*data.amplitude / data.amplitudeRate
	for i=1,2 do
		local ptl = Animation.spawn(265, math.random(v.x, v.x + v.width), math.random(v.y, v.y + v.height))
		ptl.x=ptl.x-ptl.width/2
		ptl.y=ptl.y-ptl.height/2
	end
end

return star;