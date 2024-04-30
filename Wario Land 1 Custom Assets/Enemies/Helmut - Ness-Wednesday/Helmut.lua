local npcManager = require("npcManager")
local colliders = require("colliders")
local npcutils = require("npcs/npcutils")

local HelmutNPC = {}

local npcIDs = {}

local STATE_DOWN = 0
local STATE_SWIM = 1

function HelmutNPC.register(id)
	npcManager.registerEvent(id, HelmutNPC, "onTickEndNPC")
	npcIDs[id] = true
end

function HelmutNPC.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]

	if not data.state then
		data.timer = 0
		data.state = STATE_DOWN
	end
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.moveSpike = 0
		data.TipTop = config.TipTop
		data.spikeHitbox = Colliders.Tri(v.x,v.y,{10,0},{5,data.TipTop*v.direction},{0,0})
		data.buttBox = Colliders.Box(v.x,v.y,28,6)
		data.buttBoxY = 0
		data.seaSlider = config.seaSlider
	end
	
	data.buttBox.x = v.x + 2
	data.buttBox.y = v.y + data.buttBoxY
	data.spikeHitbox.x = v.x + 12
	data.spikeHitbox.y = v.y + data.moveSpike

	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v.forcedState > 0 or v:mem(0x136, FIELD_BOOL) or v.heldIndex ~= 0 or v.isProjectile or v.generatorTimer > 0 then
		data.state = nil
		data.timer = 0
		if not data.seaSlider then
			v.speedX = 0
		end
		return
	end
	
	v.speedX = 0
	
	local redirector = BGO.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)
	
	if v.direction == 1 then
		data.moveSpike = 24
		data.buttBoxY = 0
	elseif v.direction == -1 then
		data.moveSpike = 0
		data.buttBoxY = 18
	end
	
	if v.collidesBlockBottom then
		if not v.dontMove then
			data.state = STATE_SWIM
		end
	elseif v.collidesBlockUp or v:mem(0x1C,FIELD_WORD) < 2 then
		data.state = STATE_DOWN
	end

	if data.state == STATE_SWIM and not v.dontMove then
		data.timer = data.timer + 1
		if data.timer >= 5 then
			v.speedY = -2
			v.animationFrame = 1
		elseif data.timer <= 4 then
			v.speedY = 1.5
			v.animationFrame = 0
		end
		if data.timer >= 20 then
			data.timer = 0
		end
	end
	
	if data.state == STATE_DOWN then
		data.timer = 0
		v.animationFrame = 0
		v.speedY = 0.95
	end
	
	for k,b in ipairs(redirector) do
		if b.id == 199 then
			data.state = STATE_DOWN
		end
		if b.id == 221 then
			data.state = STATE_SWIM
		end
	end

	if not v.friendly then
		for _,p in ipairs(Player.get()) do
			if Colliders.collide(p, data.spikeHitbox) then
				p:harm()
				if p.forcedState ~= 0 and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL) then
					if v.direction == -1 then
						data.state = STATE_DOWN
					elseif v.direction == 1 then
						data.state = STATE_SWIM
					end
				end
			end
			if not config.sturdy then
				if Colliders.collide(p, data.buttBox) then
					if (p.forcedState == 0 and p.deathTimer == 0 and (not p:mem(0x13C,FIELD_BOOL) and v:mem(0x1C,FIELD_WORD) > 0)) or v.direction == 1 then
						v:harm(3)
					end
					if v.direction == 1 then
						Colliders.bounceResponse(p)
					end
				end
			end
		end
		
		for _,w in ipairs(Player.getIntersecting(v.x,v.y,v.x+32,v.y+17)) do
			if w.forcedState == 0 and w.deathTimer == 0 and not w:mem(0x13C,FIELD_BOOL) and not w.isMega then
				local direction = (math.sign((w.x+(w.width/2))-(v.x+(v.width/2))))
	
				w:mem(0x138,FIELD_FLOAT,2.8*direction)
	
				SFX.play(2)
			end
		end
	end
	
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = npcIDs.frames
	});
end

return HelmutNPC