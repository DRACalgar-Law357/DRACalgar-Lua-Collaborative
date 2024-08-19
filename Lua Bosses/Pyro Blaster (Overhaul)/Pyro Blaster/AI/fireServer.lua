local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local fireServer = {}


fireServer.npcList = {}
fireServer.npcMap = {}

fireServer.shotList = {}
fireServer.shotMap = {}

fireServer.tankList = {}
fireServer.tankMap = {}

fireServer.explosiveList = {}
fireServer.explosiveMap = {}


local STATE = {
	IDLE = 0,
	SHOOT = 1,
	RETRACT = 2,
}

local customExplosion = Explosion.register(48, nil, nil, true, false)

local function SFXPlay(sfx)
	if sfx and sfx.id then
		SFX.play(sfx.id, sfx.volume)
	end
end

-- Thanks to Rednaxela for this function!
-- distanceX/Y are relative change in SMBX position (up = negative)
-- jumpHeight/grav are assumed to be expressed as positive numbers
local function getJumpSpeed(distanceX, distanceY, jumpHeight, grav)
    distanceX = distanceX or 0
    distanceY = distanceY or 0
    jumpHeight = jumpHeight or 0
    grav = grav or Defines.npc_grav

	-- jumpHeight is not enough to reach the required distance
	if -distanceY > jumpHeight then
		jumpHeight = jumpHeight + (-distanceY)
	end

    local speedY = -math.sqrt(2 * grav * jumpHeight)
    local speedX = distanceX / ((-speedY + math.sqrt(speedY * speedY + 2 * grav * distanceY)) / grav)

    return speedX, speedY
end


local function spawnExplosion(v, cfg)
	local x = v.x + v.width/2
	local y = v.y + v.height/2

	local e = Explosion.create(x, y, customExplosion, nil, false)

	if e then
		SFXPlay(cfg.explodeSFX)
		Effect.spawn(cfg.deathEffect, x, y)
		e.radius = cfg.explosionRadius
		--e.collider:debug(true)
	end

	return e
end


local function positionHeldNPC(v, n, offset, frameOffsets)
	local extraOffset = vector(0, 0)

	if frameOffsets and frameOffsets[v.data.frame + 1] then
		extraOffset.x = frameOffsets[v.data.frame + 1].x
		extraOffset.y = frameOffsets[v.data.frame + 1].y
	end

	n.x = v.x + v.width/2 + (offset.x + extraOffset.x) * v.direction - n.width/2
	n.y = v.y + v.height/2 + offset.y + extraOffset.y - n.height/2
	n.direction = v.direction
end


local function transformNPC(v, id)
	v:transform(id, true)
	v.data.initialized = false
	v.speedX = 0
end


function fireServer.registerNPC(id)
	npcManager.registerEvent(id, fireServer, "onStartNPC", "onStartServer")
	npcManager.registerEvent(id, fireServer, "onTickNPC", "onTickServer")
	npcManager.registerEvent(id, fireServer, "onTickEndNPC", "onTickEndServer")
	table.insert(fireServer.npcList, id)
	fireServer.npcMap[id] = true
end


function fireServer.registerShot(id)
	npcManager.registerEvent(id, fireServer, "onTickNPC", "onTickFireBall")
	npcManager.registerEvent(id, fireServer, "onDrawNPC", "onDrawFireBall")
	table.insert(fireServer.shotList, id)
	fireServer.shotMap[id] = true
end


function fireServer.registerTank(id)
	npcManager.registerEvent(id, fireServer, "onTickNPC", "onTickTank")
	npcManager.registerEvent(id, fireServer, "onDrawNPC", "onDrawTank")
	table.insert(fireServer.tankList, id)
	fireServer.tankMap[id] = true
end


function fireServer.registerExplosive(id)
	npcManager.registerEvent(id, fireServer, "onTickEndNPC", "onTickEndExplosive")
	npcManager.registerEvent(id, fireServer, "onDrawNPC", "onDrawExplosive")
	table.insert(fireServer.explosiveList, id)
	fireServer.explosiveMap[id] = true
end


function fireServer.onInitAPI()
	registerEvent(fireServer, "onNPCKill")
	registerEvent(fireServer, "onPostNPCKill")
end


-----------------
-- Fire Server --
-----------------

-- using onStartNPC because this runs before onTickEnd
function fireServer.onStartServer(v)
	local data = v.data
	local config = NPC.config[v.id]

	if not data.heldNPC and config.heldNPCID > 0 then
		data.heldNPC = NPC.spawn(config.heldNPCID, 0, 0)
		data.heldNPC.data.parent = v
		positionHeldNPC(v, data.heldNPC, config.heldNPCOffset)
	end
end


function fireServer.onTickServer(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	local heldOffset = config.heldNPCOffset

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.timer = 0
		data.targetPlayer = 0
		data.state = STATE.IDLE
		data.frame = 0
		data.shotCount = 0

		if not data.heldNPC and config.heldNPCID > 0 then
			data.heldNPC = NPC.spawn(config.heldNPCID, 0, 0)
			data.heldNPC.data.parent = v
			positionHeldNPC(v, data.heldNPC, heldOffset)
		end
	end

	if data.heldNPC and data.heldNPC.isValid then
		positionHeldNPC(v, data.heldNPC, heldOffset, config.frameOffsets)
	end

	if v:mem(0x12C, FIELD_WORD) > 0 -- Grabbed
	or v:mem(0x136, FIELD_BOOL)     -- Thrown
	or v:mem(0x138, FIELD_WORD) > 0 -- Contained within
	then
		return
	end

	local bounds = config.shootArea

	local box = {
		x1 = v.x + v.width/2 + bounds.x * v.direction,
		y1 = v.y + v.height/2 + bounds.y,
		x2 = v.x + v.width/2 + (bounds.x + bounds.w) * v.direction,
		y2 = v.y + v.height/2 + bounds.y + bounds.h,
	}

	if v.direction == -1 then
		box.x1, box.x2 = box.x2, box.x1
	end

	local canShoot = #Player.getIntersecting(box.x1, box.y1, box.x2, box.y2) > 0

	--[[
	Graphics.drawBox{
		x = box.x1,
		y = box.y1,
		w = box.x2 - box.x1,
		h = box.y2 - box.y1,
		sceneCoords = true,
		color = Color.red..0.5,
	}

	Text.print(box.x2 > box.x1, 0, 0)
	Text.print(box.y2 > box.y1, 0, 30)
	]]

	if data.state == STATE.IDLE then
		data.frame = math.floor(data.timer / config.framespeed) % config.idleFrames

		if canShoot and data.timer >= config.idleTime then
			data.state = STATE.SHOOT
			data.timer = 0
			data.player = npcutils.getNearestPlayer(v)
		end

	elseif data.state == STATE.SHOOT then
		local minTime = config.framespeed * config.shootFrames - 1
		local over = false
		data.frame = (math.floor(math.min(data.timer, minTime) / config.framespeed) % config.shootFrames) + config.idleFrames

		if data.timer >= minTime and (data.timer - minTime) % config.shotDelay == 0 then
			if data.shotCount < config.shotCount then
				local offset = config.shootOffset
				local xOffset = v.x + v.width/2 + offset.x * v.direction
				local yOffset = v.y + v.height/2 + offset.y

				local n = NPC.spawn(config.shootNPCID, xOffset, yOffset, v.section, false, true)
				local e = Effect.spawn(10, xOffset, yOffset)
		
				local p = data.player
				local dx = (p.x + p.width/2) - (n.x + n.width/2)
				local dy = (p.y + p.height/2) - (n.y + n.height/2)
				local jumpHeight = math.max(config.minHeight, config.minHeight - dy)
		
				if math.abs(dx) < config.minDistanceX then
					dx = config.minDistanceX * v.direction
				elseif math.abs(dx) > config.maxDistanceX then
					dx = config.maxDistanceX * v.direction
				end

				if jumpHeight > config.maxHeight then
					jumpHeight = config.maxHeight
					dy = jumpHeight - dy
				end
		
				n.direction = v.direction
				n.speedX, n.speedY = getJumpSpeed(dx, dy, jumpHeight)

				e.x = e.x - e.width/2
				e.y = e.y - e.height/2

				data.shotCount = data.shotCount + 1
				SFXPlay(config.shootSFX)
			else
				over = true
			end
		end

		if over then
			data.shotCount = 0
			data.timer = 0
			data.state = STATE.RETRACT
		end

	elseif data.state == STATE.RETRACT then
		local frames = config.frames - (config.shootFrames + config.idleFrames)
		local minTime = config.framespeed * frames - 1
		data.frame = (math.floor(math.min(data.timer, minTime) / config.framespeed) % frames) + (config.shootFrames + config.idleFrames)

		if data.timer >= minTime then
			data.timer = 0
			data.state = STATE.IDLE
		end
	end

	if data.heldNPC and data.heldNPC.isValid then
		positionHeldNPC(v, data.heldNPC, heldOffset, config.frameOffsets)
	end
	
	data.timer = data.timer + 1
end


function fireServer.onTickEndServer(v)
	local data = v.data
	local config = NPC.config[v.id]

	if data.frame then
		if config.framestyle == 1 and v.direction == 1 then
			v.animationFrame = data.frame + config.frames
		else
			v.animationFrame = data.frame
		end
	end
end


--------------------
-- Fire Ball Stuff --
--------------------

function fireServer.onTickFireBall(v)
	if Defines.levelFreeze then return end
	
	local data = v.data

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
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

	for k, b in Block.iterateIntersecting(v.x, v.y, v.x + v.width, v.y + v.height) do
		if not b.isHidden and not b:mem(0x5A, FIELD_BOOL) and Block.SOLID_MAP[b.id] then
			v:kill(HARM_TYPE_PROJECTILE_USED)
			break
		end
	end
end


function fireServer.onDrawFireBall(v)
	local config = NPC.config[v.id]

	if v.despawnTimer <= 0 or v.isHidden then return end

	local dir = vector(v.speedX * v.direction, v.speedY):normalize()
    local rotation = math.deg(math.atan2(dir.y, dir.x))

	Graphics.drawBox{
		texture = Graphics.sprites.npc[v.id].img,
		x = v.x + v.width/2 + config.gfxoffsetx * v.direction,
		y = v.y + v.height/2 + config.gfxoffsety,
		sourceX = 0,
		sourceY = v.animationFrame * config.gfxheight,
		sourceWidth = config.gfxwidth,
		sourceHeight = config.gfxheight,
		priority = (config.foreground and -15) or -45,
		sceneCoords = true,
		centered = true,
		rotation = rotation * v.direction,
	}

	npcutils.hideNPC(v)
end


----------------
-- Tank Stuff --
----------------

function fireServer.onTickEndExplosive(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.timer = 0
		data.thrown = false
		data.rotation = 0
		data.direction = v.direction
	end

	if v:mem(0x12C, FIELD_WORD) > 0 -- Grabbed
	or v:mem(0x136, FIELD_BOOL)     -- Thrown
	or v:mem(0x138, FIELD_WORD) > 0 -- Contained within
	then
		return
	end

	if data.timer == config.waitTime then
		local p = npcutils.getNearestPlayer(v)
		local dx = (p.x + p.width/2) - (v.x + v.width/2)
		local dy = (p.y + p.height/2) - (v.y + v.height/2)
		local jumpHeight = math.max(config.minHeight, config.minHeight - dy)
		local direction = math.sign(dx)

		if math.abs(dx) < config.minDistanceX then
			dx = config.minDistanceX * direction
		elseif math.abs(dx) > config.maxDistanceX then
			dx = config.maxDistanceX * direction
		end

		if jumpHeight > config.maxHeight then
			jumpHeight = config.maxHeight
			dy = jumpHeight - dy
		end

		local oldX, oldY = v.x + v.width/2, v.y + v.height/2

		v.width = config.thrownSize.x
		v.height = config.thrownSize.y
		v.x, v.y = oldX - v.width/2, oldY - v.height/2

		for k, field in ipairs{"Top", "Bottom", "Right", "Left"} do
			v["collidesBlock"..field] = false
		end

		v.speedX, v.speedY = getJumpSpeed(dx, dy, jumpHeight)
		data.thrown = true
		data.direction = direction
		SFXPlay(config.bounceSFX)
	end

	v:mem(0x120, FIELD_BOOL, false)

	if data.thrown then
		if v.collidesBlockTop or v.collidesBlockBottom or v.collidesBlockRight or v.collidesBlockLeft then
			v:kill(HARM_TYPE_PROJECTILE_USED)
		end

		data.rotation = data.rotation + math.sqrt(v.speedX * v.speedX + v.speedY * v.speedY) * data.direction * config.rotationMultiplier
	end

	data.timer = data.timer + 1
end


function fireServer.onDrawExplosive(v)
	local config = NPC.config[v.id]

	if v.despawnTimer <= 0 or v.isHidden then return end

	Graphics.drawBox{
		texture = Graphics.sprites.npc[v.id].img,
		x = v.x + v.width/2 + config.gfxoffsetx * v.direction,
		y = v.y + v.height/2 + config.gfxoffsety,
		sourceX = 0,
		sourceY = v.animationFrame * config.gfxheight,
		sourceWidth = config.gfxwidth,
		sourceHeight = config.gfxheight,
		priority = (config.foreground and -15) or -45,
		sceneCoords = true,
		centered = true,
		rotation = v.data.rotation or 0,
	}

	--[[
	Graphics.drawBox{
		x = v.x,
		y = v.y,
		w = v.width,
		h = v.height,
		sceneCoords = true,
		color = Color.green..0.5,
	}
	]]

	npcutils.hideNPC(v)
end


function fireServer.onTickTank(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	local transformID = config.transformID

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
	end

	if v:mem(0x12C, FIELD_WORD) > 0 -- Grabbed
	or v:mem(0x136, FIELD_BOOL)     -- Thrown
	or v:mem(0x138, FIELD_WORD) > 0 -- Contained within
	then
		return
	end

	local explode = false

	if (not data.parent or not data.parent.isValid) then
		for k, n in NPC.iterateIntersecting(v.x, v.y, v.x + v.width, v.y + v.height) do
			if not n.isHidden and not n.isGenerator and not config.blackListedNPCs[n.id] and NPC.config[n.id].ishot then
				n:kill(HARM_TYPE_PROJECTILE_USED)
				explode = true
				break
			end
		end
	end

	if explode then
		if transformID > 0 then
			--Misc.dialog(transformID)
			transformNPC(v, transformID)
			SFXPlay(config.hitSFX)
		else
			spawnExplosion(v, config)
		end
	end
end


function fireServer.onDrawTank(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local priority = (NPC.config[v.id].foreground and -15) or -45

	npcutils.drawNPC(v, {priority = priority - 0.1})
	npcutils.hideNPC(v)
end


function fireServer.onNPCKill(e, v, r)
	if e.cancelled or not fireServer.tankMap[v.id] then return end
	if r == HARM_TYPE_LAVA or r == HARM_TYPE_OFFSCREEN then return end

	local transformID = NPC.config[v.id].transformID
	local hasParent = (v.data.parent and v.data.parent.isValid)

	if transformID > 0 and not hasParent then
		e.cancelled = true
		transformNPC(v, transformID)
	else
		spawnExplosion(v, NPC.config[v.id])
	end
end


function fireServer.onPostNPCKill(v, r)
	if r == HARM_TYPE_LAVA or r == HARM_TYPE_OFFSCREEN then return end

	if fireServer.npcMap[v.id] then
		local n = v.data.heldNPC

		if n and n.isValid then
			local transformID = NPC.config[n.id].transformID
			
			if transformID > 0 then
				transformNPC(n, transformID)
				n.data.parent = nil
			else
				n:kill()
			end
		end
	elseif fireServer.explosiveMap[v.id] then
		spawnExplosion(v, NPC.config[v.id])
	end
end


return fireServer