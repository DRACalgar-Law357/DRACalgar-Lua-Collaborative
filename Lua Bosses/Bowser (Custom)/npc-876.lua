local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local flame = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 24,
	height = 24,
	frames = 6,
	framestyle = 1,
	jumphurt = 1,
	nogravity = 0,
	noblockcollision = 0,
	ignorethrownnpcs = true,
	nofireball=1,
	noiceball=1,
	npcblock=0,
	noyoshi=1,
	spinjumpsafe = false,
	lightradius=40,
	lightbrightness=1,
	lightcolor=Color.orange,
	ishot = true,
})

function flame.onInitAPI()
	npcManager.registerEvent(npcID, flame, "onTickEndNPC", "onTickEndTrail")
	npcManager.registerEvent(npcID, flame, "onDrawNPC", "onDrawTrail")
end

function flame.onTickEndTrail(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 then
		data.flameTimer = nil
		return
	end

	
	
	if data.flameTimer == nil then
		data.flameTimer = 0
	end

	if v.ai1 == 0 then
		v.nogravity = true
		v.animationFrame = math.floor(lunatime.tick() / 6) % 3
		if v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockRight then
			SFX.play(16)
			v.speedX = 0
			v.speedY = 0
			v.ai1 = 1
			v.nogravity = false
		end
	else
	
		data.flameTimer = data.flameTimer + 1

		if data.flameTimer == 124 then
			v:kill(9)
		end
		if data.flameTimer > 8 and data.flameTimer <= 108 then
			v.animationFrame = math.floor(data.flameTimer / 6) % 2 + 4
			v.friendly = false
		else
			v.animationFrame = 3
			v.friendly = true
		end
	end

	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = utils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = NPC.config[v.id].frames
		});
	end
end

function flame.onDrawTrail(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 then
		return
	end
	
	if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then
		Animation.spawn(10, v)
		SFX.play(9)
		v:kill(7)
		
		return
	end
	
	if data.flameTimer == nil then
		data.flameTimer = 0
	end
end
	
return flame