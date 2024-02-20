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
	frames = 10,
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
	
	--The effect that spawns when the helmet is knocked off of the penguin
	killEffect = 10,
	--The effect that spawns when the boss gets hit
	bulletID = 773,
	--X and Y offsets of the bullet spawns
	bulletSpawnX = {
		[1] = 16,
		[-1] = -16,
	},
	bulletSpawnY = -24,
	walkDelays = {
		[0] = 64, --Minimum
		[1] = 160, --Maximum
	},
	--Spawn Procedures for each round of shots in STATE_SHOOT
	shootRoundDelay = 48,
	bulletBillSets = {
		[0] = {
			id = 17,
			speedX = 3,
			speedY = 0
			delay = 12,
			effect = 10,
			SFX = 22,
		},
		[1] = {
			id = 17,
			speedX = 3,
			speedY = 0
			delay = 12,
			effect = 10,
			SFX = 22,
		},
		[2] = {
			id = 17,
			speedX = 3,
			speedY = 0
			delay = 60,
			effect = 10,
			SFX = 22,
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
		[HARM_TYPE_NPC]=sampleNPCSettings.killEffect,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]=sampleNPCSettings.killEffect,
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local STATE_WALK = 1
local STATE_SHOOT = 2
local STATE_RAM = 3
local STATE_SPINOUT = 4

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

		data.initialized = true
		data.health = settings.health
		data.state = STATE_WALK
		data.timer = 0
		data.walkTimer = 0
		v.ai1 = 0 --Sub-States
		v.ai2 = 0 --Spin Out Timer
		v.ai3 = 0 --Spin Out Cannon Direction
		v.ai4 = 0 --Frame Timer
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
		v.speedX = 1.5 * v.direction
		data.walkTimer = data.walkTimer + 1
		
		if data.walkTimer % 48 == 0 and v:mem(0x12C, FIELD_WORD) == 0 then
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
			if data.state == STATE_WALK then
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
				if data.helmet > 0 then
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
				end
			end
			
			data.health = data.health - 8
			if data.health > 0 then	SFX.play("WL1 Boss Hit.wav") data.effect = Effect.spawn(NPC.config[v.id].stunnedEffect, NPC.config[v.id].effectSpawnX, NPC.config[v.id].effectSpawnY) end
			data.hitY = v.y
			data.state = STATE_HURT
			Misc.givePoints(2, {x = v.x + (v.width / 2.5),y = v.y + (v.height / 2.5)}, true)
			data.timer = 0
				
		elseif reason == HARM_TYPE_NPC then
			--Interact with Superballs and bullets from Marine Pop and Sky Pop for minor damage
			if culprit then
				if type(culprit) == "NPC" then
					if data.helmet == 0 then
						if culprit.id == 13 or NPC.config[culprit.id].SMLDamageSystem then
							SFX.play(9)
							data.health = data.health - 2
						else
							data.health = data.health - 8
							if data.health > 0 then	SFX.play("WL1 Boss Hit.wav") data.effect = Effect.spawn(NPC.config[v.id].stunnedEffect, NPC.config[v.id].effectSpawnX, NPC.config[v.id].effectSpawnY) end
							data.hitY = v.y
							data.state = STATE_HURT
							Misc.givePoints(2, {x = v.x + (v.width / 2.5),y = v.y + (v.height / 2.5)}, true)
							data.timer = 0
						end
					else
						data.helmet = 0
						SFX.play(3)
						Effect.spawn(NPC.config[v.id].helmetEffect, v.x + NPC.config[v.id].effectSpawnX, v.y + NPC.config[v.id].effectSpawnY)
					end
				else
					data.health = data.health - 8
					if data.health > 0 then	SFX.play("WL1 Boss Hit.wav") data.effect = Effect.spawn(NPC.config[v.id].stunnedEffect, NPC.config[v.id].effectSpawnX, NPC.config[v.id].effectSpawnY) end
					data.hitY = v.y
					data.state = STATE_HURT
					Misc.givePoints(2, {x = v.x + (v.width / 2.5),y = v.y + (v.height / 2.5)}, true)
					data.timer = 0
				end
			else
				for _,n in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
					if NPC.config[n.id].SMLDamageSystem then
						if data.helmet == 0 then
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
							data.helmet = 0
							SFX.play(3)
							Effect.spawn(NPC.config[v.id].helmetEffect, v.x + NPC.config[v.id].effectSpawnX, v.y + NPC.config[v.id].effectSpawnY)
						end
						return
					end
				end
				
				if data.helmet == 0 then
					data.health = data.health - 8
					if data.health > 0 then	SFX.play("WL1 Boss Hit.wav") data.effect = Effect.spawn(NPC.config[v.id].stunnedEffect, NPC.config[v.id].effectSpawnX, NPC.config[v.id].effectSpawnY) end
					data.hitY = v.y
					data.state = STATE_HURT
					Misc.givePoints(2, {x = v.x + (v.width / 2.5),y = v.y + (v.height / 2.5)}, true)
					data.timer = 0
				else
					SFX.play(3)	
					data.helmet = 0
					Effect.spawn(NPC.config[v.id].helmetEffect, v.x + NPC.config[v.id].effectSpawnX, v.y + NPC.config[v.id].effectSpawnY)
				end
			end
		elseif v:mem(0x12, FIELD_WORD) == 2 then
			v:kill(HARM_TYPE_OFFSCREEN)
		else
			if data.helmet == 0 then
				data.state = STATE_HURT
				data.timer = 0
				data.health = data.health - 8
				if data.health > 0 then	SFX.play("WL1 Boss Hit.wav") data.effect = Effect.spawn(NPC.config[v.id].stunnedEffect, NPC.config[v.id].effectSpawnX, NPC.config[v.id].effectSpawnY) end
				data.hitY = v.y
				Misc.givePoints(2, {x = v.x + (v.width / 2.5),y = v.y + (v.height / 2.5)}, true)
			else
				data.helmet = 0
				SFX.play(3)
				Effect.spawn(NPC.config[v.id].helmetEffect, v.x + NPC.config[v.id].effectSpawnX, v.y + NPC.config[v.id].effectSpawnY)
				eventObj.cancelled = true
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
			v:kill(HARM_TYPE_NPC)
		elseif data.health > 0 then
			if data.state == STATE_HURT then
				v:mem(0x156,FIELD_WORD,60)
			end
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
	SFX.play("WL1 Boss Dead.wav")
end

--Gotta return the library table!
return sampleNPC