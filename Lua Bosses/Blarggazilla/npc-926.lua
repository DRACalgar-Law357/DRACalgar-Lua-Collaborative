--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
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
	gfxheight = 190,
	gfxwidth = 196,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 124,
	height = 146,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 5,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.
	staticdirection = true,
	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	score = 6,
	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
	fireBGO = 926,
	lobBallID = 927,
	fireBreathID = 282,
	firePinchID = 246,
	fallDebrisID = 791,
	fireChargeID = 928
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=926,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

local STATE_IDLE = 0
local STATE_WALK = 1
local STATE_FIRE = 2
local STATE_THROW = 3
local STATE_JUMP = 4
local STATE_CHARGE = 5


local spawnOffset = {
[-1] = 0,
[1] = sampleNPCSettings.width,
}
--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onStartNPC")
	registerEvent(sampleNPC, "onNPCHarm")
	registerEvent(sampleNPC, "onNPCKill")
end

local bgoTable
function sampleNPC.onStartNPC(v)
	bgoTable = BGO.get(NPC.config[v.id].fireBGO)
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
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
		if settings.breath == nil then
			settings.breath = true
		end
		if settings.walk == nil then
			settings.walk = true
		end
		if settings.lob == nil then
			settings.lob = true
		end
		if settings.charge == nil then
			settings.charge = true
		end
		if settings.jump == nil then
			settings.jump = true
		end
		settings.health = settings.health or 6
		settings.phaseSet = settings.phaseSet or 0

		data.timer = data.timer or 0
		data.hurtTimer = data.hurtTimer or 0
		data.iFrames = false
		data.health = settings.health
		data.state = STATE_IDLE
        data.frametimer = 0
		data.statelimit = 0
        --v.walkingtimer is how much Blarggazilla walks before turning around
		v.walkingtimer = 0
		--v.walkingdirection is the direction Blarggazilla is moving
		v.walkingdirection = v.direction
		--v.initialdirection is Blarggazilla's initial direction. If the player is beyond their initial direction then they'll chase the player
		v.initialdirection = v.direction
        v.ai2 = RNG.randomInt(64,160)
		data.phase = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_IDLE
        v.animationFrame = 0
		data.timer = 0
        return
	end
	if settings.phaseSet == 0 then
		if data.health <= settings.health*2/3 and data.phase == 0 then
			data.phase = 1
		elseif data.health <= settings.health*1/3 and data.phase == 1 then
			data.phase = 2
		end
	elseif settings.phaseSet == 1 then
		data.phase = 0
	elseif settings.phaseSet == 2 then
		data.phase = 2
	end
	
	data.timer = data.timer + 1
	
	if data.state == STATE_IDLE then
		--Nothing really happens here, just a phase to wait before doing something
		npcutils.faceNearestPlayer(v)
        v.animationFrame = 0
		v.speedX = 0
		if data.timer >= 64 then
			local options = {}
			if data.statelimit ~= STATE_WALK and settings.walk == true then table.insert(options,STATE_WALK) table.insert(options,STATE_WALK) end
			if data.statelimit ~= STATE_CHARGE and settings.charge == true then table.insert(options,STATE_CHARGE) end
			if data.statelimit ~= STATE_THROW and settings.lob == true then table.insert(options,STATE_THROW) end
			if data.statelimit ~= STATE_FIRE and settings.breath == true then table.insert(options,STATE_FIRE) end
			if data.statelimit ~= STATE_JUMP and settings.jump == true then table.insert(options,STATE_JUMP) end
			if #options > 0 then
				data.state = RNG.irandomEntry(options)
			end
			data.statelimit = data.state
			data.timer = 0
		end
    elseif data.state == STATE_WALK then
        --Code by Murphmario
        data.frametimer = data.frametimer + 1
        if v.walkingdirection == -1 then
            if data.frametimer < 8 then
                v.animationFrame = 0
            elseif data.frametimer < 16 then
                v.animationFrame = 1
            elseif data.frametimer < 24 then
                v.animationFrame = 2
            else
                v.animationFrame = 0
                data.frametimer = 0
            end
        else
            if data.frametimer < 8 then
                v.animationFrame = 2
            elseif data.frametimer < 16 then
                v.animationFrame = 1
            elseif data.frametimer < 24 then
                v.animationFrame = 0
            else
                v.animationFrame = 2
                data.frametimer = 0
            end
        end
        if v.direction ~= v.initialdirection then
			v.speedX = 2 * sampleNPCSettings.speed * v.direction
		else
			v.speedX = 2 * sampleNPCSettings.speed * v.walkingdirection
			
			v.walkingtimer = v.walkingtimer - v.walkingdirection
			
			if v.walkingtimer == 40 or v.walkingtimer == -40 then
				v.walkingdirection = v.walkingdirection * -1
			end
		end
        if data.timer >= v.ai2 then
            data.timer = 0
            v.speedX = 0
			local options = {}
			if data.statelimit ~= STATE_WALK and settings.walk == true then table.insert(options,STATE_WALK) table.insert(options,STATE_WALK) end
			if data.statelimit ~= STATE_CHARGE and settings.charge == true then table.insert(options,STATE_CHARGE) end
			if data.statelimit ~= STATE_THROW and settings.lob == true then table.insert(options,STATE_THROW) end
			if data.statelimit ~= STATE_FIRE and settings.breath == true then table.insert(options,STATE_FIRE) end
			if data.statelimit ~= STATE_JUMP and settings.jump == true then table.insert(options,STATE_JUMP) end
			if #options > 0 then
				data.state = RNG.irandomEntry(options)
			end
			data.statelimit = data.state
            v.ai2 = RNG.randomInt(64,160)
			npcutils.faceNearestPlayer(v)
        end
    elseif data.state == STATE_FIRE then
        if data.timer < 8 then
            v.animationFrame = 0
        elseif data.timer < 16 then
            v.animationFrame = 3
        elseif data.timer < 24 then
            v.animationFrame = 3
        elseif data.timer < 32 then
            v.animationFrame = 4
        else
            v.animationFrame = 0
        end
        v.speedX = 0
        if data.timer == 32 then
            SFX.play(42)
			if data.phase == 0 or data.phase == 1 then
				local rotate = RNG.randomInt(10,25)
				for i = 1, 3 do
					local dir = -vector.right2:rotate(0 + (i * 25) * v.direction + rotate * -v.direction)
					local n = NPC.spawn(config.fireBreathID, v.x + spawnOffset[v.direction], v.y - 16)
					n.x=n.x-n.width/2
					n.y=n.y-n.height/2
					n.speedX = dir.x * 2.5
					n.speedY = dir.y * 2.5
				end
			else
				local rotate = RNG.randomInt(10,25)
				for i = 1, 6 do
					local dir = -vector.right2:rotate(0 + (i * 20) * v.direction + rotate * -v.direction)
					local n = NPC.spawn(config.firePinchID, v.x + spawnOffset[v.direction], v.y - 16)
					n.x=n.x-n.width/2
					n.y=n.y-n.height/2
					n.speedX = dir.x * 1.5
					n.speedY = dir.y * 1.5
				end
			end
        end
        if data.timer >= 48 then
            data.timer = 0
			npcutils.faceNearestPlayer(v)
            data.state = STATE_IDLE
        end
    elseif data.state == STATE_THROW then
        v.animationFrame = math.floor(data.timer / 8) % 3 + 2
        v.speedX = 0
        if data.timer % 24 == 0 then
            h = NPC.spawn(config.lobBallID, v.x + spawnOffset[v.direction], v.y - 16)
            h.speedX = RNG.random(1,6) * v.direction
            h.speedY = -7
			h.x=h.x-h.width/2
			h.y=h.y-h.height/2
            SFX.play{sound=18, delay=7}
        end
        if data.timer == 1 then
			v.ai3 = 4 + data.phase
		end
        if data.timer >= (24 * v.ai3) + 8 then
            data.timer = 0
			npcutils.faceNearestPlayer(v)
            data.state = STATE_IDLE
        end
    elseif data.state == STATE_JUMP then
        if v.ai1 == 0 then
            if data.timer < 20 and not v.collidesBlockBottom then
                data.timer = 0
            end
            v.speedX = 0
            if data.timer < 20 then
                v.animationFrame = 3
            else
                v.animationFrame = 4
            end
            if data.timer == 20 then v.speedY = -10 end
            if data.timer > 20 and v.collidesBlockBottom then
                data.timer = 0
                v.ai1 = 1
                Defines.earthquake = 5
                SFX.play(37)
                local ptll = Animation.spawn(10,v.x,v.y+v.height)
                local ptlr = Animation.spawn(10,v.x+v.width,v.y+v.height)
                ptll.x=ptll.x-ptll.width/2
                ptll.y=ptll.y-ptll.height/2
                ptlr.x=ptlr.x-ptlr.width/2
                ptlr.y=ptlr.y-ptlr.height/2
				if #bgoTable > 0 then
					local fallAmount = 4 + 1 * data.phase
					for i=1,fallAmount do
						data.location = RNG.irandomEntry(bgoTable)
						local n = NPC.spawn(NPC.config[v.id].fallDebrisID, data.location.x, data.location.y)
						n.x=n.x-n.width/2+16
						n.y=n.y-n.height/2+16
						n.ai1 = 64
						n.ai2 = 927
						n.ai3 = 0
					end
				end
            end
        else
            v.speedX = 0
            v.animationFrame = 1
            if data.timer >= 24 then
                data.timer = 0
				npcutils.faceNearestPlayer(v)
				data.state = STATE_IDLE
                v.ai1 = 0
            end
        end
	elseif data.state == STATE_CHARGE then
		if data.timer < 64 then
            v.animationFrame = 0
        else
			if data.timer % 48 >= 32 then
				v.animationFrame = 3
			elseif data.timer % 48 >= 16 then
				v.animationFrame = 4
			else
				v.animationFrame = 0
			end
        end
        v.speedX = 0
		if data.timer == 1 then
			v.ai3 = 1 + data.phase
		end
        if data.timer >= 64 then
			if data.timer % 48 == 32 then
				SFX.play("fireBreath.ogg")
				local n = NPC.spawn(config.fireChargeID, v.x + spawnOffset[v.direction], v.y - 16)
				n.x=n.x-n.width/2
				n.y=n.y-n.height/2
				n.speedX = RNG.random(1,5.5) * v.direction
				n.speedY = -7
				for i=1,16 do
					local ptl = Animation.spawn(265, v.x + spawnOffset[v.direction], v.y - 16)
					ptl.x=ptl.x-ptl.width/2
					ptl.y=ptl.y-ptl.height/2
					ptl.speedX = RNG.random(1,6) * v.direction
					ptl.speedY = -RNG.random(3,7)
				end
			end
		else
			local ptl = Animation.spawn(265, math.random(v.x, v.x + v.width), math.random(v.y, v.y + v.height))
			ptl.speedY = -2
			if data.timer % 8 == 0 then
				SFX.play(16)
			end
        end
        if data.timer >= 64 + 48 * v.ai3 then
            data.timer = 0
			npcutils.faceNearestPlayer(v)
            data.state = STATE_IDLE
        end
	end
	
	--Give Blarggazilla some i-frames to make the fight less cheesable
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
	
	--Prevent Blarggazilla from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	
	if Colliders.collide(plr, v) and not v.friendly and not Defines.cheat_donthurtme then
		plr:harm()
	end
	
end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end

		if reason ~= HARM_TYPE_LAVA and reason ~= HARM_TYPE_OFFSCREEN then
			if reason == HARM_TYPE_JUMP or killReason == HARM_TYPE_SPINJUMP or killReason == HARM_TYPE_FROMBELOW then
				SFX.play(2)
				data.iFrames = true
				data.health = data.health - 1
			elseif reason == HARM_TYPE_SWORD then
				if v:mem(0x156, FIELD_WORD) <= 0 then
					data.health = data.health - 1
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
							data.health = data.health - 0.25
						else
							data.health = data.health - 1
							data.iFrames = true
						end
					else
						data.health = data.health - 1
						data.iFrames = true
					end
				else
					data.health = data.health - 1
					data.iFrames = true
				end
			elseif reason == HARM_TYPE_LAVA and v ~= nil then
				v:kill(HARM_TYPE_OFFSCREEN)
			elseif v:mem(0x12, FIELD_WORD) == 2 then
				v:kill(HARM_TYPE_OFFSCREEN)
			else
				data.iFrames = true
				data.health = data.health - 1
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
                SFX.play(44)
                v:kill(HARM_TYPE_NPC)
			elseif data.health > 0 then
				v:mem(0x156,FIELD_WORD,60)
			end
		else
            if reason == HARM_TYPE_LAVA then
                SFX.play(44)
			    v:kill(HARM_TYPE_LAVA)
            elseif reason == HARM_TYPE_OFFSCREEN then
                SFX.play(44)
                v:kill(9)
            end
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
	SFX.play(44)
end

--Gotta return the library table!
return sampleNPC