local rng = require("rng")
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
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
	beamanglestart = 10,
	beamangleend = 180,
	walktime = 240,
	ramtime = 220,
	idletime = 65,
	speedIncrease = 6,
	shoottime = 75,
	chargetime = 60,
	jumptime = 40,
	jumpheight = 9.5,
	beamtime = 80,
	sparkspawndelay = 0.3,
	sparkkilldelay = 0.1,
	sparkid = 847,
	beamid = 846,
	shootspeed = 6,
	hp = 8
}

npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA, HARM_TYPE_PROJECTILE_USED}, 
	{
		[HARM_TYPE_NPC] = npcID,
		[HARM_TYPE_HELD] = npcID,
		[HARM_TYPE_JUMP] = {id=npcID, speedX=0, speedY=0},
		[HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_PROJECTILE_USED] = npcID
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

local sfx_beamstart = Misc.resolveSoundFile("doo-beam-start")
local sfx_beamloop = Misc.resolveSoundFile("doo-beam")
local sfx_bosshurt = Misc.resolveFile("kirby_enemyhurt.wav")
local sfx_bossdefeat = Misc.resolveFile("kirby_bossdead2.wav")

local loopingSounds = {}

function waddledoo.onInitAPI()
	registerEvent(waddledoo, "onNPCHarm")
	npcManager.registerEvent(npcID, waddledoo, "onTickEndNPC", "onTickEndDoo")
	npcManager.registerEvent(npcID, waddledoo, "onDrawNPC", "onDrawDoo")
end

function waddledoo.onNPCHarm(eventObj, killedNPC, killReason)
	if killedNPC.id == npcID then
		local data = killedNPC.data._basegame
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
	local data = v.data._basegame
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
		sparp.friendly = true
		
		for _,n in ipairs(Colliders.getColliding{a=sparp, b=NPC.HITTABLE, btype=Colliders.NPC}) do
			if (not n.friendly) and (not n.isHidden) and (n.id ~= sparp.id) and (n.idx ~= v.idx) and (Colliders.collide(sparp, n)) then
				n:harm(HARM_TYPE_NPC)
			end
		end
	else
		sparp.friendly = false
	end
end

function waddledoo.onTickEndDoo(v)
	if Defines.levelFreeze then return end
	local data = v.data._basegame
	local cfg = NPC.config[v.id]
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
		data.health = cfg.hp
	end

	
	-- when he despawns or isn't gonna hurt you
	if v:mem(0x12A, FIELD_WORD) <= 0 or v.friendly or v.isHidden then
		changeState(v, STATE_WALK)
		
	--when he's coming out of a block
	elseif v:mem(0x138, FIELD_WORD) == 1 or v:mem(0x138, FIELD_WORD) == 3 then
		if not data.OOBDirPicked then
			v.direction = rng.randomInt(0,1)*2-1
			data.OOBDirPicked = true
		end
		
	--when he's not in the reserve box
	elseif v:mem(0x138, FIELD_WORD) == 0 then
		if v:mem(0x12E, FIELD_WORD) == 30 then
			data.hasBeenHeld = true
		elseif data.hasBeenHeld then
			v:harm()
			return
		end
		if data.floating then
			v.nogravity = true
			v.speedY = 0
		else
			v.nogravity = false
		end
		if data.state == STATE_IDLE then
			if v:mem(0x12E, FIELD_WORD) == 0 and math.abs(v.speedX) > 0 then
				v.speedX = v.speedX * 0.75
				
				if v.speedX < 0.4 then
					v.speedX = 0
				end
			end
			v.dontMove = true
			if (data.stateTimer >= cfg.idletime and v.collidesBlockBottom) then
				changeState(v, RNG.irandomEntry{STATE_HOP, STATE_WALK, STATE_SHOOT, STATE_WALK, STATE_JUMP_TO_BEAM})
				v.dontMove = false
			end
		elseif data.state == STATE_JUMP_TO_BEAM then
			if data.stateTimer == 1 then
				SFX.play(1)
				v.speedY = -cfg.jumpheight
			end
			v.speedX = cfg.speed * 3 * v.direction
			if data.stateTimer >= cfg.jumptime then
				data.floating = true
				v.speedX = 0
				changeState(v, STATE_CHARGE)
			end
		elseif data.state == STATE_SHOOT then
			if v:mem(0x12E, FIELD_WORD) == 0 and math.abs(v.speedX) > 0 then
				v.speedX = v.speedX * 0.75
				
				if v.speedX < 0.4 then
					v.speedX = 0
				end
			end
			v.dontMove = true
			if data.stateTimer >= cfg.shoottime then
				SFX.play(22)
				local n
				if v.direction == 1 then
					n = NPC.spawn(cfg.beamid, v.x + v.width/2, v.y)
				else
					n = NPC.spawn(cfg.beamid, v.x - v.width/4, v.y)
				end
				n.speedX = cfg.shootspeed * v.direction
				n.direction = v.direction
				v.dontMove = false
				changeState(v, STATE_IDLE)
			end
		elseif data.state == STATE_HOP then
			if data.stateTimer == 1 then
				v.speedY = -5
				SFX.play(1)
			end
			v.dontMove = true
			if data.stateTimer > 1 and v.collidesBlockBottom then
				changeState(v, STATE_RAM)
				v.dontMove = false
			end
			if v:mem(0x12E, FIELD_WORD) == 0 and math.abs(v.speedX) > 0 then
				v.speedX = v.speedX * 0.75
				
				if v.speedX < 0.4 then
					v.speedX = 0
				end
			end
		elseif data.state == STATE_RAM then
			if (data.stateTimer >= cfg.ramtime and v.collidesBlockBottom) or (v.collidesBlockLeft or v.collidesBlockRight) then
				changeState(v, STATE_DONE_RAM)
				if v.collidesBlockLeft or v.collidesBlockRight then
					SFX.play(37)
					Defines.earthquake = 6
					v.speedY = -3
				end
				v.speedX = 0
			end
			
			v.speedX = cfg.speed * cfg.speedIncrease * v.direction
		elseif data.state == STATE_DONE_RAM then
			if data.stateTimer == 1 then
				v.speedY = -5
				SFX.play(1)
			end
			if v:mem(0x12E, FIELD_WORD) == 0 and math.abs(v.speedX) > 0 then
				v.speedX = v.speedX * 0.75
				
				if v.speedX < 0.4 then
					v.speedX = 0
				end
			end
			if data.stateTimer > 1 and v.collidesBlockBottom then
				changeState(v, STATE_IDLE)
			end
		elseif data.state == STATE_WALK then
			if (data.stateTimer >= cfg.walktime and v.collidesBlockBottom) then
				changeState(v, RNG.irandomEntry{STATE_CHARGE, STATE_SHOOT, STATE_JUMP_TO_BEAM})
			end
			
			if v:mem(0x12E, FIELD_WORD) == 0 and v.speedX ~= cfg.speed then
				if v.speedX == 0 then
					v.speedX = v.direction * cfg.speed
				elseif math.abs(v.speedX) > cfg.speed then
					v.speedX = v.speedX * 0.9
					if math.abs(v.speedX) < cfg.speed then
						v.speedX = v.direction * cfg.speed
					end
				else
					v.speedX = v.speedX * 1.25
					if math.abs(v.speedX) > cfg.speed then
						v.speedX = v.direction * cfg.speed
					end
				end
			end
			
		elseif data.state == STATE_CHARGE then
			v.animationTimer = v.animationTimer + 1
		
			if v:mem(0x132, FIELD_WORD) == 0 then
				v.x = v.x - v.speedX -- make him not walk
			end

			local ct = cfg.chargetime
			
			if data.stateTimer >= ct * math.clamp(1-cfg.sparkspawndelay, 0, 1) then
				if data.sound == nil then
					data.sound = SFX.play(sfx_beamstart)
					table.insert(loopingSounds, {source=v, effect=data.sound})
				end
				local isFriendly = v:mem(0x12E, FIELD_WORD) == 30 and Player(v:mem(0x130, FIELD_WORD)).character ~= CHARACTER_LINK

				if data.sparkCooldown > 0 then
					data.sparkCooldown = data.sparkCooldown - 1
				else
					--spawn in the sparks
					while data.sparkCooldown <= 0 and #data.sparkList < cfg.beamlength do
						local i = #data.sparkList + 1
						local bp = getBeamPos(v, i, cfg.beamanglestart)
						local shiny = NPC.spawn(cfg.sparkid, bp.x, bp.y, v:mem(0x146, FIELD_WORD), false, true)
						shiny.data._basegame.parent = v
						shiny.layerName = "Spawned NPCs"
						if isFriendly then
							shiny.friendly = true
						end
						data.sparkList[i] = shiny;
						data.sparkCooldown = data.sparkCooldown + ct * math.clamp(cfg.sparkspawndelay, 0, 1) / (cfg.beamlength+1)
					end
				end

				for i, sparp in ipairs(data.sparkList) do
					i = i + data.sparkOffset
					if sparp.isValid then
						local bp = getBeamPos(v, i, cfg.beamanglestart)
						sparp.x = bp.x - sparp.width/2 + rng.randomInt(-2,2) -- this'll be so much beter with centerx and centery
						sparp.y = bp.y - sparp.height/2 + rng.randomInt(-2,2)
						
						-- when he's your bestest friend
						harmEnemies(v, sparp)
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
				
				for i, sparp in ipairs(data.sparkList) do
					i = i + data.sparkOffset
					if sparp.isValid then
						local bp = getBeamPos(v, i, cfg.beamanglestart + (data.stateTimer/cfg.beamtime)*(cfg.beamangleend-cfg.beamanglestart) - 2*(i*((1+data.stateTimer)/(cfg.beamtime*0.8))))
						sparp.x = bp.x - sparp.width/2 + rng.randomInt(-2,2) -- this'll be so much beter with centerx and centery
						sparp.y = bp.y - sparp.height/2 + rng.randomInt(-2,2)
						
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
			
			if v:mem(0x12E, FIELD_WORD) == 0 and math.abs(v.speedX) > 0 then
				v.speedX = v.speedX * 0.75
				
				if v.speedX < 0.4 then
					v.speedX = 0
				end
			end

			if data.sound and data.state ~= STATE_WALK and data.sound.isValid and not data.sound:isPlaying() then
				data.sound = SFX.play(sfx_beamloop)
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
		v.animationFrame = 0
	elseif data.state == STATE_BEAM then
		v.animationFrame = 2
	elseif data.state == STATE_SHOOT then
		v.animationFrame = 2
	end
	v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
end

function waddledoo.onDrawDoo(v)
	local data = v.data._basegame
	


	if Misc.isPaused() and data.sound and data.sound.isValid and data.sound:isPlaying() then
		data.sound:Stop()
	end
	

end



function waddledoo.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data._basegame
	if v.id ~= npcID then return end
	
	if v:mem(0x156,FIELD_WORD) == 0 then
		if culprit then
			if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50 and culprit.id ~= 13) and NPC.HITTABLE_MAP[culprit.id] then
				culprit:kill(HARM_TYPE_NPC)
				data.health = data.health - 1
				v:mem(0x156,FIELD_WORD,60)
			elseif culprit.__type == "Player" then
				data.health = data.health - 1
				v:mem(0x156,FIELD_WORD,60)
			else
				SFX.play(9)
				data.health = data.health - 0.25
				v:mem(0x156,FIELD_WORD,10)
			end
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
			end
		end
		if data.health <= 0 then
			SFX.play(sfx_bossdefeat)
			local e = Animation.spawn(856, v.x - v.width/2, v.y - v.height/2)
		elseif data.health > 0 then
			eventObj.cancelled = true
			SFX.play(sfx_bosshurt)
		end
	else
		eventObj.cancelled = true
	end
end

return waddledoo