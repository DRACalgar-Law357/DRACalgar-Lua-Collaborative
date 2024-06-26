--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
local easing = require("ext/easing")
klonoa.UngrabableNPCs[NPC_ID] = true
--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 344,
	gfxwidth = 588,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 72,
	height = 72,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 62,
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
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	staticdirection = true,
	-- ultra-configurable beam stuff!
	frameStates = {
		[0] = {
			frames = {0,1,2},
			framespeed = 6,
			loopFrames = true,
		},
		[1] = {
			frames = {3,4,5},
			framespeed = 8,
			loopFrames = true,
		},
		[2] = {
			frames = {6,7,8,9,10,11},
			framespeed = 4,
			loopFrames = false,
		},
		[3] = {
			frames = {12,13,14,15,16,17,18,19,20,21,22},
			framespeed = 4,
			loopFrames = true,
		},
		[4] = {
			frames = {23},
			framespeed = 6,
			loopFrames = false,
		},
		[5] = {
			frames = {24},
			framespeed = 6,
			loopFrames = false,
		},
		[6] = {
			frames = {25,26,27,28,29},
			framespeed = 6,
			loopFrames = false,
		},
		[7] = {
			frames = {30,31},
			framespeed = 6,
			loopFrames = true,
		},
		[8] = {
			frames = {32,33,34},
			framespeed = 4,
			loopFrames = false,
		},
		[9] = {
			frames = {35,36,37,38,39,40,41,42,43,44,45},
			framespeed = 4,
			loopFrames = false,
		},
		[10] = {
			frames = {46,47,48,49},
			framespeed = 6,
			loopFrames = false,
		},
		[11] = {
			frames = {50,51,52},
			framespeed = 6,
			loopFrames = false,
		},
		[12] = {
			frames = {53,54},
			framespeed = 6,
			loopFrames = true,
		},
		[13] = {
			frames = {3,4,5},
			framespeed = 6,
			loopFrames = true,
		},
		[14] = {
			frames = {55,24},
			framespeed = 6,
			loopFrames = true,
		},
		[15] = {
			frames = {56,57},
			framespeed = 8,
			loopFrames = false,
		},
		[16] = {
			frames = {24,58},
			framespeed = 8,
			loopFrames = false,
		},
		[17] = {
			frames = {23,24,59,60,61},
			framespeed = 6,
			loopFrames = false,
		},
		[18] = {
			frames = {17,18,19,20},
			framespeed = 6,
			loopFrames = false,
		},
	},
	flipSpriteWhenFacingDirection = true, --flips the sprite by a scale
	priority = -45,
	spriteoffsetx = 0,
	spriteoffsety = -120,

	beamlength = 6,
	beamanglestart = 0,
	beamangleend = 150,
	beamanglestartfloat = 10,
	beamangleendfloat = 210,
	walktime = 240,
	ramtime = 220,
	idletime = 60,
	speedIncrease = 2.5,
	walkspeed = 1.5,
	shoottime = 75,
	chargetime = 60,
	jumptime = 40,
	jumpheight = 8,
	beamtime = 80,
	sparkspawndelay = 0.3,
	sparkkilldelay = 0.1,
	sparkid = 793,
	beamid = 792,
	elecid = 794,
	starID = 782,
	shootspeed = 6,
	hp = 40
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
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=856,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

local effectOffsetSkid = {
	[-1] = 64,
	[1] = 32
}

local BOSSANIMSTATE = {
	IDLE = 0,
	WALK = 1,
	CHARGEBEAM = 2,
	HOP = 3,
	PREPAREJUMP = 4,
	RELEASEBEAM = 5,
	AIRBEAMINDICATE = 6,
	AIRBEAMWHIP = 7,
	FALLING = 8,
	BEAMINDICATE = 9,
	BEAMWHIP = 10, --BEAM ATTACK!
	BEAMWHIPAFTER = 11,
	DEFEATEDAIR = 12,
	DEFEATEDLANDED = 13,
	DEFEATEDSTATIC = 14,
	LOB1 = 15,
	LOB2 = 16,
	SUPERJUMP = 17,
	AIRBALL1 = 18,
	AIRBALL2 = 19,
	LANDED = 20,
	RUNNING = 21
}
local function changeAnimateState(v,data,config,animateState)
	if data.animateState ~= animateState then
		--Change animation state
		data.animateState = animateState
		data.currentFrame = config.frameStates[animateState].frames[0]
		data.currentFrameTimer = 0
		data.frameCounter = 1
		data.frameTimer = 0
	end
end

--Waddle Doo States
local STATE_IDLE = 0
local STATE_WALK = 1
local STATE_CHARGE = 2
local STATE_BEAM = 3
local STATE_HOP = 4
local STATE_RAM = 5
local STATE_DONE_RAM = 6
local STATE_JUMP_TO_BEAM = 7
local STATE_SHOOT = 8
local STATE_LOB = 9
local STATE_KILL = 10
local STATE_SKID = 11

local sfx_beamstart = Misc.resolveSoundFile("doo-beam-start")
local sfx_beamloop = Misc.resolveSoundFile("doo-beam")
local sfx_bosshurt = Misc.resolveFile("Kirby Enemy Hit.wav")
local sfx_bossdefeat = Misc.resolveFile("Boss Dead.wav")

local loopingSounds = {}

function sampleNPC.onInitAPI()
	registerEvent(sampleNPC, "onNPCHarm")
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC", "onTickEndDoo")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC", "onDrawDoo")
end

-- Doo Functions & Events

local function getBeamPos(v, step, angle)
	local bv = vector(0, step*-32 + NPC.config[v.id].height/2):rotate(angle)
	return {x = (bv.x+16)*v.direction + (v.x + v.width/2) + v.speedX, y = bv.y + (v.y + v.height/2) + v.speedY}
end

local function changeState(v, newState)
	local data = v.data
	data.timer = 0
	data.state = newState
	data.sparkCooldown = 0
	data.sparkOffset = 0
	if newState ~= STATE_BEAM then
		for i=#data.sparkList, 1, -1 do
			if data.sparkList[i].isValid then
				data.sparkList[i]:kill()
			end
		end
		data.sparkList = {}
		if data.sound and data.sound.isValid and data.sound:isPlaying() then data.sound:Stop() end
		data.sound = nil
	end
end
local spawnOffset = {
	[-1] = -20,
	[1] = 72 + 20
}
function sampleNPC.onTickEndDoo(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local cfg = NPC.config[v.id]
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
		data.timer = data.timer or 0
		data.timer2 = 0
		data.hurtTimer = data.hurtTimer or 0
		data.iFrames = false
		data.health = NPC.config[v.id].hp
		data.state = STATE_IDLE
		data.statelimit = 0
		data.randomWalkDistance = RNG.randomInt(0,64)
		data.alphaTimer = 8
		data.defeatLanded = 0

		data.sparkCooldown = 0
		data.sparkList = {}
		data.sparkOffset = 0
		data.beamConsecutive = 0

		--Handling animations
		data.currentFrame = 0
		data.currentFrameTimer = 0
		data.frameCounter = 1
		data.frameTimer = 0
		data.animateState = 0
		data.img = {
			[-1] = Graphics.sprites.npc[v.id].img,
			[1] = Graphics.loadImageResolved("npc-"..npcID.."-right.png"),
		}
		data.imgInitTick = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_IDLE
		data.timer = 0
	end

	--Handling frames (animation code by Murphmario and refined by DRACalgar Law)

	data.currentFrame = config.frameStates[data.animateState].frames[data.frameCounter]
	data.currentFrameTimer = config.frameStates[data.animateState].framespeed
	data.frameTimer = data.frameTimer - 1
	
	v.animationFrame = data.currentFrame

	if config.frameStates[data.animateState].loopFrames == true then
		if data.frameTimer <= 0 then
			data.frameTimer = config.frameStates[data.animateState].framespeed
			if data.frameCounter < #config.frameStates[data.animateState].frames then
				data.frameCounter = data.frameCounter + 1
			else
				data.currentFrameTimer = 0
				data.frameCounter = 1
			end
		end
	else
		if data.frameTimer <= 0 then
			data.frameTimer = config.frameStates[data.animateState].framespeed
			if data.frameCounter < #config.frameStates[data.animateState].frames then
				data.frameCounter = data.frameCounter + 1
			end
		end
	end
	--Colliders.getHitbox(v):draw()

	data.imgInitTick = math.clamp(data.imgInitTick+1,0,3)
	
	data.timer = data.timer + 1
	if data.state == STATE_IDLE then
		v.speedX = 0
		changeAnimateState(v,data,config,0)
		npcutils.faceNearestPlayer(v)
		if (data.timer >= NPC.config[v.id].idletime and v.collidesBlockBottom) then
			data.timer = 0
			data.state = RNG.irandomEntry{STATE_WALK,STATE_HOP}
		end
	elseif data.state == STATE_HOP then
		if data.timer == 24 then
			npcutils.faceNearestPlayer(v)
			v.speedX = 3 * -v.direction
			v.speedY = -5
			SFX.play("Kirby Jump.wav")
		end
		if data.timer < 24 then changeAnimateState(v,data,config,4) else changeAnimateState(v,data,config,5) end
		if data.timer > 24 and v.collidesBlockBottom then
			npcutils.faceNearestPlayer(v)
			data.state = STATE_RAM
		end
	elseif data.state == STATE_RAM then
		changeAnimateState(v,data,config,13)
		v.speedX = (NPC.config[v.id].walkspeed + NPC.config[v.id].speedIncrease) * v.direction
		if (v.collidesBlockLeft and v.direction == -1) or (v.collidesBlockRight and v.direction == 1) then
			SFX.play(37)
			Defines.earthquake = 6
			v.speedX = 3 * -v.direction
			v.speedY = -6
			data.timer = 0
			NPC.spawn(NPC.config[v.id].starID, v.x + v.width / 2, v.y + v.height / 2)
			data.state = STATE_DONE_RAM
		end
		if (data.timer >= NPC.config[v.id].ramtime and v.collidesBlockBottom) then
			data.timer = 0
			data.state = STATE_SKID
		end
		if data.timer % 12 == 0 then 
			SFX.play(86)
			Effect.spawn(131, v.x + effectOffsetSkid[v.direction], v.y + v.height * 0.75)
		end
	elseif data.state == STATE_SKID then
		changeAnimateState(v,data,config,5)
		v.speedX = v.speedX - 0.1 * v.direction
		Effect.spawn(74, v.x + effectOffsetSkid[v.direction], v.y + v.height)
		if data.timer % 8 == 0 then
			SFX.play(10)
		end
		if math.abs(v.speedX) <= 0.1 then
			v.speedX = 0
			data.timer = 0
			data.state = STATE_IDLE
		end
	elseif data.state == STATE_DONE_RAM then
		changeAnimateState(v,data,config,10)
		if data.timer <= 8 then
			v.animationFrame = 46
		elseif data.timer <= 16 then
			v.animationFrame = 47
		elseif data.timer <= 24 then
			v.animationFrame = 48
		else
			v.animationFrame = 49
		end
		if data.timer > 1 and v.collidesBlockBottom then
			data.timer = 0
			SFX.play(37)
			Defines.earthquake = 6
			local n = NPC.spawn(NPC.config[v.id].starID, v.x + v.width / 2, v.y + v.height / 2)
			n.speedX = 6 * -v.direction
			n.speedY = -3
			data.state = STATE_IDLE
		end
	elseif data.state == STATE_WALK then
		changeAnimateState(v,data,config,1)
		if (data.timer >= NPC.config[v.id].walktime and v.collidesBlockBottom) then
			data.timer = 0
			data.state = STATE_IDLE
		end
		if v.collidesBlockRight then v.direction = -1 end
		if v.collidesBlockLeft then v.direction = 1 end
		if math.abs((plr.x) - (v.x + v.width/2)) <= 80 then
			v.speedX = 0
			data.timer = 0
			data.state = STATE_IDLE
		else
			v.speedX = NPC.config[v.id].walkspeed * v.direction
		end
	else
		--Death stuff
		--Make the npc flash to show it's almost dead
		data.animationTick = data.animationTick or 0
			if data.animationTick == 0 then
				changeAnimateState(v,data,config,10)
			elseif data.animationTick == 1 then
				changeAnimateState(v,data,config,11)
			else
				changeAnimateState(v,data,config,12)
			end
		--Bounce a little bit to simulate physics
		if v.collidesBlockBottom and data.timer >= 8 then
			data.animationTick = math.clamp(data.animationTick+1,0,2)
			if math.abs(v.speedX) >= 2 then
				v.speedX = v.speedX / 2
				v.speedY = -3
			else
				v.speedX = 0
			end
			--Die after a bit
			if data.timer >= 386 then
				v:kill(HARM_TYPE_NPC)
				SFX.play("Boss Dead.wav")
			end
		end
	end

	--Give King Doo some i-frames to make the fight less cheesable
	if data.iFrames then
		v.friendly = true
		data.hurtTimer = data.hurtTimer + 1
		
		if data.hurtTimer == 1 then SFX.play("Kirby Enemy Hit.wav") data.alphaTimer = 8 end
		if data.hurtTimer >= 64 then
			v.friendly = false
			data.iFrames = false
			data.hurtTimer = 0
		end
	end
	--Prevent King Doo from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	
	if Colliders.collide(plr, v) and not v.friendly and data.state ~= STATE_KILL and not Defines.cheat_donthurtme and (v:mem(0x12C, FIELD_WORD) == 0 and not v:mem(0x136, FIELD_BOOL)) then
		plr:harm()
	end
	
end

function sampleNPC.onDrawDoo(v)
	--just making sure the npc is right
	if v.id ~= npcID then return end
	local data = v.data
	local config = NPC.config[v.id]
	data.w = math.pi/65

	--Setup code by Mal8rk

	local opacity = 1

	local priority = 1
	--[[if lowPriorityStates[v:mem(0x138,FIELD_WORD)] then
		priority = -75
	elseif v:mem(0x12C,FIELD_WORD) > 0 then
		priority = -30
	end]]

	--Text.print(v.x, 8,8)
	--Text.print(data.timer, 8,32)

	if data.iFrames then
		opacity = math.sin(lunatime.tick()*math.pi*0.25)*0.75 + 0.9
	end
	local faceLeft = true
	if config.flipSpriteWhenFacingDirection and v.direction == 1 then faceLeft = false end
	if data.imgInitTick == 1 then faceLeft = false end
	if data.img then
		if faceLeft then
			Graphics.drawImageToSceneWP( --King Doo Left
				data.img[-1],
				v.x+v.width/2-config.gfxwidth/2+config.spriteoffsetx,
				v.y+v.height/2-config.gfxheight/2+config.spriteoffsety,
				0,
				config.gfxheight*(v.animationFrame),
				config.gfxwidth,
				config.gfxheight,
				opacity,
				config.priority
			)
		else
			Graphics.drawImageToSceneWP( --King Doo Right
				data.img[1],
				v.x+v.width/2-config.gfxwidth/2+config.spriteoffsetx,
				v.y+v.height/2-config.gfxheight/2+config.spriteoffsety,
				0,
				config.gfxheight*(v.animationFrame),
				config.gfxwidth,
				config.gfxheight,
				opacity,
				config.priority
			)
		end
	end
	if Misc.isPaused() and data.sound and data.sound.isValid and data.sound:isPlaying() then
		data.sound:Stop()
	end
	
	npcutils.hideNPC(v)
end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end
	if data.state ~= STATE_KILL then
		if reason ~= HARM_TYPE_LAVA then
			if reason == HARM_TYPE_JUMP or killReason == HARM_TYPE_SPINJUMP or killReason == HARM_TYPE_FROMBELOW then
				SFX.play(2)
				data.iFrames = true
				data.health = data.health - 5
			elseif reason == HARM_TYPE_SWORD then
				if v:mem(0x156, FIELD_WORD) <= 0 then
					data.health = data.health - 5
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
							SFX.play("Kirby Enemy Hit.wav")
							data.health = data.health - 1
						else
							data.health = data.health - 5
							data.iFrames = true
						end
					else
						data.health = data.health - 5
						data.iFrames = true
					end
				else
					data.health = data.health - 5
					data.iFrames = true
				end
			elseif reason == HARM_TYPE_LAVA and v ~= nil then
				v:kill(HARM_TYPE_OFFSCREEN)
			elseif v:mem(0x12, FIELD_WORD) == 2 then
				v:kill(HARM_TYPE_OFFSCREEN)
			else
				data.iFrames = true
				data.health = data.health - 5
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
				data.timer = 0
				data.state = STATE_KILL
				Effect.spawn(856,v.x - v.width / 2,v.y - v.width / 2)
				SFX.play("Miniboss Dead.wav")
				v.speedX = 2 * -v.direction
				v.speedY = -10
			elseif data.health > 0 then
				v:mem(0x156,FIELD_WORD,60)
			end
		else
			v:kill(HARM_TYPE_LAVA)
		end
	else
		v:kill(HARM_TYPE_NPC)
		SFX.play("Boss Dead.wav")
	end
	eventObj.cancelled = true
end

return sampleNPC