local npcManager = require("npcManager")

local TogemaruNPC = {}

local npcIDs = {}

function TogemaruNPC.register(id)
	npcManager.registerEvent(id, TogemaruNPC, "onTickEndNPC")
	npcIDs[id] = true
end

function TogemaruNPC.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		data.timer = 0
		return
	end

	if not data.initialized then
		data.initialized = true
		data.timer = data.timer or 0
	end

	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138,FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x12C, FIELD_WORD) > 0 then
		data.jumpCounter = nil
		return
	end
	
	if data.jumpCounter == nil then
		data.jumpCounter = 0
	end

	v.speedX = 1.1 * v.direction
	data.timer = data.timer + 1
	
	if v.collidesBlockBottom then
		data.timer = 0
		data.jumpCounter = data.jumpCounter + 1
		if data.jumpCounter < config.bouncecounter then
			v.speedY = config.shorthop
		elseif data.jumpCounter == config.bouncecounter then
			v.speedY = config.fullhop
			data.jumpCounter = 0
		end
		if data.timer == 0 and v:mem(0x04,FIELD_WORD) <= 1 then
			SFX.play(config.bouncysound)
		end
		if v.direction == -1 then
			v.animationFrame = 0
		else
			v.animationFrame = 2
		end
	end
	v.animationTimer = 0
	if data.timer >= 11 then
		if v.direction == -1 then
			v.animationFrame = 1
		else
			v.animationFrame = 3
		end
	end
	if not config.sturdy then
		for _,p in ipairs(Player.getIntersecting(v.x+4,v.y+46,v.x+24,v.y+46)) do
			if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL) and (v:mem(0x12E,FIELD_WORD) <= 0 or v:mem(0x130,FIELD_WORD) ~= p.idx) then
				v:harm(2)
			end
		end
	end
end

return TogemaruNPC