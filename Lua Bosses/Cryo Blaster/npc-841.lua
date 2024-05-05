local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}
local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,
	gfxheight = 68,
	gfxwidth = 68,

	width = 22,
	height = 22,

	gfxoffsety = 23,

	frames = 10,
	framestyle = 0,
	framespeed = 8,
	speed = 1,

	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= false,
	nowaterphysics = true,

	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside = false,
	grabtop = false,
	ignorethrownnpcs = true,
	luahandlesspeed = true,
	terminalvelocity = 20,
}

npcManager.setNpcSettings(sampleNPCSettings)
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);
--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
end
function sampleNPC.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height/2)
	if v.despawnTimer <= 0 then
		v:kill(9)
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		--timer
		v.ai1 = v.ai1 or 0
		--state
		v.ai2 = v.ai2 or 0
		--mode
		v.ai3 = v.ai3 or 0
		--speed
		v.ai4 = v.ai4 or 1.5
		--acceleration
		v.ai5 = v.ai5 or 0.1
		data.velocityCap = 7
		data.vector = 0
		data.presetRotation = 0
		data.rotation = 0
		data.angleVelocity = 0
		data.img = data.img or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = sampleNPCSettings.frames, texture = Graphics.sprites.npc[v.id].img}
	end

	if v:mem(0x12C, FIELD_WORD) > 0 -- Grabbed
	or v:mem(0x136, FIELD_BOOL)     -- Thrown
	or v:mem(0x138, FIELD_WORD) > 0 -- Contained within
	then
		return
	end

	--[[
	v:mem(0x120, FIELD_BOOL, false)

	if v.collidesBlockTop or v.collidesBlockBottom or v.collidesBlockRight or v.collidesBlockLeft then
		v:kill(HARM_TYPE_PROJECTILE_USED)
	end
	]]
	local center = vector(v.x + v.width/2, v.y + v.height/2)
	v.ai1 = v.ai1 + 1
	if v.ai2 == 0 then
		if math.abs(v.speedX) <= 0.1 then
			v.speedX = 0
		else
			v.speedX = v.speedX * 0.9
		end
		if math.abs(v.speedY) <= 0.1 then
			v.speedY = 0
		else
			v.speedY = v.speedY * 0.9
		end
		v.animationFrame = math.floor((v.ai1-1) / 4) % 9
		if v.ai1 >= 36 then
			v.ai1 = 0
			v.ai2 = 1
			if v.ai3 == 0 then
				data.vector = vector(plr.x+plr.width/2-v.x+(-v.width)*0.5, plr.y+plr.height/2-v.y+(-v.height)*0.5):normalize()
				local cPlayer = Player.getNearest(center.x, center.y)
				data.chVector = vector((cPlayer.x+cPlayer.width/2) - (center.x), (cPlayer.y+cPlayer.height/2) - (center.y)) -- Thanks 8luestorm for this chunk lol
				data.rotation = math.deg(math.atan2(data.chVector.y, data.chVector.x)) + 90
				data.angleVelocity = data.vector
			elseif v.ai3 == 1 then
				data.rotation = 180
				data.angleVelocity = vector(0, 60):normalize()
			elseif v.ai3 == 2 then
				if v.direction == -1 then
					data.rotation = 270
				else
					data.rotation = 90
				end
				data.angleVelocity = vector(v.direction, 0):normalize()
			end
		end
	else
		v.animationFrame = 9
		v.speedX = data.angleVelocity.x * v.ai4
		v.speedY = data.angleVelocity.y * v.ai4
		v.ai4 = math.clamp(v.ai4 + v.ai5, -data.velocityCap, data.velocityCap)
		if v.ai1 % 12 == 6 then
			local a = Effect.spawn(npcID,v.x+v.width/2,v.y+v.height/2)
			a.x=a.x-a.width/2
			a.y=a.y-a.height/2
		end
	end
	if v.noblockcollision == false then
		for k, b in Block.iterateIntersecting(v.x, v.y, v.x + v.width, v.y + v.height) do
			if not b.isHidden and not b:mem(0x5A, FIELD_BOOL) and Block.SOLID_MAP[b.id] then
				v:kill(HARM_TYPE_PROJECTILE_USED)
				SFX.play("s1047_cirno_bullet.wav")
				break
			end
		end
	end
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
	end
end


function sampleNPC.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data
	if v.despawnTimer <= 0 or v.isHidden then return end
	--Setup code by Mal8rk
	local pivotOffsetX = 0
	local pivotOffsetY = 0
	
	local opacity = 1
	if data.img then
		-- Setting some properties --
		data.img.x, data.img.y = v.x + 0.5 * v.width + config.gfxoffsetx, v.y + 0.5 * v.height --[[+ config.gfxoffsety]]
		data.img.transform.scale = vector(1, 1)
		data.img.rotation = data.rotation

		local p = -45

		-- Drawing --
		data.img:draw{frame = v.animationFrame + 1, sceneCoords = true, priority = p, color = Color.white..opacity}
		npcutils.hideNPC(v)
	end
end

return sampleNPC