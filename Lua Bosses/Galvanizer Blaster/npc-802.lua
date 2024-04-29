local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local afterimages = require("afterimages")
afterimages.useShader = false

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
	noblockcollision = false,
	spinjumpsafe = false,
	ignorethrownnpcs = true,
	lightradius = 64,
	lightbrightness = 1,
	lightcolor = Color.lightblue,
}

npcManager.setNpcSettings(fireSettings)
local S3KExplosion = Misc.resolveFile("S3K_83.wav")
Explosion.register(-1, 24, 951, S3KExplosion)

function elecBall.onInitAPI()
	npcManager.registerEvent(npcID, elecBall, "onTickEndNPC")
	npcManager.registerEvent(npcID, elecBall, "onDrawNPC")
end

function elecBall.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data
	local config = NPC.config[v.id]
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = 0
	end

	if data.rotation == nil then
		data.rotation = 0
	end



	local speed = 0
	data.timer = data.timer + 1
	if (math.abs(v.speedX) > math.abs(v.speedY)) or (math.abs(v.speedX) == math.abs(v.speedY)) then
		speed = v.speedX
	elseif math.abs(v.speedX) < math.abs(v.speedY) then
		speed = v.speedY
	end
	if data.timer < 60 then
		if v.speedX >= 0.1 then
			v.speedX = v.speedX - 0.1
		elseif v.speedX <= -0.1 then
			v.speedX = v.speedX + 0.1
		else
			v.speedX = 0
		end
		if v.speedY >= 0.1 then
			v.speedY = v.speedY - 0.1
		elseif v.speedY <= -0.1 then
			v.speedY = v.speedY + 0.1
		else
			v.speedY = 0
		end
	else
		v.speedY = v.speedY + 0.3
		v.dontMove = true
		if v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockRight or v.collidesBlockUp then
			v:kill()
			Defines.earthquake = 5
			Explosion.spawn(v.x - v.width/4, v.y + v.height/2, -1)
		end
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
		local gfxw = NPC.config[v.id].gfxwidth
		local gfxh = NPC.config[v.id].gfxheight
		if gfxw == 0 then gfxw = v.width end
		if gfxh == 0 then gfxh = v.height end
		local frames = Graphics.sprites.npc[v.id].img.height / gfxh
		local framestyle = NPC.config[v.id].framestyle
		local frame = v.animationFrame
		local framesPerSection = frames
		if framestyle == 1 then
			framesPerSection = framesPerSection * 0.5
			if direction == 1 then
				frame = frame + frames
			end
			frames = frames * 2
		elseif framestyle == 2 then
			framesPerSection = framesPerSection * 0.25
			if direction == 1 then
				frame = frame + frames
			end
			frame = frame + 2 * frames
		end
		local p = priority or -46
		Graphics.drawBox{
			texture = Graphics.sprites.npc[v.id].img,
			x = v.x + (v.width / 2), y = v.y + v.height-(config.gfxheight / 2),
			sourceX = 0, sourceY = v.animationFrame * config.gfxheight,
			sourceWidth = config.gfxwidth, sourceHeight = config.gfxheight,
			priority = -45, rotation = data.rotation,
			centered = true, sceneCoords = true,
		}
		afterimages.addAfterImage{
			x = v.x + 0.5 * v.width - 0.5 * gfxw + NPC.config[v.id].gfxoffsetx,
			y = v.y + 0.5 * v.height - 0.5 * gfxh + NPC.config[v.id].gfxoffsety,
			texture = Graphics.sprites.npc[v.id].img,
			lifetime = 16,
			width = gfxw,
			height = gfxh,
			texOffsetX = 0,
			texOffsetY = frame / frames,
			animWhilePaused = false,
			color = Color(0.4,0.4,0.4),
			useShader = false
		}
	end

	npcutils.hideNPC(v)
end
	
return elecBall