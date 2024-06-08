local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local flame = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 16,
	height = 16,
	frames = 2,
	framestyle = 0,
	jumphurt = 1,
	nogravity = 0,
	noblockcollision = 0,
	ignorethrownnpcs = true,
	nofireball=1,
	noiceball=1,
	npcblock=0,
	noyoshi=1,
	spinjumpsafe = false,
	lightradius=32,
	lightbrightness=1,
	lightcolor=Color.orange,
	ishot = true,
	fireDelay = 200,
	disappearDelay = 60,
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
	
	data.flameTimer = data.flameTimer + 1
	if data.flameTimer > NPC.config[v.id].fireDelay then
		v.friendly = true
	end
	if data.flameTimer == NPC.config[v.id].fireDelay + NPC.config[v.id].disappearDelay then
		v:kill(9)
	end
	if data.flameTimer <= NPC.config[v.id].fireDelay then
		v.animationFrame = math.floor(data.flameTimer / NPC.config[v.id].framespeed) % NPC.config[v.id].frames
	else
		v.animationFrame = math.floor(data.flameTimer / NPC.config[v.id].framespeed) % NPC.config[v.id].frames
		if data.flameTimer % 4 <= 2 then
			v.animationFrame = -50
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