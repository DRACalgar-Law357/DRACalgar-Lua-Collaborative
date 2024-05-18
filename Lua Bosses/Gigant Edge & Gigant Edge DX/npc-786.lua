--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
local colliders = require("colliders")
klonoa.UngrabableNPCs[NPC_ID] = true

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 144,
	gfxwidth = 254,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 54,
	height = 74,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 4,
	--Frameloop-related
	frames = 21,
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
	hp = 40,
	starID = 782,
	sworderangID = 790,
	shockwaveID = 999,
	doPowWhenHittingWalls = false
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
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=856,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

local STATE_IDLE = 0
local STATE_WALK = 1
local STATE_RAM = 2
local STATE_SWORD = 4
local STATE_THROW = 5
local STATE_SHIELD = 6
local STATE_STUNNED = 7
local STATE_KILL = 8

local effectOffsetSkid = {
	[-1] = 64,
	[1] = 32
}

local destroyColliderOffset = {
	[-1] = -8,
	[1] = 64
}

local spawnOffset = {
[-1] = -96,
[1] = sampleNPCSettings.width / 2 + 100
}
local spawnOffsetEffect = {
	[-1] = -12,
	[1] = sampleNPCSettings.width / 2 + 16
	}

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end


function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
	data.swordBox = Colliders.Box(v.x - (v.width * 2), v.y - (v.height * 1.5), 84, 36)
	if v.direction == DIR_RIGHT then
		data.swordBox.x = v.x + v.width/2 + 48
	else
		data.swordBox.x = v.x + v.width/2 - 128
	end
	data.swordBox.y = v.y + 32
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		data.hurtTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 0
		data.hurtTimer = data.hurtTimer or 0
		data.iFrames = false
		data.health = NPC.config[v.id].hp
		data.state = STATE_IDLE
		data.statelimit = -1
		data.swordConsecutive = 0
		data.necessaryShield = false
		data.waveTimer = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_IDLE
		data.timer = 0
	end
	
	data.timer = data.timer + 1
	--Turn on walls
	if (v.collidesBlockLeft or v.collidesBlockRight) and (data.state == STATE_SWORD) then
		v.direction = -v.direction
	end
	if data.health <= NPC.config[v.id].hp/2 then
		data.swordConsecutive = 1
	end
	if data.state == STATE_IDLE then
		--Nothing really happens here, just a phase to wait before doing something
		npcutils.faceNearestPlayer(v)
		v.speedX = 0
		v.animationFrame = 0
		if data.timer == 1 then
			if data.necessaryShield == false then
				local options = {}
				if data.statelimit ~= 0 then table.insert(options,0) table.insert(options,0) end
				if data.statelimit ~= 1 then table.insert(options,1) end
				if data.statelimit ~= 2 then table.insert(options,2) end
				if #options > 0 then
					v.ai5 = RNG.irandomEntry(options)
				end
				data.statelimit = v.ai5
			end
		end
		if (data.timer >= 80 and data.necessaryShield == false) or (data.timer >= 65 and data.necessaryShield == true) then
			data.timer = 0
			if data.necessaryShield == false then
				if v.ai5 == 0 then
					if v.ai2 == 0 then
						data.state = STATE_SWORD
						v.ai3 = 0
					else
						data.state = STATE_SWORD
						v.ai3 = 1
					end
				elseif v.ai5 == 1 then
					data.state = STATE_RAM
				elseif v.ai5 == 2 then
					data.state = STATE_THROW
				end
			else
				data.state = STATE_SHIELD
			end
		end
	elseif data.state == STATE_RAM then
		if v.ai1 == 0 then
			if data.timer <= 130 then
				--Walk back and get ready
				if data.timer < 120 then
					v.animationFrame = math.floor(data.timer / 6) % 4 + 8
				else
					v.animationFrame = 4
				end
				v.speedX = -v.direction
				if data.timer % 40 == 0 then
					SFX.play(37)
					Defines.earthquake = 3
				end
			else
				--Charges at the player with its sword
				v.animationFrame = math.floor(data.timer / 4) % 4 + 12
				v.speedX = 4 * v.direction
				
				if data.timer % 12 == 0 then 
					SFX.play(86)
					Effect.spawn(131, v.x + effectOffsetSkid[v.direction], v.y + v.height * 0.75)
				end
				if Colliders.collide(plr,data.swordBox) then
					plr:harm()
				end
				if (v.collidesBlockLeft and v.direction == DIR_LEFT) or (v.collidesBlockRight and v.direction == DIR_RIGHT) then
					data.timer = 0
					v.ai1 = 1
					if NPC.config[v.id].doPowWhenHittingWalls then
						Misc.doPOW()
					else
						SFX.play(37)
						Defines.earthquake = 6
					end
					v.speedX = 3 * -v.direction
					v.speedY = -6
					NPC.spawn(NPC.config[v.id].starID, v.x + v.width / 2, v.y + v.height / 2)
				end
				if data.timer >= 270 then
					data.timer = 0
					v.ai1 = 2
				end

				local tbl = Block.SOLID .. Block.PLAYER
				local list = Colliders.getColliding{
				a = data.swordBox,
				b = tbl,
				btype = Colliders.BLOCK,
				filter = function(other)
					if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
						return false
					end
					return true
				end
				}
				for _,b in ipairs(list) do
					if (Block.config[b.id].smashable ~= nil and Block.config[b.id].smashable == 3) then
						b:remove(true)
					else
						b:hit(true)
					end
				end
			end
		elseif v.ai1 == 1 then
			v.animationFrame = 19
			if v.collidesBlockBottom then
				v.speedX = 0
				data.state = STATE_IDLE
				v.ai1 = 0
				SFX.play(37)
				Defines.earthquake = 5
				data.necessaryShield = true
				local n = NPC.spawn(NPC.config[v.id].starID, v.x + v.width / 2, v.y + v.height / 2)
				n.speedX = -6 * v.direction
				n.speedY = -3
			end
		else
			v.animationFrame = 19
			v.speedX = v.speedX - 0.1 * v.direction
			Effect.spawn(74, v.x + effectOffsetSkid[v.direction], v.y + v.height)
			if data.timer % 8 == 0 then
				SFX.play(10)
			end
			if math.abs(v.speedX) <= 0.1 then
				v.speedX = 0
				data.timer = 0
				data.state = STATE_IDLE
				v.ai1 = 0
				data.necessaryShield = true
			end
		end
	elseif data.state == STATE_SWORD then
		if v.ai3 == 0 then
			if v.ai1 == 0 then
				if data.timer == 1 then
					--Track the player's position, and walk to the player for the charge attack
					npcutils.faceNearestPlayer(v)
				end
				v.animationFrame = math.floor(data.timer / 6) % 4 + 8
				if math.abs((player.x + player.width/2) - (v.x + v.width/2)) <= 96 then
					v.speedX = 0
					v.ai1 = 1
					data.timer = 0
				else
					v.speedX = 1.5 * v.direction
				end
				if data.timer >= 320 then data.timer = 0 data.state = STATE_IDLE v.speedX = 0 end
			else
				v.speedX = 0
				--Animation for sword attack
				if data.timer < 6 then
					v.animationFrame = 0
				elseif data.timer < 12 then
					v.animationFrame = 1
				elseif data.timer < 20 then
					v.animationFrame = 3
				elseif data.timer < 54 then
					v.animationFrame = 4
				elseif data.timer < 57 then
					v.animationFrame = 3
				elseif data.timer < 60 then
					v.animationFrame = 5
				elseif data.timer < 108 then
					v.animationFrame = 6
				else
					v.animationFrame = 7
				end
				if Colliders.collide(plr,data.swordBox) and (v.animationFrame == 5 or v.animationFrame == 6) then
					plr:harm()
				end
				if data.timer == 62 then
					SFX.play(37)
					Defines.earthquake = 5
					local n = NPC.spawn(NPC.config[v.id].starID, v.x + spawnOffset[v.direction], v.y + v.height / 2)
					n.speedX = 4.5 * v.direction
				end
				--To get back up from its sword
				if data.timer >= 108 then
					v.speedX = 7 * v.direction
				end
				--If in a pinch, it slashes twice
				if data.timer >= 116 then
					data.timer = 0
					v.speedX = 0
					if v.ai4 < data.swordConsecutive then
						v.ai4 = v.ai4 + 1
						data.timer = 32
					else
						data.state = STATE_IDLE
						v.ai2 = 1
						v.ai1 = 0
						v.ai4 = 0
					end
				end
			end
		else
			v.speedX = 0
			--Animation for sword beam attack and charging
			if data.timer < 6 then
				v.animationFrame = 0
			elseif data.timer < 12 then
				v.animationFrame = 1
			elseif data.timer < 20 then
				v.animationFrame = 3
			elseif data.timer < 54 then
				v.animationFrame = 4
			elseif data.timer < 57 then
				v.animationFrame = 3
			elseif data.timer < 60 then
				v.animationFrame = 5
			elseif data.timer < 108 then
				v.animationFrame = 6
			else
				v.animationFrame = 7
			end
			if data.timer < 62 then
				for i = 1,4 do
					local ptl = Animation.spawn(80, v.x + spawnOffsetEffect[-v.direction], v.y - 10)
					ptl.speedX = RNG.random(-2.5,2.5)
					ptl.speedY = RNG.random(0,-4)
				end
			end
			if data.timer == 1 then SFX.play(41) end
			if Colliders.collide(plr,data.swordBox) and (v.animationFrame == 5 or v.animationFrame == 6) then
				plr:harm()
			end
			if data.timer == 62 then
				SFX.play("Beam Charged.wav")
				Defines.earthquake = 8
				local n = NPC.spawn(NPC.config[v.id].starID, v.x + spawnOffset[v.direction], v.y + v.height / 2)
				n.speedX = 4.5 * v.direction
				--Spawn a shockwave
				if data.feet == nil then
					data.feet = Colliders.Box(0,0,v.width,1)
					data.lastFrameCollision = true
				end
				data.lastFrameCollision = collidesWithSolid
				data.feet.x = v.x
				data.feet.y = v.y + v.height
				local collidesWithSolid = false
				local footCollisions = Colliders.getColliding{
			
					a=	data.feet,
					b=	Block.SOLID ..
						Block.PLAYER ..
						Block.SEMISOLID .. 
						Block.SIZEABLE,
					btype = Colliders.BLOCK,
					filter= function(other)
						if (not collidesWithSolid and not other.isHidden and other:mem(0x5A, FIELD_WORD) == 0) then
							if Block.SOLID_MAP[other.id] or Block.PLAYER_MAP[other.id] then
								return true
							end
							if data.feet.y <= other.y + 8 then
								return true
							end
						end
						return false
					end
					
					}
	
				if #footCollisions > 0 then
					collidesWithSolid = true
					if not data.lastFrameCollision then
						local id = NPC.config[v.id].shockwaveID
						local f = NPC.spawn(id, v.x + spawnOffset[v.direction], footCollisions[1].y - 0.5 * NPC.config[id].height, v:mem(0x146, FIELD_WORD), false, true)
						f.speedX = 3 * v.direction
						f.direction = v.direction
						return
					end
				end
				data.lastFrameCollision = collidesWithSolid
			end
			--To get back up from its sword
			if data.timer >= 108 then
				v.speedX = 7 * v.direction
			end
			if data.timer >= 116 then
				data.timer = 0
				v.speedX = 0
				data.state = STATE_IDLE
				v.ai2 = 0
				v.ai1 = 0
				v.ai4 = 0
			end
		end
	elseif data.state == STATE_SHIELD then
		--Shield and be impervious from attacks
		if data.timer == 1 then
			SFX.play(85)
			npcutils.faceNearestPlayer(v)
		end
		if data.timer < 12 or data.timer >= 122 then
			v.animationFrame = 17
		else
			v.animationFrame = 18
		end
		if data.timer >= 132 then
			data.state = STATE_IDLE
			data.timer = 0
			data.necessaryShield = false
		end
	elseif data.state == STATE_THROW then
		v.speedX = 0
		if v.ai1 == 0 then
			--Animation for throw sword attack
			if data.timer < 6 then
				v.animationFrame = 0
			elseif data.timer < 12 then
				v.animationFrame = 1
			elseif data.timer < 20 then
				v.animationFrame = 3
			elseif data.timer < 86 then
				v.animationFrame = 4
			elseif data.timer < 89 then
				v.animationFrame = 3
			elseif data.timer < 92 then
				v.animationFrame = 5
			else
				v.animationFrame = 16
			end
			if Colliders.collide(plr,data.swordBox) and (v.animationFrame == 5 or v.animationFrame == 6) then
				plr:harm()
			end
			if data.timer == 94 then
				SFX.play("Woosh 2.wav")
				--Attack with the scythe
				data.sworderang = NPC.spawn(NPC.config[v.id].sworderangID, v.x + spawnOffset[v.direction], v.y + v.height / 2)
				data.sworderang.direction = v.direction
				data.sworderang.layerName = "Spawned NPCs"
				data.sworderang.data.parent = v
				data.sworderang.data.owner = v
			end
			--To get back up from its sword
			if data.timer >= 136 then
				v.speedX = 3 * -v.direction
			end
			if data.timer >= 148 then
				data.timer = 0
				v.ai1 = 1
			end
		elseif v.ai1 == 1 then
			npcutils.faceNearestPlayer(v)
			v.speedX = 0
				if data.timer >= 320 or not data.sworderang then
					data.timer = 0
					data.state = STATE_IDLE
					v.ai1 = 0
				else
					if Colliders.collide(v, data.sworderang) then
						data.sworderang:kill(9)
						data.sworderang = nil
						data.timer = 0
						v.ai1 = 2
					end
				end
			v.animationFrame = 16
		else
			npcutils.faceNearestPlayer(v)
			if data.timer < 8 then
				v.animationFrame = 2
			else
				v.animationFrame = 1
			end
			if data.timer >= 18 then
				data.timer = 0
				data.state = STATE_IDLE
				v.ai1 = 0
			end
		end
	else
		--Death stuff
		--Make the npc flash to show it's almost dead
		if lunatime.tick() % 64 > 4 then
			if v.ai1 == 0 then
				v.animationFrame = 19
				if v.collidesBlockBottom and data.timer >= 8 then
					v.ai1 = 1
					SFX.play(37)
					Defines.earthquake = 7
				end
			else
				v.animationFrame = 20
			end
		else
			v.animationFrame = -50
		end
		
		--Bounce a little bit to simulate physics
		if v.collidesBlockBottom and data.timer >= 8 then
			if math.abs(v.speedX) >= 2 then
				v.speedX = v.speedX / 2
				v.speedY = -3
			else
				v.speedX = 0
			end
			--Die after a bit
			if data.timer >= 386 then
				v:kill(HARM_TYPE_NPC)
				SFX.play("Boss Dead.wav")
			end
		end
	end
	
	--Give Gigant Edge some i-frames to make the fight less cheesable
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

	--Give Gigant Edge some i-frames for shield dynamics
	if data.state == STATE_SHIELD then
		if data.timer % 6 <= 3 and data.timer > 6 then
			v.animationFrame = -50
		end
	end
	
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
	end
	
	--Prevent Gigant Edge from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	
	if Colliders.collide(plr, v) and not v.friendly and data.state ~= STATE_KILL and not Defines.cheat_donthurtme then
		plr:harm()
	end
end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end
	if data.state ~= STATE_KILL then
		if reason ~= HARM_TYPE_LAVA then
			if reason == HARM_TYPE_JUMP or killReason == HARM_TYPE_SPINJUMP or killReason == HARM_TYPE_FROMBELOW then
				if data.state ~= STATE_SHIELD then
					SFX.play(2)
					data.iFrames = true
					data.health = data.health - 5
				else
					SFX.play(85)
				end
			elseif reason == HARM_TYPE_SWORD then
				if data.state ~= STATE_SHIELD then
					if v:mem(0x156, FIELD_WORD) <= 0 then
						data.health = data.health - 5
						data.iFrames = true
						SFX.play(89)
						v:mem(0x156, FIELD_WORD,20)
					end
				else
					SFX.play(85)
					if culprit then
						local effect = Animation.spawn(75, culprit.x, culprit.y)
						effect.x = effect.x
						effect.y = effect.y
					end
				end
				if Colliders.downSlash(player,v) then
					player.speedY = -6
				end
			elseif reason == HARM_TYPE_NPC then
				if data.state ~= STATE_SHIELD then
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
				else
					SFX.play(85)
					if culprit then
						local effect = Animation.spawn(75, culprit.x, culprit.y)
						effect.x = effect.x
						effect.y = effect.y
						if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50 and culprit.id ~= 781 and culprit.id ~= 779) and NPC.HITTABLE_MAP[culprit.id] then
							culprit:kill(HARM_TYPE_NPC)
						elseif type(culprit) == "NPC" and (NPC.HITTABLE_MAP[culprit.id] or culprit.id == 45) and culprit.id ~= 781 and culprit.id ~= 50 and v:mem(0x138, FIELD_WORD) == 0 then
							culprit:kill(HARM_TYPE_NPC)
						end
					end
				end
			elseif reason == HARM_TYPE_LAVA and v ~= nil then
				v:kill(HARM_TYPE_OFFSCREEN)
			elseif v:mem(0x12, FIELD_WORD) == 2 then
				v:kill(HARM_TYPE_OFFSCREEN)
			else
				if data.state ~= STATE_SHIELD then
					data.iFrames = true
					data.health = data.health - 5
				else
					SFX.play(85)
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
				elseif type(culprit) == "NPC" and (NPC.HITTABLE_MAP[culprit.id] or culprit.id == 45) and culprit.id ~= 50 and v:mem(0x138, FIELD_WORD) == 0 then
					culprit:kill(HARM_TYPE_NPC)
				end
			end
			if data.health <= 0 then
				data.state = STATE_KILL
				data.timer = 0
				v.ai1 = 0
				Effect.spawn(856,v.x - v.width / 2,v.y - v.width / 2)
				SFX.play("Miniboss Dead.wav")
				v.speedX = 2 * -v.direction
				v.speedY = -10
				if data.sworderang then
					data.sworderang:kill(9)
					data.sworderang = nil
				end
				for _,n in ipairs(NPC.get()) do
					if n.id == NPC.config[v.id].shockwaveID then
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

--Gotta return the library table!
return sampleNPC