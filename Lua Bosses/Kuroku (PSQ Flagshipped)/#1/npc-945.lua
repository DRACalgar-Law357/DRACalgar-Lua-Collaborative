local npcManager = require("npcManager")
local effectconfig = require("game/effectconfig")
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
		id = 1,
		throwSet = 0
		throwSpeedX = 4,
		throwSpeedY = 4
		throwSFX = 25,
		pickupSFX= 18,
		availableHPMin = 0,
		availableHPMax = 3,
	},
	[2] = {
		id = 2,
		throwSet = 1,
		throwSpeedY = 7
		throwSpeedRestrictRate = 7.5,
		availableHPMin = 0,
		availableHPMax = 3,
	},
	[3] = {
		id = 3,
		throwSet = 2,

		availableHPMin = 0,
		availableHPMax = 3,
	},
},

local attackTable = {

}

local kurokuSettings = {
	id = npcID,
	
	gfxwidth = 64,
	gfxheight = 64,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	width = 48,
	height = 48,
	
	frames = 8,
	idleFrames = 1,
	idleFramespeed = 8,
	framestyle = 1,

	speed = 1,
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	idleTime = 96, -- How long the NPC is idle before spawning a ball.
	holdTime = 32, -- How long the ball NPC is held before throwing it.

	throwSFX = 25, -- Sound effect to be played after throwing the thrown NPC.
}

npcManager.setNpcSettings(kurokuSettings)
npcManager.registerDefines(npcID, {NPC.HITTABLE})
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD,
	},
	{
		[HARM_TYPE_JUMP]=deathEffectID,
		[HARM_TYPE_FROMBELOW]=deathEffectID,
		[HARM_TYPE_NPC]=deathEffectID,
		[HARM_TYPE_PROJECTILE_USED]=deathEffectID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=deathEffectID,
		[HARM_TYPE_TAIL]=deathEffectID,
		[HARM_TYPE_SPINJUMP]=10,
	}
)

local STATE_STANDING = 0
local STATE_THROWING = 1
function kuroku.onInitAPI()
	npcManager.registerEvent(npcID,kuroku,"onTickEndNPC")
	npcManager.registerEvent(npcID,kuroku,"onDrawNPC")
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

function effectconfig.onTick.TICK_KUROKU(v) -- Logic for Kuroku death effects
    v.animationFrame = math.min(v.frames-1,math.floor((v.lifetime-v.timer)/v.framespeed))
end

function kuroku.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.state = nil
		data.timer = nil
		data.animationBall = nil
		return
	end

	local config = NPC.config[v.id]
	local frames = (config.idleFrames + 2)
	if not data.state then
		data.state = STATE_STANDING
		data.timer = 0
		data.animationBall = nil

		data.throwID = v.ai1
		if data.throwID == 0 then
			data.throwID = config.throwID
		end
	end

	-- Animation
	if data.state == STATE_STANDING	then
		if data.timer >= 0 then
			v.animationFrame = math.floor(data.timer / config.idleFramespeed) % config.idleFrames
		else
			v.animationFrame = config.idleFrames + 1
		end
	elseif data.state == STATE_THROWING then
		local b = data.animationBall
		if b and b.speedY >= 0 and b.yOffset >= -v.height then
			v.animationFrame = config.idleFrames
		elseif b and b.speedY < 0 then
			v.animationFrame = config.idleFrames
		else
			v.animationFrame = config.idleFrames
		end
	end
	if config.framestyle >= 1 and v.direction == DIR_RIGHT then
		v.animationFrame = v.animationFrame + frames
	end
	if config.framestyle >= 2 and (v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL)) then
		v.animationFrame = v.animationFrame + frames
		if v.direction == DIR_RIGHT then
			v.animationFrame = v.animationFrame + frames
		end
	end

	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_STANDING
		data.timer = 0
		data.animationBall = nil
		return
	end

	if data.state == STATE_STANDING then
		data.timer = data.timer + 1

		if data.timer > config.idleTime then
			data.state = STATE_THROWING
			data.timer = 0
		end
	elseif data.state == STATE_THROWING then
		if not data.animationBall then
			local goalY = -v.height - NPC.config[config.throwID].height/2
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
			data.timer = data.timer + 1
			if data.timer >= config.holdTime then
				data.state = STATE_STANDING
				data.timer = -32
				local s = NPC.spawn(
					data.throwID,
					v.x + (v.width  / 2),
					v.y - (NPC.config[data.throwID].height / 2) + v.speedY,
					v:mem(0x146,FIELD_WORD),
					false,true
				)
				
				s.direction = v.direction
				s.speedX = (config.throwXSpeed) * v.direction
				s.speedY = -(config.throwYSpeed)
				s.data.rotation = 0
				s.data.bounced = false
				s.friendly = v.friendly
				s:mem(0x136, FIELD_BOOL,true)
				data.animationBall = nil -- Remove animation version of ball

				-- Play throw sound effect
				if config.throwSFX then
					SFX.play(config.throwSFX)
				end
			end
		end
	end
end

function kuroku.onDrawNPC(v)
	if v:mem(0x12A, FIELD_WORD) <= 0 then return end

	local data = v.data
	local b = data.animationBall

	if not b then return end

	local config = NPC.config[v.id]
	local bconfig = NPC.config[data.throwID]

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
		data.throwID,
		(v.x + (v.width / 2)) + bconfig.gfxoffsetx,
		(v.y + v.height) - (gfxheight/2) + b.yOffset + bconfig.gfxoffsety,
		frame,priority,0
	)
end

return kuroku