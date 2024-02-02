--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
--Create the library table
local gigaPhanto = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
--Defines NPC config for our NPC. You can remove superfluous definitions.
local gigaPhantoSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 76,
	gfxwidth = 80,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 76,
	height = 76,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 16,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
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
	staticdirection = true,
	projectileID = 414,
	orbID = npcID + 1,
	shockwaveID = npcID + 2,
	phantoNormalID = npcID + 3,
	phantoAggroID = npcID + 4,
	phantoFuriousID = npcID + 5,
	iFramesSet = 0,
	--An iFrame system that has the boss' frame be turned invisible from the set of frames periodically.
	--Set 0 defines its hurtTimer until it is at its iFramesDelay
	--Set 1 defines the same from Set 0 but whenever the boss has been harmed, it stacks up the iFramesDelay the more. The catch is that when the boss has been left alone after getting harmed, it resets the iFramesStacks so that the player can be able to jump on the boss for some time again.
	iFramesDelay = 32,
	iFramesDelayStack = 48,

	bombArray = {
		134,
		135,
	},
	
	--A config that uses Enjil's/Emral's freezeHighlight.lua; if set to true the lua file of it needs to be in the local or episode folder.
	useFreezeHightLight = true
}

--Applies NPC settings
npcManager.setNpcSettings(gigaPhantoSettings)

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
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

local STATE = {
	IDLE = 0,
	CHASE = 1,
	SUMMON = 2,
	CALLEVENT = 3,
	SHOOT = 4,
	SHOCKWAVE = 5,
	LOB = 6,
	PHASE = 7,
	KILL = 8,
}

local function handleFlyAround(v,data,config,settings)
	local horizontalDistance = settings.flyAroundHorizontalDistance*0.5*v.spawnDirection
	local verticalDistance = settings.flyAroundVerticalDistance*0.5
	local horizontalTime = settings.flyAroundHorizontalTime / math.pi / 2
	local verticalTime   = settings.flyAroundVerticalTime   / math.pi / 2

	v.speedX = math.sin(data.flyAroundTimer / horizontalTime)*horizontalDistance / horizontalTime
	v.speedY = math.sin(data.flyAroundTimer / verticalTime  )*verticalDistance   / verticalTime

	data.flyAroundTimer = data.flyAroundTimer + 1

	npcutils.faceNearestPlayer(v)
end

local hurtCooldown = 160

local hpboarder = Graphics.loadImage("hpconboss.png")
local hpfill = Graphics.loadImage("hpfillboss.png")
--Register events
function gigaPhanto.onInitAPI()
	npcManager.registerEvent(npcID, gigaPhanto, "onTickEndNPC")
	npcManager.registerEvent(npcID, gigaPhanto, "onDrawNPC")
	registerEvent(gigaPhanto, "onNPCHarm")
end

function gigaPhanto.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
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

		settings.hp = settings.hp or 120
		settings.summonSet = settings.summonSet or 0

		data.timer = data.timer or 0
		data.hurtTimer = data.hurtTimer or 0
		data.iFrames = false
		data.health = settings.hp
		data.state = STATE.IDLE
		data.hurtCooldownTimer = 0
		data.hurting = false
		data.iFramesDelay = NPC.config[v.id].iFramesDelay
		data.iFramesStack = 0
		data.statelimit = 0
		data.flyAroundTimer = 0
		v.ai1 = 0
		v.ai2 = 0
		v.ai3 = 0
		data.phase = 0
		data.rndTimer = RNG.randomInt(80,144)
		data.frameTimer = 0
		data.hurtPlayer = false
		data.statelimit = 0
		data.phantoPrompt = NPC.config[v.id].phantoNormalID
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE.IDLE
		v.ai1 = 0
		data.timer = 0
	end
	if (data.health <= settings.hp*2/3 and data.phase == 0) or (data.health <= settings.hp*1/3 and data.phase == 1) then
		data.phase = data.phase + 1
		SFX.play(7)
		local n = NPC.spawn(9, v.x + v.width / 2, v.y + v.height/2)
		n.dontMove = true
		n.speedY = -5
		data.timer = 0
	end
	if data.phase == 0 then
		data.phantoPrompt = NPC.config[v.id].phantoNormalID
	elseif data.phase == 1 then
		data.phantoPrompt = NPC.config[v.id].phantoAggroID
	else
		data.phantoPrompt = NPC.config[v.id].phantoFuriousID
	end
	data.timer = data.timer + 1
	if data.state < STATE.PHASE then
		handleFlyAround(v,data,config,settings)
	end
	if data.state == STATE.IDLE then
		v.animationFrame = 0
		if data.timer == 1 then data.rndTimer = RNG.randomInt(80,144) end
		if data.timer >= data.rndTimer then
			data.timer = 0
			local options = {}
			if data.statelimit ~= STATE.SHOOT then table.insert(options,STATE.SHOOT) end
			if data.statelimit ~= STATE.SHOCKWAVE then table.insert(options,STATE.SHOCKWAVE) end
			if data.statelimit ~= STATE.SUMMON then table.insert(options,STATE.SUMMON) end
			if data.statelimit ~= STATE.LOB then table.insert(options,STATE.LOB) table.insert(options,STATE.LOB) end
			if #options > 0 then
				data.state = RNG.irandomEntry(options)
			end
			data.statelimit = data.state
		end
	elseif data.state == STATE.SHOOT then
		if data.timer % 48 < 6 then
			v.animationFrame = 0
		elseif data.timer % 48 < 12 then
			v.animationFrame = 8
		elseif data.timer % 48 < 18 then
			v.animationFrame = 9
		elseif data.timer % 48 < 24 then
			v.animationFrame = 10
		elseif data.timer % 48 < 30 then
			v.animationFrame = 11
		elseif data.timer % 48 < 36 then
			v.animationFrame = 10
		elseif data.timer % 48 < 42 then
			v.animationFrame = 9
		else
			v.animationFrame = 8
		end
		if data.timer % 48 == 30 then
			SFX.play(82)
			for i = 1,2 do
				local n = NPC.spawn(NPC.config[v.id].projectileID, v.x, v.y, player.section, false, false)
				if i==1 then
					n.x=v.x+v.width/4
					n.y=v.y+v.height/2
				else
					n.x=v.x+v.width*3/4
					n.y=v.y+v.height/2
				end
				n.x=n.x-n.width/2
				n.y=n.y-n.height/2
				npcutils.faceNearestPlayer(n)
			end
		end
		local shootDelay = 144 + (48 * data.phase)
		if data.timer >= shootDelay then
			data.timer = 0
			data.state = STATE.IDLE
		end
	elseif data.state == STATE.SHOCKWAVE then
		if data.timer % 48 < 6 then
			v.animationFrame = 0
		elseif data.timer % 48 < 12 then
			v.animationFrame = 8
		elseif data.timer % 48 < 18 then
			v.animationFrame = 9
		elseif data.timer % 48 < 24 then
			v.animationFrame = 10
		elseif data.timer % 48 < 30 then
			v.animationFrame = 11
		elseif data.timer % 48 < 36 then
			v.animationFrame = 10
		elseif data.timer % 48 < 42 then
			v.animationFrame = 9
		else
			v.animationFrame = 8
		end
		if data.timer % 48 == 30 then
			SFX.play(82)
			for i = 1,2 do
				local n = NPC.spawn(NPC.config[v.id].orbID, v.x, v.y, player.section, false, false)
				if i==1 then
					n.x=v.x+v.width/4
					n.y=v.y+v.height/2
				else
					n.x=v.x+v.width*3/4
					n.y=v.y+v.height/2
				end
				n.x=n.x-n.width/2
				n.y=n.y-n.height/2
				n.speedX = RNG.random(-3,3)
				n.speedY = -RNG.random(5,8)
			end
		end
		local shootDelay = 96 + (48 * data.phase)
		if data.timer >= shootDelay then
			data.timer = 0
			data.state = STATE.IDLE
		end
	elseif data.state == STATE.SUMMON then
		if data.timer < 8 then
			v.animationFrame = 0
		elseif data.timer < 16 then
			v.animationFrame = 8
		elseif data.timer < 24 then
			v.animationFrame = 9
		elseif data.timer < 32 then
			v.animationFrame = 10
		elseif data.timer < 40 then
			v.animationFrame = 11
		elseif data.timer < 48 then
			v.animationFrame = 10
		elseif data.timer < 56 then
			v.animationFrame = 9
		elseif data.timer < 64 then
			v.animationFrame = 8
		else
			v.animationFrame = 0
		end
		if data.timer == 1 then SFX.play("Boss Hurt 2.wav") defines.earthquake = 4 end
		v.y=v.y+(math.sin(-data.timer/5)*3 / 3)
		if data.timer >= 96 then
			data.timer = 0
			SFX.play("Air Bullet.wav")
			local summonAmount = 2
			if settings.summonSet == 1 then summonAmount = 4 end
			for i = 1,2 do
				local phantoServant
				phantoServant = data.phantoPrompt
				local n = NPC.spawn(phantoServant, v.x+v.width/2, v.y+v.height/2, player.section, false, false)
				n.x=n.x-n.width/2
				n.y=n.y-n.height/2
				if i == 1 then
					n.speedX = -5
					n.speedY = 0
				elseif i == 2 then
					n.speedX = 5
					n.speedY = 0
				elseif i == 3 then
					n.speedX = 0
					n.speedY = -5
				elseif i == 4 then
					n.speedX = 0
					n.speedY = 5
				end
				n.data.state = 5
			end
			data.state = STATE.IDLE
		end
	elseif data.state == STATE.SHOCKWAVE then
		if data.timer % 48 < 6 then
			v.animationFrame = 0
		elseif data.timer % 48 < 12 then
			v.animationFrame = 8
		elseif data.timer % 48 < 18 then
			v.animationFrame = 9
		elseif data.timer % 48 < 24 then
			v.animationFrame = 10
		elseif data.timer % 48 < 30 then
			v.animationFrame = 11
		elseif data.timer % 48 < 36 then
			v.animationFrame = 10
		elseif data.timer % 48 < 42 then
			v.animationFrame = 9
		else
			v.animationFrame = 8
		end
		if data.timer % 48 == 30 then
			SFX.play(82)
			for i = 1,2 do
				local n = NPC.spawn(NPC.config[v.id].orbID, v.x, v.y, player.section, false, false)
				if i==1 then
					n.x=v.x+v.width/4
					n.y=v.y+v.height/2
				else
					n.x=v.x+v.width*3/4
					n.y=v.y+v.height/2
				end
				n.x=n.x-n.width/2
				n.y=n.y-n.height/2
				n.speedX = RNG.random(-3,3)
				n.speedY = -RNG.random(5,8)
			end
		end
		local shootDelay = 96 + (48 * data.phase)
		if data.timer >= shootDelay then
			data.timer = 0
			data.state = STATE.IDLE
		end
	elseif data.state == STATE.LOB then
		if data.timer < 8 then
			v.animationFrame = 0
		elseif data.timer < 16 then
			v.animationFrame = 8
		elseif data.timer < 24 then
			v.animationFrame = 9
		elseif data.timer < 32 then
			v.animationFrame = 10
		elseif data.timer < 40 then
			v.animationFrame = 11
		elseif data.timer < 48 then
			v.animationFrame = 10
		elseif data.timer < 56 then
			v.animationFrame = 9
		elseif data.timer < 64 then
			v.animationFrame = 8
		else
			v.animationFrame = 0
		end
		if data.timer == 1 then SFX.play("Boss Hurt 2.wav") defines.earthquake = 4 end
		v.x=v.x+(math.sin(-data.timer/5)*3 / 3)
		if data.timer >= 96 then
			data.timer = 0
			SFX.play("Air Bullet.wav")
			local summonAmount = 2
			if settings.summonSet == 1 then summonAmount = 4 end
			for i = 1,3 do
				local n = NPC.spawn(RNG.irandomEntry(NPC.config[v.id].bombArray), v.x+v.width/2, v.y+v.height/2, player.section, false, false)
				n.x=n.x-n.width/2
				n.y=n.y-n.height/2
				if i == 1 then
					n.speedX = -3
					n.speedY = -2
					n.direction = -1
				elseif i == 2 then
					n.speedX = 3
					n.speedY = -2
					n.direction = 1
				elseif i == 3 then
					npcutils.faceNearestPlayer(n)
					n.speedX = 0
					n.speedY = -4
				end
			end
			data.state = STATE.IDLE
		end
    else
        if lunatime.tick() % 24 == 0 then
    		Animation.spawn(10, math.random(v.x, v.x + v.width), math.random(v.y, v.y + v.height))
			SFX.play(36)
		end
		v.speedX = 0
		v.speedY = 0
		v.friendly = true
		if lunatime.tick() % 64 > 4 then 
			v.animationFrame = 15
		else
			v.animationFrame = -50
		end
		if data.timer >= 240 then
		    v:kill(HARM_TYPE_NPC)
		end
	end
	
	--Give Giga Phanto some i-frames to make the fight less cheesable
	--iFrames System made by MegaDood & DRACalgar Law
	if NPC.config[v.id].iFramesSet == 1 then
        if data.hurting == false then
            data.hurtCooldownTimer = 0
            data.iFramesStack = -1
        else
            data.hurtCooldownTimer = data.hurtCooldownTimer + 1
            local stacks = (NPC.config[v.id].iFramesDelayStack * data.iFramesStack)
            if stacks < 0 then
                stacks = 0
            end
            data.iFramesDelay = NPC.config[v.id].iFramesDelay + stacks
            if data.hurtCooldownTimer >= hurtCooldown then
                data.hurtCooldownTimer = 0
                data.hurting = false
                data.iFramesStack = -1
            end
        end
    end
	if data.iFrames then
		v.friendly = true
		data.hurtTimer = data.hurtTimer + 1
		
		if data.hurtTimer == 1 then
		    SFX.play("sfx_playerhurt.wav")
		end
		
		if data.hurtTimer % 8 <= 4 and data.hurtTimer > 8 then
			v.animationFrame = -50
		end
		if data.hurtTimer >= data.iFramesDelay then
			v.friendly = false
			data.iFrames = false
			data.hurtTimer = 0
		end
	end
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = gigaPhantoSettings.frames
		});
	end
	
	--Prevent gigaPhanto from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	if Colliders.collide(plr, v) and not v.friendly and data.state ~= STATE_KILL and not Defines.cheat_donthurtme then
		plr:harm()
	end
end
function gigaPhanto.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end

			if data.iFrames == false then
				local fromFireball = (culprit and culprit.__type == "NPC" and culprit.id == 13 )
				local hpd = 10
				if fromFireball then
					hpd = 4
					SFX.play(9)
				elseif reason == HARM_TYPE_LAVA then
					v:kill(HARM_TYPE_LAVA)
				else
					hpd = 10
					data.iFrames = true
					if reason == HARM_TYPE_SWORD then
						if v:mem(0x156, FIELD_WORD) <= 0 then
							SFX.play(89)
							hpd = 8
							v:mem(0x156, FIELD_WORD,20)
						end
						if Colliders.downSlash(player,v) then
							player.speedY = -6
						end
					elseif reason == HARM_TYPE_LAVA and v ~= nil then
						v:kill(HARM_TYPE_OFFSCREEN)
					elseif v:mem(0x12, FIELD_WORD) == 2 then
						v:kill(HARM_TYPE_OFFSCREEN)
					else
						if reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP or reason == HARM_TYPE_FROMBELOW then
							SFX.play(2)
						end
						data.iFrames = true
						hpd = 10
					end
					if data.iFrames then
						data.hurting = true
						data.iFramesStack = data.iFramesStack + 1
						data.hurtCooldownTimer = 0
					end
				end
				
				data.health = data.health - hpd
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
				if NPC.config[v.id].useFreezeHightLight == true then
					freeze.set(48)
				end
				SFX.play(63)
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
	eventObj.cancelled = true
end

function gigaPhanto.onDrawNPC(v)
	local data = v.data
	local settings = v.data._settings

	if v.legacyBoss == true and data.state ~= STATE_KILL and data.health then
		Graphics.drawImage(hpboarder, 740, 120)
		local healthoffset = 126
		healthoffset = healthoffset-(126*(data.health/settings.hp))
		Graphics.drawImage(hpfill, 748, 128+healthoffset, 0, 0, 12, 126-healthoffset)
	end
end

--Gotta return the library table!
return gigaPhanto
