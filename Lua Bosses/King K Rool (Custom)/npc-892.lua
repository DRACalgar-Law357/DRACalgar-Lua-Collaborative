local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}
local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxwidth = 160,
	gfxheight = 160,

	width = 64,
	height = 96,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 77,
	framestyle = 0,
	framespeed = 8,

	foreground = false,

	speed = 1,
	luahandlesspeed = false,
	nowaterphysics = false,
	cliffturn = false,
	staticdirection = false,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,

	score = 1,

	jumphurt = false,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,
	nowalldeath = false,

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	health=9,

	airImage = Graphics.loadImageResolved("npc-"..npcID.."-air.png"),

	airOffsetXRight = -54,
	airOffsetXLeft = 138,
	airOffsetXLeftOG = 138,
	airOffsetY = 48,

	airFrames = 3,
	airFramespeed = 4,
	airHeight = 88,

	frameStates = {
		[0] = {
			frames = {0},
			framespeed = 8,
			loopFrames = false,
		},
		[1] = {
			frames = {1,2,3,4,5,6,7},
			framespeed = 6,
			loopFrames = true,
		},
		[2] = {
			frames = {8,9,10,11,12,13},
			framespeed = 8,
			loopFrames = false,
		},
		[3] = {
			frames = {12,11,10,9,8},
			framespeed = 8,
			loopFrames = false,
		},
		[4] = {
			frames = {14,15},
			framespeed = 6,
			loopFrames = false,
		},
		[5] = {
			frames = {16,17},
			framespeed = 6,
			loopFrames = false,
		},
		[6] = {
			frames = {16,15},
			framespeed = 6,
			loopFrames = false,
		},
		[7] = {
			frames = {18,19,20,21,22},
			framespeed = 6,
			loopFrames = false,
		},
		[8] = {
			frames = {20,19,18,18},
			framespeed = 6,
			loopFrames = true,
		},
		[9] = {
			frames = {21,22},
			framespeed = 8,
			loopFrames = true,
		},
		[10] = {
			frames = {22,11,20,19,18,0},
			framespeed = 6,
			loopFrames = false,
		},
		[11] = {
			frames = {23,24,25,26,27},
			framespeed = 6,
			loopFrames = false,
		},
		[12] = {
			frames = {27},
			framespeed = 6,
			loopFrames = false,
		},
		[13] = {
			frames = {28,29},
			framespeed = 6,
			loopFrames = false,
		},
		[14] = {
			frames = {30,31},
			framespeed = 6,
			loopFrames = false,
		},
		[15] = {
			frames = {32,33,34,35},
			framespeed = 8,
			loopFrames = false,
		},
		[16] = {
			frames = {36,37,38,39,40,41,42,43,44,45,46,47},
			framespeed = 2,
			loopFrames = true,
		},
		[17] = {
			frames = {48,49,49,49},
			framespeed = 2,
			loopFrames = false,
		},
		[18] = {
			frames = {50,51},
			framespeed = 12,
			loopFrames = true,
		},
		[19] = {
			frames = {50,51},
			framespeed = 6,
			loopFrames = true,
		},
		[20] = {
			frames = {51},
			framespeed = 8,
			loopFrames = false,
		},
		[21] = {
			frames = {52,52,52,53},
			framespeed = 4,
			loopFrames = false,
		},
		[22] = {
			frames = {54},
			framespeed = 8,
			loopFrames = false,
		},
		[23] = {
			frames = {55,56},
			framespeed = 6,
			loopFrames = false,
		},
		[24] = {
			frames = {57,58},
			framespeed = 6,
			loopFrames = false,
		},
		[25] = {
			frames = {59,60},
			framespeed = 8,
			loopFrames = false,
		},
		[26] = {
			frames = {61,62,63},
			framespeed = 2,
			loopFrames = true,
		},
		[27] = {
			frames = {64,65,65,65},
			framespeed = 2,
			loopFrames = false,
		},
		[28] = {
			frames = {66,67},
			framespeed = 8,
			loopFrames = false,
		},
		[29] = {
			frames = {66},
			framespeed = 6,
			loopFrames = false,
		},
		[30] = {
			frames = {67},
			framespeed = 8,
			loopFrames = false,
		},
		[31] = {
			frames = {68,69},
			framespeed = 12,
			loopFrames = true,
		},
		[32] = {
			frames = {68,69},
			framespeed = 6,
			loopFrames = true,
		},
		[33] = {
			frames = {69},
			framespeed = 4,
			loopFrames = false,
		},
		[34] = {
			frames = {66},
			framespeed = 6,
			loopFrames = false,
		},
		[35] = {
			frames = {67},
			framespeed = 8,
			loopFrames = false,
		},
		[36] = {
			frames = {68,69},
			framespeed = 12,
			loopFrames = true,
		},
		[37] = {
			frames = {68,69},
			framespeed = 6,
			loopFrames = true,
		},
		[38] = {
			frames = {70,70,70,71},
			framespeed = 4,
			loopFrames = true,
		},
		[39] = {
			frames = {72,73,74,75,76},
			framespeed = 6,
			loopFrames = false,
		},
		[40] = {
			frames = {74,73,72,72},
			framespeed = 6,
			loopFrames = false,
		},
		[41] = {
			frames = {75,76},
			framespeed = 8,
			loopFrames = true,
		},
		[42] = {
			frames = {76,75,74,73,72,54},
			framespeed = 4,
			loopFrames = false,
		},
		[43] = {
			frames = {-50},
			framespeed = 8,
			loopFrames = false,
		},
	},

	flipSpriteWhenFacingDirection = false, --flips the sprite by a scale
	priority = -45,
	spriteoffsetx = 0,
	spriteoffsety = 0,

    iFramesDelay = 48,
}

npcManager.setNpcSettings(sampleNPCSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
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
--Phase 1
local STATE_IDLE = 0
local STATE_THROW = 1
local STATE_CATCH = 2
local STATE_RUN1 = 3
local STATE_RUN2 = 4
local STATE_RUN3 = 5
local STATE_JUMP1 = 6
local STATE_JUMP2 = 7
local STATE_JUMP3 = 8
local STATE_HOP1 = 9
local STATE_HOP2 = 10
local STATE_HOP3 = 11
local STATE_HURT = 12
local STATE_FAKEOUT = 13
local STATE_DEFEAT = 14
local STATE_INTRO = 15
--Phase 2
local STATE_INTRO = 0
local STATE_SHOOT = 1
local STATE_PROPEL1 = 2
local STATE_PROPEL2 = 3
local STATE_PROPEL3 = 4
local STATE_VACCUM = 5
local STATE_BACKFIRE = 6
local STATE_SHOOT2 = 7
local STATE_SHOOT3 = 8
local STATE_SHOOTSTRAIGHT = 10
local STATE_SHOOTBOUNCY = 11
local STATE_SHOOTCIRCLE = 12
local STATE_STUNCLOUD = 13
local STATE_SLOWCLOUD = 14
local STATE_REVERSECLOUD = 15
local STATE_APPEARDISAPPEAR = 16
local STATE_ATTACK = 17
local STATE_DEFEATED = 18

local spawnOffset = {
	[-1] = -32,
	[1] = sampleNPCSettings.width / 2 + 52
}

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function isNearPit(v)
	--This function either returns false, or returns the direction the npc should go to. numbers can still be used as booleans.
	local testblocks = Block.SOLID.. Block.SEMISOLID.. Block.PLAYER

	local centerbox = Colliders.Box(v.x-64, v.y, 8, v.height + 10)
	local l = centerbox
	if v.direction == DIR_RIGHT then
		l.x = l.x + 192
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

local function doJumpLogic(v)
	local data = v.data

	if v.speedY < 0 then
		data.jumpTimer = data.jumpTimer + 1

		if data.jumpTimer > 8 then
			v.animationFrame = 29
		elseif data.jumpTimer > 1 then
			v.animationFrame = math.floor(data.jumpTimer/3)%4+27
		end
	else
		v.animationFrame = 30
		data.jumpTimer = 0
	end

	if v.collidesBlockBottom then
		v.animationFrame = 26
		v.speedX = 0

		if data.timer > 299 then
			v.animationFrame = math.floor(data.timer/14)%4
		elseif data.timer == 299 then
			v.animationFrame = math.floor(data.timer/14)%4
			v.direction = -v.direction
		end
	end

	if data.timer > 18 and v.collidesBlockBottom then
		data.landTimer = data.landTimer +1

		if data.landTimer == 1 then
			Defines.earthquake = 6
			SFX.play(37)
		end
	else
		data.landTimer = 0
	end

	if data.timer == 156 then
		v.speedY = -14
		v.speedX = 5.3*v.direction
		SFX.play("Animal buddy jump.mp3")
	elseif data.timer == 80 then
		v.speedY = -8
		SFX.play("Animal buddy jump.mp3")
	elseif data.timer == 16 then
		v.speedY = -6
		SFX.play("Animal buddy jump.mp3")
	end
end

local function doHopLogic(v)
	local data = v.data

	if v.speedY < 0 then
		data.jumpTimer = data.jumpTimer + 1

		if data.jumpTimer > 8 then
			v.animationFrame = 29
		elseif data.jumpTimer > 1 then
			v.animationFrame = math.floor(data.jumpTimer/3)%4+27
		end
	else
		v.animationFrame = 30
		data.jumpTimer = 0
	end

	if v.collidesBlockBottom then
		v.animationFrame = 26
		v.speedX = 0
	end

	if data.timer > 18 and v.collidesBlockBottom then
		data.landTimer = data.landTimer +1

		if data.landTimer == 1 then
			Defines.earthquake = 6
			SFX.play(37)
		end
	else
		data.landTimer = 0
	end
end

function sampleNPC.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = data.state or STATE_INTRO
		data.crown = data.crown or nil
		data.timer = data.timer or 0
		data.health = config.health
		data.jumpTimer = 0
		data.landTimer = 0

		data.hurtTimer = data.hurtTimer or 0
		data.iFrames = false
		data.iFramesDelay = config.iFramesDelay
		data.sprSizex = 1
		data.sprSizey = 1
		data.img = data.img or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = frankSettings.frames * (1 + frankSettings.framestyle), texture = Graphics.sprites.npc[v.id].img}
	end

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

	if v.heldIndex ~= 0
	or v.isProjectile
	or v.forcedState > 0
	then
		-- Handling
	end

	data.timer = data.timer + 1

	if data.state == STATE_IDLE then
		--[[v.animationFrame = math.floor(data.timer/14)%4

		if data.timer > 80 then
			data.state = STATE_THROW
			data.timer = 0
		end]]
		v.speedX = 0
	--[[elseif data.state == STATE_THROW then
		v.animationFrame = math.floor(data.timer/6)%5+4

		if data.crown and data.crown.isValid then
			if Colliders.collide(v,data.crown) then
				data.crown:kill(HARM_TYPE_VANISH)
				v.animationFrame = 0
				data.state = STATE_CATCH
				data.timer = 0
			end
		end

		if data.timer > 80 then
			v.animationFrame = math.floor(data.timer/14)%4+9
		elseif data.timer > 28 then
			v.animationFrame = 8
		end

		if data.timer == 24 then
			data.crown = NPC.spawn(npcID+1, v.x + spawnOffset[v.direction], v.y+8 + v.height / 2, player.section, false)
			data.crown.direction = v.direction
			SFX.play(25)
		end
	elseif data.state == STATE_CATCH then
		v.animationFrame = 0

		if data.timer == 1 then
			Effect.spawn(npcID, v.x, v.y-16, player.section, false)
		end

		if data.timer > 48 then
			if data.health == 10 then
				data.state = STATE_IDLE
				data.timer = 0
			elseif data.health == 9 then
				data.state = STATE_RUN1
				data.timer = 0
			elseif data.health == 8 then
				data.state = STATE_RUN1
				data.timer = 0
			elseif data.health == 7 then
				data.state = STATE_RUN1
				data.timer = 0
			elseif data.health == 6 then
				data.state = STATE_JUMP1
				data.timer = 0
			elseif data.health == 5 then
				data.state = STATE_JUMP2
				data.timer = 0
			elseif data.health == 4 then
				data.state = STATE_JUMP3
				data.timer = 0
			elseif data.health == 3 then
				data.state = STATE_HOP1
				data.timer = 0
			elseif data.health == 2 then
				data.state = STATE_HOP1
				data.timer = 0
			elseif data.health == 1 then
				data.state = STATE_HOP1
				data.timer = 0
			end
		end
	elseif data.state == STATE_HURT then
		v.animationFrame = 13

		if data.timer > 32 then
			v.animationFrame = math.floor(data.timer/6)%4+14

			if data.crown and data.crown.isValid then
				data.crown:kill(HARM_TYPE_VANISH)
				Effect.spawn(npcID, v.x, v.y-16, player.section, false)
			end
		end

		if data.timer > 100 then
			if data.health == 9 then
				data.state = STATE_RUN1
				data.timer = 0
			elseif data.health == 8 then
				data.state = STATE_RUN1
				data.timer = 0
			elseif data.health == 7 then
				data.state = STATE_RUN1
				data.timer = 0
			elseif data.health == 6 then
				data.state = STATE_JUMP1
				data.timer = 0
			elseif data.health == 5 then
				data.state = STATE_JUMP2
				data.timer = 0
			elseif data.health == 4 then
				data.state = STATE_JUMP3
				data.timer = 0
			elseif data.health == 2 then
				data.state = STATE_HOP1
				data.timer = 0
			elseif data.health == 1 then
				data.state = STATE_HOP1
				data.timer = 0
			end
		end
	elseif data.state == STATE_RUN1 then
		v.animationFrame = math.floor(data.timer/6)%8+18
		v.speedX = 3.5*v.direction

		if data.timer % 24 == 0 then
			SFX.play("Klomp.wav")
		end

		if isNearPit(v) or v.collidesBlockLeft or v.collidesBlockRight then
			data.state = STATE_IDLE
			v.direction = -v.direction
			data.timer = 0

			if data.health == 8 then
				data.state = STATE_RUN2
				data.timer = 0
			elseif data.health == 7 then
				data.state = STATE_RUN2
				data.timer = 0
			end
		end
	elseif data.state == STATE_RUN2 then
		v.animationFrame = math.floor(data.timer/14)%4

		if data.timer > 50 then
			v.animationFrame = math.floor(data.timer/5)%8+18
			v.speedX = 5*v.direction

			if data.timer % 20 == 0 then
				SFX.play("Klomp.wav")
			end
		end

		if isNearPit(v) or v.collidesBlockLeft or v.collidesBlockRight then
			data.state = STATE_IDLE
			v.direction = -v.direction
			data.timer = 0

			if data.health == 7 then
				data.state = STATE_RUN3
				data.timer = 0
			end
		end
	elseif data.state == STATE_RUN3 then
		v.animationFrame = math.floor(data.timer/14)%4

		if data.timer > 50 then
			v.animationFrame = math.floor(data.timer/4)%8+18
			v.speedX = 6.2*v.direction

			if data.timer % 16 == 0 then
				SFX.play("Klomp.wav")
			end
		end

		if isNearPit(v) or v.collidesBlockLeft or v.collidesBlockRight then
			data.state = STATE_IDLE
			v.direction = -v.direction
			data.timer = 0
		end
	elseif data.state == STATE_JUMP1 then
		doJumpLogic(v)

		if data.timer % 40 == 0 and data.timer >= 270 and data.timer <= 600 then
			NPC.spawn(npcID+2, player.x + 0.5 * player.width, Camera.get()[1].y - 0, player.section, false, true)
			SFX.play("Barrel_blast.mp3")
		end

		if data.timer > 690 then
			data.state = STATE_THROW
			data.timer = 0
		end
	elseif data.state == STATE_JUMP2 then
		doJumpLogic(v)

		if data.timer % 35 == 0 and data.timer >= 270 and data.timer <= 600 then
			NPC.spawn(npcID+2, player.x + 0.5 * player.width, Camera.get()[1].y - 0, player.section, false, true)
			SFX.play("Barrel_blast.mp3")
		end

		if data.timer > 690 then
			data.state = STATE_THROW
			data.timer = 0
		end
	elseif data.state == STATE_JUMP3 then
		doJumpLogic(v)

		if data.timer % 30 == 0 and data.timer >= 270 and data.timer <= 600 then
			NPC.spawn(npcID+2, player.x + 0.5 * player.width, Camera.get()[1].y - 0, player.section, false, true)
			SFX.play("Barrel_blast.mp3")
		end

		if data.timer > 690 then
			data.state = STATE_THROW
			data.timer = 0
		end
	elseif data.state == STATE_FAKEOUT then
		v.friendly = true

		v.animationFrame = 13

		if data.timer > 510 then
			data.state = STATE_HOP1
			v.friendly = false
			v.animationFrame = 26
			data.timer = 0
		elseif data.timer > 488 then
			v.animationFrame = math.floor(data.timer/14)%4
		elseif data.timer > 482 then
			v.animationFrame = 32
		elseif data.timer > 476 then
			v.animationFrame = 33
		elseif data.timer > 470 then
			v.animationFrame = 34
			if data.timer == 471 then SFX.play("Animal buddy jump.mp3") end
		elseif data.timer > 390 then
			v.animationFrame = 33
			if data.timer == 391 then SFX.play("Tyre bounce.mp3") end
		elseif data.timer > 128 then
			v.animationFrame = 34
		elseif data.timer > 120 then
			v.animationFrame = math.floor(data.timer/6)%4+32
			if data.timer == 121 then 
				SFX.play("Krusha Die.wav") 
			end
		elseif data.timer > 32 then
			v.animationFrame = 31

			if data.timer%4 > 0 and data.timer%4 < 3 then
				v.x = v.x + 2
			else
				v.x = v.x - 2
			end

			if data.crown and data.crown.isValid then
				data.crown:kill(HARM_TYPE_VANISH)
				Effect.spawn(npcID, v.x, v.y-16, player.section, false)
			end
		end
	elseif data.state == STATE_HOP1 then
		doHopLogic(v)

		if data.timer == 95 then
			v.speedY = -8
			v.speedX = 5*v.direction
			SFX.play("Animal buddy jump.mp3")
		elseif data.timer == 16 then
			v.speedY = -8
			v.speedX = 5*v.direction
			SFX.play("Animal buddy jump.mp3")
		end

		if data.timer > 170 then
			v.animationFrame = math.floor(data.timer/14)%4
		elseif data.timer == 170 then
			v.animationFrame = math.floor(data.timer/14)%4
			v.direction = -v.direction

			if data.health == 2 then
				data.state = STATE_HOP2
				v.animationFrame = 26
				data.timer = 0
			elseif data.health == 1 then
				data.state = STATE_HOP2
				v.animationFrame = 26
				data.timer = 0
			end
		end

		if data.timer > 230 then
			data.state = STATE_THROW
			data.timer = 0
		end
	elseif data.state == STATE_HOP2 then
		doHopLogic(v)

		if data.timer == 180 then
			v.speedY = -8
			v.speedX = 3.3*v.direction
			SFX.play("Animal buddy jump.mp3")
		elseif data.timer == 95 then
			v.speedY = -8
			v.speedX = 3.3*v.direction
			SFX.play("Animal buddy jump.mp3")
		elseif data.timer == 16 then
			v.speedY = -8
			v.speedX = 3.3*v.direction
			SFX.play("Animal buddy jump.mp3")
		end

		if data.timer > 260 then
			v.animationFrame = math.floor(data.timer/14)%4
		elseif data.timer == 260 then
			v.animationFrame = math.floor(data.timer/14)%4
			v.direction = -v.direction

			if data.health == 1 then
				data.state = STATE_HOP3
				v.animationFrame = 26
				data.timer = 0
			end
		end

		if data.timer > 330 then
			data.state = STATE_THROW
			data.timer = 0
		end
	elseif data.state == STATE_HOP3 then
		doHopLogic(v)

		if data.timer == 340 then
			v.speedY = -8
			v.speedX = 1.95*v.direction
			SFX.play("Animal buddy jump.mp3")
		elseif data.timer == 260 then
			v.speedY = -8
			v.speedX = 1.95*v.direction
			SFX.play("Animal buddy jump.mp3")
		elseif data.timer == 180 then
			v.speedY = -8
			v.speedX = 1.95*v.direction
			SFX.play("Animal buddy jump.mp3")
		elseif data.timer == 95 then
			v.speedY = -8
			v.speedX = 1.95*v.direction
			SFX.play("Animal buddy jump.mp3")
		elseif data.timer == 16 then
			v.speedY = -8
			v.speedX = 1.95*v.direction
			SFX.play("Animal buddy jump.mp3")
		end

		if data.timer > 420 then
			v.animationFrame = math.floor(data.timer/14)%4
		elseif data.timer == 420 then
			v.animationFrame = math.floor(data.timer/14)%4
			v.direction = -v.direction
		end

		if data.timer > 490 then
			data.state = STATE_THROW
			data.timer = 0
		end
	elseif data.state == STATE_DEFEAT then
		v.friendly = true

		v.animationFrame = 13

		if data.timer == 210 then
			local orb = NPC.spawn(354, v.x-32+v.width*0.5, v.y+v.height*0.5, player.section, false)
			orb.speedY = -6
			orb.speedX = 5.1*v.direction
			SFX.play(20)
			v.animationFrame = 34
		elseif data.timer > 128 then
			v.animationFrame = 34
		elseif data.timer > 120 then
			v.animationFrame = math.floor(data.timer/6)%4+32
			if data.timer == 121 then 
				SFX.play("Krusha Die.wav") 
			end
		elseif data.timer > 32 then
			v.animationFrame = 31

			if data.timer%4 > 0 and data.timer%4 < 3 then
				v.x = v.x + 2
			else
				v.x = v.x - 2
			end

			if data.crown and data.crown.isValid then
				data.crown:kill(HARM_TYPE_VANISH)
				Effect.spawn(npcID, v.x, v.y-16, player.section, false)
			end
		end
	elseif data.state == STATE_INTRO then
		v.animationFrame = 30

		if v.collidesBlockBottom then
			v.animationFrame = 26
			data.landTimer = data.landTimer + 1

			if data.landTimer == 1 then
				Defines.earthquake = 6
				SFX.play(37) 
			end

			if data.landTimer > 32 then
				data.state = STATE_IDLE
				data.timer = 0
				data.landTimer = 0
			end
		end]]
	end

	--iFrames System made by MegaDood & DRACalgar Law
	if data.iFrames then
		v.friendly = true
		data.hurtTimer = data.hurtTimer + 1
		
		if data.hurtTimer == 1 and data.health > 0 then
		    SFX.Play(39)
		end
		if data.hurtTimer >= data.iFramesDelay then
			v.friendly = false
			data.iFrames = false
			data.hurtTimer = 0
		end
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = data.frames
	});
end

function sampleNPC.onDrawNPC(v)
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

	if data.state == STATE_DEFEAT then
		npcutils.drawNPC(v,{priority = -32})
		npcutils.hideNPC(v)
	end

	if data.img then
		-- Setting some properties --
		data.img.x, data.img.y = v.x + 0.5 * v.width + config.spriteoffsetx, v.y + 0.5 * v.height + config.spriteoffsety
		if config.flipSpriteWhenFacingDirection then
			data.img.transform.scale = vector(data.sprSizex * -v.direction, data.sprSizey)
		else
			data.img.transform.scale = vector(data.sprSizex, data.sprSizey)
		end
		data.img.rotation = data.angle

		local p = config.priority

		-- Drawing --
		data.img:draw{frame = v.animationFrame + 1, sceneCoords = true, priority = p, color = Color.white..opacity}
		npcutils.hideNPC(v)
	end

end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
    local data = v.data
    if v.id ~= npcID then return end
	eventObj.cancelled = true

    if culprit then
        if (reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP) and type(culprit) == "Player" and not (data.state == STATE_HURT or data.state == STATE_IDLE or data.state == STATE_CATCH or data.state == STATE_RUN1 or data.state == STATE_RUN2 or data.state == STATE_RUN3 or data.state == STATE_JUMP1 or data.state == STATE_JUMP2 or data.state == STATE_JUMP3 or data.state == STATE_HOP1 or data.state == STATE_HOP2 or data.state == STATE_HOP3) and data.timer > 28 then
			data.health = data.health - 1
			data.state = STATE_HURT
			data.timer = 0
			SFX.play("Krusha Die.wav")
			SFX.play("Enemy hit.mp3")
			culprit.speedX = math.sign((culprit.x+(culprit.width/2))-(v.x+(v.width/2)))*4.5

			if data.health == 3 then
				data.state = STATE_FAKEOUT
				data.timer = 0
				SFX.play("Krusha Die.wav")
				SFX.play("Enemy hit.mp3")
				culprit.speedX = math.sign((culprit.x+(culprit.width/2))-(v.x+(v.width/2)))*4.5
			end

			if data.health == 0 then
				data.state = STATE_DEFEAT
				data.timer = 0
				SFX.play("Krusha Die.wav")
				SFX.play("Enemy hit.mp3")
				culprit.speedX = math.sign((culprit.x+(culprit.width/2))-(v.x+(v.width/2)))*4.5
			end
		else
			player:harm()
		end
    end
end

return sampleNPC