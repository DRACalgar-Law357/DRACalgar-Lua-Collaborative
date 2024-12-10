-----------------------------------------
--Bucket Heads from Wario Land: Super Mario Land 3
--Original sprite by The IT
--Coded by Ness-Wednesday. Please credit me if used!
--Special Thanks to MegaDood for helping me with the extra-settings toggles!
-----------------------------------------
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local wario = require("warioLand1NPC")

local bucketHead = {}

local npcIDs = {}

local STATE_OUTRANGE = 0
local STATE_INRANGE = 1
local STATE_FALL = 2

function bucketHead.register(id)
	npcManager.registerEvent(id, bucketHead, "onTickEndNPC")
	npcIDs[id] = true
end

function bucketHead.onInitAPI()
    registerEvent(bucketHead, "onNPCHarm")
	registerEvent(bucketHead, "onTickEnd")
end

local function heldFilterFunc(other)
	return other.despawnTimer >= 0 and (not other.isGenerator) and (not other.friendly) and other:mem(0x12C, FIELD_WORD) == 0 and other.forcedState == 0
end

local Flakes = {}

function bucketHead.onTickEnd()
	for i=#Flakes, 1, -1 do
		local v = Flakes[i]
		if v.isValid then
			if (not v.friendly) then
				for k,n in ipairs(Colliders.getColliding{
					a = v,
					b = NPC.HITTABLE,
					btype = Colliders.NPC,
					collisionGroup = v.collisionGroup,
					filter = heldFilterFunc
				}) do
					n:harm(3)
				end
			end
		else
			table.remove(Flakes, i)
		end
	end
end

local function spawnNPC(v, data, cfg)
	local flake = NPC.spawn(data.spawnid, v.x, v.y + cfg.spawnOffsetY, v:mem(0x146, FIELD_WORD))
	flake.direction = v.direction
	flake.friendly = v.friendly
	flake.speedX = cfg.projectileSpeedX * v.direction
	flake.speedY = cfg.projectileSpeedY
	flake.layerName = "Spawned NPCs"
	SFX.play(cfg.spitSFX)
	if data.hasBeenHeld then
		flake:mem(0x12E, FIELD_WORD, 9999)
		flake:mem(0x130, FIELD_WORD, v:mem(0x12C, FIELD_WORD))
		table.insert(Flakes, flake)
	end
end

function bucketHead.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data
	local cfg = NPC.config[v.id]
	local settings = v.data._settings

	if v.id == cfg.transformID then return end

	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.state = nil
		data.leeway = nil
		data.turnAround = nil
		return
	end
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.volley = settings.volley or 1;
		data.followTheLeader = settings.followTheLeader
		if data.followTheLeader == nil then data.followTheLeader = true end
		data.useRadius = settings.useRadius
		if data.useRadius == nil then data.useRadius = true end
		data.pauseTime = settings.pauseTime or 55;
		data.breakTimer = data.pauseTime
		data.leeway = 0
		data.turnAround = 0
		data.initialized = true
		data.shootRadius = cfg.shootRadius
		data.shootTimer = 0
		data.volleyCount = 0
		data.spitShine = settings.spitShine or 17;
		data.spawnid = v.ai1
		if data.spawnid == 0 then
			data.spawnid = cfg.spawnid
		end
		data.hasBeenHeld = false
	end
	
	--Debug stuff
	--Text.print(data.breakTimer, 0, 0)
	
	if not data.state then
		data.state = STATE_OUTRANGE
	end

	if v.heldIndex > 0 then
		data.state = STATE_INRANGE
		if data.state ~= STATE_INRANGE then
			return
		end
	elseif v.heldIndex <= 0 then
		if (v.forcedState > 0 or v.isProjectile) and not data.hasBeenHeld then
			v.animationFrame = 0
			return
		end
		if not v.isProjectile then
			for _,p in ipairs(Player.get()) do
				if Colliders.collide(p, v) and p.deathTimer <= 0 then
					if (p.character == 7 or p.character == 8) then
						data.state = STATE_OUTRANGE
						data.breakTimer = data.pauseTime
						data.shootTimer = 0
						return
					end
				end
			end
		end
	end

	if v:mem(0x12E, FIELD_WORD) == 30 then
		data.hasBeenHeld = true
	elseif data.hasBeenHeld then
		v:harm()
		return
	end


	--Execute main AI.
	local player = Player.getNearest(v.x+(v.width/2),v.y+(v.height/2))
	
	if data.state == STATE_OUTRANGE then
		data.volleyCount = 0
		data.breakTimer = data.breakTimer + 1
		if v.collidesBlockBottom and (not v.isProjectile) and data.turnAround <= 0 then
			v.speedX = cfg.speed * v.direction
			v.animationFrame = math.floor(lunatime.tick() / 8) % 4
		else
			v.animationFrame = 0
		end
	
		if data.turnAround <= 0 and data.leeway > 0 then -- Turnaround code by MrNameless because it's much cleaner than the mess I wrote lmao
			data.leeway = data.leeway - 1
		end
	
		if v:mem(0x120, FIELD_BOOL) and data.turnAround <= 0 and data.leeway <= 0 then
			data.leeway = 12
			data.turnAround = 64
		end
	
		if data.turnAround > 0 then
			v.animationFrame = 0
			v.speedX = 0
			data.turnAround = data.turnAround - 1
		end
		if data.breakTimer >= data.pauseTime then
			data.breakTimer = data.pauseTime
		end
		
		if data.breakTimer <= 0 then --Make sure it doesn't go below 0.
			data.breakTimer = 0
		end
		
		if player and player.deathTimer == 0 then
			local distanceX = (player.x+(player.width /2))-(v.x+(v.width /2))
			local distanceY = (player.y+(player.height/2))-(v.y+(v.height/2))
			
			local distance = math.abs(distanceX)+math.abs(distanceY)
			
			if (distance < data.shootRadius and data.useRadius) or not data.useRadius then
				if data.breakTimer >= data.pauseTime and not v:mem(0x120, FIELD_BOOL) and data.turnAround <= 0 and data.leeway <= 0 then
					data.state = STATE_INRANGE
				end
			end
		end
	end
	
	if data.state == STATE_INRANGE then
		data.breakTimer = 0
		if data.followTheLeader then
			if data.shootTimer == 1 and not data.hasBeenHeld then --Check if the player is behind or in front of the NPC.
				if player.x > v.x then
					v.direction = 1
				elseif player.x < v.x then
					v.direction = -1
				end
			end
		end
		v.speedX = 0
		if data.shootTimer <= cfg.spitCharge then
			v.animationFrame = 4
		elseif data.shootTimer >= cfg.spitTime and data.shootTimer < data.spitShine then
			v.animationFrame = 5
		end
		if data.shootTimer == cfg.spitTime then
			spawnNPC(v, data, cfg)
			data.volleyCount = data.volleyCount + 1
		end
		if data.shootTimer >= data.spitShine then
			if data.volleyCount < data.volley then
				data.shootTimer = 0
			elseif data.volleyCount == data.volley then
				v.animationFrame = 0
			end
		end
		data.shootTimer = data.shootTimer + 1
		if data.shootTimer >= cfg.exitInRange then
			data.shootTimer = 0
			if v.heldIndex ~= 0 then
				data.volleyCount = 0
			elseif v.heldIndex == 0 then
				data.state = STATE_OUTRANGE
			end
		end
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = npcIDs.frames
	});
end

function bucketHead.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	local cfg = NPC.config[v.id]
	if not npcIDs[v.id] then
		data.state = STATE_OUTRANGE
		data.breakTimer = data.pauseTime
		data.shootTimer = 0
		return
	end
end

return bucketHead