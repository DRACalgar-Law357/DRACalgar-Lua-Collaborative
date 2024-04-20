local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local warioNPC = {}
local npcIDs = {}

--Register events
function warioNPC.register(id)
	npcManager.registerEvent(id, warioNPC, "onTickNPC")
	npcManager.registerEvent(id, warioNPC, "onStartNPC")
	npcIDs[id] = true
end

function warioNPC.onInitAPI()
    registerEvent(warioNPC, "onNPCHarm")
end

function warioNPC.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	local config = NPC.config[v.id]
	if not npcIDs[v.id] then return end
	if (reason == HARM_TYPE_JUMP or reason == HARM_TYPE_TAIL or reason == HARM_TYPE_FROMBELOW) and config.transformID then
		if not config.stunned then
			v:transform(config.transformID)
		else
			v.speedY = -2
			data.stunTimer = 0
			v.speedX = -5 * math.sign(culprit.x + culprit.width/2 - v.x - v.width/2)
		end
		eventObj.cancelled = true
		SFX.play(9)
	end
end

local originWalkSpeed
local originRunSpeed

function warioNPC.onStartNPC(v)
	originWalkSpeed, originRunSpeed, originJumpHeight, originJumpBounce = Defines.player_walkspeed, Defines.player_runspeed
end

function warioNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local config = NPC.config[v.id]
	local data = v.data
	
	if v.heldIndex == 0 and not v.isProjectile then
		for _,p in ipairs(Player.get()) do
			if Colliders.collide(p, v) then
				if not config.stunned and not config.cantPush then
					if (p.character == 7 or p.character == 8) and not config.bigEnemy then
						v:transform(config.transformID)
						SFX.play(9)
						v.speedX = -5 * math.sign(p.x + p.width/2 - v.x - v.width/2)
						v.speedY = -2
					else
						--An empty data variable, do whatever you want with it
						data.isBumped = true
					end
				else
					if v.collidesBlockBottom then
						SFX.play(9)
						v.speedX = -5 * math.sign(p.x + p.width/2 - v.x - v.width/2)
						v.speedY = -2
					end
				end
			end
		end
		
		--When flipped over, flip back up after a bit
		if config.stunned then
			data.stunTimer = data.stunTimer or 0
			data.stunTimer = data.stunTimer + 1
			if v.speedX ~= 0 then
				data.stunTimer = 0
			end
			if v.collidesBlockBottom then
				v.speedX = v.speedX * 0.5
				if math.abs(v.speedX) <= 0.1 then
					v.speedX = 0
				end
			end
			if config.stunTime > -1 then
				if data.stunTimer >= config.stunTime - 64 then
					data.x = data.x or 0
					if data.x == 0 then
						v.x = v.x + 2
						data.x = 1
					else
						v.x = v.x - 2
						data.x = 0
					end
					if data.stunTimer >= config.stunTime then
						v:transform(config.transformID)
						data.stunTimer = 0
					end
				end
				if v.underwater then v:kill(HARM_TYPE_NPC) end
			end
		end
	else
		data.stunTimer = 0
		
		--Bit of code taken from IAmPlayer
		
		if config.bigEnemy then
			if player.holdingNPC and v.id == player.holdingNPC.id then
				Defines.player_walkspeed = originWalkSpeed / 1.5
				Defines.player_runspeed = originRunSpeed / 1.5
			else
				Defines.player_walkspeed = originWalkSpeed
				Defines.player_runspeed = originRunSpeed
			end
		end
		
		if config.bigEnemy and (v.isProjectile and (v.collidesBlockLeft or v.collidesBlockRight)) then
			v:harm(HARM_TYPE_NPC)
		end
	end
end

return warioNPC