local npcManager = require("npcManager")

local reznor = {}

local npcID = NPC_ID

local fireSettings = {
	id = npcID,
	gfxoffsety = 4,
	gfxheight = 48,
	gfxwidth = 48,
	width = 40,
	height = 40,
	frames = 4,
	framespeed = 4,
	jumphurt = true,
	framestyle = 0,
	nofireball = true,
	noiceball = true,
	nogravity = true,
	noyoshi = true,
	speed = 5,
	noblockcollision = true,
	spinjumpsafe = false,
	ignorethrownnpcs = true,
	linkshieldable = true,
	lightradius = 80,
	lightbrightness = 2,
	lightcolor = Color.orange,
	ishot = true,
	durability = 4,
	alwaysaim = false
}
local sfx = 42

npcManager.setNpcSettings(fireSettings)

function reznor.onInitAPI()
	npcManager.registerEvent(npcID, reznor, "onTickNPC", "onTickFire")
end

function reznor.onTickFire(v)
	if Defines.levelFreeze then return end
	
	if v.isHidden or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x138, FIELD_WORD) > 0 then
		v.ai1 = 0
		return
	end
	
	if v.ai1 ~= 0 then return end
	
	v.ai1 = 1

	if not v.dontMove then
		local chasePlayer = player
		if player2 then
			local d1 = player.x + player.width * 0.5
			local d2 = player2.x + player2.width * 0.5
			local dr = v.x + v.width * 0.5
			if (v.direction == 1 and d1 < dr)
			or (v.direction == -1 and d1 > dr)
			or RNG.randomInt(0,1) == 1 then
				chasePlayer = player2
			end
		end
		local dir = vector.v2(chasePlayer.x + 0.5 * chasePlayer.width  - (v.x + 0.5 * v.width), 
							  chasePlayer.y + 0.5 * chasePlayer.height - (v.y + 0.5 * v.height)):normalize()
							  
		dir.y = dir.y * NPC.config[v.id].speed
								   
		SFX.play(sfx)
		
		if (v.direction == 0) then
			v.direction = math.sign(dir.x)
		end
		
		if NPC.config[v.id].alwaysaim then
			v.speedX = dir.x
		else
			v.speedX = math.abs(dir.x) * v.direction
		end
		v.speedY = dir.y
	end
end
	
return reznor