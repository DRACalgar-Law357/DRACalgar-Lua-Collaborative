local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local debris = {}
local npcIDs = {}

function debris.register(id)
	npcManager.registerEvent(id, debris, "onTickNPC")
	npcManager.registerEvent(id, debris, "onTickEndNPC")
	npcManager.registerEvent(id, debris, "onDrawNPC")
	npcIDs[id] = true
end

function debris.onInitAPI()
	registerEvent(debris, "onNPCHarm")
	registerEvent(debris, "onPostNPCKill")
end

local blocks = Block.SOLID .. Block.SLOPE .. Block.PLAYER .. Block.SEMISOLID

function debris.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local cfg = NPC.config[v.id]
	local collider = Colliders.getSpeedHitbox(v)
	
	if not data.rotationSpeed then data.rotationSpeed = RNG.irandomEntry({-cfg.rotationSpeed, cfg.rotationSpeed}) end
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.angle = 0
		data.destroyedBlocks = 0
		if cfg.smokeid and cfg.smokeid ~= 0 then data.timer = 0 end
		data.initialized = true
	end
	
	if v:mem(0x12C, FIELD_WORD) == 0 and v:mem(0x138, FIELD_WORD) == 0 then data.angle = data.angle + data.rotationSpeed end
	if v:mem(0x136, FIELD_BOOL) or v.speedX ~= 0 then data.rotationSpeed = math.abs(data.rotationSpeed) * v.direction end
	if v.speedY > 2 then v.speedY = 2 end
	
	if v.friendly then return end
end

function debris.onTickEndNPC(v)
	local data = v.data
	local cfg = NPC.config[v.id]
	
	if not Defines.levelFreeze and cfg.smokeid ~= 0 and data.timer and v:mem(0x138, FIELD_WORD) == 0 then
		if data.timer % 12 == 0 then Effect.spawn(cfg.smokeid, v.x + RNG.random(cfg.width * 0.25, cfg.width * 0.75), v.y + RNG.random(math.min(cfg.height * 0.5, 12), cfg.height * 0.5)) end
		data.timer = data.timer + 1
	end
	
	if v:mem(0x138, FIELD_WORD) > 0 then v.height = cfg.height end
end

function debris.onDrawNPC(v)
	local data = v.data
	local cfg = NPC.config[v.id]
	
	if v.despawnTimer > 0 and v:mem(0x12C, FIELD_WORD) == 0 and v:mem(0x138, FIELD_WORD) == 0 and not v.isHidden then
		local p = -45
		if cfg.foreground then p = -15 end
		
		if not data.sprite then
			data.sprite = Sprite{
				image = Graphics.sprites.npc[v.id].img,
				frames = npcutils.getTotalFramesByFramestyle(v),
				align = vector.v2(0.5 + cfg.gfxoffsetx / cfg.gfxwidth, 0.5 + cfg.gfxoffsety / cfg.gfxheight)
			}
		else
			data.sprite.x = v.x + cfg.width * 0.5 + cfg.gfxoffsetx
			data.sprite.y = v.y + cfg.height * 0.5 + cfg.gfxoffsety
			data.sprite.rotation = data.angle
			
			data.sprite:draw{
				frame = v.animationFrame + 1,
				priority = p,
				sceneCoords = true
			}
			npcutils.hideNPC(v)
		end
	end
end

function debris.onNPCHarm(eventToken, v, harmtype, culprit)
	if not npcIDs[v.id] then return end
	
	local cfg = NPC.config[v.id]	
	if harmtype == HARM_TYPE_JUMP and cfg.jumphurt then
		eventToken.cancelled = true
	end
end

function debris.onPostNPCKill(v, harmtype)
	if not npcIDs[v.id] or harmtype == HARM_TYPE_LAVA or harmtype == HARM_TYPE_VANISH then return end
	
	local cfg = NPC.config[v.id]
	for i = 1, 4 do
		local e = Effect.spawn(cfg.smokeId, v.x + RNG.random(cfg.width * 0.25, cfg.width * 0.75), v.y + RNG.random(math.min(cfg.height * 0.5, 12), cfg.height * 0.5))
		e.speedX = RNG.random(-2, 2)
		e.speedY = RNG.random(-2, 2)
	end
end

return debris