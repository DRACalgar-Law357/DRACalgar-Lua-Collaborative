local npcManager = require("npcManager")
local effectconfig = require("game/effectconfig")
local npcutils = require("npcs/npcutils")
local kuroku = {}
local npcID = NPC_ID

local STATE = {
	IDLE = 0,
	RUN = 1,
	THROW = 2,
	FURIOUS1 = 3,
	FURIOUS2 = 4,
	HURT = 5,
	KILL = 6,
}

local maxHP = 3

local deathEffectID = (npcID)
--[[
	throwTable is a config where Kuroku throws specified NPCs and uses sets of ways to throw them
	-throwSet: 0 thrown at a set speed, 1 thrown velocity is determined by user's position and modifies horizontal speed for this while using a set speedY, 2 thrown velocity is determined by user's position and uses vertical speed for this while using the set speedX, 3 uses an rng range for speedX and speedY
	-throwSpeedX and throwSpeedY: pretty self explanatory except throwSpeedY goes upper if positive value is inputed
	-id: throws that NPC with the id
	-throwSFX and pickupSFX: plays a sfx if thrown and plays a sfx when displaying an animation before throwing
	-availableHP: uses these values to compare with his HP to use it or not at these moments
	-throwSpeedRestrictRate: restricts the vector speed; intended to be optimal; used for throwSet 1 and 2
	-throwSpeedXMin, throwSpeedXMax, throwSpeedYMin, throwSpeedYMax: used for throwSet 3 that uses RNG.random to determine their velocity
]]
local throwTable = {
	[1] = {
		index = 1,
		id = 889,
		delay = 45,
		throwSet = 3,
		throwSpeedXMin = -6,
		throwSpeedXMax = 6,
		throwSpeedYMin = 4,
		throwSpeedYMax = 6,
		throwSFX = 25,
		pickupSFX= 73,
		availableHPMin = 0,
		availableHPMax = 3,
		cooldown = {min = 50, max = 70},
		getThrown = false,
	},
	[2] = {
		index = 2,
		id = 890,
		delay = 60,
		throwSet = 3,
		throwSpeedXMin = -5,
		throwSpeedXMax = 5,
		throwSpeedYMin = 5,
		throwSpeedYMax = 7,
		throwSFX = 25,
		pickupSFX= 73,
		availableHPMin = 0,
		availableHPMax = 3,
		cooldown = {min = 90, max = 110},
		getThrown = false,
	},
	[3] = {
		index = 3,
		id = 891,
		delay = 40,
		throwSet = 1,
		throwSpeedY = 6,
		throwSpeedRestrictRate = 60,
		speedLimitMin = 0,
		speedLimitMax = 9,
		throwSFX = 25,
		pickupSFX= 73,
		availableHPMin = 0,
		availableHPMax = 3,
		cooldown = {min = 40, max = 60},
		getThrown = false,
	},
	[4] = {
		index = 4,
		id = 134,
		delay = 40,
		throwSet = 3,
		throwSpeedXMin = -6,
		throwSpeedXMax = 6,
		throwSpeedYMin = 4,
		throwSpeedYMax = 6,
		throwSFX = 25,
		pickupSFX= 73,
		availableHPMin = 2,
		availableHPMax = 3,
		cooldown = {min = 40, max = 60},
		getThrown = false,
	},
}

local kurokuSettings = {
	id = npcID,
	
	gfxwidth = 96,
	gfxheight = 80,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	width = 48,
	height = 48,
	
	frames = 20,
	
	framestyle = 0,

	speed = 1,
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	staticdirection = true,

	frameStates = {
		[0] = {
			frames = {0},
			framespeed = 8,
			loopFrames = false,
		},
		[1] = {
			frames = {1,2,3,4},
			framespeed = 8,
			loopFrames = true,
		},
		[2] = {
			frames = {5},
			framespeed = 8,
			loopFrames = false,
		},
		[3] = {
			frames = {6,7,8,9},
			framespeed = 8,
			loopFrames = true,
		},
		[4] = {
			frames = {10,11,12},
			framespeed = 6,
			loopFrames = false,
		},
		[5] = {
			frames = {13,14,15,16},
			framespeed = 6,
			loopFrames = true,
		},
		[6] = {
			frames = {17,18},
			framespeed = 6,
			loopFrames = true,
		},
		[7] = {
			frames = {19},
			framespeed = 8,
			loopFrames = false,
		},
	},
	flipSpriteWhenFacingDirection = true, --flips the sprite by a scale
	priority = -45,
	spriteoffsetx = 0,
	spriteoffsety = -10,
}

npcManager.setNpcSettings(kurokuSettings)
npcManager.registerDefines(npcID, {NPC.HITTABLE})
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD,
	},
	{
		[HARM_TYPE_JUMP]=deathEffectID,
		--[HARM_TYPE_FROMBELOW]=deathEffectID,
		[HARM_TYPE_NPC]=deathEffectID,
		[HARM_TYPE_PROJECTILE_USED]=deathEffectID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=deathEffectID,
		--[HARM_TYPE_TAIL]=deathEffectID,
		--[HARM_TYPE_SPINJUMP]=10,
	}
)

function kuroku.onInitAPI()
	npcManager.registerEvent(npcID,kuroku,"onTickEndNPC")
	npcManager.registerEvent(npcID,kuroku,"onDrawNPC")
	registerEvent(kuroku, "onNPCHarm")
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

local function decideThrowNPC(v,data,config,settings)
	local options = {}
	if throwTable and #throwTable > 0 then
		for i in ipairs(throwTable) do
			if data.health >= throwTable[i].availableHPMin and data.health <= throwTable[i].availableHPMax then
				table.insert(options,throwTable[i].index)
			end
		end
	end
	if #options > 0 then
		data.throwIndex = RNG.irandomEntry(options)
		data.throwing = true
		data.throwCooldown = RNG.randomInt(throwTable[data.throwIndex].cooldown.min,throwTable[data.throwIndex].cooldown.max)
	end
	data.throwTimer = 0
end

-- This function is just to fix   r e d i g i t   issues lol
local function gfxSize(config)
	local gfxwidth  = config.gfxwidth
	if gfxwidth  == 0 then gfxwidth  = config.width  end
	local gfxheight = config.gfxheight
	if gfxheight == 0 then gfxheight = config.height end

	return gfxwidth, gfxheight
end

local function drawBall(data,id,x,y,frame,priority,rotation)
	local config = NPC.config[id]
	local gfxwidth,gfxheight = gfxSize(config)

	if data.ballSprite == nil then
		local texture = Graphics.sprites.npc[id].img

		data.ballSprite = Sprite{texture = texture,frames = texture.height/gfxheight,pivot = Sprite.align.CENTRE}
	end

	data.ballSprite.x = x
	data.ballSprite.y = y
	data.ballSprite.rotation = rotation or 0

	data.ballSprite:draw{frame = frame+1,priority = priority,sceneCoords = true}
end
kuroku.drawBall = drawBall

function kuroku.onNPCHarm(e, v, o, c)
	if v.id ~= NPC_ID then return end
	local data = v.data
	local config = NPC.config[v.id]
	if v:mem(0x156, FIELD_WORD) <= 0 then
		if o == HARM_TYPE_JUMP or o == HARM_TYPE_SPINJUMP or o == HARM_TYPE_SWORD or o == HARM_TYPE_FROMBELOW or (type(c) == "NPC" and c.id ~= 13) then
			data.health = (data.health or maxHP) - 1
	    elseif type(c) == "NPC" and c.id == 13 then
            data.health = (data.health or maxHP) - 1
        else
            data.health = (data.health or maxHP) - 1
		end
		if o ~= HARM_TYPE_JUMP and o ~= HARM_TYPE_SPINJUMP then
			if c then
				Animation.spawn(75, c.x+c.width/2-16, c.y+c.width/2-16)
			end
        end
        if data.health > 0 then
			e.cancelled = true
			data.timer = 0
			if o == HARM_TYPE_JUMP or o == HARM_TYPE_SPINJUMP then
				SFX.play(2)
				v:mem(0x156, FIELD_WORD,25)
			elseif o == HARM_TYPE_SWORD then
				SFX.play(Misc.resolveSoundFile("zelda-hit"))
			    v:mem(0x156, FIELD_WORD,15)
			else
			    if type(c) == "NPC" and c.id == 13 then
				    SFX.play(9)
				    v:mem(0x156, FIELD_WORD,10)
				else
			        SFX.play(39)
					v:mem(0x156, FIELD_WORD,25)
			    end
			end
		end
	else
		e.cancelled = true
	end
	if c and type(c) == "NPC" and (NPC.HITTABLE_MAP[c.id] or c.id == 45) and c.id ~= 50 and v:mem(0x138, FIELD_WORD) == 0 then
		c:kill(HARM_TYPE_NPC)
	end
end

function kuroku.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.state = nil
		data.timer = nil
		data.animationBall = nil
		data.frameTimer = 0
		return
	end

	local config = NPC.config[v.id]
	if not data.state then
		data.state = STATE.RUN
		data.timer = 0
		data.animationBall = nil

		--Handling sprites
		data.img = data.img or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = config.frames, texture = Graphics.sprites.npc[v.id].img}
		data.angle = 0
		data.sprSizex = 1
		data.sprSizey = 1

		--Handling animations
		data.currentFrame = 0
		data.currentFrameTimer = 0
		data.frameCounter = 1
		data.frameTimer = 0
		data.animateState = 0

		data.throwing = false
		data.throwIndex = 0
		data.throwTimer = 0
		data.throwCooldown = RNG.randomInt(120,210)

		data.health = maxHP
	end

	--Handling frames (animation code by Murphmario)

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

	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE.IDLE
		data.timer = 0
		data.animationBall = nil
		return
	end
	data.timer = data.timer + 1
	if data.state == STATE.IDLE or data.state == STATE.RUN then
		if data.throwing == true then
			
		else
			data.throwTimer = data.throwTimer + 1
			if data.throwTimer >= data.throwCooldown then
				decideThrowNPC(v,data,config,settings)
				-- Play pickup sound effect
				if throwTable[data.throwIndex].pickupSFX then
					SFX.play(throwTable[data.throwIndex].pickupSFX)
				end
			end
		end
	end
	if data.state == STATE.IDLE then
		v.speedX = 0
		if data.animateState ~= 0 and data.throwing == false then
			data.animateState = 0
			data.currentFrame = config.frameStates[data.animateState].frames[0]
			data.currentFrameTimer = 0
			data.frameCounter = 1
			data.frameTimer = 0
		elseif data.animateState ~= 2 and data.throwing == true then
			data.animateState = 2
			data.currentFrame = config.frameStates[data.animateState].frames[0]
			data.currentFrameTimer = 0
			data.frameCounter = 1
			data.frameTimer = 0
		end
	elseif data.state == STATE.RUN then
		v.speedX = 2 * v.direction
		if data.animateState ~= 1 and data.throwing == false then
			data.animateState = 1
			data.currentFrame = config.frameStates[data.animateState].frames[0]
			data.currentFrameTimer = 0
			data.frameCounter = 1
			data.frameTimer = 0
		elseif data.animateState ~= 3 and data.throwing == true then
			data.animateState = 3
			data.currentFrame = config.frameStates[data.animateState].frames[0]
			data.currentFrameTimer = 0
			data.frameCounter = 1
			data.frameTimer = 0
		end
		if isNearPit(v) and v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockRight then
			v.direction = -v.direction
		end
	end

	if data.throwing then
		if not data.animationBall then
			local goalY = -v.height - NPC.config[throwTable[data.throwIndex].id].height/2
			local t = 24

			local speedY = (goalY / t) - (Defines.npc_grav * t) / 2

			data.animationBall = {yOffset = 0,speedY = speedY}
		end


		local b = data.animationBall

		b.speedY = b.speedY + Defines.npc_grav
		if b.speedY > 8 then
			b.speedY = 8
		end
		b.yOffset = b.yOffset + b.speedY

		if b.speedY >= 0 and b.yOffset >= -v.height then
			b.yOffset = -v.height
			b.speedY = 0
			data.throwTimer = data.throwTimer + 1
			if data.throwTimer >= throwTable[data.throwIndex].delay then
				data.throwing = false
				data.throwTimer = 0
				local s = NPC.spawn(
					throwTable[data.throwIndex].id,
					v.x + (v.width  / 2),
					v.y - (NPC.config[throwTable[data.throwIndex].id].height / 2) + v.speedY,
					v:mem(0x146,FIELD_WORD),
					false,true
				)
				
				s.direction = v.direction
				if throwTable[data.throwIndex].throwSet == 0 then
					s.speedX = (throwTable[data.throwIndex].throwSpeedX) * v.direction
					s.speedY = -(throwTable[data.throwIndex].throwSpeedY)
				elseif throwTable[data.throwIndex].throwSet == 1 then
					npcutils.faceNearestPlayer(s)
					local throwxspeed = vector.v2(Player.getNearest(v.x + v.width/2, v.y + v.height).x + 0.5 * Player.getNearest(v.x + v.width/2, v.y + v.height).width - (v.x + 0.5 * v.width))
					s.speedX = math.clamp(math.abs(throwxspeed.x / throwTable[data.throwIndex].throwSpeedRestrictRate), throwTable[data.throwIndex].speedLimitMin, throwTable[data.throwIndex].speedLimitMax) * s.direction
					s.speedY = -(throwTable[data.throwIndex].throwSpeedY)
				elseif throwTable[data.throwIndex].throwSet == 2 then
					local throwyspeed = vector.v2(Player.getNearest(v.x + v.width/2, v.y + v.height).y + 0.5 * Player.getNearest(v.x + v.width/2, v.y + v.height).height - (v.y + 0.5 * v.height))
					s.speedY = math.clamp(throwyspeed.y / throwTable[data.throwIndex].throwSpeedRestrictRate, throwTable[data.throwIndex].speedLimitMin, throwTable[data.throwIndex].speedLimitMax)
					s.speedX = (throwTable[data.throwIndex].throwSpeedX) * v.direction
				elseif throwTable[data.throwIndex].throwSet == 3 then
					s.speedX = RNG.random(throwTable[data.throwIndex].throwSpeedXMin,throwTable[data.throwIndex].throwSpeedXMax) * v.direction
					s.speedY = -(throwTable[data.throwIndex].throwSpeedYMin)
				end
				s.data.rotation = 0
				s.data.bounced = false
				s.friendly = v.friendly
				if throwTable[data.throwIndex].getThrown == true then s:mem(0x136, FIELD_BOOL,true) end
				data.animationBall = nil -- Remove animation version of ball
				data.ballSprite = nil

				-- Play throw sound effect
				if throwTable[data.throwIndex].throwSFX then
					SFX.play(throwTable[data.throwIndex].throwSFX)
				end
			end
		end
	end

	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = config.frames
		});
	end

	--Prevent Kuroku from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
end

function kuroku.onDrawNPC(v)
	if v:mem(0x12A, FIELD_WORD) <= 0 then return end

	local data = v.data
	local config = NPC.config[v.id]
	local b = data.animationBall

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

	--[[if data.iFrames then
		opacity = math.sin(lunatime.tick()*math.pi*0.25)*0.75 + 0.9
	end]]

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

	if not b then return end

	local bconfig = NPC.config[throwTable[data.throwIndex].id]

	local gfxwidth,gfxheight = gfxSize(bconfig)

	local priority
	if bconfig.priority then
		priority = -16
	else
		priority = -46
	end

	local frame = 0
	if v.direction == DIR_RIGHT and bconfig.framestyle >= 1 then
		frame = bconfig.frames
	end

	drawBall(
		data,
		throwTable[data.throwIndex].id,
		(v.x + (v.width / 2)) + bconfig.gfxoffsetx,
		(v.y + v.height) - (gfxheight/2) + b.yOffset + bconfig.gfxoffsety,
		frame,priority,0
	)
end

return kuroku