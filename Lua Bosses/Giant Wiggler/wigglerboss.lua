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
	noyoshi=0,
	nogravity=0,
	cliffturn=-1,
	defeatScore = 8,
	hitScore = 1,
	score = 0,
	spinjumpsafe = true,
	terminalvelocity = 15, 
	trailcount=6,
	trailID = 752,
	distance = 32,
	angryID = 753,
	normalID = 751,

	--Behavior-related
	health = 25,
	angryHealth = 5,
	walkingSpeed = 1.5,
	angryWalkingSpeed = 2.0,
	speedStack = 0.2,
	jumpHeight = 10,
	jumpStack = 0.2,
	angryDelay = 400,
	jumpDelay = 70,
	canStomp = true,

	--SFX
	angryWalkingID = 3,
	jumpSoundID = 1,
	angryChangeSoundID = 72,
	normalChangeSoundID = 50,
	stunSoundID = 37,
	hurtSoundID = 39,
	killSoundID = 9,
	moveWhenJumping = false,
	jumpsThroughBlock = true,
	jumpCooldown = 250,
	hitSet = 0 --0 jump on the head and briefly turn angry and impervious to attacks; 1 same as 0 but the player must jump on its angered segments to turn them to calmed segments in order for the head's anger be calmed and whenever the calmed head is hit, it'll turn into an anger state.
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
	
	local sec = v:mem(0x146, FIELD_WORD)
	local dir = v:mem(0xD8,FIELD_FLOAT)
	v.hp = NPC.config[v.id].health
	if v.direction == 0 then
		v.direction = rng.randomInt(0, 1) * 2 - 1
	end
	
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
	if v.collidesBlockBottom then data.stillJump = false end
	--Stomp
	if v.speedY > 1 and NPC.config[v.id].canStomp then
		v.speedY = v.speedY + .5
		data.canStomp = true
	end
	
	if data.canStomp and v.collidesBlockBottom then
		for k, p in ipairs(Player.get()) do --Section copypasted from the Sledge Bros. code
			if p:isGroundTouching() and not playerStun.isStunned(k) and v:mem(0x146, FIELD_WORD) == player.section then
				playerStun.stunPlayer(k, 70)
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
	Text.print(v.hp,110,200)
	data.blockCheckDown.x = v.x
	data.blockCheckDown.y = v.y + (v.height * 1.7)
		if v.collidesBlockBottom then --Jumping through blocks, god this code's a mess
			data.jumpTimer = data.jumpTimer + 1
		if data.jumpTimer == math.random(50, NPC.config[v.id].jumpCooldown) or data.jumpTimer >= NPC.config[v.id].jumpCooldown then
			data.jumpTimer = 0
			if NPC.config[v.id].jumpsThroughBlock then
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
						data.passthrough = 25
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
						
						if NPC.config[v.id].isSledge then
							data.passthrough = 25
						else
							data.passthrough = 30
						end
					elseif data.triedUp == false then
						data.jumpTimer = 300
						data.jumpsDown = 0
					end
					
					data.triedDown = true
				end
				data.blockDetect = nil
			else
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
	Text.print(data.passthrough,110,110)
	Text.print(data.jumpTimer,110,126)
	Text.print(data.triedUp,110,142)
	Text.print(data.triedDown,110,158)
	if not data.isAngry then
		if data.stillJump == false then
			v.speedX = (cfg.walkingSpeed + cfg.speedStack) * v.direction
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
				v.speedX = (cfg.angryWalkingSpeed + cfg.speedStack) * v.direction
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
			if data.chaseTimer <= 0 then
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
	elseif data.turningAngry then
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
end

function wiggler.onTickBody(v)
	if Defines.levelFreeze or v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v.data._basegame.trackedData == nil then
		return
	end
	
	local data = v.data._basegame
	
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
	if not (wiggler.headMap[npc.id] or wiggler.trailMap[npc.id]) then
		return
	end
	if reason == 1 or reason == 8 then
		event.cancelled = true
		
		if culprit.__type == "Player" then
			if reason == 8 then
				Colliders.bounceResponse(culprit, 6)
			end
			SFX.play(9)
		end
			if wiggler.trailMap[npc.id] then
				npc = npc.data._basegame.head
			end
			if not npc or not npc.isValid then
				return
			end
			if npc.data._basegame.isAngry then
				return
			end
			if not npc.data._basegame.trackedData then return end
			if npc.data._basegame.turningAngry then return end
			npc.data._basegame.turningAngry = true
			return
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

	if wiggler.trailMap[npc.id] and reason ~= 9 then
		local v = npc.data._basegame.head
		if v.isValid then
			v:harm(reason)
			getTrails(v, function(t) t:harm(9) end)
		end
	end
end

return wiggler;