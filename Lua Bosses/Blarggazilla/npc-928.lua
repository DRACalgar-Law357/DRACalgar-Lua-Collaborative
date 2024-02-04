local lightning = {}

local npcManager = require("npcManager")

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	gfxwidth = 64, 
	gfxheight = 64, 
	width = 64,
	height = 64,
	frames = 8,
	harmlessgrab=true,
	ignorethrownnpcs = true,
	framespeed = 4,
	frames = 8,
	framestyle = 0,
	nofireball=true,
	noiceball=true,
	noyoshi=true,
	nohurt=false,
	speed=1,
	nogravity=false,
	noblockcollision=false,
	jumphurt = 1,
	nowaterphysics=false,
	spinjumpsafe = false,
	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.orange,
	ishot = true,
	staticdirection = true,

	spawnid = 929
})

function lightning.onInitAPI()
	npcManager.registerEvent(npcID, lightning, "onTickEndNPC")
end

function lightning.onTickEndNPC(v)
	if Defines.levelFreeze
		or v.isHidden
		or v:mem(0x12C, FIELD_WORD) > 0
		or v:mem(0x138, FIELD_WORD) > 0
		or v:mem(0x12A, FIELD_WORD) <= 0 then return end

	local data = v.data
	
	if v.collidesBlockBottom then
		local id = NPC.config[v.id].spawnid
		for i=0,6 do
			local f = NPC.spawn(id, v.x + 0.5 * v.width, v.y + v.height - 0.5 * NPC.config[id].height, v:mem(0x146, FIELD_WORD), false, true)
			f.speedX = -1.5 + (1.5/3) * i
			f.speedY = -3
		end
		SFX.play(43)
		local a = Animation.spawn(828,0,0)
		a.x = v.x + v.width/2 - a.width/2
		a.y = v.y + v.height/2 - a.height/2
		v:kill(9)
	end
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
end

return lightning