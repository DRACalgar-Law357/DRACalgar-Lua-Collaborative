--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local bulletBills = require("bulletBills_ai")
--NPCutils for rendering
local npcutils = require("npcs/npcutils")

--Create the library table
local draggadonBoss = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

local STATE = {
	IDLE = 0,
	RAIN = 1,
	SUMMON = 2,
	METEOR = 3,
	STREAMOFFIRE = 4,
	DASH = 5,
	HURT = 6,
	CONSUME = 7,
	KILL = 8,
}

local maxHP = 3
-- The Shooting SFX File --
sfx_fire = 42

--Defines NPC config for our NPC. You can remove superfluous definitions.
local draggadonBossSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 320,
	gfxwidth = 320,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 128,
	height = 160,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 48,
	--Frameloop-related
	frames = 8,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
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

	--Define custom properties below
	summonEnemyTable = {
		210,
		23,
	},
	neckHitbox = {
		width = 96,
		height = 80,
		x = {
			[-1] = -128,
			[1] = 32,
		},
		y = -96,
	},
	headHitbox = {
		width = 96,
		height = 96,
		x = {
			[-1] = -224,
			[1] = 128,
		},
		y = -128,
	},
	mouthHitbox = {
		width = 96,
		height = 96,
		x = {
			[-1] = -272,
			[1] = 172,
		},
		y = -96,
	},
	totalHP = maxHP,
	attackTable = {
		[STATE.RAIN] = {
			availableHPMin = 0,
			availableHPMax = maxHP,
		},
		[STATE.SUMMON] = {
			availableHPMin = 0,
			availableHPMax = maxHP,
		},
		[STATE.STREAMOFFIRE] = {
			availableHPMin = 0,
			availableHPMax = maxHP,
		},
		[STATE.METEOR] = {
			availableHPMin = maxHP/3,
			availableHPMax = maxHP*2/3,
		},
		[STATE.DASH] = {
			availableHPMin = 0,
			availableHPMax = maxHP/3,
		},
	},
	meteorID=861,
	fireBreathID=860,
	fireRainID=859,
	headOffset = {
		[-1] = {
			x = -192,
			y = -72,
		},
		[1] = {
			x = 192,
			y = -72,
		}
	},
	spawnOffset = {
		[-1] = {
			x = -112,
			y = -48,
		},
		[1] = {
			x = 112,
			y = -48,
		}
	},
	bodyFrames = 8,
	bodyFrameStyle = 1,
	headFrames = 16,
	headFrameStyle = 1,
	--Whenever Draggadon opens its mouth to charge a stream of fire attack, players can throw certain NPCs into its mouth and damage it.
	consumeNPCTable = {
		896,
		434,
		135,
		134,
		136,
		137,
		697,
		408,
		409,
	},
	priority = 15,
	hpDecWeak= 0.25,
	hpDecStrong= 1,
	sfx_hurt = 39,
	iFramesDelay = 80,
}

--Applies NPC settings
local draggadonConfig = npcManager.setNpcSettings(draggadonBossSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function draggadonBoss.onInitAPI()
	npcManager.registerEvent(npcID, draggadonBoss, "onTickEndNPC")
	--npcManager.registerEvent(npcID, draggadonBoss, "onTickEndNPC")
	npcManager.registerEvent(npcID, draggadonBoss, "onDrawNPC")
	registerEvent(draggadonBoss, "onNPCHarm")
end
local function SFXPlay(sfx)
	if sfx then
		SFX.play(sfx)
	end
end

local function SFXPlayTable(sfx)
	if sfx then
		local sfxChoice = RNG.irandomEntry(sfx)
		if sfxChoice then
			SFX.play(sfxChoice)
		end
	end
end
function draggadonBoss.onTickEndNPC(v)
	--Don't act during time freeze --
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	local cfg = v.data._settings
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height/2)

	data.neckBox = Colliders.Box(v.x - (v.width * 2), v.y - (v.height * 1.5), config.neckHitbox.width, config.neckHitbox.height)
	data.neckBox.x = v.x + v.width/2 + config.neckHitbox.x[v.direction]
	data.neckBox.y = v.y + v.height/2 + config.neckHitbox.y

	data.headBox = Colliders.Box(v.x - (v.width * 2), v.y - (v.height * 1.5), config.headHitbox.width, config.headHitbox.height)
	data.headBox.x = v.x + v.width/2 + config.headHitbox.x[v.direction]
	data.headBox.y = v.y + v.height/2 + config.headHitbox.y

	data.mouthBox = Colliders.Box(v.x - (v.width * 2), v.y - (v.height * 1.5), config.mouthHitbox.width, config.mouthHitbox.height)
	data.mouthBox.x = v.x + v.width/2 + config.mouthHitbox.x[v.direction]
	data.mouthBox.y = v.y + v.height/2 + config.mouthHitbox.y
	--If despawned --
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary --
		data.initialized = false
		return
	end

	--Initialize --
	if not data.initialized then
		--Initialize necessary data. --
		data.initialized = true
		data.bodyimg = data.bodyimg or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = draggadonConfig.bodyFrames * (1 + draggadonConfig.bodyFrameStyle), texture = Graphics.sprites.npc[v.id].img}
		data.headimg = data.headimg or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = draggadonConfig.headFrames * (1 + draggadonConfig.headFrameStyle), texture = Graphics.loadImageResolved("npc-"..npcID.."-head.png")}
	end

	--Depending on the NPC, these checks must be handled differently --
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		return
	end

	-- Custom Animations: Variables --
	data.attacking = data.attacking or false
	data.flyAroundTimer = data.flyAroundTimer or 1
	data.headcurrentFrame = data.headcurrentFrame or 1
	data.headframeTimer = data.headframeTimer or 8
	data.headcurrentAnim = data.headcurrentAnim or 0
	data.currentFrame = data.currentFrame or 1
	data.frameTimer = data.frameTimer or 8
	data.currentAnim = data.currentAnim or 1
	data.selectedAttack = data.selectedAttack or nil
	data.rainState = data.rainState or 0
	data.rainTimer = data.rainTimer or 0
	data.headOffsetY = data.headOffsetY or 0
	data.state = data.state or 0
	data.health = data.health or 0
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	data.iFrames = data.iFrames or false
	data.hurtTimer = data.hurtTimer or 0
	data.iFramesDelay = data.iFramesDelay or config.iFramesDelay
	data.shootTimer = data.shootTimer or 0
	data.shootsFired = data.shootsFired or 0
	data.rotation = data.rotation or 0
	data.rotationTick = data.rotationTick or 0
	
	-- Custom Animations: Handling --
	data.frameTimer = data.frameTimer + 1

	data.currentFrame = math.floor(data.frameTimer / 6) % 8
	
	-- Custom Animations: Handling Head--
	data.headframeTimer = data.headframeTimer + 1
	if data.headcurrentAnim == 0 then
		if data.headframeTimer < 40 then
			data.headcurrentFrame = 0
		elseif data.headframeTimer < 48 then
			data.headcurrentFrame = 1
		else
			data.headframeTimer = 0
			data.headcurrentFrame = 0
		end
	elseif data.headcurrentAnim == 1 then
		if data.headframeTimer < 4 then
			data.headcurrentFrame = 3
		elseif data.headframeTimer < 8 then
			data.headcurrentFrame = 4
		elseif data.headframeTimer < 12 then
			data.headcurrentFrame = 5
		elseif data.headframeTimer < 16 then
			data.headcurrentFrame = 4
		elseif data.headframeTimer < 20 then
			data.headcurrentFrame = 3
		else
			data.headframeTimer = 0
			data.headcurrentFrame = 3
			data.headcurrentAnim = 0
		end
	elseif data.headcurrentAnim == 2 then
		if data.headframeTimer < 10 then
			data.headcurrentFrame = 1
		elseif data.headframeTimer < 70 then
			data.headcurrentFrame = math.floor((data.headframeTimer - 10) / 8) % 2 + 6
		elseif data.headframeTimer < 80 then
			data.headcurrentFrame = 1
		else
			data.headframeTimer = 0
			data.headcurrentFrame = 1
			data.headcurrentAnim = 0
		end
	end
	-- Let's set custom settings --
	--Shooting stuff --
	data.rotation = data.rotation or 0
	data.rotationTick = data.rotationTick or 0
	data.timer = data.timer + 1
	if data.state == STATE.IDLE or data.state == STATE.RAIN then
		local horizontalDistance = cfg.flyAroundHorizontalDistance*0.5*v.spawnDirection
		local verticalDistance = cfg.flyAroundVerticalDistance*0.5
		local horizontalTime = cfg.flyAroundHorizontalTime / math.pi / 2
		local verticalTime   = cfg.flyAroundVerticalTime   / math.pi / 2
		v.speedX = math.cos(data.flyAroundTimer / horizontalTime)*horizontalDistance / horizontalTime
		v.speedY = math.sin(data.flyAroundTimer / verticalTime  )*verticalDistance   / verticalTime
		data.flyAroundTimer = data.flyAroundTimer + 1
	else
		v.speedX = 0
		v.speedY = 0
	end
	if data.state == STATE.IDLE then
		if data.timer >= 64 and not data.attacking then
			data.attacking = true
			data.state = STATE.RAIN
			data.timer = 0
		end
	elseif data.state == STATE.RAIN then
		data.shootTimer = data.shootTimer - 1
		if data.shootTimer <= 0 and data.attacking then
			if data.rainState == 0 then
				data.rotation = data.rotation + 2
				data.rotationTick = data.rotationTick + 2
				data.headOffsetY = data.headOffsetY + 4/5
				if data.rotationTick >= 50 then
					data.rotation = 50
					data.rainState = 1
					data.shootTimer = 30
					data.headOffsetY = 20
				end
			elseif data.rainState == 1 then
				data.headcurrentAnim = 1
				data.headcurrentFrame = 3
				data.headframeTimer = 0
				if data.shootsFired >= 6 - 1 then
					data.shootsFired = 0
					data.rainState = 2
				else
					data.shootTimer = lunatime.toTicks(0.5)
					data.shootsFired = data.shootsFired + 1
					data.attacking = true
				end
			elseif data.rainState == 2 then
				data.rotation = data.rotation - 2
				data.rotationTick = data.rotationTick - 2
				data.headOffsetY = data.headOffsetY - 4/5
				if data.rotationTick <= 0 then
					data.rotation = 0
					data.rotationTick = 0
					data.rainState = 0
					data.shootTimer = 0
					data.shootsFired = 0
					data.attacking = false
					data.headOffsetY = 0
					data.timer = 0
					data.state = STATE.IDLE
				end
			end
		end
	elseif data.state == STATE.HURT then
		if data.timer >= 80 then
			data.timer = 0
			data.state = STATE.IDLE
		end
	end
		--iFrames System made by MegaDood & DRACalgar Law
		if data.iFrames then
			v.friendly = true
			data.hurtTimer = data.hurtTimer + 1
			
			if data.hurtTimer == 1 and data.health < maxHP then
				SFXPlay(config.sfx_hurt)
				data.state = STATE.HURT
				data.timer = 0
			end
			if data.hurtTimer >= data.iFramesDelay then
				v.friendly = false
				data.iFrames = false
				data.hurtTimer = 0
			end
		end
	if (Colliders.collide(plr, v) or Colliders.collide(plr, data.neckBox) or Colliders.collide(plr, data.headBox) or (Colliders.collide(plr, data.mouthBox) and data.state == STATE.IDLE)) and not v.friendly and data.state ~= STATE.KILL and data.state ~= STATE.HURT and not Defines.cheat_donthurtme then
		plr:harm()
	end
end
function draggadonBoss.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	local config = NPC.config[v.id]
	if v.id ~= npcID then return end

			if data.iFrames == false and data.state ~= STATE.KILL and data.state ~= STATE.HURT then
				local fromFireball = (culprit and culprit.__type == "NPC" and culprit.id == 13 )
				local hpd = config.hpDecStrong
				if fromFireball then
					hpd = config.hpDecWeak
					SFX.play(9)
				elseif reason == HARM_TYPE_LAVA then
					v:kill(HARM_TYPE_LAVA)
				else
					hpd = config.hpDecStrong
					data.iFrames = true
					if reason == HARM_TYPE_SWORD then
						if v:mem(0x156, FIELD_WORD) <= 0 then
							SFX.play(89)
							hpd = config.hpDecStrong
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
						hpd = config.hpDecStrong
					end
					if data.iFrames then
						data.state = STATE.HURT
						data.timer = 0
						data.headcurrentAnim = 2
						data.headcurrentFrame = 1
						data.headframeTimer = 0
					end
				end
				
				data.health = data.health + hpd
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
			if data.health >= maxHP then
				data.state = STATE.KILL
				data.timer = 0
			else
				v:mem(0x156,FIELD_WORD,60)
			end
	eventObj.cancelled = true
end
function draggadonBoss.onDrawNPC(v)
	local data = v.data
	local config = NPC.config[v.id]
	local opacity = 1
	if data.iFrames then
		opacity = math.sin(lunatime.tick()*math.pi*0.25)*0.75 + 0.9
	end
	if data.headimg then
		-- Setting some properties --
		data.headimg.x, data.headimg.y = v.x + 0.5 * v.width + draggadonConfig.gfxoffsetx + draggadonConfig.headOffset[v.direction].x, v.y + 0.5 * v.height + draggadonConfig.headOffset[v.direction].y - data.headOffsetY --[[+ draggadonConfig.gfxoffsety]]
		data.headimg.transform.scale = vector(-v.direction, 1)
		data.headimg.rotation = data.rotation * -v.direction

		local p = -config.priority

		-- Drawing --
		data.headimg:draw{frame = data.headcurrentFrame + 1, sceneCoords = true, priority = p, color = Color.white..opacity}
	end
	if data.bodyimg then
		-- Setting some properties --
		data.bodyimg.x, data.bodyimg.y = v.x + 0.5 * v.width + draggadonConfig.gfxoffsetx, v.y + 0.5 * v.height --[[+ draggadonConfig.gfxoffsety]]
		data.bodyimg.transform.scale = vector(-v.direction, 1)

		local p = -config.priority - 0.1

		-- Drawing --
		data.bodyimg:draw{frame = data.currentFrame + 1, sceneCoords = true, priority = p, color = Color.white..opacity}
	end
	npcutils.hideNPC(v)
end

--Gotta return the library table!
return draggadonBoss