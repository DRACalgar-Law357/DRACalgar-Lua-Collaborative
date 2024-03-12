--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local colliders = require("colliders")
local klonoa = require("characters/klonoa")
local playerStun = require("playerstun")
klonoa.UngrabableNPCs[NPC_ID] = true
local sprite

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 64,
	gfxwidth = 124,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 124,
	height = 58,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 6,
	--Frameloop-related
	frames = 3,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	staticdirection = true,

	positionPointBGO = 1000,
	fireball1ID = 755,
	fireball2ID = 756,
	calltable = {
		493,
	},
	indicateBGO = 997,
	indicateID = 791,
	callYAxis = {
		[0] = -100,
		[1] = 860,
	},
	quaketable = {
		759,
	},
	health = 80,
	fallMultiplier = 1,
	fallAmount = 3,
	fallConsecutive = 3,
	quakeSpawnDelay = 48,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

local STATE_IDLE = 0
local STATE_FIRE = 1
local STATE_JUMP = 2
local STATE_KILL = 3
local STATE_QUAKE = 4
local STATE_CALL = 5


local spawnOffset = {
[-1] = 24,
[1] = sampleNPCSettings.width-24,
}

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onStartNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

local bgoTable
local quakeTable

function sampleNPC.onStartNPC(v)
	bgoTable = BGO.get(NPC.config[v.id].positionPointBGO)
	quakeTable = BGO.get(NPC.config[v.id].indicateBGO)
end
function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	local settings = v.data._settings
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		data.hurtTimer = 0
		data.turnTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		if settings.fire == nil then
			settings.fire = true
		end
		if settings.quake == nil then
			settings.quake = true
		end
		if settings.call == nil then
			settings.call = true
		end
		if settings.jump == nil then
			settings.jump = true
		end

		data.timer = data.timer or 0
		data.timer2 = data.timer2 or 0
		data.hurtTimer = data.hurtTimer or 0
		data.turnTimer = data.turnTimer or 0
		data.iFrames = false
		data.pinch = false
		v:mem(0x148, FIELD_FLOAT, 0)
        data.state = STATE_IDLE
		data.location = 0
		data.statelimit = 0
		data.explosionTimer = 0
		
		data.explosionNoise = nil

        v.ai2 = RNG.randomInt(56,80)
        v.ai3 = RNG.randomInt(100,164)
        v.ai4 = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_IDLE
		data.timer = 0
		v.animationFrame = 0
		return
	end
	if data.state ~= STATE_JUMP then
	    data.timer = data.timer + 1
	end
	if data.state == STATE_IDLE or data.state == STATE_JUMP then
	    v.ai4 = v.ai4 + 1
	end
	data.explosionTimer = data.explosionTimer + 1
	if data.explosionTimer == 7 then
		data.explosionTimer = 0
	end
	if data.state ~= STATE_KILL then
		if v.collidesBlockBottom then
			if data.state == STATE_FIRE or data.state == STATE_IDLE then
				v.animationFrame = math.floor(lunatime.tick() / 8) % 2
			else
				v.animationFrame = 0
			end
		else
			v.animationFrame = 1
		end
	end
	if data.state == STATE_IDLE then
        if data.timer >= v.ai3 and v.collidesBlockBottom then
            data.timer = 0
            v.ai3 = RNG.randomInt(80,112)
			local options = {}
			if data.statelimit ~= STATE_QUAKE and settings.quake == true then
				table.insert(options,STATE_QUAKE)
			end
			if data.statelimit ~= STATE_FIRE and settings.fire == true then
				table.insert(options,STATE_FIRE)
			end
			if data.statelimit ~= STATE_FIRE and settings.call == true then
				table.insert(options,STATE_CALL)
			end
			if #options > 0 then
				data.state = RNG.irandomEntry(options)
				data.statelimit = data.state
				if data.state == STATE_FIRE then
					if v:mem(0x148, FIELD_FLOAT) >= sampleNPCSettings.health/2 then
						v.ai1 = 2
					end
					if v:mem(0x148, FIELD_FLOAT) >= sampleNPCSettings.health/4 and v:mem(0x148, FIELD_FLOAT) < sampleNPCSettings.health/2 then
						v.ai1 = 1
					end
					if v:mem(0x148, FIELD_FLOAT) < sampleNPCSettings.health/4 then
						v.ai1 = 0
					end
				end
			else
				if settings.quake == true then
					data.state = STATE_QUAKE
				end
				if settings.fire == true then
					data.state = STATE_FIRE
				end
				if settings.call == true then
					data.state = STATE_CALL
				end
			end
        end
        if v.collidesBlockBottom then
            v.speedX = 0
            npcutils.faceNearestPlayer(v)
        end
        if v.ai4 >= v.ai2 and v.collidesBlockBottom and #bgoTable > 0 and settings.jump == true then
            v.ai2 = RNG.randomInt(60,74)
            v.ai4 = 0
            data.state = STATE_JUMP
        end
		if v.ai4 >= v.ai2 - 24 or data.timer >= v.ai3 - 20 then
			v.animationFrame = 0
		end
    elseif data.state == STATE_FIRE then
        if v.collidesBlockBottom then
            v.speedX = 0
        end
		if data.timer % 2 == 0 and (v.ai1 == 2 or v.ai1 == 0) then
			local ptl = Animation.spawn(265, v.x + spawnOffset[v.direction], v.y + (v.height * 0.75))
			ptl.x=ptl.x-ptl.width/2
			ptl.y=ptl.y-ptl.height/2
			ptl.speedX = RNG.random(1,4) * v.direction
			ptl.speedY = RNG.random(-2,2)
		end
		if data.timer % 8 == 0 and v.ai1 == 2 then SFX.play(16) end
        if data.timer % 64 == 0 then
            if v.ai1 == 0 then
                if v.ai5 == 1 then
                    v.ai5 = 0
                    data.timer = 0
                    data.state = STATE_IDLE
                    local fireball1 = NPC.spawn(NPC.config[v.id].fireball1ID, v.x + spawnOffset[v.direction], v.y + (v.height * 0.15))
					fireball1.layerName = "Spawned NPCs"
					fireball1.direction = v.direction
					fireball1.spawnDirection = v.direction
					fireball1.speedX = 3.5 * v.direction
					SFX.play(42)
                else
                    v.ai5 = v.ai5 + 1
                    local fireball2 = NPC.spawn(NPC.config[v.id].fireball1ID, v.x + spawnOffset[v.direction], v.y + (v.height * 0.5))
					fireball2.layerName = "Spawned NPCs"
					fireball2.direction = v.direction
					fireball2.spawnDirection = v.direction
					fireball2.speedX = 3.5 * v.direction
					SFX.play(42)
                end
            else
					local fireball1 = NPC.spawn(NPC.config[v.id].fireball2ID, v.x + spawnOffset[v.direction], v.y + (v.height * 0.15))
					fireball1.direction = v.direction
					fireball1.layerName = "Spawned NPCs"
					fireball1.spawnDirection = v.direction
					Effect.spawn(10, v.x + spawnOffset[v.direction], v.y + (v.height * 0.15))
					local fireball2 = NPC.spawn(NPC.config[v.id].fireball2ID, v.x + spawnOffset[v.direction], v.y + (v.height * 0.5))
					fireball2.layerName = "Spawned NPCs"
					fireball2.direction = v.direction
					fireball2.spawnDirection = v.direction
					Effect.spawn(10, v.x + spawnOffset[v.direction], v.y + (v.height * 0.5))
					SFX.play(82)
					if v.ai1 == 2 then
						fireball1.ai2 = 2
						fireball2.ai2 = 2
					end
					if v.ai5 < 2 and v.ai1 == 2 then
						v.ai5 = v.ai5 + 1
					else
						data.timer = 0
						v.ai5 = 0
						data.state = STATE_IDLE
					end
            end
        end
    elseif data.state == STATE_JUMP then
		if v.ai1 == 0 then
			if not v.collidesBlockBottom then v.ai4 = 0 end
				if v.ai4 >= 30 then
					if #bgoTable > 0 then
						data.location = RNG.irandomEntry(bgoTable)
						v.speedY = -11
						local xspeed = vector.v2(data.location.x + 0.5 * data.location.width - (v.x + 0.5 * v.width))
						v.speedX = xspeed.x / 88
						if math.abs(v.speedX) >= 16 then
							v.speedX = v.speedX * v.direction
						end
						SFX.play(1)
					end
					v.ai4 = 0
					v.ai1 = 1
				end
		else
			if v.collidesBlockBottom then
				v.ai4 = 0
				v.ai1 = 0
				local e = RNG.randomInt(0,1)
				data.state = STATE_IDLE
				if e == 0 and v:mem(0x148, FIELD_FLOAT) >= sampleNPCSettings.health/2 then
					data.timer = 80
				end
				v.speedX = 0
			end
		end
	elseif data.state == STATE_QUAKE then
		v.speedX = 0
		
		if data.timer == 48 then
			if v.collidesBlockBottom then
				v.y = v.y - 1
				v.speedY = -6
			end
		elseif data.timer > 48 then
			if v.collidesBlockBottom then
				if data.timer2 == 0 then
					SFX.play(37)
					local fallAmount = config.fallAmount
					local phaseSet = 0
					if v:mem(0x148, FIELD_FLOAT) >= sampleNPCSettings.health*1/4 then
						phaseSet = 1
					end
					if v:mem(0x148, FIELD_FLOAT) >= sampleNPCSettings.health*2/4 then
						phaseSet = 2
					end
					if v:mem(0x148, FIELD_FLOAT) >= sampleNPCSettings.health*3/4 then
						phaseSet = 3
					end
					local consecutive = config.fallConsecutive + config.fallMultiplier * phaseSet
					Routine.setFrameTimer(config.quakeSpawnDelay, (function() 
						for i=1,fallAmount do
							data.location = RNG.irandomEntry(quakeTable)
							local n = NPC.spawn(NPC.config[v.id].indicateID, data.location.x, data.location.y, v.section, true, true)
							n.x=n.x+16
							n.y=n.y+16
							n.ai1 = 48
							n.ai2 = RNG.irandomEntry(config.quaketable)
							n.ai3 = 0
						end
						end), consecutive, false)
					Defines.earthquake = 6
					
					local x = v.x - 32
					local y = v.y + v.height - 32

					Effect.spawn(10, x, y)
					Effect.spawn(10, x + v.width + 32, y)
					
					if not v.friendly then
						for k, p in ipairs(Player.get()) do
							if p:isGroundTouching() and not playerStun.isStunned(k) and v.section == player.section then
								playerStun.stunPlayer(k, 32)
							end
						end
					end	
				end
				
				data.timer2 = data.timer2 + 1
			end
		end
		
		if data.timer2 >= 48 then
			data.state = STATE_IDLE
			data.timer = 0
			data.timer2 = 0
		end
	elseif data.state == STATE_CALL then
		if v.collidesBlockBottom then
			if data.timer >= 45 then
                data.timer = 0
                data.state = STATE_IDLE
			end
			v.speedY = -4
		end
		if data.timer == 1 then
			SFX.play(69)
			Routine.setFrameTimer(28, (function() 
				local movement = RNG.irandomEntry{config.callYAxis[0],config.callYAxis[1]}
				local n = NPC.spawn(RNG.irandomEntry(sampleNPCSettings.calltable), Camera.get()[1].x + movement, Camera.get()[1].y + 1 * 10 + RNG.randomInt(200,500), v.section)
				n.layerName = "Spawned NPCs"
				if movement == -100 then
					n.direction = 1
				else
					n.direction = -1
				end
				n.speedX = 4 * n.direction
				SFX.play(66)
				end), RNG.randomInt(3,5), false)
		end
		v.speedX = 0
		npcutils.faceNearestPlayer(v)
	else
		v.animationFrame = 2
		v.friendly = true
		v.speedX = 0
        
			if data.explosionTimer == 2 then
				Animation.spawn(108, math.random(v.x, v.x + v.width), math.random(v.y, v.y + v.height))
				if data.explosionNoise ~= nil then
					data.explosionNoise:stop()
				end
				data.explosionNoise = SFX.play("SMexplosion.wav")
			end
			if data.timer >= 240 then
				v:kill(HARM_TYPE_SPINJUMP)
				if v.legacyBoss then
					oldX = v.x
					oldY = v.y
					oldWidth = v.width
					oldSection = v:mem(0x146,FIELD_WORD)
					Routine.run(function()
						Routine.wait(1,false)
						goal = NPC.spawn(16, oldX, oldY, oldSection,true,true)
						goal:mem(0xA8, FIELD_DFLOAT,0)
						goal.speedY = -5
						end
					)
				end
			end
	end
	
	--Give Vicious Keeper some i-frames to make the fight less cheesable
	if data.iFrames then
		v.friendly = true
		data.hurtTimer = data.hurtTimer + 1
		
		if data.hurtTimer == 1 then SFX.play(39) end
		
		if data.hurtTimer % 8 <= 4 and data.hurtTimer > 8 then
			v.animationFrame = -50
		end
		if data.hurtTimer >= 64 then
			v.friendly = false
			data.iFrames = false
			data.hurtTimer = 0
		end
	end

	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
	end
	
	--Prevent Vicious Keeper from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	
	if Colliders.collide(plr, v) and not v.friendly and not Defines.cheat_donthurtme and not data.state == STATE_KILL then
		plr:harm()
	end
end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end
			if data.state ~= STATE_KILL then
				if reason ~= HARM_TYPE_LAVA then
					if reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP or reason == HARM_TYPE_FROMBELOW then
								if reason == HARM_TYPE_JUMP then
									v:mem(0x148, FIELD_FLOAT, v:mem(0x148, FIELD_FLOAT) + 4)
									SFX.play(2)
									data.iFrames = true
								elseif reason == HARM_TYPE_FROMBELOW then
									v:mem(0x148, FIELD_FLOAT, v:mem(0x148, FIELD_FLOAT) + 4)
									SFX.play(2)
									data.iFrames = true
								end
					elseif reason == HARM_TYPE_SWORD then
						if v:mem(0x156, FIELD_WORD) <= 0 then
							v:mem(0x148, FIELD_FLOAT, v:mem(0x148, FIELD_FLOAT) + 4)
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
									SFX.play(9)
									v:mem(0x148, FIELD_FLOAT, v:mem(0x148, FIELD_FLOAT) + 1)
								else
									v:mem(0x148, FIELD_FLOAT, v:mem(0x148, FIELD_FLOAT) + 1)
									data.iFrames = true
								end
							else
								v:mem(0x148, FIELD_FLOAT, v:mem(0x148, FIELD_FLOAT) + 4)
								data.iFrames = true
							end
						else
							v:mem(0x148, FIELD_FLOAT, v:mem(0x148, FIELD_FLOAT) + 4)
							data.iFrames = true
						end
					elseif reason == HARM_TYPE_LAVA and v ~= nil then
						v:kill(HARM_TYPE_OFFSCREEN)
					elseif v:mem(0x12, FIELD_WORD) == 2 then
						v:kill(HARM_TYPE_OFFSCREEN)
					else
						data.iFrames = true
						v:mem(0x148, FIELD_FLOAT, v:mem(0x148, FIELD_FLOAT) + 4)
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
					if v:mem(0x148, FIELD_FLOAT) >= sampleNPCSettings.health then
						data.state = STATE_KILL
						data.timer = 0
					elseif v:mem(0x148, FIELD_FLOAT) < sampleNPCSettings.health then
						v:mem(0x156,FIELD_WORD,60)
					end
				else
					v:kill(HARM_TYPE_LAVA)
				end
			else

			end
	eventObj.cancelled = true
end

--Gotta return the library table!
return sampleNPC