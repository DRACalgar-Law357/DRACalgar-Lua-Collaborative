--[[
	
	CARRYABLE TORPEDO
	Custom SMBX2 NPC by KING DRACalgar Law
	Original GFX by Dr. Tapeworm

	-------------------------------
	BEHAVIOR
	- A carryable block that allows the player to swim through the water (and maybe the air) seamlessly (being able to stay afloat and move at a direction in a momentum).

	NPC CONFIG
	- floatSet = 0, -- 0 (able to float in the water), 1 (able to float in the air), 2 (able to float in both the air and the water)
	- maxswimspeedx = 5, -- The max speed at which the player should swim horizontally in the water
	- maxswimspeedy = 5, -- The max speed at which the player should swim vertically in the water
	- accelerationx = 0.1, -- How fast should the player be able to accelerate in the water horizontally
	- accelerationy = 0.1, -- How fast should the player be able to accelerate in the water vertically
	- frictionx = 0.1, -- The deacceleration the player should slow down horizontally when no keys has been held
	- frictiony = 0.1, -- The deacceleration the player should slow down vertically when no keys has been held
]]

--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local carryableTorpedo = {}

function carryableTorpedo.register(id)
	npcManager.registerEvent(id, carryableTorpedo, "onTickEndNPC")
	-- npcManager.registerEvent(id, carryableTorpedo, "onDrawNPC")
end

function carryableTorpedo.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.holdingKeys = false
		data.heldKeyX = 0 --0 (Neutral), 1 (Left), 2 (Right)
		data.heldKeyY = 0 --0 (Neutral), 1 (Up), 2 (Down)
		data.originSpeedY = 0
	end

	--Depending on the NPC, these checks must be handled differently

	
	-- Put main AI below here
	-- Code that makes the NPC friendly and makes it talk. This is a test for verifying that your code runs.
	-- NOTE: If you have no code to put here, comment out the registerEvent line for onTickNPC.

	if v.heldPlayer then
		local held = v.heldPlayer
		if (held.mem(0x36, FIELD_BOOL) == true and NPC.config[v.id].floatSet == 0) or (held.mem(0x36, FIELD_BOOL) == false and NPC.config[v.id].floatSet == 1) or (NPC.config[v.id].floatSet == 2) then
			if NPC.config[v.id].floatSet == 0 then
				data.originSpeedY = -Defines.player_grav
			elseif NPC.config[v.id].floatSet == 1 then
				data.originSpeedY = -Defines.player_grav
			elseif NPC.config[v.id].floatSet == 2 then
				if held.mem(0x36, FIELD_BOOL) == true then
					data.originSpeedY = -Defines.player_grav
				else
					data.originSpeedY = -Defines.player_grav
				end
			end
			if (held.keys.up or held.keys.down) then
				if data.holdingKeys == true and data.heldKeyY ~= 0  then
					--held.isOnGround = false
					if data.heldKeyY == 1 then
						if held.speedY > -NPC.config[v.id].maxswimspeedy then
							if held:mem(0x14A,FIELD_WORD) == 0 then
								held.speedY = held.speedY + data.originSpeedY - NPC.config[v.id].accelerationy
							else
								held.speedY = data.originSpeedY
							end
						end
					elseif data.heldKeyY == 2 then
						if held.speedY < NPC.config[v.id].maxswimspeedy then
							if held:mem(0x146,FIELD_WORD) == 0 then
								held.speedY = held.speedY + data.originSpeedY + NPC.config[v.id].accelerationy
							else
								held.speedY = data.originSpeedY
							end
						end
					end
				else
					data.holdingKeys = false
					data.heldKeyY = 0
				end
			end
			if (held.keys.left or held.keys.right) then
				if data.holdingKeys == true and data.heldKeyX ~= 0  then
					--held.isOnGround = false
					if data.heldKeyX == 1 then
						if held.speedX > -NPC.config[v.id].maxswimspeedx then
							if held:mem(0x14A,FIELD_WORD) == 0 then
								held.speedX = held.speedX - NPC.config[v.id].accelerationx
							else
								held.speedX = 0
							end
						end
					elseif data.heldKeyX == 2 then
						if held.speedX < NPC.config[v.id].maxswimspeedx then
							if held:mem(0x146,FIELD_WORD) == 0 then
								held.speedX = held.speedX + NPC.config[v.id].accelerationx
							else
								held.speedX = 0
							end
						end
					end
				else
					data.holdingKeys = false
					data.heldKeyX = 0
				end
			end

			if (held.keys.up == KEYS_PRESSED or held.keys.down == KEYS_PRESSED)
			and data.heldKeyY == 0 then
				if held.keys.up == KEYS_PRESSED then
					data.heldKeyY = 1
				elseif held.keys.down == KEYS_PRESSED then
					data.heldKeyY = 2
				end
			else
				data.heldKeyY = 0
			end
			if (held.keys.left == KEYS_PRESSED or held.keys.right == KEYS_PRESSED)
			and data.heldKeyX == 0 then
				if held.keys.left == KEYS_PRESSED then
					data.heldKeyX = 1
				elseif held.keys.right == KEYS_PRESSED then
					data.heldKeyX = 2
				end
			else
				data.heldKeyX = 0
			end
			if (data.heldKeyX ~= 0 or data.heldKeyY ~= 0) and data.holdingKeys == false then
				data.holdingKeys = true
			end

			if data.heldKeyY == 0 then
				if held.speedY < data.originSpeedY then
					held.speedY = math.clamp(held.speedY + NPC.config[v.id].frictiony + data.originSpeedY, -math.huge, data.originSpeedY)
				elseif held.speedY > data.originSpeedY then
					held.speedY = math.clamp(held.speedY - NPC.config[v.id].frictiony + data.originSpeedY, data.originSpeedY, math.huge)
				else
					held.speedY = data.originSpeedY
				end
			end
			if data.heldKeyX == 0 then
				if held.speedX < 0 then
					held.speedX = math.clamp(held.speedX + NPC.config[v.id].frictionx, -math.huge, 0)
				elseif held.speedX > 0 then
					held.speedX = math.clamp(held.speedX - NPC.config[v.id].frictionx, 0, math.huge)
				end
			end
		else
			data.heldKeyX = 0
			data.heldKeyX = 0
			data.holdingKeys = false
		end
	else

	end
	
	-- Animation frame handling
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = config.frames
		});
	end
end

-- function carryableTorpedo.onDrawNPC(v)
-- 	local data = v.data
-- end

--Gotta return the library table!
return carryableTorpedo