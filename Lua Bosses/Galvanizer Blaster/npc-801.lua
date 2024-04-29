local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local elecBall = {}

local npcID = NPC_ID

local fireSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 28,
	height = 28,
	frames = 2,
	framespeed = 5,
	jumphurt = true,
	framestyle = 0,
	nofireball = true,
	noiceball = true,
	nogravity = true,
	noyoshi = true,
	noblockcollision = true,
	spinjumpsafe = false,
	ignorethrownnpcs = true,
	lightradius = 64,
	lightbrightness = 1,
	lightcolor = Color.lightblue,
}

npcManager.setNpcSettings(fireSettings)

function elecBall.onInitAPI()
	npcManager.registerEvent(npcID, elecBall, "onTickNPC")
	npcManager.registerEvent(npcID, elecBall, "onDrawNPC")
end

function elecBall.onTickNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data
	local config = NPC.config[v.id]

	if data.rotation == nil then
		data.rotation = 0
	end

	local speed = 0

	if (math.abs(v.speedX) > math.abs(v.speedY)) or (math.abs(v.speedX) == math.abs(v.speedY)) then
		speed = v.speedX
	elseif math.abs(v.speedX) < math.abs(v.speedY) then
		speed = v.speedY
	end

	data.rotationSpeed = speed * 4
	data.rotation = data.rotation + data.rotationSpeed

	if data.rotation > 360 then
		data.rotation = 0
	elseif data.rotation < 0 then
		data.rotation = 360
	end
end

local function isDespawned(v)
	return v.despawnTimer <= 0
end

function elecBall.onDrawNPC(v)
	local data = v.data
	local config = NPC.config[v.id]

	if not isDespawned(v) then
		Graphics.drawBox{
			texture = Graphics.sprites.npc[v.id].img,
			x = v.x + (v.width / 2), y = v.y + v.height-(config.gfxheight / 2),
			sourceX = 0, sourceY = v.animationFrame * config.gfxheight,
			sourceWidth = config.gfxwidth, sourceHeight = config.gfxheight,
			priority = -45, rotation = data.rotation,
			centered = true, sceneCoords = true,
		}
	end

	npcutils.hideNPC(v)
end
	
return elecBall