--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
local effectconfig = require("game/effectconfig")
--Create the library table
local docCroc = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
--A list of states Doc Croc can take in
local STATE = {
	--Stays in place briefly before making an attack
	IDLE = 0,
	--Briefly chases the player before making an attack
	CHASE = 1,
	--Flashes yellow before consecutively shooting lightnings in different sets
	LIGHTNING = 2,
	--Flashes red before charging at the player at an angle
	CHARGE = 3,
	--Swim out of the screen and then zig zag through the screen
	ZIGZAG = 4,
	--Swim out of the screen and then skim around the screen while shooting lightning
	SKIM = 5,
	--Self-explanatory
	KILL = 6,
	--Retreats to one of the hurt BGOs
	HURT = 7,
}
--Defines NPC config for our NPC. You can remove superfluous definitions.
local docCrocSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 64,
	gfxwidth = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 56,
	height = 56,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 4,
	--Frameloop-related
	frames = 8,
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
	nofireball = false,
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
	splashWhileOutOfWater = true,
	hp = 18,
	--This decreases the hp when hit by strong attacks
	hpDecStrong = 6,
	--This decreases the hp when hit by a fireball
	hpDecWeak = 1,
	--Lightning... ;used in STATE.LIGHTNING and STATE.SKIM
	lightningID = 935,
	--A config component in which King Jelectro will randomly choose. He'll still have a chance to choose to throw  mushroom vial.
	alloutTable = {
		STATE.CHASE,
		STATE.CHASE,
		-- STATE.SKIM,
		-- STATE.ZIGZAG,
		STATE.LIGHTNING,
	},
	
	--Coordinate offset when spawning NPCs; starts at 0 on the physical center coordinate
	spawnX = 0,
	spawnY = 0,
	pulsex = false, -- controls the scaling of the sprite when firing
	pulsey = false,
	cameraOffsetY = -32,
	idleDelay = 72,
	chaseDelay = 240,
	swimAcceleration = {
		x = {
			acc = 0.05,
			cap = 5,
		},
		y = {
			acc = 0.05,
			cap = 5,
		},
	},
	beforeChaseLightningDelay = 48,
	chaseWithLightningDelay = 270,
	initLightningDelay = 30,
	lightningFrequency = 60,

	--SFX List
	sfx_introSwimIn = nil,
	sfx_introStart = nil,
	sfxTable_swimming = {
		nil,
	},
	sfxTable_startSwimming = {
		nil,
	},
	sfxTable_stopSwimming = {
		nil,
	},
	sfx_lightningInd = nil,
	sfxTable_lightningSpark = {Misc.resolveSoundFile("magikoopa-magic")},
	sfx_lightningLoop = nil,
	sfxTable_swimOut = {nil},
	sfxTable_swimZigZag = {nil},
	sfx_chargeInd = nil,
	sfxTable_chargeRush = {nil},
	sfx_hurt = 39,
	sfx_pokedSpike = nil,
	--For appealing SFX voices
	sfx_voiceAttackTable = {
		nil,
		nil,
	},
	sfx_voiceHurtTable = {
		nil,
		nil,
	},
	sfx_voiceIntro = nil,
	sfx_voiceDefeat1 = nil,
	sfx_voiceDefeat2 = nil,

	iFramesDelay = 60,
}

--Applies NPC settings
npcManager.setNpcSettings(docCrocSettings)

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
		[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Register events
function docCroc.onInitAPI()
	npcManager.registerEvent(npcID, docCroc, "onTickEndNPC")
	npcManager.registerEvent(npcID, docCroc, "onDrawNPC")
	registerEvent(docCroc, "onNPCHarm")
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

local function decideAttack(v,data,config,settings)
	local options = {}

	if config.alloutTable and #config.alloutTable > 0 then
		for i in ipairs(config.alloutTable) do
			table.insert(options,config.alloutTable[i])
		end
	end
	if #options > 0 then
		data.state = RNG.irandomEntry(options)
		data.selectedAttack = data.state
	end
	data.timer = 0
end

function docCroc.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height/2)
	local config = NPC.config[v.id]
	local settings = v.data._settings
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		return
	end
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		settings.intro = settings.intro or true

		data.w = math.pi/65
		data.timer = data.timer or 0
		data.lightningTimer = data.lightningTimer or 0
		data.hurtTimer = data.hurtTimer or 0
		data.iFrames = false
		data.health = data.health or config.hp
		if not settings.intro then
			data.state = STATE.IDLE
		else
			data.state = STATE.INTRO
			v.y = camera.y + config.cameraOffsetY - v.height/2
		end
		data.iFramesDelay = config.iFramesDelay
		data.pattern = 0
		v.ai1 = 0
		v.ai2 = 0
		v.ai3 = 0
		v.ai4 = 0
		data.moveSpeed = {
			x = 0,
			y = 0,
		}
		data.pinch = false
		data.selectedAttack = 0
		data.bgoTable = {
			[0] = {BGO.get(config.travelWhenHurtBGOID)},
			[1] = {BGO.get(config.verticalLightningBGOID)},
		}
		data.selectBGO = nil
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
	data.timer = data.timer + 1
	if data.state == STATE.IDLE then
		v.animationFrame = math.floor(data.timer / 8) % 2
		v.speedX =  0
		v.speedY = 0
		if data.timer >= config.idleDelay then
			data.timer = 0
			decideAttack(v,data,config,settings)
			data.moveSpeed.x = 0
			data.moveSpeed.y = 0
		end
	elseif data.state == STATE.CHASE then
		v.animationFrame = math.floor(data.timer / 8) % 2
		if plr.x + plr.width / 2 < v.x + v.width / 2 then
			data.moveSpeed.x = math.clamp(data.moveSpeed.x - config.swimAcceleration.x.acc, -config.swimAcceleration.x.cap, config.swimAcceleration.x.cap)
		elseif plr.x + plr.width / 2 > v.x + v.width / 2 then
			data.moveSpeed.x = math.clamp(data.moveSpeed.x + config.swimAcceleration.x.acc, -config.swimAcceleration.x.cap, config.swimAcceleration.x.cap)
		end
		if plr.y + plr.height / 2 < v.y + v.height / 2 then
			data.moveSpeed.y = math.clamp(data.moveSpeed.x - config.swimAcceleration.y.acc, -config.swimAcceleration.y.cap, config.swimAcceleration.y.cap)
		elseif plr.y + plr.height / 2 > v.y + v.height / 2 then
			data.moveSpeed.y = math.clamp(data.moveSpeed.x + config.swimAcceleration.y.acc, -config.swimAcceleration.y.cap, config.swimAcceleration.y.cap)
		end
		v.speedX = data.moveSpeed.x
		v.speedY = data.moveSpeed.y
		if data.timer == 1 then
			data.moveSpeed.x = 0
			data.moveSpeed.y = 0
		elseif data.timer >= config.chaseDelay then
			data.moveSpeed.x = 0
			data.moveSpeed.y = 0
			data.timer = 0
			data.state = STATE_IDLE
			v.speedX = 0
			v.speedY = 0
		end
	elseif data.state == STATE.LIGHTNING then
		if v.ai1 == 0 then
			v.speedX = 0
			v.speedY = 0
			if data.timer % 16 >= 12 then
				v.animationFrame = 0
			elseif data.timer % 16 >= 8 then
				v.animationFrame = 4
			elseif data.timer % 16 >= 4 then
				v.animationFrame = 1
			else
				v.animationFrame = 5
			end
			if data.timer >= config.beforeChaseLightningDelay then
				data.timer = 0
				v.ai1 = 1
			end
		elseif v.ai1 == 1 then
			data.lightningTimer = data.lightningTimer + 1
			if data.lightning then
				if data.timer % 16 >= 12 then
					v.animationFrame = 0
				elseif data.timer % 16 >= 8 then
					v.animationFrame = 4
				elseif data.timer % 16 >= 4 then
					v.animationFrame = 1
				else
					v.animationFrame = 5
				end
				v.speedX = 0
				v.speedY = 0
				if data.lightningTimer >= config.lightningDelay then
					data.lightning = false
					data.lightningTimer = 0
				end
			else
				if data.timer % 16 >= 12 then
					v.animationFrame = 0
				elseif data.timer % 16 >= 8 then
					v.animationFrame = 0
				elseif data.timer % 16 >= 4 then
					v.animationFrame = 1
				else
					v.animationFrame = 1
				end
				if plr.x + plr.width / 2 < v.x + v.width / 2 then
					data.moveSpeed.x = math.clamp(data.moveSpeed.x - config.swimAcceleration.x.acc, -config.swimAcceleration.x.cap, config.swimAcceleration.x.cap)
				elseif plr.x + plr.width / 2 > v.x + v.width / 2 then
					data.moveSpeed.x = math.clamp(data.moveSpeed.x + config.swimAcceleration.x.acc, -config.swimAcceleration.x.cap, config.swimAcceleration.x.cap)
				end
				if plr.y + plr.height / 2 < v.y + v.height / 2 then
					data.moveSpeed.y = math.clamp(data.moveSpeed.x - config.swimAcceleration.y.acc, -config.swimAcceleration.y.cap, config.swimAcceleration.y.cap)
				elseif plr.y + plr.height / 2 > v.y + v.height / 2 then
					data.moveSpeed.y = math.clamp(data.moveSpeed.x + config.swimAcceleration.y.acc, -config.swimAcceleration.y.cap, config.swimAcceleration.y.cap)
				end
				v.speedX = data.moveSpeed.x
				v.speedY = data.moveSpeed.y
				if data.lightningTimer >= config.lightningFrequency then
					data.lightning = true
					data.lightningTimer = 0
					SFXPlay(sfxTable_lightningSpark)
					for i = 0,1 do
						local n = NPC.spawn(config.lightningID, v.x + v.width / 2, v.y + v.height / 2, v.section, false, true)
						n.direction = -1 + (2 * i)
						n.speedX = 5 * n.direction
					end
				end
			end
			if data.timer == 1 then
				data.moveSpeed.x = 0
				data.moveSpeed.y = 0
			elseif data.timer >= config.chaseWithLightningDelay then
				data.moveSpeed.x = 0
				data.moveSpeed.y = 0
				data.timer = 0
				v.ai1 = 0
				data.timer = 0
				v.speedX = 0
				v.speedY = 0
				data.lightning = false
				data.lightningTimer = 0
			end
		else
			data.timer = 0
			v.ai1 = 1
		end
	elseif data.state == STATE.INTRO then
		v.friendly = true
		v.speedX = 0
		if v.ai1 == 0 then
			if data.timer == 1 then SFXPlay(config.sfx_introSwimIn) end
			v.animationFrame = math.floor(data.timer / 8) % 2
			if v.y >= v.spawnY then
				v.y = v.spawnY
				data.timer = 0
				v.ai1 = 1
			else
				v.y = v.y + 2
				--v:mem(0x12C, FIELD_WORD) = 6
			end
		else
			if data.timer == 1 then SFXPlay(config.sfx_introStart) end
			v.animationFrame = math.floor(data.timer / 8) % 2
			if data.timer >= 56 then data.state = STATE.IDLE v.ai1 = 0 data.timer = 0 v.friendly = false end
		end

	elseif data.state == STATE.HURT then
		v.speedX = 0
		v.speedY = 0
		v.friendly = true
		v.animationFrame = math.floor(data.timer / 8) % 2 + 6
		if data.timer >= config.hurtDelay then
			data.timer = 0
			data.state = STATE.IDLE
			v.friendly = false
			v.ai1 = 0
			v.ai2 = 0
			v.ai3 = 0
		end
    else
		v.speedX = 0
		v.speedY = 0
		v.friendly = true
		v.animationFrame = math.floor(data.timer / 8) % 2 + 6
		if data.timer == 1 then SFXPlay(config.sfx_voiceDefeat1) end
		if data.timer >= 120 then
			v:kill(HARM_TYPE_NPC)
			SFXPlay(config.sfx_defeatPoof)
			SFXPlay(config.sfx_voiceDefeat2)
		end
	end

	local verticalDistance = 16*0.5
	local verticalTime   = 48 / math.pi / 2
	v.speedY = v.speedY + math.sin(lunatime.tick() / verticalTime  )*verticalDistance   / verticalTime

	--Give Doc Croc some i-frames to make the fight less cheesable
	--iFrames System made by MegaDood & DRACalgar Law
	if data.iFrames then
		v.friendly = true
		data.hurtTimer = data.hurtTimer + 1
		
		if data.hurtTimer == 1 and data.health > 0 then
		    SFXPlay(config.sfx_hurt)
			SFXPlayTable(config.sfx_voiceHurtTable)
			data.state = STATE.HURT
			data.timer = 0
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
			frames = docCrocSettings.frames
		});
	end
	if config.pinchSet == 0 and not data.pinch and data.health <= config.pinchHP then
		data.pinch = true
	end
	
	--Prevent Doc Croc from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	if Colliders.collide(plr, v) and not v.friendly and data.state ~= STATE.TELEPORT and data.state ~= STATE.KILL and data.state ~= STATE.HURT and not Defines.cheat_donthurtme then
		plr:harm()
	end
end

function docCroc.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	local config = NPC.config[v.id]
	if v.id ~= npcID then return end

			if data.iFrames == false and data.state ~= STATE.KILL and data.state ~= STATE.HURT then
				local fromFireball = (culprit and culprit.__type == "NPC" and culprit.id == 13 )
				local hpd = 10
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
						data.hurting = true
						
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
				data.state = STATE.KILL
				data.timer = 0
			else
				v:mem(0x156,FIELD_WORD,60)
			end
	eventObj.cancelled = true
end

local lowPriorityStates = table.map{1,3,4}
function docCroc.onDrawNPC(v)
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]
	data.w = math.pi/65

	--Setup code by Mal8rk
	local pivotOffsetX = 0
	local pivotOffsetY = 0

	local opacity = 1

	local priority = 1
	if lowPriorityStates[v:mem(0x138,FIELD_WORD)] then
		priority = -75
	elseif v:mem(0x12C,FIELD_WORD) > 0 then
		priority = -30
	end

	--Text.print(v.x, 8,8)
	--Text.print(data.timer, 8,32)

	if data.iFrames then
		opacity = math.sin(lunatime.tick()*math.pi*0.25)*0.75 + 0.9
	end

	if data.img then
		-- Setting some properties --
		data.img.x, data.img.y = v.x + 0.5 * v.width + config.gfxoffsetx, v.y + 0.5 * v.height --[[+ config.gfxoffsety]]
		data.img.transform.scale = vector(data.sprSizex, data.sprSizey)
		data.img.rotation = data.angle

		local p = -55

		-- Drawing --
		data.img:draw{frame = v.animationFrame + 1, sceneCoords = true, priority = p, color = Color.white..opacity}
		npcutils.hideNPC(v)
	end
end

--Gotta return the library table!
return docCroc