local rng = require("rng")
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
local waddledoo = {}

local npcID = NPC_ID

npcManager.setNpcSettings{
	id = npcID,
	width = 60,
	height = 60,
	gfxheight = 64,
	gfxwidth = 60,
	framestyle = 1,
	frames = 5,
	framespeed = 8,
	speed = 1,
	score = 4,
	nofireball = false,
	noiceball = true,
	noyoshi = true,
	-- ultra-configurable beam stuff!
	beamlength = 6,
	beamanglestart = 0,
	beamangleend = 150,
	beamanglestartfloat = 10,
	beamangleendfloat = 210,
	walktime = 240,
	ramtime = 220,
	idletime = 65,
	speedIncrease = 4.5,
	walkspeed = 2.5,
	shoottime = 75,
	chargetime = 60,
	jumptime = 40,
	jumpheight = 8,
	highjumpheight = 11,
	beamtime = 80,
	sparkspawndelay = 0.3,
	sparkkilldelay = 0.1,
	sparkid = 796,
	beamid = 792,
	elecid = 794,
	starID = 782,
	shootspeed = 6,
	hp = 40
}

npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_NPC, HARM_TYPE_FROMBELOW, HARM_TYPE_HELD, HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA, HARM_TYPE_PROJECTILE_USED}, 
	{
		[HARM_TYPE_NPC] = 856
	}
)

--Waddle Doo States
local STATE_IDLE = 0
local STATE_WALK = 1
local STATE_CHARGE = 2
local STATE_BEAM = 3
local STATE_HOP = 4
local STATE_RAM = 5
local STATE_DONE_RAM = 6
local STATE_JUMP_TO_BEAM = 7
local STATE_SHOOT = 8
local STATE_LOB = 9
local STATE_SHOWER = 10
local STATE_KILL = 11

local sfx_beamstart = Misc.resolveSoundFile("doo-beam-start")
local sfx_beamloop = Misc.resolveSoundFile("doo-beam")
local sfx_bosshurt = Misc.resolveFile("Kirby Enemy Hit.wav")
local sfx_bossdefeat = Misc.resolveFile("Boss Dead.wav")

local loopingSounds = {}



function waddledoo.onInitAPI()
	registerEvent(waddledoo, "onNPCHarm")
	npcManager.registerEvent(npcID, waddledoo, "onTickEndNPC", "onTickEndDoo")
	npcManager.registerEvent(npcID, waddledoo, "onDrawNPC", "onDrawDoo")
end

function waddledoo.onNPCHarm(eventObj, killedNPC, killReason)
	if killedNPC.id == npcID then
		local data = killedNPC.data
		if data and data.sparkList then
			for _,v in ipairs(data.sparkList) do
				v:kill()
			end
		end
	end
end

-- Doo Functions & Events



local function getBeamPos(v, step, angle)
	local bv = vector(0, step*-32 + NPC.config[v.id].height/2):rotate(angle)
	return {x = (bv.x+16)*v.direction + (v.x + v.width/2) + v.speedX, y = bv.y + (v.y + v.height/2) + v.speedY}
end

local function changeState(v, newState)
	local data = v.data
	data.stateTimer = 0
	data.state = newState
	data.sparkCooldown = 0
	data.sparkOffset = 0
	if newState ~= STATE_BEAM then
		for i=#data.sparkList, 1, -1 do
			if data.sparkList[i].isValid then
				data.sparkList[i]:kill()
			end
		end
		data.sparkList = {}
		if data.sound and data.sound.isValid and data.sound:isPlaying() then data.sound:Stop() end
		data.sound = nil
	end
end

local function harmEnemies(v, sparp)
	if v:mem(0x12E, FIELD_WORD) == 30 and Player(v:mem(0x130, FIELD_WORD)).character ~= CHARACTER_LINK then
		
		for _,n in ipairs(Colliders.getColliding{a=sparp, b=NPC.HITTABLE, btype=Colliders.NPC}) do
			if (not n.friendly) and (not n.isHidden) and (n.id ~= sparp.id) and (n.idx ~= v.idx) and (Colliders.collide(sparp, n)) then
				n:harm(HARM_TYPE_NPC)
			end
		end
	else

	end
end

function waddledoo.onTickEndDoo(v)
	if Defines.levelFreeze then return end
	local data = v.data
	local cfg = NPC.config[v.id]
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.stateTimer = 0
		data.hurtTimer = 0
		return
	end
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_IDLE
		data.stateTimer = 0
		data.sparkCooldown = 0
		data.sparkList = {}
		data.hasBeenHeld = false
		data.sparkOffset = 0
		data.floating = false
		data.health = NPC.config[v.id].hp
		data.state = STATE_IDLE
		data.stateLimit = 0
		data.iFrames = false
		data.beamConsecutive = 1
		data.lobConsecutive = 0
		data.hurtTimer = data.hurtTimer or 0
	end
	local spawnOffset = {
		[-1] = -8,
		[1] = cfg.width + 8
	}
	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_IDLE
		data.stateTimer = 0
	end
	if data.health <= cfg.hp/2 then
		data.beamConsecutive = 3
		data.lobConsecutive = 1
	end
		--Turn on walls
	if (v.collidesBlockLeft or v.collidesBlockRight) and data.state == STATE_WALK then
		v.direction = -v.direction
	end
	-- when he despawns or isn't gonna hurt you
	if v:mem(0x12A, FIELD_WORD) <= 0 or v.isHidden then
		changeState(v, STATE_WALK)
		
	--when he's coming out of a block
	elseif v:mem(0x138, FIELD_WORD) == 1 or v:mem(0x138, FIELD_WORD) == 3 then
		if not data.OOBDirPicked then
			v.direction = RNG.randomInt(0,1)*2-1
			data.OOBDirPicked = true
		end
	--when he's not in the reserve box
	elseif v:mem(0x138, FIELD_WORD) == 0 then
		if data.floating == true then
			v.speedY = -Defines.npc_grav
		end
		if data.state == STATE_IDLE then
			if v:mem(0x12E, FIELD_WORD) == 0 and math.abs(v.speedX) > 0 then
				v.speedX = v.speedX * 0.75
				
				if v.speedX < 0.4 then
					v.speedX = 0
				end
			end
			npcutils.faceNearestPlayer(v)
			if (data.stateTimer >= cfg.idletime and v.collidesBlockBottom) then
				local options = {}
				if data.stateLimit ~= STATE_HOP then
					table.insert(options,STATE_HOP)
				end
				if data.stateLimit ~= STATE_JUMP_TO_BEAM then
					table.insert(options,STATE_JUMP_TO_BEAM)
				end
				if data.stateLimit ~= STATE_SHOOT then
					table.insert(options,STATE_SHOOT)
				end
				if data.stateLimit ~= STATE_WALK then
					table.insert(options,STATE_WALK)
				end
				if data.stateLimit ~= STATE_LOB then
					table.insert(options,STATE_LOB)
				end
				if data.stateLimit ~= STATE_SHOWER then
					table.insert(options,STATE_SHOWER)
				end
				if #options > 0 then
					changeState(v, RNG.irandomEntry(options))
					data.stateLimit = data.state
				end
				data.stateTimer = 0
			end
		elseif data.state == STATE_JUMP_TO_BEAM then
			if v.ai1 == 2 then
				if data.stateTimer == 1 then
					SFX.play("Kirby Jump.wav")
					v.speedY = -cfg.jumpheight
				end
				v.speedX = cfg.speed * 3 * v.direction
				if data.stateTimer >= cfg.jumptime then
					data.floating = true
					v.speedX = 0
					v.speedY = 0
					v.ai1 = 0
					changeState(v, STATE_CHARGE)
				end
			elseif v.ai1 == 0 then
				if (data.stateTimer >= cfg.walktime and v.collidesBlockBottom) then
					changeState(v, STATE_IDLE)
				end
				
				if math.abs((player.x + player.width/2) - (v.x + v.width/2)) <= 176 then
					v.speedX = 0
					v.ai1 = 1
					data.stateTimer = 0
				else
					v.speedX = cfg.walkspeed * v.direction
				end
			elseif v.ai1 == 1 then
				v.speedX = 0
				if data.stateTimer == 1 then SFX.play(13) end

				if data.stateTimer >= 65 then
					data.stateTimer = 0
					v.ai1 = 2
				end
			end
		elseif data.state == STATE_SHOOT then
			if v:mem(0x12E, FIELD_WORD) == 0 and math.abs(v.speedX) > 0 then
				v.speedX = v.speedX * 0.75
				
				if v.speedX < 0.4 then
					v.speedX = 0
				end
			end
			if data.stateTimer == 1 then
				SFX.play("Woosh 2.wav")
			end
			if data.stateTimer < cfg.shoottime - 32 then
				for i = 1,4 do
					if v.direction == 1 then
						local ptl = Animation.spawn(80, v.x + v.width, v.y + v.height/2)
						ptl.x = ptl.x - ptl.width/2
						ptl.y = ptl.y - ptl.height/2
						ptl.speedX = RNG.random(0,2)
						ptl.speedY = RNG.random(0,2)
					else
						local ptl = Animation.spawn(80, v.x, v.y + v.height/2)
						ptl.x = ptl.x - ptl.width/2
						ptl.y = ptl.y - ptl.height/2
						ptl.speedX = -RNG.random(0,2)
						ptl.speedY = RNG.random(0,2)
					end
				end
			end
			if data.stateTimer >= cfg.shoottime then
				SFX.play("Beam Charged.wav")
				local n
				if v.direction == 1 then
					n = NPC.spawn(cfg.beamid, v.x + v.width, v.y + v.height/2)
				else
					n = NPC.spawn(cfg.beamid, v.x, v.y + v.height/2)
				end
				n.x = n.x - n.width/2
				n.y = n.y - n.height/2
				local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
				local startX = p.x + p.width / 2
				local startY = p.y + p.height / 2
				local X
				if v.direction == -1 then
					X = v.x
				else
					X = v.x + v.width
				end
				local Y = v.y + v.height/2
				local angle = math.atan2((Y - startY), (X - startX))
				n.speedX = -cfg.shootspeed * math.cos(angle)
				n.speedY = -cfg.shootspeed * math.sin(angle)
				n.direction = v.direction
				if v.ai1 == data.beamConsecutive then
					changeState(v, STATE_IDLE)
					v.ai1 = 0
					data.stateTimer = 0
				else
					v.ai1 = v.ai1 + 1
					data.stateTimer = cfg.shoottime - 32
				end
			end
		elseif data.state == STATE_HOP then
			if data.stateTimer == 1 then
				v.speedY = -4
				v.speedX = 0
				SFX.play("Kirby Jump.wav")
			end
			if data.stateTimer > 1 and v.collidesBlockBottom then
				changeState(v, STATE_RAM)
			end
		elseif data.state == STATE_RAM then
			if v.collidesBlockLeft or v.collidesBlockRight then
				changeState(v, STATE_DONE_RAM)
				v.speedX = 0
				SFX.play(37)
				Defines.earthquake = 6
				local n = NPC.spawn(NPC.config[v.id].starID, v.x + spawnOffset[v.direction], v.y + v.height / 2)
				n.x=n.x-n.width/2
				n.y=n.y-n.height/2
				n.ai1 = -96
			elseif (data.stateTimer >= cfg.ramtime and v.collidesBlockBottom) then
				v.speedX = 0
				changeState(v,STATE_IDLE)
			end

			v.speedX = (cfg.walkspeed + cfg.speedIncrease) * v.direction
		elseif data.state == STATE_DONE_RAM then
			if data.stateTimer == 1 then
				v.speedY = -2
				v.speedX = -v.direction * 2.5
			end
			if data.stateTimer > 1 and v.collidesBlockBottom then
				SFX.play(37)
				Defines.earthquake = 6
				local n = NPC.spawn(NPC.config[v.id].starID, v.x + spawnOffset[v.direction], v.y + v.height / 2)
				n.x=n.x-n.width/2
				n.y=n.y-n.height/2
				n.speedX = 2.5 * v.direction
				changeState(v, STATE_IDLE)
			end
		elseif data.state == STATE_WALK then
			if (data.stateTimer >= cfg.walktime and v.collidesBlockBottom) then
				changeState(v, STATE_IDLE)
			end
			
			if math.abs((player.x + player.width/2) - (v.x + v.width/2)) <= 80 then
				v.speedX = 0
				data.stateTimer = 0
				changeState(v,STATE_CHARGE)
			else
				v.speedX = cfg.walkspeed * v.direction
			end
			
		elseif data.state == STATE_CHARGE then
			v.animationTimer = v.animationTimer + 1
			if data.stateTimer == 1 then SFX.play(13) end
			if v:mem(0x132, FIELD_WORD) == 0 then
				v.x = v.x - v.speedX -- make him not walk
			end

			local ct = cfg.chargetime
			
			if data.stateTimer >= ct * math.clamp(1-cfg.sparkspawndelay, 0, 1) then
				if data.sound == nil then
					data.sound = SFX.play(sfx_beamstart)
					table.insert(loopingSounds, {source=v, effect=data.sound})
				end
				if data.floating == false then
					if data.sparkCooldown > 0 then
						data.sparkCooldown = data.sparkCooldown - 1
					else
						--spawn in the sparks
						while data.sparkCooldown <= 0 and #data.sparkList < cfg.beamlength do
							local i = #data.sparkList + 1
							local bp = getBeamPos(v, i, cfg.beamanglestart)
							local shiny = NPC.spawn(cfg.sparkid, bp.x, bp.y, v:mem(0x146, FIELD_WORD), false, true)
							shiny.data.parent = v
							shiny.layerName = "Spawned NPCs"
							data.sparkList[i] = shiny;
							data.sparkCooldown = data.sparkCooldown + ct * math.clamp(cfg.sparkspawndelay, 0, 1) / (cfg.beamlength+1)
						end
					end

					for i, sparp in ipairs(data.sparkList) do
						i = i + data.sparkOffset
						if sparp.isValid then
							local bp = getBeamPos(v, i, cfg.beamanglestart)
							sparp.x = bp.x - sparp.width/2 + RNG.randomInt(-2,2) -- this'll be so much beter with centerx and centery
							sparp.y = bp.y - sparp.height/2 + RNG.randomInt(-2,2)
							
							-- when he's your bestest friend
							harmEnemies(v, sparp)
						end
					end
				else
					if data.sparkCooldown > 0 then
						data.sparkCooldown = data.sparkCooldown - 1
					else
						--spawn in the sparks
						while data.sparkCooldown <= 0 and #data.sparkList < cfg.beamlength do
							local i = #data.sparkList + 1
							local bp = getBeamPos(v, i, cfg.beamanglestartfloat)
							local shiny = NPC.spawn(cfg.sparkid, bp.x, bp.y, v:mem(0x146, FIELD_WORD), false, true)
							shiny.data.parent = v
							shiny.layerName = "Spawned NPCs"
							data.sparkList[i] = shiny;
							data.sparkCooldown = data.sparkCooldown + ct * math.clamp(cfg.sparkspawndelay, 0, 1) / (cfg.beamlength+1)
						end
					end

					for i, sparp in ipairs(data.sparkList) do
						i = i + data.sparkOffset
						if sparp.isValid then
							local bp = getBeamPos(v, i, cfg.beamanglestartfloat)
							sparp.x = bp.x - sparp.width/2 + RNG.randomInt(-2,2) -- this'll be so much beter with centerx and centery
							sparp.y = bp.y - sparp.height/2 + RNG.randomInt(-2,2)
							
							-- when he's your bestest friend
							harmEnemies(v, sparp)
						end
					end
				end
			end
		
			if data.stateTimer >= cfg.chargetime then
				changeState(v, STATE_BEAM)
			end
			
			if v:mem(0x12E, FIELD_WORD) == 0 and math.abs(v.speedX) > 0 then
				v.speedX = v.speedX * 0.75
				
				if v.speedX < 0.4 then
					v.speedX = 0
				end
			end
			
		elseif data.state == STATE_BEAM then	
			v.animationTimer = v.animationTimer + 1
			
			if v:mem(0x132, FIELD_WORD) == 0 then
				v.speedX = 0
			end
			
			if data.stateTimer >= cfg.beamtime then
				if v:mem(0x12E,FIELD_WORD) == 30 and Player(v:mem(0x130, FIELD_WORD)).character ~= CHARACTER_LINK then
					changeState(v, STATE_CHARGE)
				else
					changeState(v, STATE_IDLE)
					if data.floating then
						data.floating = false
					end
				end
			else
				if data.floating == false then
					for i, sparp in ipairs(data.sparkList) do
						i = i + data.sparkOffset
						if sparp.isValid then
							local bp = getBeamPos(v, i, cfg.beamanglestart + (data.stateTimer/cfg.beamtime)*(cfg.beamangleend-cfg.beamanglestart) - 2*(i*((1+data.stateTimer)/(cfg.beamtime*1.2))))
							sparp.x = bp.x - sparp.width/2 + RNG.randomInt(-2,2) -- this'll be so much beter with centerx and centery
							sparp.y = bp.y - sparp.height/2 + RNG.randomInt(-2,2)
							
							-- when he's your bestest friend
							harmEnemies(v, sparp)
						end
					end
					local ct = cfg.beamtime
				
					if data.stateTimer >= ct * math.clamp(1-cfg.sparkkilldelay, 0, 1) then
						if data.sparkCooldown <= 0 then
							while data.sparkCooldown <= 0 and #data.sparkList > 0 do
								--cleanup the sparks
								if data.sparkList[1].isValid then
									data.sparkList[1]:kill()
								end
								table.remove(data.sparkList, 1)
								data.sparkCooldown = data.sparkCooldown + ct * math.clamp(cfg.sparkkilldelay, 0, 1) / (cfg.beamlength+1)
								data.sparkOffset = data.sparkOffset + 1
							end
						else
							data.sparkCooldown = data.sparkCooldown - 1
						end
					end
				else
					for i, sparp in ipairs(data.sparkList) do
						i = i + data.sparkOffset
						if sparp.isValid then
							local bp = getBeamPos(v, i, cfg.beamanglestartfloat + (data.stateTimer/cfg.beamtime)*(cfg.beamangleendfloat-cfg.beamanglestartfloat) - 2*(i*((1+data.stateTimer)/(cfg.beamtime*1.2))))
							sparp.x = bp.x - sparp.width/2 + RNG.randomInt(-2,2) -- this'll be so much beter with centerx and centery
							sparp.y = bp.y - sparp.height/2 + RNG.randomInt(-2,2)
							
							-- when he's your bestest friend
							harmEnemies(v, sparp)
						end
					end
					local ct = cfg.beamtime
				
					if data.stateTimer >= ct * math.clamp(1-cfg.sparkkilldelay, 0, 1) then
						if data.sparkCooldown <= 0 then
							while data.sparkCooldown <= 0 and #data.sparkList > 0 do
								--cleanup the sparks
								if data.sparkList[1].isValid then
									data.sparkList[1]:kill()
								end
								table.remove(data.sparkList, 1)
								data.sparkCooldown = data.sparkCooldown + ct * math.clamp(cfg.sparkkilldelay, 0, 1) / (cfg.beamlength+1)
								data.sparkOffset = data.sparkOffset + 1
							end
						else
							data.sparkCooldown = data.sparkCooldown - 1
						end
					end
				end
			end
			
			if v:mem(0x12E, FIELD_WORD) == 0 and math.abs(v.speedX) > 0 then
				v.speedX = v.speedX * 0.75
				
				if v.speedX < 0.4 then
					v.speedX = 0
				end
			end

			if data.sound and data.state ~= STATE_WALK and data.sound.isValid and not data.sound:isPlaying() then
				data.sound = SFX.play(sfx_beamloop)
			end
		elseif data.state == STATE_LOB then
			if data.stateTimer == 1 then
				npcutils.faceNearestPlayer(v)
				SFX.play("Woosh 2.wav")
			end

			if data.stateTimer < 48 then
				for i = 1,4 do
					if v.direction == 1 then
						local ptl = Animation.spawn(80, v.x + v.width, v.y + v.height/2)
						ptl.x = ptl.x - ptl.width/2
						ptl.y = ptl.y - ptl.height/2
						ptl.speedX = RNG.random(0,2)
						ptl.speedY = RNG.random(0,-2)
					else
						local ptl = Animation.spawn(80, v.x, v.y + v.height/2)
						ptl.x = ptl.x - ptl.width/2
						ptl.y = ptl.y - ptl.height/2
						ptl.speedX = -RNG.random(0,2)
						ptl.speedY = RNG.random(0,-2)
					end
				end
			end
			if data.stateTimer == 64 or data.stateTimer == 112 then
				SFX.play("Beam Charged.wav")
				local n
				if v.direction == 1 then
					n = NPC.spawn(cfg.elecid, v.x + v.width, v.y + v.height/2)
				else
					n = NPC.spawn(cfg.elecid, v.x, v.y + v.height/2)
				end
				n.x = n.x - n.width/2
				n.y = n.y - n.height/2
				n.speedY = -9
				--Bit of code here by Murphmario
				local bombxspeed = vector.v2(Player.getNearest(v.x + v.width/2, v.y + v.height).x + 0.5 * Player.getNearest(v.x + v.width/2, v.y + v.height).width - (v.x + 0.5 * v.width))
				n.speedX = bombxspeed.x / 75
				n.direction = v.direction
			end
			if data.stateTimer >= 156 then
				if v.ai1 >= data.lobConsecutive then
					changeState(v, STATE_IDLE)
					v.ai1 = 0
					data.stateTimer = 0
				else
					v.ai1 = v.ai1 + 1
					data.stateTimer = 48
				end
			end
		elseif data.state == STATE_SHOWER then
			if v.ai1 == 2 then
				if data.stateTimer == 1 then
					SFX.play("Kirby Jump.wav")
					v.speedY = -cfg.highjumpheight
					v.speedX = RNG.randomInt(-3,3)
				end
				npcutils.faceNearestPlayer(v)
				if data.stateTimer >= cfg.jumptime then
					data.floating = true
					v.speedX = 0
					v.speedY = 0
					v.ai1 = 3
					data.stateTimer = 0
				end
			elseif v.ai1 == 0 then
				if (data.stateTimer >= cfg.walktime and v.collidesBlockBottom) then
					changeState(v, STATE_IDLE)
				end
				
				if math.abs((player.x + player.width/2) - (v.x + v.width/2)) <= 160 then
					v.speedX = 0
					v.ai1 = 1
					data.stateTimer = 0
				else
					v.speedX = cfg.walkspeed * v.direction
				end
			elseif v.ai1 == 1 then
				v.speedX = 0
				if data.stateTimer == 1 then SFX.play(13) end

				if data.stateTimer >= 65 then
					data.stateTimer = 0
					v.ai1 = 2
				end
			elseif v.ai1 == 3 then
				if data.stateTimer % 18 == 0 then
					local n
					if v.direction == 1 then
						n = NPC.spawn(cfg.elecid, v.x + v.width, v.y + v.height/2)
					else
						n = NPC.spawn(cfg.elecid, v.x, v.y + v.height/2)
					end
					n.x = n.x - n.width/2
					n.y = n.y - n.height/2
					n.speedY = 10
					n.speedX = RNG.random(2,6) * v.direction
					n.nogravity = true
					SFX.play("Beam Charged.wav")
				end

				if data.stateTimer >= 82 then
					v.ai1 = 4
					data.stateTimer = 0
					data.floating = false
					npcutils.faceNearestPlayer(v)
				end
			elseif v.ai1 == 4 then
				if v.collidesBlockBottom then
					data.stateTimer = 0
					v.ai1 = 0
					changeState(v,STATE_IDLE)
				end
				npcutils.faceNearestPlayer(v)
			end
		else
					--Death stuff
			--Make the npc flash to show it's almost dead
			if lunatime.tick() % 64 > 4 then 
				v.animationFrame = 3
			else
				v.animationFrame = -50
			end
			
			--Bounce a little bit to simulate physics
			if v.collidesBlockBottom and data.stateTimer >= 8 then
				if math.abs(v.speedX) >= 2 then
					v.speedX = v.speedX / 2
					v.speedY = -3
				else
					v.speedX = 0
				end
				--Die after a bit
				if data.stateTimer >= 386 then
					v:kill(HARM_TYPE_NPC)
					SFX.play("Boss Dead.wav")
				end
			end
		end
		
		data.stateTimer = data.stateTimer + 1
	end
	if data.state == STATE_WALK then
		v.animationFrame = math.floor(lunatime.tick() / 8) % 2
	elseif data.state == STATE_RAM then
		v.animationFrame = math.floor(lunatime.tick() / 4) % 2
	elseif data.state == STATE_DONE_RAM then
		v.animationFrame = 3
	elseif data.state == STATE_HOP then
		v.animationFrame = math.floor(lunatime.tick() / 4) % 2
	elseif data.state == STATE_CHARGE then
		v.animationFrame = 0
	elseif data.state == STATE_IDLE then
		v.animationFrame = 1
	elseif data.state == STATE_JUMP_TO_BEAM then
		if v.ai1 == 2 then
			v.animationFrame = 0
		else
			v.animationFrame = math.floor(lunatime.tick() / 8) % 2
		end
	elseif data.state == STATE_SHOWER then
		if v.ai1 == 2 or v.ai1 == 4 then
			v.animationFrame = 0
		elseif v.ai1 == 3 then
			v.animationFrame = 2
		else
			v.animationFrame = math.floor(lunatime.tick() / 8) % 2
		end
	elseif data.state == STATE_BEAM then
		v.animationFrame = 2
	elseif data.state == STATE_SHOOT then
		v.animationFrame = 2
	elseif data.state == STATE_LOB then
		v.animationFrame = 2
	end

	--Give King Doo some i-frames to make the fight less cheesable
	if data.iFrames then
		v.friendly = true
		data.hurtTimer = data.hurtTimer + 1
		
		if data.hurtTimer == 1 then SFX.play("Kirby Enemy Hit.wav") end
		
		if data.hurtTimer % 8 <= 4 and data.hurtTimer > 8 then
			v.animationFrame = -50
		end
		if data.hurtTimer >= 64 then
			v.friendly = false
			data.iFrames = false
			data.hurtTimer = 0
		end
	end
	--Give King Doo some i-frames for BEAM ATTACK indication
	if data.state == STATE_CHARGE then
		if data.stateTimer % 6 <= 3 and data.stateTimer > 6 and data.stateTimer <= cfg.chargetime then
			v.animationFrame = 4
		end
	elseif (data.state == STATE_JUMP_TO_BEAM or data.state == STATE_SHOWER) and v.ai1 == 1 then
		if data.stateTimer % 6 <= 3 and data.stateTimer > 6 and data.stateTimer <= 54 then
			v.animationFrame = 4
		end
	end
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = cfg.frames
		});
	end
	
	--Prevent King Doo from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	
	if Colliders.collide(plr, v) and not v.friendly and data.state ~= STATE_KILL and not Defines.cheat_donthurtme then
		plr:harm()
	end
end

function waddledoo.onDrawDoo(v)
	local data = v.data
	


	if Misc.isPaused() and data.sound and data.sound.isValid and data.sound:isPlaying() then
		data.sound:Stop()
	end
	

end



function waddledoo.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end
	if data.state ~= STATE_KILL then
		if reason ~= HARM_TYPE_LAVA then
			if reason == HARM_TYPE_JUMP or killReason == HARM_TYPE_SPINJUMP or killReason == HARM_TYPE_FROMBELOW then
				SFX.play(2)
				data.iFrames = true
				data.health = data.health - 5
			elseif reason == HARM_TYPE_SWORD then
				if v:mem(0x156, FIELD_WORD) <= 0 then
					data.health = data.health - 5
					data.iFrames = true
					SFX.play(89)
					v:mem(0x156, FIELD_WORD,20)
				end
				if Colliders.downSlash(player,v) then
					player.speedY = -6
				end
			elseif reason == HARM_TYPE_NPC then
				if culprit then
					if type(culprit) == "NPC" then
						if culprit.id == 13  then
							SFX.play("Kirby Enemy Hit.wav")
							data.health = data.health - 1
						else
							data.health = data.health - 5
							data.iFrames = true
						end
					else
						data.health = data.health - 5
						data.iFrames = true
					end
				else
					data.health = data.health - 5
					data.iFrames = true
				end
			elseif reason == HARM_TYPE_LAVA and v ~= nil then
				v:kill(HARM_TYPE_OFFSCREEN)
			elseif v:mem(0x12, FIELD_WORD) == 2 then
				v:kill(HARM_TYPE_OFFSCREEN)
			else
				data.iFrames = true
				data.health = data.health - 5
			end
			if culprit then
				if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
					culprit:kill(HARM_TYPE_NPC)
				elseif culprit.__type == "Player" then
					--Bit of code taken from the basegame chucks
					if (culprit.x + 0.5 * culprit.width) < (v.x + v.width*0.5) then
						culprit.speedX = -5
					else
						culprit.speedX = 5
					end
				elseif type(culprit) == "NPC" and (NPC.HITTABLE_MAP[culprit.id] or culprit.id == 45) and culprit.id ~= 50 and v:mem(0x138, FIELD_WORD) == 0 then
					culprit:kill(HARM_TYPE_NPC)
				end
			end
			if data.health <= 0 then
				data.state = STATE_KILL
				data.stateTimer = 0
				Effect.spawn(856,v.x - v.width / 2,v.y - v.width / 2)
				SFX.play("Miniboss Dead.wav")
				v.speedX = 2 * -v.direction
				v.speedY = -10
				for _,n in ipairs(NPC.get()) do
					if n.id == NPC.config[v.id].elecid or n.id == NPC.config[v.id].sparkid or n.id == NPC.config[v.id].beamid then
						if n.x + n.width > camera.x and n.x < camera.x + camera.width and n.y + n.height > camera.y and n.y < camera.y + camera.height then
							n:kill(9)
							Animation.spawn(10, n.x, n.y)
						end
					end
				end
			elseif data.health > 0 then
				v:mem(0x156,FIELD_WORD,60)
			end
		else
			v:kill(HARM_TYPE_LAVA)
		end
	else
		v:kill(HARM_TYPE_NPC)
		SFX.play("Boss Dead.wav")
	end
	eventObj.cancelled = true
end

return waddledoo