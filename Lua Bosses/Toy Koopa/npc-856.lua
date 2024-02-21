--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 80,
	gfxwidth = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 48,
	height = 48,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 15,
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
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	score = 8,

	staticdirection = true,
	
	--The effect that spawns when the helmet is knocked off of the penguin
	killEffect = 10,
	--The effect that spawns when the boss gets hit
	bulletID = 17,
	spinOutBulletSpeedX = 5,
	--X and Y offsets of the bullet spawns
	bulletSpawnX = {
		[1] = 16,
		[-1] = -16,
	},
	bulletSpawnY = -32,
	walkDelays = {
		[0] = 64, --Minimum
		[1] = 160, --Maximum
	},
	ramDelay = 60,
	spinoutReady = 60,
	spinoutDelay = 300,
	stunnedDelay = 80,
	shellSpeed = 4,
	walkSpeed = 1.5,
	turnAroundDelay = 48,
	sfx_cannon_ready = Misc.resolveFile("mechakoopa_blaster_prepare.wav"),
	sfx_cannon = Misc.resolveFile("mechakoopa_blaster_fire.wav"),
	--Spawn Procedures for each round of shots in STATE_SHOOT
	shootRoundDelay = 48,
	bulletBillSets = {
		[0] = {
			id = cannonID,
			speedX = 3,
			speedY = 0
			delay = 12,
			effect = 10,
			SFX = sfx_cannon,
		},
		[1] = {
			id = cannonID,
			speedX = 3,
			speedY = 0
			delay = 12,
			effect = 10,
			SFX = sfx_cannon,
		},
		[2] = {
			id = cannonID,
			speedX = 3,
			speedY = 0
			delay = 60,
			effect = 10,
			SFX = sfx_cannon,
		},
	},
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
		--HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]=sampleNPCSettings.killEffect,
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local STATE_WALK = 1
local STATE_SHOOT = 2
local STATE_RAM = 3
local STATE_SPINOUT = 4

local effectOffsetSkid = {
	[-1] = sampleNPCSettings.skidOffset[-1],
	[1] = sampleNPCSettings.skidOffset[1]
}

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCKill")
	registerEvent(sampleNPC, "onNPCHarm")
end

local bulletOffset = {
[-1] = sampleNPCSettings.bulletSpawnX[-1],
[1] = sampleNPCSettings.bulletSpawnX[1]
}

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]
	
	local list
	local npcs
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		if settings.spinOutSet == nil then settings.spinOutSet = 0 end
		if settings.health == nil then settings.health = 32 end 
		data.initialized = true
		data.health = settings.health or 32
		data.state = STATE_WALK
		data.timer = 0
		data.walkTimer = 0
		v.ai1 = 0 --Sub-States
		v.ai2 = 1 --Spin Out Timer
		v.ai3 = 0 --Spin Out Cannon Direction
		v.ai4 = 0 --Frame Timer (Unused; Non-Implemented)
		v.ai5 = 0 --Bullet Bill Consecutive
		data.rnd = RNG.randomInt(config.walkDelays[0],config.walkDelays[1])
		data.guaranteed = false --Guarantees a cannon attack after using ram or spinout attack in a walking state

	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_WALK
		data.timer = 0
		return
	end

	data.timer = data.timer + 1
	
	if data.state == STATE_WALK then
		--Simply walk about
		v.speedX = config.walkSpeed * v.direction
		data.walkTimer = data.walkTimer + 1
		
		if data.walkTimer % config.turnAroundDelay == 0 and v:mem(0x12C, FIELD_WORD) == 0 then
			npcutils.faceNearestPlayer(v)
		end

		if data.timer >= data.rnd then
			data.rnd = RNG.randomInt(config.walkDelays[0],config.walkDelays[1])
			data.timer = 0
			local options = {}
			if data.guaranteed == false then
				if settings.spinOutSet == 0 then
					table.insert(options,STATE_SHOOT)
					table.insert(options,STATE_SHOOT)
					table.insert(options,STATE_RAM)
				else
					table.insert(options,STATE_SHOOT)
					table.insert(options,STATE_SHOOT)
					table.insert(options,STATE_RAM)
					if (settings.spinOutSet == 1) or (settings.spinOutSet == 2 and data.health <= settings.health / 2) then
						table.insert(options,STATE_SPINOUT)
					end
				end
			else
				table.insert(options,STATE_SHOOT)
			end
			if #options > 0 then
				data.state = RNG.irandomEntry(options)
				npcutils.faceNearestPlayer(v)
				if (data.state == STATE_RAM or data.state == STATE_SPINOUT) and data.guaranteed == false then
					data.guaranteed = true
				end
			end
		end
		--Animation stays consistent regardless of what happens
		v.animationFrame = math.floor(data.timer / 8) % 2
	elseif data.state == STATE_SHOOT then
		v.speedX = 0
		v.animationFrame = 2
		if data.timer == 1 then v.ai5 = 0 end
		if data.timer == 1 and config.sfx_cannon_ready then SFX.play(config.sfx_cannon_ready.SFX, config.sfx_cannon_ready.delay) end
		if data.timer >= config.shootRoundDelay then
			if config.bulletBillSets[v.ai5] then
				if data.timer == config.shootRoundDelay then
					if config.bulletBillSets[v.ai5].SFX then SFX.play(config.bulletBillSets[v.ai5].SFX) end
					if config.bulletBillSets[v.ai5].id then
						local n = NPC.spawn(config.bulletBillSets[v.ai5].id, v.x + v.width/2 + config.bulletSpawnX[v.direction], v.y + v.height/2 + config.bulletSpawnY, v.section, true, true)
						if config.bulletBillSets[v.ai5].speedX then
							n.speedX = config.bulletBillSets[v.ai5].speedX * v.direction
						end
						if config.bulletBillSets[v.ai5].speedY then
							n.speedY = config.bulletBillSets[v.ai5].speedY
						end
					end
					if config.bulletBillSets[v.ai5].effect then
						local a = Animation.spawn(config.bulletBillSets[v.ai5].effect, v.x + v.width/2 + config.bulletSpawnX[v.direction], v.y + v.height/2 + config.bulletSpawnY, v.section)
						a.x=a.x-a.width/2
						a.y=a.y-a.height/2
					end
				elseif data.timer >= config.shootRoundDelay + config.bulletBillSets[v.ai5].delay then
					data.timer = config.shootRoundDelay
					v.ai5 = v.ai5 + 1
				end
			else
				v.ai5 = 0
				data.timer = 0
				data.state = STATE_WALK
			end
		end
	elseif data.state == STATE_RAM then
		if v.ai1 == 0 then
			if data.timer < config.ramDelay then
				v.animationFrame = 3
				v.speedX = 0
			else
				v.animationFrame = math.floor(data.timer / 6) % 4 + 3
				v.speedX = config.shellSpeed * v.direction
				if (v.collidesBlockLeft and v.direction == -1) or (v.collidesBlockRight and v.direction == 1) then
					data.timer = 0
					v.ai1 = 1
					v.speedX = 2 * -v.direction
					v.speedY = -4
					SFX.play(37)
					if v.collidesBlockLeft then
						Animation.spawn(75,v.x-16,v.y+v.height/2-16)
					elseif v.collidesBlockRight then
						Animation.spawn(75,v.x+v.width-16,v.y+v.height/2-16)
					end
				end
			end
		else
			v.animationFrame = 3
			if v.colldesBlockBottom then
				v.speedX = 0
			end
			if data.timer >= config.stunnedDelay then
				data.timer = 0
				data.state = STATE_WALK
				npcutils.faceNearestPlayer(v)
				v.ai1 = 0
			end
		end
	elseif data.state == STATE_SPINOUT then
		if v.ai1 == 0 then
			v.animationFrame = math.floor(v.ai2 / 6) % 8 + 7
			v.speedX = 0
			if data.timer >= config.spinoutReady then
				data.timer = 0
				v.ai1 = 1
			end
		elseif v.ai1 == 1 then
			v.speedX = config.shellSpeed * v.direction
			v.ai2 = v.ai2 + 1 * v.direction
			v.ai3 = (math.floor(v.ai2 / 24) % 2) * 2 - 1
			v.animationFrame = math.floor((v.ai2 + 1) / 6) % 8 + 7
			if v.collidesBlockLeft or v.collidesBlockRight then
				v.direction = -v.direction
				SFX.play(3)
				if v.collidesBlockLeft then
					Animation.spawn(75,v.x-16,v.y+v.height/2-16)
				elseif v.collidesBlockRight then
					Animation.spawn(75,v.x+v.width-16,v.y+v.height/2-16)
				end
			end
			if data.timer >= config.spinoutDelay then
				data.timer = 0
				v.ai1 = 2
			end
			if v.ai2 % 24 == 0 then
				if config.sfx_cannon then SFX.play(config.sfx_cannon) end
				local n = NPC.spawn(config.bulletBillSets[v.ai5].id, v.x + v.width/2 + config.bulletSpawnX[v.direction], v.y + v.height/2 + config.bulletSpawnY, v.section, true, true)
				if config.bulletBillSets[v.ai5].effect then
					local a = Animation.spawn(config.bulletBillSets[v.ai5].effect, v.x + v.width/2 + config.bulletSpawnX[v.direction], v.y + v.height/2 + config.bulletSpawnY)
					a.x=a.x-a.width/2
					a.y=a.y-a.height/2
				end
				n.speedX = config.spinOutBulletspeedX * v.direction * v.ai3
			end
		elseif v.ai1 == 2 then
			v.ai2 = v.ai2 + 0.5 * v.direction
			v.animationFrame = math.floor(v.ai2 / 6) % 8 + 7
			v.speedX = v.speedX - 0.4 * v.direction
			Effect.spawn(74, v.x + effectOffsetSkid[v.direction], v.y + v.height)
			if data.timer % 8 == 0 then
				SFX.play(10)
			end
			if math.abs(v.speedX) <= 0.4 then
				v.speedX = 0
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_IDLE
			end
		end
	end
	
	--Flip animation if it changes direction
	if v.animationFrame >= 0 then
		v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
	end
	
	--If the player is ground pounding, do all this
	if (player.character == CHARACTER_WARIO and player.keys.altJump and player.powerup > 1) then
		player.data.isGroundPounding = true
	end
	
	if player:isGroundTouching() then player.data.isGroundPounding = nil end
	
	--Handle interactions with ground pounds
	for _, npc in ipairs(NPC.getIntersecting(player.x, player.y + player.height, player.x + player.width, player.y + player.height + 30)) do
		if player.speedY > 0 and npc.id == v.id and player.data.isGroundPounding then
			if data.state == STATE_SHOOT then
				npc:harm(HARM_TYPE_JUMP)
			elseif data.state == STATE_RAM or data.state == STATE_SPINOUT then
				SFX.play(2)
			else
				player:harm()
			end
		end
	end
	
end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end
	
	if reason ~= HARM_TYPE_LAVA then
		if reason ~= HARM_TYPE_NPC then
		
			if reason == HARM_TYPE_SWORD then
				if Colliders.downSlash(player,v) then
					player.speedY = -6
					SFX.play(2)
				else
					if v:mem(0x156, FIELD_WORD) <= 0 then
						SFX.play(89)
						v:mem(0x156, FIELD_WORD,20)
					end
				end
			end
		
			if reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP then
				if data.state == STATE_WALK then
					if type(culprit) == "Player" then
						if reason == HARM_TYPE_JUMP then
							if not culprit:mem(0x50,FIELD_BOOL) then
								culprit:harm()
							else
								SFX.play(2)
							end
						else
							SFX.play(2)
						end
					end
					eventObj.cancelled = true
					return
				elseif data.state == STATE_RAM or data.state == STATE_SPINOUT then
					SFX.play(2)
					eventObj.cancelled = true
					return
				else
					SFX.play(2)
				end
			end
			if data.state == STATE_WALK or data.state == STATE_SHOOT then
				data.health = data.health - 8
				if data.health > 0 then	SFX.play(39) end
				data.state = STATE_RAM
				v.ai1 = 0
				Misc.givePoints(2, {x = v.x + (v.width / 2.5),y = v.y + (v.height / 2.5)}, true)
				data.timer = 0
			else
				SFX.play(2)
			end
		elseif reason == HARM_TYPE_NPC then
			--Interact with Superballs and bullets from Marine Pop and Sky Pop for minor damage
			if culprit then
				if type(culprit) == "NPC" then
					if data.state == STATE_WALK or data.state == STATE_SHOOT then
						if culprit.id == 13 or NPC.config[culprit.id].SMLDamageSystem then
							SFX.play(9)
							data.health = data.health - 2
						else
							data.health = data.health - 8
							if data.health > 0 then	SFX.play(39) data.effect = Effect.spawn(NPC.config[v.id].stunnedEffect, NPC.config[v.id].effectSpawnX, NPC.config[v.id].effectSpawnY) end
							data.state = STATE_RAM
							v.ai1 = 0
							Misc.givePoints(2, {x = v.x + (v.width / 2.5),y = v.y + (v.height / 2.5)}, true)
							data.timer = 0
						end
					else
						if v:mem(0x156, FIELD_WORD) <= 0 then
							SFX.play(3)
							if culprit then
								Animation.spawn(75, culprit.x, culprit.y)
								culprit.speedX = -(culprit.speedX + 2)
								culprit.speedY = -8
								if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
									culprit:kill(HARM_TYPE_NPC)
								end
							end
							v:mem(0x156, FIELD_WORD,3)
						end
					end
				else
					if data.state == STATE_WALK or data.state == STATE_SHOOT then
						data.health = data.health - 8
						if data.health > 0 then	SFX.play(39) data.effect = Effect.spawn(NPC.config[v.id].stunnedEffect, NPC.config[v.id].effectSpawnX, NPC.config[v.id].effectSpawnY) end
						data.state = STATE_RAM
						v.ai1 = 0
						Misc.givePoints(2, {x = v.x + (v.width / 2.5),y = v.y + (v.height / 2.5)}, true)
						data.timer = 0
					else
						if v:mem(0x156, FIELD_WORD) <= 0 then
							SFX.play(3)
							if culprit then
								Animation.spawn(75, culprit.x, culprit.y)
								culprit.speedX = -(culprit.speedX + 2)
								culprit.speedY = -8
								if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
									culprit:kill(HARM_TYPE_NPC)
								end
							end
							v:mem(0x156, FIELD_WORD,3)
						end
					end
				end
			else
				for _,n in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
					if NPC.config[n.id].SMLDamageSystem then
						if data.state == STATE_WALK or data.state == STATE_SHOOT then
							if v:mem(0x156, FIELD_WORD) <= 0 then
								data.health = data.health - 2
								v:mem(0x156, FIELD_WORD,5)
								SFX.play(9)
								Animation.spawn(75, n.x, n.y)
								if data.health <= 0 then
									v:kill(HARM_TYPE_NPC)
								end
							end
						else
							SFX.play(3)
						end
						return
					end
				end
				
				if data.state == STATE_WALK or data.state == STATE_SHOOT then
					data.health = data.health - 8
					if data.health > 0 then	SFX.play(39) end
					data.hitY = v.y
					data.state = STATE_HURT
					Misc.givePoints(2, {x = v.x + (v.width / 2.5),y = v.y + (v.height / 2.5)}, true)
					data.timer = 0
				else
					if v:mem(0x156, FIELD_WORD) <= 0 then
						SFX.play(3)
						if culprit then
							Animation.spawn(75, culprit.x, culprit.y)
							culprit.speedX = -(culprit.speedX + 2)
							culprit.speedY = -8
							if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
								culprit:kill(HARM_TYPE_NPC)
							end
						end
						v:mem(0x156, FIELD_WORD,3)
					end
				end
			end
		elseif v:mem(0x12, FIELD_WORD) == 2 then
			v:kill(HARM_TYPE_OFFSCREEN)
		else
			if data.state == STATE_WALK or data.state == STATE_SHOOT then
				data.health = data.health - 8
				if data.health > 0 then	SFX.play(39) end
				data.hitY = v.y
				data.state = STATE_HURT
				Misc.givePoints(2, {x = v.x + (v.width / 2.5),y = v.y + (v.height / 2.5)}, true)
				data.timer = 0
			else
				if v:mem(0x156, FIELD_WORD) <= 0 then
					SFX.play(3)
					if culprit then
						Animation.spawn(75, culprit.x, culprit.y)
						culprit.speedX = -(culprit.speedX + 2)
						culprit.speedY = -8
						if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
							culprit:kill(HARM_TYPE_NPC)
						end
					end
					v:mem(0x156, FIELD_WORD,3)
				end
			end
		end
		
		if culprit then
			if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
				culprit:kill(HARM_TYPE_NPC)
			elseif type(culprit) == "NPC" and (NPC.HITTABLE_MAP[culprit.id] or culprit.id == 45) and culprit.id ~= 50 and v:mem(0x138, FIELD_WORD) == 0 then
				culprit:kill(HARM_TYPE_NPC)
			end
		end
		
		if data.health <= 0 then
			v:kill(HARM_TYPE_SPINJUMP)
		elseif data.health > 0 then
			v:mem(0x156,FIELD_WORD,20)
		end
	else
		v:kill(HARM_TYPE_LAVA)
	end
	eventObj.cancelled = true
end

function sampleNPC.onNPCKill(eventObj,v,reason)
	local data = v.data
	if v.id ~= npcID then return end
	if reason == HARM_TYPE_OFFSCREEN then return end
	if v.legacyBoss and reason ~= HARM_TYPE_LAVA then
	  local ball = NPC.spawn(16, v.x, v.y)
		ball.x = ball.x + ((v.width - ball.width) / 2)
		ball.y = ball.y + ((v.height - ball.height) / 2)
		ball.speedY = -6
		ball.despawnTimer = 100
				
		SFX.play(20)
	end
end

--Gotta return the library table!
return sampleNPC