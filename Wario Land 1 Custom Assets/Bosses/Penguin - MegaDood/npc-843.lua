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
	gfxheight = 96,
	gfxwidth = 100,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 58,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 20,
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
	noyoshi= false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	cliffturn = true,
	
	--The effect that spawns when the helmet is knocked off of the penguin
	helmetEffect = 844,
	--The effect that spawns when the boss gets hit
	stunnedEffect = 773,
	--X and Y offsets of the stunned effect
	effectSpawnX = 0,
	effectSpawnY = -24,
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
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=npcID,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]=npcID,
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local STATE_WALK = 1
local STATE_BOX = 2
local STATE_HURT = 3
local STATE_JUMP = 4

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCKill")
	registerEvent(sampleNPC, "onNPCHarm")
end

function isNearPit(v)
	--This function either returns false, or returns the direction the npc should go to. numbers can still be used as booleans.
	local testblocks = Block.SOLID.. Block.SEMISOLID.. Block.PLAYER

	local centerbox = Colliders.Box(v.x + 8, v.y, 8, v.height + 10)
	local l = centerbox
	if v.direction == DIR_RIGHT then
		l.x = l.x + 38
	end
	
	for _,centerbox in ipairs(
	  Colliders.getColliding{
		a = testblocks,
		b = l,
		btype = Colliders.BLOCK
	  }) do
		return false
	end
	
	return true
end

local boxOffset = {
[-1] = -sampleNPCSettings.width / 4,
[1] = 0
}

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
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
		data.initialized = true
		data.health = settings.health
		data.state = STATE_WALK
		data.helmet = 0
		data.timer = 0
		data.boxBox = data.boxBox or Colliders.Box(v.x, v.x, v.width + 16, v.height)
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_WALK
		data.timer = 0
		data.boxBox = nil
		return
	end
	
	--If this becomes nil then reset it when possible
	if not data.boxBox then data.boxBox = Colliders.Box(v.x, v.x, v.width + 16, v.height) end
	
	data.boxBox.x = v.x + boxOffset[v.direction]
	data.boxBox.y = v.y
			
	--Interact with NPCs
	npcs = Colliders.getColliding{a = data.boxBox,btype = Colliders.NPC}
	
	-- Interact with blocks
	local tbl = Block.SOLID .. Block.PLAYER
	list = Colliders.getColliding{
	a = data.boxBox,
	b = tbl,
	btype = Colliders.BLOCK,
	filter = function(other)
		if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
			return false
		end
		return true
	end
	}

	data.timer = data.timer + 1
	
	--Bump Wario and Bowser
	for _,p in ipairs(Player.get()) do
		if p.character == CHARACTER_WARIO or p.character == CHARACTER_BOWSER then
			if p.powerup > 1 then
				if Colliders.collide(p, v) then
					SFX.play(3)
					if (p.x + 0.5 * p.width) < (v.x + v.width*0.5) then
						p.speedX = -5
					else
						p.speedX = 5
					end
				end
			end
		else
			if Colliders.collide(p, v) and not v.friendly then
				p:harm()
			end
		end
	end
	
	if data.state == STATE_WALK then
	
		--If it's about to walk off a cliff or run into a wall, begin the turn ai
		if isNearPit(v) and v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockRight then
			data.isTurning = true
			data.turnTimer = data.turnTimer or 0
		end
	
		if not data.isTurning then
			--Simply walk about
			v.speedX = 2 * v.direction
			data.turnTimer = 0
			
			if data.timer >= 64 and v:mem(0x12C, FIELD_WORD) == 0 then
				data.timer = 0
				data.state = STATE_BOX
			end
			
			--Hit Blocks
			for _,b in ipairs(list) do
				if (Block.config[b.id].smashable ~= nil and Block.config[b.id].smashable == 3) then
					data.timer = 0
					data.state = STATE_BOX
				end
			end

			--Push or hurt NPCs
			for _,npc in ipairs(npcs) do
				if npc ~= v then
					if not NPC.config[npc.id].iscollectable and not NPC.config[npc.id].iscoin and not npc.isHidden then
						data.timer = 0
						data.state = STATE_BOX
					end
				end
			end
			
		else
			--Turning thing
			data.turnTimer = data.turnTimer + 1
			v.speedX = 0
			if data.turnTimer == 64 then
				v.direction = -v.direction
			elseif data.turnTimer == 128 then
				data.isTurning = false
				data.timer = 0
			end
		end
		
		--Animation stays consistent regardless of what happens
		v.animationFrame = math.floor(data.timer / 8) % 4 + data.helmet
		
	elseif data.state == STATE_BOX then
	
		v.speedX = 0
		v.animationFrame = math.floor(data.timer / 8) % 4 + (4 + data.helmet)
		
		if data.timer == 1 or data.timer == 12 then
			SFX.play(77)
		elseif data.timer == 24 then
			data.timer = 0
			data.state = STATE_WALK
		end
		
		--Hurt players
		for _,p in ipairs(Player.get()) do
			if (Colliders.collide(p, data.boxBox) and v:mem(0x12C, FIELD_WORD) == 0) and not v.friendly then
				p:harm()
			end
		end
		
		--Hit Blocks
		for _,b in ipairs(list) do
			if (Block.config[b.id].smashable ~= nil and Block.config[b.id].smashable == 3) then
				b:remove(true)
			else
				b:hit(true)
			end
		end

		--Push or hurt NPCs
		for _,npc in ipairs(npcs) do
			if npc ~= v then
				if not NPC.config[npc.id].iscollectable and not NPC.config[npc.id].iscoin and not npc.isHidden then
					if npc.id == 45 then npc.ai1 = 1 end
					npc.speedX = 4 * v.direction
					npc.speedY = -6
					if not NPC.config[npc.id].powerup then
						npc.isProjectile = true
					end
					npc.dontMove = false
					if NPC.config[npc.id].grabtop or NPC.config[npc.id].grabside then
						SFX.play(3)
					else
						npc:harm(HARM_TYPE_NPC)
					end
				end
			end
		end
	elseif data.state == STATE_HURT then
		--Stand still for a bit and play an animation
		v.friendly = true
		v.speedX = 0
		data.helmet = 0
		
		--Move the stun effect with the NPC, if something causes it to move
		data.effect.x = v.x
		data.effect.y = v.y - 24
		
		--Animate, then cause it to jump
		if data.timer >= 32 then
			v.animationFrame = 0
			if data.timer >= 64 then
				data.timer = 0
				data.state = STATE_JUMP
			end
		else
			v.animationFrame = 9
		end
	else
		--Animation
		if data.rise == nil then
			v.animationFrame = 0
			--Make it jump offscreen, then when at the bottom have it come back up
			if not v.collidesBlockBottom then data.timer = 0 end
			if v.y >= camera.y + 640 then
				if settings.helmet then
					data.helmet = 10
				end
				data.rise = 1
				data.holdY = v.y
			end
		else
			if data.timer >= 96 then
				if data.timer == 96 then SFX.play(24) end
				--If not at the same y-coords as when it got hit
				if v.y > data.hitY then
					if v.noblockcollision then
						v.speedY = -6
					end
				else
					--When there, start the next part of the state
					v.noblockcollision = false
				end
				
				--Animation
				if v.noblockcollision then
					v.animationFrame = 8 + data.helmet
				else
					v.animationFrame = 0 + data.helmet
					--When finally touching the ground at the end of the state, go back to walking
					if v.collidesBlockBottom then
						data.timer = 0
						v.friendly = false
						data.state = STATE_WALK
						data.rise = nil
					end
				end
			else
				--When offscreen, linger there a bit before coming back up
				v.despawnTimer = 180
				v.animationFrame = -50
				v.y = data.holdY
			end
		end
		--Right at the start of the state, jump offscreen
		if data.timer >= 33 and v.collidesBlockBottom then
			v.speedY = -5
			v.noblockcollision = true
			SFX.play(1)
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
			if data.helmet == 0 then
				npc:harm(HARM_TYPE_JUMP)
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
							culprit:harm()
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