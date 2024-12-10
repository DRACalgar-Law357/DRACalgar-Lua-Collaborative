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
	gfxwidth = 80,
	gfxheight = 80,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 64,
	--Frameloop-related
	frames = 4,
	framestyle = 1,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes
	
	nowaterphysics = true,
	staticdirection = true, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	noblockcollision = true,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC

	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce

	score = 8,
	spawnCoinID = 844,
	spawnID = npcID + 1,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=npcID,
	}
);

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onStartNPC")
	registerEvent(sampleNPC, "onTick")
	registerEvent(sampleNPC, "onNPCKill")
	registerEvent(sampleNPC, "onNPCHarm")
end

local bgoTable
local randomBgo

function sampleNPC.onStartNPC(v)
	bgoTable = BGO.get(NPC.config[v.id].warpPointBGO)
end

--Turn coins into boss projectiles
function sampleNPC.onTick()
	for _,n in NPC.iterate(npcID) do
		for _,v in NPC.iterate(NPC.config[n.id].spawnCoinID) do
			local data = v.data
			v.friendly = true
			if data.spawnedFromBoss then
				for _,p in ipairs(Player.get()) do
					if math.abs(v.y - p.y) <= 8 then
						v.friendly = false
						v.noblockcollision = false
						npcutils.faceNearestPlayer(v)
						v:transform(NPC.config[n.id].spawnID)
					end
				end
			end
		end
	end
end

local STATE_DECIDE = 0
local STATE_ARC1 = 1
local STATE_ARC2 = 2
local STATE_ARC3 = 3
local STATE_SPAWNENEMIES3 = 4
local STATE_TRAVEL = 5
local STATE_HURT = 6

local function spawnEnemy(v)
	--Spawn an enemy to hurt the boss with
	local n = NPC.spawn(NPC.config[v.id].spawnCoinID, v.x + v.width * 0.5, v.y, player.section, false)
	SFX.play(14)
	n.data.spawnedFromBoss = true
	n.noblockcollision = true
	n.ai1 = 1
	n.speedX = 3 * v.direction
	n.speedY = -4
	v.data.timer = 0
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	local settings = v.data._settings
	
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
		data.timer = 0
		data.state = STATE_DECIDE
		data.keepPos = vector.zero2
		data.keepPosTimer = 0
		data.random = RNG.randomInt(1,5)
	end

	data.timer = data.timer + 1

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		return
	end
	
	for _,p in ipairs(Player.get()) do
		
		--If the player touches the boss, freeze them in place
		if data.state ~= STATE_HURT then
			if not v.friendly and not v.isHidden and Colliders.collide(p, v) and data.keepPos == vector.zero2 then
				if settings.harm then
					data.keepPos.x = p.x
					data.keepPos.y = p.y
					data.keepPosTimer = 1
					SFX.play(13)
				else
					p:harm()
				end
			end
			
			--Try and stay within camera bounds
			if v.x < camera.x then
				v.direction = 1
			elseif v.x > camera.x + camera.width - 64 then
				v.direction = -1
			end
			
			if data.state == STATE_DECIDE then
				data.state = data.random
				data.random = RNG.randomInt(1,5)
				npcutils.faceNearestPlayer(v)
			elseif data.state == STATE_ARC1 then
				--Move in an arc motion
				if data.timer >= 192 then
					spawnEnemy(v)
					npcutils.faceNearestPlayer(v)
					data.state = STATE_TRAVEL
				end
				v.speedX = 4 * v.direction
				v.y = v.y + -96 * math.pi/48 * -math.sin(math.pi/48*data.timer)
			elseif data.state == STATE_ARC2 then
				--Move in an arc motion
				if data.timer >= 576 then
					spawnEnemy(v)
					npcutils.faceNearestPlayer(v)
					data.state = STATE_TRAVEL
				end
				v.speedX = 2 * v.direction
				v.y = v.y + -128 * math.pi/48 * -math.sin(math.pi/48*data.timer)
			elseif data.state == STATE_ARC3 then
				if data.cantDoState then data.state = STATE_TRAVEL data.timer = 0 end
				--Swoop at the player, like the angry sun
				if data.timer >= 32 then
					v.x = v.x + (175 * -1 * math.pi/65 * math.cos(1 * math.pi/65*(data.timer - 192) / 2)) * v.direction
					v.y = v.y + 175 * -1 * math.pi/65 * math.sin(1 * math.pi/65*(data.timer - 192))
					if data.timer >= 96 then
						spawnEnemy(v)
						npcutils.faceNearestPlayer(v)
						data.state = STATE_DECIDE
						data.cantDoState = true
					end
				end
			elseif data.state == STATE_SPAWNENEMIES3 then
				npcutils.faceNearestPlayer(v)
				--Spawn three enemies
				if data.timer >= 32 then
					if data.timer % 32 == 1 then
						--Spawn an enemy to hurt the boss with
						local n = NPC.spawn(NPC.config[v.id].spawnCoinID, v.x + v.width * 0.5, v.y, player.section, false)
						SFX.play(14)
						n.data.spawnedFromBoss = true
						n.noblockcollision = true
						n.ai1 = 1
						n.speedX = 3 * v.direction
						n.speedY = -4
					end
					if data.timer >= 128 then
						data.state = STATE_DECIDE
						data.timer = 0
					end
				end
			elseif data.state == STATE_TRAVEL then
				--A state where the ghost travels to a certain BGO
				if bgoTable then
					if not randomBgo then
						randomBgo = RNG.irandomEntry(bgoTable)
					else
						data.dirVectr = vector.v2(
							(randomBgo.x + 16) - (v.x + v.width * 0.5),
							(randomBgo.y + 16) - (v.y + v.height * 0.5)
						):normalize() * 3
						v.speedX = data.dirVectr.x
						v.speedY = data.dirVectr.y
						if math.abs(v.x - randomBgo.x - 16) <= 36 and math.abs(v.y - randomBgo.y - 16) <= 36 then
							v.speedX = 0
							v.speedY = 0
							data.timer = 0
							data.state = STATE_DECIDE
							randomBgo = nil
							data.cantDoState = nil
						end
					end
				end
			end
		else
			--State if hurt
			v.speedX = 0
			v.speedY = 0
			
			--Stand still for a bit and play an animation
			v.friendly = true

			if data.timer >= 64 then
				data.timer = 0
				data.state = STATE_TRAVEL
				v.friendly = false
			end
		end
		
		--Code to handle freezing the player
		if data.keepPosTimer > 0 then
			data.keepPosTimer = data.keepPosTimer + 1
			p.x = data.keepPos.x
			p.y = data.keepPos.y
			if data.keepPosTimer >= 64 then
				data.keepPosTimer = 0
				data.keepPos = vector.zero2
			end
		end
	end
end

function sampleNPC.onDrawNPC(v)
	local data = v.data
	local config = NPC.config[v.id]
	
	--Flash constantly to make it look transparant
	if data.state ~= STATE_HURT then
		if lunatime.tick() % 2 <= 0 and v.data._settings.flash then
			v.animationFrame = -50
		else
			
			for _,p in ipairs(Player.get()) do if v.x < p.x then data.facePlayer = 1 else data.facePlayer = -1 end end
			
			if data.justHit then
				v.animationFrame = math.floor(lunatime.tick() / 8) % 2 + 1 + ((data.facePlayer + 1) * config.frames / 2)
			else
				v.animationFrame = math.floor(lunatime.tick() / 8) % 2 + ((data.facePlayer + 1) * config.frames / 2)
			end
		end
	else
		v.animationFrame = 3 + ((data.facePlayer + 1) * config.frames / 2)
	end
end

--Code to handle damaging the NPC
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
			
			data.health = data.health - 8
			if data.health > 0 then	SFX.play("WL1 Boss Hit.wav") end
			data.state = STATE_HURT
			Misc.givePoints(2, {x = v.x + (v.width / 2.5),y = v.y + (v.height / 2.5)}, true)
			data.timer = 0
				
		elseif reason == HARM_TYPE_NPC then
			--Interact with Superballs and bullets from Marine Pop and Sky Pop for minor damage
			if culprit then
				if type(culprit) == "NPC" then
					if culprit.id == 13 or NPC.config[culprit.id].SMLDamageSystem then
						SFX.play(9)
						data.health = data.health - 2
					else
						data.health = data.health - 8
						if data.health > 0 then	SFX.play("WL1 Boss Hit.wav") end
						data.state = STATE_HURT
						Misc.givePoints(2, {x = v.x + (v.width / 2.5),y = v.y + (v.height / 2.5)}, true)
						data.timer = 0
					end
				else
					data.health = data.health - 8
					if data.health > 0 then	SFX.play("WL1 Boss Hit.wav") end
					data.state = STATE_HURT
					Misc.givePoints(2, {x = v.x + (v.width / 2.5),y = v.y + (v.height / 2.5)}, true)
					data.timer = 0
				end
			else
				for _,n in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
					if NPC.config[n.id].SMLDamageSystem then
						if v:mem(0x156, FIELD_WORD) <= 0 then
							data.health = data.health - 2
							v:mem(0x156, FIELD_WORD,5)
							SFX.play(9)
							Animation.spawn(75, n.x, n.y)
							if data.health <= 0 then
								v:kill(HARM_TYPE_NPC)
							end
						end
						return
					end
				end
				
				data.health = data.health - 8
				if data.health > 0 then	SFX.play("WL1 Boss Hit.wav") end
				data.state = STATE_HURT
				Misc.givePoints(2, {x = v.x + (v.width / 2.5),y = v.y + (v.height / 2.5)}, true)
				data.timer = 0
			end
		elseif v:mem(0x12, FIELD_WORD) == 2 then
			v:kill(HARM_TYPE_OFFSCREEN)
		else
			data.state = STATE_HURT
			data.timer = 0
			data.health = data.health - 8
			if data.health > 0 then	SFX.play("WL1 Boss Hit.wav") end
			Misc.givePoints(2, {x = v.x + (v.width / 2.5),y = v.y + (v.height / 2.5)}, true)
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