local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local playerStun = require("playerstun")
local colliders = require("colliders")
local particles = require("particles")
local NPCBodyguards = {}
local npcIDs = {}

local healEffect = Misc.resolveFile("bodyguard_parts/p_heal.ini")

--Configs table are available to adjust/customize your NPCBodyguards NPC...






function NPCBodyguards.register(id)
	npcManager.registerEvent(id, NPCBodyguards, "onTickEndNPC")
	npcManager.registerEvent(id, NPCBodyguards, "onDrawNPC")
	npcIDs[id] = true
end
function NPCBodyguards.onInitAPI()
    registerEvent(NPCBodyguards, "onNPCHarm")
	registerEvent(NPCBodyguards, "onTick", "onTick", false)
	registerEvent(NPCBodyguards, "onDraw", "onDraw", false)
end
local particleList = {}
local repulseList = {}

NPCBodyguards.healSpeed = RNG.randomInt(-4,4)
NPCBodyguards.healSpread = 100

local function falloff(t)
	return 1
end

function NPCBodyguards.addRepulsionField(x,y)
	local f = particles.PointField(x,y,200,2000,falloff)
	
	for _,v in ipairs(particleList) do
		f:addEmitter(v.effect, false)
	end
	
	table.insert(repulseList, {f,12})
end

function NPCBodyguards.onTick()
	
	local i = 1
	while i <= #repulseList do
	
		if repulseList[i][2] > 0 then
			repulseList[i][2] = repulseList[i][2]-1
			i = i+1
		else
		
			for _,v in ipairs(particleList) do
				repulseList[i][1]:removeEmitter(v.effect)
			end
			
			table.remove(repulseList,i)
			
		end
		
	end
end

function NPCBodyguards.onDraw()
	local i = 1
	while i <= #particleList do
	
		particleList[i].effect:Draw(-5)
		
		if not particleList[i].npc.isValid then
			particleList[i].effect.enabled = false;
			if particleList[i].effect:Count() == 0 then
				particleList[i].effect:Destroy()
				table.remove(particleList,i)
			else
				i = i+1
			end
		else
			i = i+1
		end
		
	end
end

function NPCBodyguards.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local vx = v.x + v.width/2
	local vy = v.y + v.height/2
	data.provokeBox = Colliders.Box(v.x - (v.width * 2), v.y - (v.height * 1.5), NPC.config[v.id].provokeRangeX, NPC.config[v.id].provokeRangeY)
	data.provokeBox.x = vx - NPC.config[v.id].provokeRangeX/2
	data.provokeBox.y = vy - NPC.config[v.id].provokeRangeY/2
	data.attackBox = Colliders.Box(v.x - (v.width * 2), v.y - (v.height * 1.5), NPC.config[v.id].attackRangeX, NPC.config[v.id].attackRangeY)
	data.attackBox.x = vx - NPC.config[v.id].attackRangeX/2
	data.attackBox.y = vy - NPC.config[v.id].attackRangeY/2
	data.meleeBox = Colliders.Box(v.x - (v.width * 2), v.y - (v.height * 1.5), NPC.config[v.id].meleeRangeX, NPC.config[v.id].meleeRangeY)
	data.meleeBox.x = vx - NPC.config[v.id].meleeRangeX/2
	data.meleeBox.y = vy - NPC.config[v.id].meleeRangeY/2
	local throwSpawnOffset = {
		[1] = NPC.config[v.id].width / 2 + NPC.config[v.id].throwXR,
		[-1] = NPC.config[v.id].width / 2 + NPC.config[v.id].throwXL
		}
	local lowShotSpawnOffset = {
		[-1] = NPC.config[v.id].width / 2 + NPC.config[v.id].lowShootXL,
		[1] = NPC.config[v.id].width / 2 + NPC.config[v.id].lowShootXR
		}
	local highShotSpawnOffset = {
		[-1] = NPC.config[v.id].width / 2 + NPC.config[v.id].highShootXL,
		[1] = NPC.config[v.id].width / 2 + NPC.config[v.id].highShootXR
		}
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		data.hurtTimer = 0
		data.state = 0
		data.stunned = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true

		if settings.rush == nil then
			settings.rush = true
		end
		if settings.smoke == nil then
			settings.smoke = false
		end
		if settings.fragmentation == nil then
			settings.fragmentation = false
		end
		if settings.shoot == nil then
			settings.shoot = false
		end
		if settings.punch == nil then
			settings.punch = false
		end
		if settings.backup == nil then
			settings.backup = false
		end
		if settings.patch == nil then
			settings.patch = false
		end
		settings.backupID = settings.backupID or 1
		settings.backupX = settings.backupX or 0
		settings.backupY = settings.backupY or 0
		settings.backupFrequency = settings.backupFrequency or 32
		settings.backupAmount = settings.backupAmount or 1
		settings.backupDirection = settings.backupDirection or -1
		settings.shootSet = settings.shootSet or 0
		settings.punchSet = settings.punchSet or 0
		settings.walkDelay = settings.walkDelay or 48
		settings.hp = settings.hp or 9

		data.timer = data.timer or 0
		data.walkTimer = data.walkTimer or 0
		data.hurtTimer = data.hurtTimer or 0
		data.state = data.state or 0
		data.iFrames = false
		data.health = settings.hp
		data.firing = false
		data.provokeTimer = 0
		data.backupFlag = false
		data.patchFlag = false
		data.stunned = false
		data.poof = 0
		data.movementRNG = 0
		data.cooldown = 0
		
		data.smokeOffset = 0
		data.fragOffset = 0
		data.thrownFrames = 0
	end
	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then

	end
	if data.provokeTimer > 0 then
		data.provokeTimer = data.provokeTimer - 1
	end
	if data.cooldown > 0 then
		data.cooldown = data.cooldown - 1
	end
	data.timer = data.timer + 1
	if (v.collidesBlockLeft or v.collidesBlockRight) and (data.state ~= 1 and data.state ~= 5 and data.state ~= 8) then
		v.direction = -v.direction
	end
	if v.collidesBlockBottom then
		data.stunned = false
	end
	if data.stunned == false then
		if data.state == 0 then
			if v.dontMove == false then
				if v.collidesBlockBottom then
					data.walkTimer = data.walkTimer + 1
							
					v.speedX = NPC.config[v.id].walkSpeed * v.direction
					if data.walkTimer == settings.walkDelay then
						data.walkTimer = -settings.walkDelay
						v.direction = v.direction * -1
					end
					if Colliders.collide(plr,data.provokeBox) and data.provokeTimer <= 0 then
						data.state = 1
						data.walkTimer = 0
						data.timer = 0
						npcutils.faceNearestPlayer(v)
						data.provokeTimer = NPC.config[v.id].provokeDelay
						if NPC.config[v.id].noticeSoundID then
							SFX.play(NPC.config[v.id].noticeSoundID)
						end
					end
				else
					v.speedX = 0
				end
			else
				data.state = 1
				v.speedX = 0
			end
		elseif data.state == 1 then
			if data.provokeTimer <= 0 then
				if v.dontMove == false then
					if Colliders.collide(plr,data.provokeBox) then
						data.provokeTimer = NPC.config[v.id].provokeDelay
						npcutils.faceNearestPlayer(v)
					else
						data.walkTimer = 0
						data.state = 0
						data.timer = 0
					end
				end
				if ((Colliders.collide(plr,data.attackBox) and v.dontMove == false) or (Colliders.collide(plr,data.provokeBox) and v.dontMove == true)) and data.cooldown <= 0 then
					data.timer = 0
					data.walkTimer = 0
					v.ai2 = 0
					v.ai1 = 0
					v.ai3 = 0
					local options = {}
					if settings.rush == true and Colliders.collide(plr,data.meleeBox) then
						table.insert(options, 8)
					end
					if settings.smoke == true then
						table.insert(options, 2)
					end
					if settings.fragmentation == true then
						table.insert(options, 3)
					end
					if settings.shoot == true then
						table.insert(options, 4)
					end
					if settings.punch == true and Colliders.collide(plr,data.meleeBox) then
						table.insert(options, 5)
					end
					if settings.backup == true and data.backupFlag == false then
						table.insert(options, 6)
					end
					if data.health > settings.hp * NPC.config[v.id].patchActivePortion then
						if #options > 0 then
							data.state = RNG.irandomEntry(options)
						end
					else
						if settings.patch == true and data.patchFlag == false then
							data.state = 7
							data.patchFlag = true
						else
							if #options > 0 then
								data.state = RNG.irandomEntry(options)
							end
						end
					end
					npcutils.faceNearestPlayer(v)
					v.speedX = 0
					data.cooldown = NPC.config[v.id].cooldownTimer
				end
			end
			if v.dontMove == false then
				if data.timer % 32 == 16 then
					data.movementRNG = RNG.randomInt(0,4)
				end
				if data.movementRNG == 2 then
					v.speedX = NPC.config[v.id].chaseSpeed * -v.direction
				elseif data.movementRNG == 3 then
					v.speedX = 0
				else
					v.speedX = NPC.config[v.id].chaseSpeed * v.direction
				end

				if v.collidesBlockBottom and (v.collidesBlockLeft or v.collidesBlockRight) then
					v.speedY = -NPC.config[v.id].jumpHeight
				end
			end
		elseif data.state == 2 or data.state == 3 then
			if v.ai2 == 0 then
				v.speedX = 0
				if (data.timer >= NPC.config[v.id].smokeDelay and data.state == 2) or (data.timer >= NPC.config[v.id].fragDelay and data.state == 3) then
					data.timer = 0
					v.ai2 = 0
					local n
					if data.state == 2 then
						if NPC.config[v.id].smokeGrenadeSoundID then
							SFX.play(NPC.config[v.id].smokeGrenadeSoundID)
						end
						n = NPC.spawn(NPC.config[v.id].smokeGrenade, v.x + throwSpawnOffset[v.direction], vy + NPC.config[v.id].throwY, player.section, false)
						n.speedY = -NPC.config[v.id].smokeSpeedY
						--Bit of code here by Murphmario, aim to where the player is
						local bombxspeed = vector.v2(plr.x + 0.5 * plr.width - (v.x + 0.5 * v.width))
						n.speedX = bombxspeed.x / NPC.config[v.id].smokeSpeedXRestrict
						data.timer = 0
						if (v.direction == -1 and n.speedX > -1) or (v.direction == 1 and n.speedX < 1) then
							n.speedX = 1 * v.direction
						end
					else
						if NPC.config[v.id].fragGrenadeSoundID then
							SFX.play(NPC.config[v.id].fragGrenadeSoundID)
						end
						n = NPC.spawn(NPC.config[v.id].fragGrenade, v.x + throwSpawnOffset[v.direction], vy + NPC.config[v.id].throwY, player.section, false)
						n.speedY = -NPC.config[v.id].fragSpeedY
						--Bit of code here by Murphmario, aim to where the player is
						local bombxspeed = vector.v2(plr.x + 0.5 * plr.width - (v.x + 0.5 * v.width))
						n.speedX = bombxspeed.x / NPC.config[v.id].fragSpeedXRestrict
						data.timer = 0
						if (v.direction == -1 and n.speedX > -1) or (v.direction == 1 and n.speedX < 1) then
							n.speedX = 1 * v.direction
						end
					end
					v.ai2 = 1
				end
			else
				v.speedX = 0
				if (data.timer >= NPC.config[v.id].smokeLag and data.state == 2) or (data.timer >= NPC.config[v.id].fragLag and data.state == 3) then
					v.ai2 = 0
					if Colliders.collide(plr,data.provokeBox) and data.provokeTimer <= 0 then
						data.state = 1
						npcutils.faceNearestPlayer(v)
						data.provokeTimer = NPC.config[v.id].provokeDelay
					else
						data.state = 0
					end
					data.walkTimer = 0
					data.timer = 0
				end
			end
		elseif data.state == 4 then
			if v.ai2 == 0 then
				v.speedX = 0
				npcutils.faceNearestPlayer(v)
				if data.timer >= 2 then
					data.timer = 0
					local options = {}
					if settings.shootSet <= 1 then
						table.insert(options, 1)
					end
					if (settings.shootSet == 0 or settings.shootSet == 2) then
						table.insert(options, 2)
					end
					if #options > 0 then
						v.ai2 = RNG.irandomEntry(options)
						v.ai3 = v.ai2
					end
				end
			elseif v.ai2 == 1 or v.ai2 == 2 then
				v.speedX = 0
				if (v.ai2 == 1 and v.ai1 >= NPC.config[v.id].lowShootDuration) or (v.ai2 == 2 and v.ai1 >= NPC.config[v.id].highShootDuration) then
					v.ai1 = 0
					v.ai2 = 3
					data.timer = 0
				end
				if (data.timer >= NPC.config[v.id].lowShootDelayBetweenShots and v.ai2 == 1) or (data.timer >= NPC.config[v.id].highShootDelayBetweenShots and v.ai2 == 2) then
					data.timer = 0
					if (v.ai2 == 1 and v.ai1 < NPC.config[v.id].lowShootDuration) or (v.ai2 == 2 and v.ai1 < NPC.config[v.id].highShootDuration) then
						v.ai1 = v.ai1 + 1
						local p
						if v.ai2 == 1 then
							if NPC.config[v.id].lowShotSoundID then
								SFX.play(NPC.config[v.id].lowShotSoundID)
							end
							for i=1,NPC.config[v.id].lowShotSpawnConsecutive do
								p = NPC.spawn(NPC.config[v.id].lowShot, v.x + lowShotSpawnOffset[v.direction], vy + NPC.config[v.id].lowShootY, player.section, false)
								p.direction = v.direction
								p.speedX = RNG.random(NPC.config[v.id].lowShootSpeedXMin,NPC.config[v.id].lowShootSpeedXMax) * v.direction
								p.speedY = RNG.random(NPC.config[v.id].lowShootSpeedYMin,NPC.config[v.id].lowShootSpeedYMax)
							end
						else
							if NPC.config[v.id].highShotSoundID then
								SFX.play(NPC.config[v.id].highShotSoundID)
							end
							for i=1,NPC.config[v.id].highShotSpawnConsecutive do
								p = NPC.spawn(NPC.config[v.id].highShot, v.x + highShotSpawnOffset[v.direction], vy + NPC.config[v.id].highShootY, player.section, false)
								p.direction = v.direction
								p.speedX = RNG.random(NPC.config[v.id].highShootSpeedXMin,NPC.config[v.id].highShootSpeedXMax) * v.direction
								p.speedY = RNG.random(NPC.config[v.id].highShootSpeedYMin,NPC.config[v.id].highShootSpeedYMax)
							end
						end
					end
				end
			else
				v.speedX = 0
				if (v.ai3 == 1 and data.timer >= NPC.config[v.id].lowShootLag) or (v.ai3 == 2 and data.timer >= NPC.config[v.id].highShootLag) then
					v.ai2 = 0
					v.ai3 = 0
					v.ai1 = 0
					if Colliders.collide(plr,data.provokeBox) and data.provokeTimer <= 0 then
						data.state = 1
						npcutils.faceNearestPlayer(v)
						data.provokeTimer = NPC.config[v.id].provokeDelay
					else
						data.state = 0
					end
					data.walkTimer = 0
					data.timer = 0
				end
			end
		elseif data.state == 5 then
			if v.ai3 == 0 then
				if data.timer == 1 then
					v.speedX = 0
					npcutils.faceNearestPlayer(v)
					if NPC.config[v.id].telegraphSoundID then
						SFX.play(NPC.config[v.id].telegraphSoundID)
					end
					if settings.punchSet == 0 then
						v.ai2 = RNG.irandomEntry{0,1}
						if v.ai2 == 0 then
							Animation.spawn(80,vx, v.y + v.height/4 + v.height/2)
						else
							Animation.spawn(80,vx, v.y + v.height/4)
						end
					elseif settings.punchSet == 1 then
						v.ai2 = 0
						Animation.spawn(80,vx, v.y + v.height/4 + v.height/2)
					else
						v.ai2 = 1
						Animation.spawn(80,vx, v.y + v.height/4)
					end
					
				end
				if data.timer == NPC.config[v.id].punchDelay then
					if NPC.config[v.id].punchSoundID then
						SFX.play(NPC.config[v.id].punchSoundID)
					end
					if v.ai2 == 0 then
						v.speedX = NPC.config[v.id].punchXSpeedGrounded * v.direction
					else
						v.speedX = NPC.config[v.id].punchXSpeedMidair * v.direction
					end
				end
				if data.timer > NPC.config[v.id].punchDelay then
					v.speedX = v.speedX - NPC.config[v.id].punchFriction * v.direction
					if v.collidesBlockLeft or v.collidesBlockRight then
						v.speedX = 0
					end
					if math.abs(v.speedX) <= 0.5 then
						v.ai2 = 0
						v.ai3 = 1
						v.ai1 = 0
						data.timer = 0
					end
				end
				if data.timer == NPC.config[v.id].punchMidairDelay and v.ai2 == 1 and v.collidesBlockBottom then
					v.speedY = -NPC.config[v.id].punchYSpeed
				end
			else
				v.speedX = 0
				if data.timer >= NPC.config[v.id].punchLag then
					v.ai2 = 0
					v.ai3 = 0
					v.ai1 = 0
					if Colliders.collide(plr,data.provokeBox) and data.provokeTimer <= 0 then
						data.state = 1
						npcutils.faceNearestPlayer(v)
						data.provokeTimer = NPC.config[v.id].provokeDelay
					else
						data.state = 0
					end
					data.walkTimer = 0
					data.timer = 0
				end
			end
		elseif data.state == 6 then
			v.speedX = 0
			if v.ai2 == 0 then
				if data.timer == 1 and NPC.config[v.id].backupSoundID then
					SFX.play(NPC.config[v.id].backupSoundID)
				end
				if data.timer >= NPC.config[v.id].backupDelay then
					v.ai2 = 1
					data.timer = 0
					Routine.setFrameTimer(settings.backupFrequency, (function() 
						local p = NPC.spawn(settings.backupID, v.spawnX + v.width/2 + settings.backupX, v.spawnY + v.height/2 + settings.backupY)
						p.direction = settings.backupDirection
						Animation.spawn(10,p.x,p.y)
						data.poof = data.poof + 1
						end), settings.backupAmount, false)
					if NPC.config[v.id].spawnSoundID then
						SFX.play(NPC.config[v.id].spawnSoundID)
					end
					data.poof = 0
					data.backupFlag = true
				end
			else
				if data.timer >= NPC.config[v.id].backupLag then
					v.ai2 = 0
					v.ai3 = 0
					v.ai1 = 0
					if Colliders.collide(plr,data.provokeBox) and data.provokeTimer <= 0 then
						data.state = 1
						npcutils.faceNearestPlayer(v)
						data.provokeTimer = NPC.config[v.id].provokeDelay
					else
						data.state = 0
					end
					data.walkTimer = 0
					data.timer = 0
				end
			end
		elseif data.state == 7 then
			if data.timer % NPC.config[v.id].patchDelay == 0 then
				data.health = math.clamp(data.health + NPC.config[v.id].patchRestore, 0, settings.hp)
				SFX.Play("bodyguard_parts/heal.wav")

				for _,p in ipairs(Player.get()) do
					if p:mem(0x164,FIELD_WORD) == 2 then
						NPCBodyguards.addRepulsionField(p.x+p.width*0.5, p.y + p.height*0.5)
					end
					
				end

				data.xSpeed = RNG.random(-100,100)
				if data.heal == nil then
					data.heal = particles.Emitter(v.x+v.width*0.5, v.y+v.height*0.5,healEffect)
					
					table.insert(particleList, {npc = v, effect = data.heal})
					
					data.heal:Attach(v, false, true, -1)
					
				end
				
				if data.heal.isValid then
					data.heal.enabled = true
				end
				
				if NPCBodyguards.healSpread ~= nil then
					data.heal:setParam("speedX", v.data.xSpeed)
					data.heal:setParam("speedY", "-"..NPCBodyguards.healSpread..":"..NPCBodyguards.healSpread)
				end
			end

			if data.health >= settings.hp then
				data.state = 0
				data.timer = 0
				data.walkTimer = 0
			end
			v.speedX = 0
			npcutils.faceNearestPlayer(v)
		elseif data.state == 8 then
			if v.ai2 == 0 then
				v.speedX = 0
				if data.timer >= NPC.config[v.id].rushDelay then
					if NPC.config[v.id].rushSoundID then
						SFX.play(NPC.config[v.id].rushSoundID)
					end
					data.timer = 0
					v.ai2 = 1
				end
			elseif v.ai2 == 1 then
				v.speedX = NPC.config[v.id].rushSpeed * v.direction
				if data.timer >= NPC.config[v.id].rushDuration or v.collidesBlockLeft or v.collidesBlockRight then
					data.timer = 0
					v.ai2 = 2
				end
			else
				v.speedX = 0
				if data.timer >= NPC.config[v.id].rushLag then
					v.ai2 = 0
					v.ai3 = 0
					v.ai1 = 0
					v.speedX = 0
					if Colliders.collide(plr,data.provokeBox) and data.provokeTimer <= 0 then
						data.state = 1
						npcutils.faceNearestPlayer(v)
						data.provokeTimer = NPC.config[v.id].provokeDelay
					else
						data.state = 0
					end
					data.walkTimer = 0
					data.timer = 0
				end
			end
		end
	end
	if data.heal ~= nil then
		if data.timer % 64 == 32 then
			if data.heal.isValid then
				data.heal.enabled = false
			end
			data.heal = nil
		end
	end
	--Make it invincible for a little bit
	if data.iFrames then
		v.friendly = true
		data.hurtTimer = data.hurtTimer + 1
	    if data.hurtTimer == 1 and NPC.config[v.id].hurtSoundID then 
	        SFX.play(NPC.config[v.id].hurtSoundID)
	    end
		if v.collidesBlockBottom and (data.state == 6 or data.state == 7) then
			if data.hurtTimer == 1 then
				v.speedY = -5
				v.speedX = RNG.irandomEntry{1,2.5} * -v.direction
				data.stunned = true
				data.timer = 0
				data.walkTimer = 0
				if NPC.config[v.id].stunSoundID then
					SFX.play(NPC.config[v.id].stunSoundID)
				end
				data.state = 1
			end
	    end
		if data.hurtTimer % 8 <= 4 and data.hurtTimer > 8 then
			v.animationFrame = -50
		else

		end
		if data.hurtTimer >= NPC.config[v.id].harmDelay then
			v.friendly = false
			data.iFrames = false
			data.hurtTimer = 0
		end
	end
	
	--Prevent them from not turning around from other NPCs
	if v:mem(0x120, FIELD_BOOL) and not (v.collidesBlockLeft or v.collidesBlockRight) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	

end

function NPCBodyguards.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if not npcIDs[v.id] then return end
	if reason ~= HARM_TYPE_LAVA then
		if reason == HARM_TYPE_JUMP or killReason == HARM_TYPE_SPINJUMP or killReason == HARM_TYPE_FROMBELOW then
			SFX.play(2)
			data.iFrames = true
			data.health = data.health - NPC.config[v.id].hpHardHit
		elseif reason == HARM_TYPE_SWORD then
			if v:mem(0x156, FIELD_WORD) <= 0 then
				data.health = data.health - NPC.config[v.id].hpHardHit
				data.iFrames = true
				SFX.play(89)
				v:mem(0x156, FIELD_WORD,20)
			end
			if Colliders.downSlash(player,v) then
				player.speedY = -6
			end
	    elseif reason == HARM_TYPE_NPC then
	        local fromFireball = (culprit and culprit.__type == "NPC" and culprit.id == 13 )
	        if fromFireball then
			    data.health = data.health - NPC.config[v.id].hpSoftHit
			    SFX.play(9)
			else
			    data.health = data.health - NPC.config[v.id].hpHardHit
			    data.iFrames = true
			end
		elseif reason == HARM_TYPE_LAVA and v ~= nil then
			v:kill(HARM_TYPE_OFFSCREEN)
		elseif v:mem(0x12, FIELD_WORD) == 4 then
			v:kill(HARM_TYPE_OFFSCREEN)
		else
			data.iFrames = true
			data.health = data.health - NPC.config[v.id].hpHardHit
		end
		if culprit then
			if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
				culprit:kill(HARM_TYPE_NPC)
			elseif culprit.__type == "Player" then
				--Bit of code taken from the basegame chucks
				if (culprit.x + 0.5 * culprit.width) < (v.x + v.width*0.5) then
					culprit.speedX = -6
				else
					culprit.speedX = 6
				end
			elseif type(culprit) == "NPC" and (NPC.HITTABLE_MAP[culprit.id] or culprit.id == 45) and culprit.id ~= 50 and v:mem(0x138, FIELD_WORD) == 0 then
				culprit:kill(HARM_TYPE_NPC)
			end
		end
		if data.health > 0 then
			v:mem(0x156,FIELD_WORD,60)
			eventObj.cancelled = true
		else
			if NPC.config[v.id].killSoundID then
			    SFX.play(NPC.config[v.id].killSoundID)
			end
		end
	else
		v:kill(HARM_TYPE_LAVA)
	end
end

function NPCBodyguards.onDrawNPC(v)
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local vx = v.x + v.width/2
	local vy = v.y + v.height/2
	local throwSpawnOffset = {
		[1] = NPC.config[v.id].width / 2 + NPC.config[v.id].throwXR,
		[-1] = NPC.config[v.id].width / 2 + NPC.config[v.id].throwXL
		}
	local shotSpawnOffset = {
		[-1] = NPC.config[v.id].width / 2 - 16,
		[1] = NPC.config[v.id].width / 2 + 16
		}
	npcutils.restoreAnimation(v)
	walk = npcutils.getFrameByFramestyle(v, {
		frames = NPC.config[v.id].walkFrames,
		gap = NPC.config[v.id].holdFrames + NPC.config[v.id].throwFrames + NPC.config[v.id].highShotFrames + NPC.config[v.id].lowShotFrames + NPC.config[v.id].backupFrames + NPC.config[v.id].patchFrames,
		offset = 0
	})
	hold = npcutils.getFrameByFramestyle(v, {
		frames = NPC.config[v.id].holdFrames,
		gap = NPC.config[v.id].throwFrames + NPC.config[v.id].highShotFrames + NPC.config[v.id].lowShotFrames + NPC.config[v.id].backupFrames + NPC.config[v.id].patchFrames,
		offset = NPC.config[v.id].walkFrames
	})
	throw = npcutils.getFrameByFramestyle(v, {
		frames = NPC.config[v.id].throwFrames,
		gap = NPC.config[v.id].highShotFrames + NPC.config[v.id].lowShotFrames + NPC.config[v.id].backupFrames + NPC.config[v.id].patchFrames,
		offset = NPC.config[v.id].walkFrames + NPC.config[v.id].holdFrames
	})
	highshot = npcutils.getFrameByFramestyle(v, {
		frames = NPC.config[v.id].highShotFrames,
		gap = NPC.config[v.id].lowShotFrames + NPC.config[v.id].backupFrames + NPC.config[v.id].patchFrames,
		offset = NPC.config[v.id].walkFrames + NPC.config[v.id].holdFrames + NPC.config[v.id].throwFrames
	})
	lowshot = npcutils.getFrameByFramestyle(v, {
		frames = NPC.config[v.id].lowShotFrames,
		gap = NPC.config[v.id].backupFrames + NPC.config[v.id].patchFrames,
		offset = NPC.config[v.id].walkFrames + NPC.config[v.id].holdFrames + NPC.config[v.id].throwFrames + NPC.config[v.id].highShotFrames
	})
	backup = npcutils.getFrameByFramestyle(v, {
		frames = NPC.config[v.id].backupFrames,
		gap = NPC.config[v.id].patchFrames,
		offset = NPC.config[v.id].walkFrames + NPC.config[v.id].holdFrames + NPC.config[v.id].throwFrames + NPC.config[v.id].highShotFrames + NPC.config[v.id].lowShotFrames
	})
	patch = npcutils.getFrameByFramestyle(v, {
		frames = NPC.config[v.id].patchFrames,
		gap = 0,
		offset = NPC.config[v.id].walkFrames + NPC.config[v.id].holdFrames + NPC.config[v.id].throwFrames + NPC.config[v.id].highShotFrames + NPC.config[v.id].lowShotFrames + NPC.config[v.id].backupFrames
	})

    if data.state == 3 or data.state == 2 then
		if v.ai2 == 0 then
			v.animationFrame = hold
							

				local heldNPC
				if data.state == 2 then
					heldNPC = NPC.config[v.id].smokeGrenade
				else
					heldNPC = NPC.config[v.id].fragGrenade
				end
			
				if v.direction == 1 then
					if NPC.config[heldNPC].framestyle ~= 0 then
						data.thrownFrames = NPC.config[heldNPC].frames
					end
				else
					data.thrownFrames = 0
				end
			
				Graphics.draw{
					type = RTYPE_IMAGE,
					image = Graphics.sprites.npc[heldNPC].img, 
					x = v.x + throwSpawnOffset[v.direction],
					y = vy + NPC.config[v.id].throwY,
					sceneCoords = true,
					sourceX = 0, 
					sourceY = NPC.config[heldNPC].gfxheight * data.thrownFrames, 
					sourceWidth = NPC.config[heldNPC].gfxwidth,
					sourceHeight = NPC.config[heldNPC].gfxheight,
					priority = -44
				}

		else
			v.animationFrame = throw
		end
    elseif data.state == 0 or data.state == 1 then
		v.animationFrame = walk
	elseif data.state == 4 then
		if v.ai2 == 0 then
			v.animationFrame = walk
		elseif v.ai2 == 1 then
			v.animationFrame = lowshot
		elseif v.ai2 == 2 then
			v.animationFrame = highshot
		else
			v.animationFrame = walk
		end
	elseif data.state == 5 then
		if v.ai3 == 0 then
			if data.timer < NPC.config[v.id].punchDelay then
				v.animationFrame = walk
			else
				v.animationFrame = throw
			end
		else
			v.animationFrame = walk
		end
	elseif data.state == 6 then
		v.animationFrame = backup
	elseif data.state == 7 then
		v.animationFrame = patch
	elseif data.state == 8 then
		v.animationFrame = walk
	elseif data.state == 9 then
		v.animationFrame = walk
    end
	if data.hurtTimer % 8 < 4 and data.iFrames then
		npcutils.hideNPC(v)
	end
end

--Gotta return the library table!
return NPCBodyguards