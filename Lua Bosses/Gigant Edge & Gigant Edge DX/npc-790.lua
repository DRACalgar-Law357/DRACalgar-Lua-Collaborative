--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local colliders = require("colliders")
local npcutils = require("npcs/npcutils")
local sprite

--*******************************************************
--Code by Minus and Saturn Yoshi - Taken from npc-615.lua
--*******************************************************


--Create the library table
local sworderang = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sworderangSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 48,
	gfxwidth = 92,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 40,
	height = 40,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 4,
	--Frameloop-related
	frames = 1,
	framestyle = 1,
	framespeed = 4, --# frames between frame change
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
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	riseheight = 96,
	trajectorywidth = 192,
	fallheight = 56
}

--Applies NPC settings
npcManager.setNpcSettings(sworderangSettings)

--Custom local definitions below

local v_SPEED = 6
local speedTotal = sworderangSettings.speed * v_SPEED

-- Called when first spawned or respawned (i.e., ai1 is 0).  Initializes all of the sworderang's relevant parameters (no data is used here, due to the
-- small number of necessary parameters).
local function initialize(v)
	local data = v.data
	-- Set the flag that the sworderang has been initialized
	v.ai1 = 1

	-- The current "state" of the sworderang's pseudo-elliptical path.
	-- 0: Not initialized.
	-- 1: Initial curve upward.
	-- 2: Horizontal movement away from the bro.
	-- 3: Curving back, first half.
	-- 4: Curving back, second half.
	-- 5: Horizontal movement back toward the bro.
	data.state = 1

	-- The timer for each phase of the sworderang path.  Once it reaches zero, the sworderang goes to the next state.
	data.timer = math.floor(math.pi * sworderangSettings.riseheight / (2 * speedTotal))
	data.killTimer = data.killTimer or 0

	-- Owner is assumed to be set to the NPC which spawned the sworderang
	-- to be able to detect whether the sworderang intersects with the original thrower while in state 5, and delete it if that's the case.
	-- data.ownerBro = nil
end

--Register events
function sworderang.onInitAPI()
	npcManager.registerEvent(npcID, sworderang, "onTickNPC")
	npcManager.registerEvent(npcID, sworderang, "onDrawNPC")
end
--[[************************
Rotation code by MrDoubleA
**************************]]

local function drawSprite(args) -- handy function to draw sprites
	args = args or {}

	args.sourceWidth  = args.sourceWidth  or args.width
	args.sourceHeight = args.sourceHeight or args.height

	if sprite == nil then
		sprite = Sprite.box{texture = args.texture}
	else
		sprite.texture = args.texture
	end

	sprite.x,sprite.y = args.x,args.y
	sprite.width,sprite.height = args.width,args.height

	sprite.pivot = args.pivot or Sprite.align.TOPLEFT
	sprite.rotation = args.rotation or 0

	if args.texture ~= nil then
		sprite.texpivot = args.texpivot or sprite.pivot or Sprite.align.TOPLEFT
		sprite.texscale = args.texscale or vector(args.texture.width*(args.width/args.sourceWidth),args.texture.height*(args.height/args.sourceHeight))
		sprite.texposition = args.texposition or vector(-args.sourceX*(args.width/args.sourceWidth)+((sprite.texpivot[1]*sprite.width)*((sprite.texture.width/args.sourceWidth)-1)),-args.sourceY*(args.height/args.sourceHeight)+((sprite.texpivot[2]*sprite.height)*((sprite.texture.height/args.sourceHeight)-1)))
	end

	sprite:draw{priority = args.priority,color = args.color,sceneCoords = args.sceneCoords or args.scene}
end
function sworderang.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	data.rotation = ((data.rotation or 0) + math.deg(2/((v.width+v.height)/8)))
	
	if v.ai1 == 0 then
		initialize(v)
	elseif data.state == 1 then
		-- The sworderang is rising upward.  Adjust the speeds so that the sworderang follows a quarter circle path upward with speed
		-- v_SPEED.

		v.speedX = v.direction * speedTotal * math.cos(speedTotal * data.timer / sworderangSettings.riseheight)
		v.speedY = -speedTotal * math.sin(speedTotal * data.timer / sworderangSettings.riseheight) * 1.5

		if data.timer > 0 then
			data.timer = data.timer - 1
		else
			data.state = 2
			data.timer = math.floor(sworderangSettings.trajectorywidth / speedTotal)
		end
	elseif data.state == 2 then
		-- The sworderang is moving away, following a horizontal path.

		v.speedX = v.direction * speedTotal
		v.speedY = 0

		if data.timer > 0 then
			data.timer = data.timer - 1
		else
			data.state = 3
			data.timer = math.floor(math.pi * sworderangSettings.fallheight / (2 * speedTotal))
		end
	elseif data.state == 3 then
		-- The sworderang is following the top half of a half-circle path to turn back.

		v.speedX = v.direction * speedTotal * math.sin(speedTotal * data.timer / sworderangSettings.fallheight)
		v.speedY = speedTotal * math.cos(speedTotal * data.timer / sworderangSettings.fallheight) * 1.5

		if data.timer > 0 then
			data.timer = data.timer - 1
		else
			data.state = 4
			data.timer = math.floor(math.pi * sworderangSettings.fallheight / (2 * speedTotal))

			-- Turn the sworderang around.

			v.direction = -v.direction
		end
	elseif data.state == 4 then
		-- The sworderang is following the bottom half of a half-circle path to turn back.

		v.speedX = v.direction * speedTotal * math.cos(speedTotal * data.timer / sworderangSettings.fallheight)
		v.speedY = speedTotal * math.sin(speedTotal * data.timer / sworderangSettings.fallheight) * 1.5

		if data.timer > 0 then
			data.timer = data.timer - 1
		else
			data.state = 5
		end
	else
		-- The sworderang is following a horizontal path back in the direction it initially came.

		v.speedX = v.direction * speedTotal
		v.speedY = 0
	end
	if lunatime.tick() % 12 == 0 then
		SFX.play("Sworderang Woosh.ogg")
	end
end
function sworderang.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation or data.rotation == 0 then return end

	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth,height = config.gfxheight,

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = priority,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}

	npcutils.hideNPC(v)
end
--Gotta return the library table!
return sworderang