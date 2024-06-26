local rng = require("rng")
local npcManager = require("npcManager");
local wiggler = {};
local npcutils = require("npcs/npcutils")
local playerStun = require("playerstun")

-- TODO: Implement onNPCIDChange and ice flower mechanics

wiggler.sharedBody = {
	gfxwidth = 72, 
	gfxheight = 104, 
	width = 64,
	height = 64,
	gfxoffsety = 8,
	frames = 4,
	framespeed = 8,
	framestyle = 1,
	jumphurt=0,
	nofireball=-1,
	noiceball=-1,
	noyoshi=-1,
	nogravity=0,
	cliffturn=false,
	hitScore = 1,
	score = 0,
	spinjumpsafe = true,
	terminalvelocity = 15, 
	trailcount=6,
	trailID = 752,
	distance = 48,
	angryID = 753,
	normalID = 751,

	--Behavior-related
	angryHealth = 5,
	walkingSpeed = 1.5,
	angryWalkingSpeed = 2.5,
	jumpHeight = 9,
	angryDelay = 400,
	jumpDelay = 70,
	canStomp = true,
	trailEffect = 752,

	--SFX
	angryWalkingID = 3,
	jumpSoundID = 1,
	angryChangeSoundID = 72,
	normalChangeSoundID = 50,
	stunSoundID = 37,
	hurtSoundID = 39,
	killSoundID = 9,
	moveWhenJumping = false,
	jumpCooldown = 250,
	positionPointBGO = 997,
	indicateID = 791,
	quaketable = {
		759,
	},
	fallAmount = 3,
	fallConsecutive = 2,
	quakeSpawnDelay = 48,
}


wiggler.sharedTrail = {
	gfxoffsetx = 0,
	gfxoffsety = 2,
	gfxwidth = 64, 
	gfxheight = 64, 
	width = 48,
	height = 48,
	frames = 4,
	framespeed = 8,
	framestyle = 1,
	noblockcollision=-1,
	jumphurt=0,
	nogravity=-1,
	nohurt=0,
	nofireball=-1,
	noiceball=-1,
	noyoshi=-1,
	score = 0,
	spinjumpsafe = true,

	angryID = 754,
	normalID = 752,
}

wiggler.speed = {}
wiggler.headMap = {}
wiggler.trailMap = {}

function wiggler.registerHead(id, config)
	local settings = npcManager.setNpcSettings(table.join(config, wiggler.sharedBody))

	npcManager.registerEvent(id, wiggler, "onTickNPC", "onTickHead")
	npcManager.registerEvent(id, wiggler, "onStartNPC", "initialize")
	npcManager.registerEvent(id, wiggler, "onDrawNPC", "onDrawHead")
	wiggler.speed[id] = NPC.config[id].speed
	wiggler.headMap[id] = true

	NPC.config[id].speed = 1
end

function wiggler.registerTrail(id, config)
	npcManager.setNpcSettings(table.join(config, wiggler.sharedTrail))
	
	npcManager.registerEvent(id, wiggler, "onTickNPC", "onTickBody")
	npcManager.registerEvent(id, wiggler, "onDrawNPC", "onDrawBody")
	wiggler.trailMap[id] = true
end

function wiggler.onInitAPI()	
	registerEvent(wiggler, "onNPCHarm");
end

local function setDir(dir, v)
	if dir then
		v.direction = 1
	else
		v.direction = -1
	end
end

local function getTrails(v,func)
	local data = v.data._basegame
	if data.trackedData then
		for k,t in ipairs(data.trackedData) do
			if t.isValid then
				func(t)
			end
		end
	end
end

function wiggler.initialize(v)
	if v.data._basegame.trackedData then return end
	
	local data = v.data._basegame
	local settings = v.data._settings
	
	local sec = v:mem(0x146, FIELD_WORD)
	local dir = v:mem(0xD8,FIELD_FLOAT)
	--set the hit set 0 for whenever the head takes a set of hits, it'll temporarily turn into an angry state and calm down after some time; 1 same as 0 but the angered segments must get hit to turn into calmed segments, the head won't calm down until all of its segments are calmed down.
	settings.hitSet = settings.hitSet or 0
	--Determines its hitpoints, if its hitSet is 0, it multiplies alongside its angryHealth, changing the v.hp but keeps it concisely as intended.
	settings.health = settings.health or 5
	--When defeated, if set to true, it stays in place and exploded in bts, leaving its segments dropping down. If set to false, it'll instantly die in a wiggle death effect.
	settings.makeFunniDeath = settings.makeFunniDeath or false
	--If set to 0, it won't jump. If set to 1, it'll jump up. If set to 2, it'll jump both and down through blocks.
	settings.jumpSet = settings.jumpSet or 0
	--If set true, periodically, it will make a short hop to cause things to fall from specified points that is if there is a specified BGO around.
	settings.isStomping = settings.isStomping or false

	if settings.hitSet == 0 then
		v.hp = settings.health * NPC.config[v.id].angryHealth
		data.hitSegments = false
	else
		v.hp = settings.health
		data.hitSegments = true
	end
	if v.direction == 0 then
		v.direction = rng.randomInt(0, 1) * 2 - 1
	end
	data.jumpSet = settings.jumpSet
	local cfg = NPC.config[v.id]
	
	v.noblockcollision = false
	
	data.trackedData = {}
	data.turningAngry = false
	data.chaseTimer = 0
	data.jumpTimer = 0
	data.walkTimer = 0
	data.jumpsDown = 0
	data.passthrough = 0
	data.ramTimer = 0
	data.groundTimer = 0 --slopes
	data.distance = cfg.distance
	data.isAngry = cfg.angryID == v.id
	data.canStomp = false
	data.bgoTable = BGO.get(NPC.config[v.id].positionPointBGO)
	data.stompTimer = 0
	data.isStomping = settings.isStomping
	data.stomping = false
	data.stompDelay = RNG.randomInt(300,420)

	data.canFunni = settings.makeFunniDeath
	data.makeFunniDeath = false
	data.deathTimer = 0

	data.blockCheckUp = Colliders.Box(v.x, v.y - 128, v.width, v.height)
		
	data.blockCheckDown = Colliders.Box(v.x, v.y + (v.height * 2), v.width, v.height)
	
	data.triedUp = false
	data.triedDown = false
	
	data.blockDetect = nil
	
	data.thrownFrames = 0
	
	data.stillJump = false
	
	for i = 1, cfg.trailcount do
		table.insert(data.trackedData, NPC.spawn(cfg.trailID, v.x, v.y, sec))
		data.trackedData[i]:mem(0xD8, FIELD_FLOAT, dir)
		data.trackedData[i].layerName = v.layerName
		data.trackedData[i].noMoreObjInLayer = v.noMoreObjInLayer
		data.finalTrail = data.trackedData[i]
	end
			
	for k, t in ipairs(data.trackedData) do
		t.friendly = v.friendly or (v:mem(0x12C, FIELD_WORD) > 0)
		if t.data._basegame == nil then t.data._basegame = {} end
		t.data._basegame.trackedData = data.trackedData[k-1]
		t.data._basegame.hierarchyPosition = k
		t.data._basegame.head = v
	end
	data.trackedData[1].data._basegame.trackedData = v
end

function wiggler.onDrawBody(v)
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 then
		return
	end
	
	if v.data._basegame == nil then v.data._basegame = {} end
	local data = v.data._basegame
	
	if (data.head and data.head.isValid) then
		npcutils.hideNPC(v)
	elseif v:mem(0xDC, FIELD_WORD) == 0 then
		v:kill(9)
	end
end

function wiggler.onDrawHead(v)
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 then
		return
	end
	
	if v.data._basegame == nil then v.data._basegame = {} end
	local data = v.data._basegame
	if not data.trackedData then return end

	for i = #data.trackedData, 1, -1 do
		local t = data.trackedData[i]
		if t.isValid then
			local tdata = t.data._basegame
			t.animationFrame = (v.animationFrame - tdata.hierarchyPosition)%NPC.config[t.id].frames + NPC.config[t.id].frames * (t.direction + 1) * 0.5
			npcutils.drawNPC(t)
		end
	end
	npcutils.drawNPC(v)

	npcutils.hideNPC(v)
end

local function squared(x)
	return math.min(x * x, math.abs(x)) * math.sign(x)
end

function wiggler.onTickHead(v)
	if Defines.levelFreeze then return end
	local data = v.data._basegame
	local settings = v.data._settings
	local onScreenValue = v:mem(0x12A, FIELD_WORD)
	local containVal = v:mem(0x138, FIELD_WORD)
	
	if v.isHidden or onScreenValue <= 0 or containVal > 0 then
		getTrails(v, function(t) t:kill(9) end)
		data.trackedData = nil
		return
	end
	
	if data.trackedData == nil then
		wiggler.initialize(v)
	end

	--horizontal speed
	local collideVal = v:mem(0x136, FIELD_BOOL)
	
	local grabTimerVal = v:mem(0x12E, FIELD_WORD)
	local grabPlayerVal = v:mem(0x12C, FIELD_WORD)
	local grabVal = v:mem(0x130, FIELD_WORD)
	local grabVal2 = v:mem(0x132, FIELD_WORD)
	
	--update trail
	--update positioning of trail
	local cfg = NPC.config[v.id]

	if not data.turningAngry then
		getTrails(v, function(t)
			local tData = t.data._basegame
			local parent = tData.trackedData
			if parent.isValid then
				local dist = 0.5 * cfg.distance
				local distanceToParent = vector(
						parent.x - t.x,
						parent.y + parent.height - t.y - t.height
				)
				local catchup = math.max(distanceToParent.length-2*dist, 0)
				local spd = squared(catchup) * distanceToParent:normalise()
				if math.abs(spd.x) < 0.3 and math.abs(spd.y) < 0.3 then
					spd = vector(
						(parent.x - dist * parent.direction - t.x) * 0.1,
						(parent.y + parent.height - t.y - t.height) * 0.2
					)
				end
				t.friendly = v.friendly or (grabPlayerVal > 0)
				t.x = t.x + spd.x
				t.y = t.y + spd.y
				t:mem(0x12A, FIELD_WORD, onScreenValue)
				t:mem(0x12E, FIELD_WORD, grabTimerVal)
				t:mem(0x130, FIELD_WORD, grabVal)
				t:mem(0x136, FIELD_BOOL, false)
				t:mem(0x132, FIELD_WORD, grabVal2)
				t:mem(0x138, FIELD_WORD, containVal)
			end
		end)
	else
		--oh i just got hit
		getTrails(v, function(t)
			t.x = t.x + v.speedX
			t.y = t.y + v.speedY
		end)
		v.animationTimer = 0
	end
	local normalCount = 0
	getTrails(v, function(t)
		local tData = t.data._basegame
		local parent = tData.trackedData
		if parent.isValid then
			if tData.isAngry then

			else
				normalCount = normalCount + 1
			end
		end
	end)
	if normalCount >= cfg.trailcount and data.hitSegments == true and data.isAngry and v.collidesBlockBottom then
		data.distance = cfg.distance
		data.isAngry = false
		v:transform(cfg.normalID)
		v.data._basegame = data
		--[[getTrails(v, function(t)
			local d = t.data._basegame
			t:transform(NPC.config[t.id].normalID)
			t.data._basegame = d
		end)]]
		if NPC.config[v.id].normalChangeSoundID then
			SFX.play(NPC.config[v.id].normalChangeSoundID)
		end
	end
	if v.collidesBlockBottom then data.stillJump = false end
	--Stomp
	if v.speedY > 1 and NPC.config[v.id].canStomp then
		data.canStomp = true
	end
	
	if data.canStomp and v.collidesBlockBottom then
		for k, p in ipairs(Player.get()) do --Section copypasted from the Sledge Bros. code
			if p:isGroundTouching() and not playerStun.isStunned(k) and v:mem(0x146, FIELD_WORD) == player.section then
				playerStun.stunPlayer(k, 48)
			end
		end
		local x = v.x - 16
		local y = v.y + v.height - 32

		Effect.spawn(10, x, y)
		Effect.spawn(10, x + v.width + 16, y)
		data.canStomp = false
		if NPC.config[v.id].stunSoundID then
		    SFX.play(NPC.config[v.id].stunSoundID)
		end
		Defines.earthquake = 6
	end
	data.blockCheckUp.x = v.x
	data.blockCheckUp.y = v.y - 128
	data.blockCheckDown.x = v.x
	data.blockCheckDown.y = v.y + (v.height * 1.7)
	if v.collidesBlockBottom and data.makeFunniDeath == false then --Jumping through blocks, god this code's a mess
		data.jumpTimer = data.jumpTimer + 1
		data.stompTimer = data.stompTimer + 1
		if data.stomping == true and #data.bgoTable > 0 then
			local fallAmount = NPC.config[v.id].fallAmount
			local consecutive = NPC.config[v.id].fallConsecutive
			Routine.setFrameTimer(NPC.config[v.id].quakeSpawnDelay, (function() 
				for i=1,fallAmount do
					data.location = RNG.irandomEntry(data.bgoTable)
					local n = NPC.spawn(NPC.config[v.id].indicateID, data.location.x, data.location.y, v.section, true, true)
					n.x=n.x+16
					n.y=n.y+16
					n.ai1 = 48
					n.ai2 = RNG.irandomEntry(NPC.config[v.id].quaketable)
					n.ai3 = 0
				end
				end), consecutive, false)
			Defines.earthquake = 6
			
			local x = v.x - 32
			local y = v.y + v.height - 32

			Effect.spawn(10, x, y)
			Effect.spawn(10, x + v.width + 32, y)
			data.stomping = false
		end
		if data.stompTimer == data.stompDelay and data.stomping == false then
			data.stompTimer = 0
			data.stompDelay = RNG.randomInt(300,420)
			v.speedY = -3.5
			if NPC.config[v.id].jumpSoundID > 0 then
				SFX.play(NPC.config[v.id].jumpSoundID)
			end
			data.stomping = true
		end
		if data.jumpTimer == math.random(50, NPC.config[v.id].jumpCooldown) or data.jumpTimer >= NPC.config[v.id].jumpCooldown and data.stomping == false then
			data.jumpTimer = 0
			if data.jumpSet == 2 then
				if data.triedDown == false and data.triedUp == false then
					data.jumpsDown = math.random(0, 1)
				elseif data.triedDown and data.triedUp then
					data.jumpsDown = -1
				end
				
				if data.jumpsDown == 0 then
					for _,z in ipairs(Block.getIntersecting(data.blockCheckUp.x, data.blockCheckUp.y, 
					data.blockCheckUp.x + v.width, data.blockCheckUp.y + v.height)) do
						if not z.invisible then
							data.blockDetect = z.id
						end
					end
					
					if not table.icontains(Block.SOLID, data.blockDetect) then
						data.blockDetect = nil
					end
					
					if data.blockDetect == nil then
						v.speedY = -NPC.config[v.id].jumpHeight
						if NPC.config[v.id].jumpSoundID > 0 then
							SFX.play(NPC.config[v.id].jumpSoundID)
						end
						
						if NPC.config[v.id].moveWhenJumping == false then
							data.stillJump = true
						end
						data.passthrough = 35
					elseif data.triedDown == false then
						data.jumpTimer = 300
						data.jumpsDown = 1
					end
					
					data.triedUp = true
				elseif data.jumpsDown == 1 then
					for _,z in ipairs(Block.getIntersecting(data.blockCheckDown.x, data.blockCheckDown.y, 
					data.blockCheckDown.x + v.width, data.blockCheckDown.y + v.height)) do
						if not z.invisible then
							data.blockDetect = z.id
						end
					end
					
					if not table.icontains(Block.SOLID, data.blockDetect) then
						data.blockDetect = nil
					end
					
					if data.blockDetect == nil then
						v.speedY = -2
						if NPC.config[v.id].jumpSoundID > 0 then
							SFX.play(NPC.config[v.id].jumpSoundID)
						end
						if NPC.config[v.id].moveWhenJumping == false then
							data.stillJump = true
						end
						
						data.passthrough = 35
					elseif data.triedUp == false then
						data.jumpTimer = 300
						data.jumpsDown = 0
					end
					
					data.triedDown = true
				end
				data.blockDetect = nil
			elseif data.jumpSet == 1 then
				if NPC.config[v.id].jumpSoundID > 0 then
					SFX.play(NPC.config[v.id].jumpSoundID)
				end
				if NPC.config[v.id].moveWhenJumping == false then
					data.stillJump = true
				end
				v.speedY = -NPC.config[v.id].jumpHeight
			end
		end
	end
	if data.passthrough > 0 then
		data.passthrough = data.passthrough - 1
		v.noblockcollision = true
		data.triedUp = false
		data.triedDown = false
	else
		v.noblockcollision = false
	end
	if v.collidesBlockBottom then
		if data.triedUp == true then data.triedUp = false end
		if data.triedDown == true then data.triedDown = false end
	end
	if data.makeFunniDeath == false then
		if not data.isAngry then
			if data.stillJump == false then
				v.speedX = (cfg.walkingSpeed) * v.direction
			else
				v.speedX = 0
			end
		end
		if data.isAngry then
			
			--DRACalgar Law's note: This is where I do most of my edits to the npc into a boss
			if data.turningAngry then
				data.chaseTimer = data.chaseTimer - 1
				if data.chaseTimer <= 0 then
					data.turningAngry = false
					data.chaseTimer = cfg.angryDelay
				end
			else
				if data.stillJump == false then
					v.speedX = (cfg.angryWalkingSpeed) * v.direction
				else
					v.speedX = 0
				end
				data.chaseTimer = data.chaseTimer - 1
				if lunatime.tick() % 32 == 0 then
					for i=0,1 do
						local a = Animation.spawn(10,v.x+v.width/2,v.y+v.height*5/8)
						a.x=a.x-a.width/2
						a.y=a.y-a.height/2
						a.speedX = -2 + 4 * i
					end
				end
				if lunatime.tick() % 8 == 0 then
					local a = Animation.spawn(10,v.x+v.width/2,v.y)
					a.x=a.x-a.width/2
					a.y=a.y-a.height/2
					a.speedX = RNG.random(-2.5,2.5)
					a.speedY = -3
				end
				if data.chaseTimer <= 0 and v.collidesBlockBottom and data.hitSegments == false then
					data.distance = cfg.distance
					data.isAngry = false
					v:transform(cfg.normalID)
					v.data._basegame = data
					getTrails(v, function(t)
						local d = t.data._basegame
						t:transform(NPC.config[t.id].normalID)
						t.data._basegame = d
					end)
					if NPC.config[v.id].normalChangeSoundID then
						SFX.play(NPC.config[v.id].normalChangeSoundID)
					end
				end
			end
		elseif data.turningAngry and v.collidesBlockBottom then
			data.chaseTimer = 65
			data.distance = cfg.distance
			data.isAngry = true
			v:transform(cfg.angryID)
			v.speedX = 0
			v.speedY = 0
			v.data._basegame = data
			getTrails(v, function(t)
				local d = t.data._basegame
				t:transform(NPC.config[t.id].angryID)
				t.data._basegame = d
			end)
			if NPC.config[v.id].angryChangeSoundID then
				SFX.play(NPC.config[v.id].angryChangeSoundID)
			end
		end
	else
		data.deathTimer = data.deathTimer + 1
		v.speedX = 0
		v.friendly = true
		getTrails(v, function(t) t.friendly = true end)
		if data.deathTimer >= 128 then
			for i=1,cfg.trailcount do
				local a = Animation.spawn(cfg.trailEffect,v.x+v.width/2,v.y+v.height/2)
				a.x=a.x-a.width/2
				a.y=a.y-a.height/2
				a.speedX = RNG.random(-3,3)
				a.speedY = -RNG.random(2,6)
			end
			v:kill(HARM_TYPE_SPINJUMP)
			Explosion.spawn(v.x + v.width/2, v.y + v.height/2, 4)
		end
	end
end

function wiggler.onTickBody(v)
	if Defines.levelFreeze or v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v.data._basegame.trackedData == nil then
		return
	end
	local cfg = NPC.config[v.id]
	local data = v.data._basegame
	data.isAngry = cfg.angryID == v.id
	if data.wigglerPrevX == nil then
		data.wigglerPrevX = v.x
	end
	if v.x < data.wigglerPrevX then
		v.direction = -1
	elseif v.x > data.wigglerPrevX then
		v.direction = 1
	end
	if not data.trackedData.isValid then
		v:kill(9)
		return
	end
	v.friendly = data.trackedData.friendly or data.trackedData:mem(0x12C, FIELD_WORD) > 0
	data.wigglerPrevX = v.x
end

function wiggler.onNPCHarm(event,npc,reason,culprit)
	local cfg = NPC.config[npc.id]
	local data = npc.data._basegame
	local settings = npc.data._settings
	if not (wiggler.headMap[npc.id] or wiggler.trailMap[npc.id]) then
		return
	end
	event.cancelled = true
	
	if culprit and culprit.__type == "Player" then
		if reason == 8 then
			Colliders.bounceResponse(culprit, 6)
		end
		SFX.play(9)
	end
	if wiggler.trailMap[npc.id] then
		if data.isAngry and npc.data._basegame.head.data._basegame.hitSegments == true then
			SFX.play(2)
			local d = npc.data._basegame
			npc:transform(NPC.config[npc.id].normalID)
			npc.data._basegame = d
		end
	elseif wiggler.headMap[npc.id] then
		if (not data.isAngry and not data.turningAngry) then
			if not data.makeFunniDeath then
				if npc:mem(0x156, FIELD_WORD) <= 0 then
					npc.hp = npc.hp - 1
					SFX.play(39)
					Misc.givePoints(NPC.config[npc.id].hitScore, {x = npc.x + (npc.width / 2),y = npc.y + (npc.height / 2)}, true)
					npc:mem(0x156, FIELD_WORD,12)
					if (npc.hp % cfg.angryHealth == 0 and settings.hitSet == 0 and npc.hp > 0) or (settings.hitSet == 1) then
						npc.data._basegame.turningAngry = true
					end
				end
				if npc.hp <= 0 then
					SFX.play(38)
					if npc.data._basegame.canFunni == false then
						npc:kill(HARM_TYPE_NPC)
					else
						data.makeFunniDeath = true
					end
				end
			end
		else

		end
	end

	--[[
	local wt = npc.data._basegame.trackedData
		if culprit and culprit.__type == "NPC" then
			local c = culprit
			if c == npc.data._basegame.head then
				event.cancelled = true
				return
			else
				local tbl = wt
				if type(wt) ~= "table" then
					tbl = c.data._basegame.trackedData
				end

				if tbl then
					for k,n in ipairs(tbl) do
						if n == c or n == npc then
							event.cancelled = true
							return
						end
					end
				end
			end
		end
	]]

	--[[if wiggler.trailMap[npc.id] and reason ~= 9 then
		local v = npc.data._basegame.head
		if v.isValid then
			v:harm(reason)
			getTrails(v, function(t) t:harm(9) end)
		end
	end]]
end

return wiggler;