local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}
local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxwidth = 12,
	gfxheight = 12,

	width = 12,
	height = 12,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 4,
	framestyle = 1,
	framespeed = 5,

	foreground = false,

	speed = 1,
	luahandlesspeed = false,
	nowaterphysics = false,
	cliffturn = false,
	staticdirection = true,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,

	score = 0,

	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	nowalldeath = false,

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,
	riseheight = 128,
	trajectorywidth = 48,
	fallheight = 68,
}

npcManager.setNpcSettings(sampleNPCSettings)

npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
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



function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

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

	sprite.pivot = args.pivot or Sprite.align.CENTER
	sprite.rotation = args.rotation or 0

	if args.texture ~= nil then
		sprite.texpivot = args.texpivot or sprite.pivot or Sprite.align.CENTER
		sprite.texscale = args.texscale or vector(args.texture.width*(args.width/args.sourceWidth),args.texture.height*(args.height/args.sourceHeight))
		sprite.texposition = args.texposition or vector(-args.sourceX*(args.width/args.sourceWidth)+((sprite.texpivot[1]*sprite.width)*((sprite.texture.width/args.sourceWidth)-1)),-args.sourceY*(args.height/args.sourceHeight)+((sprite.texpivot[2]*sprite.height)*((sprite.texture.height/args.sourceHeight)-1)))
	end

	sprite:draw{priority = args.priority,color = args.color,sceneCoords = args.sceneCoords or args.scene}
end

local v_SPEED = 6
local speedTotal = sampleNPCSettings.speed * v_SPEED

-- Called when first spawned or respawned (i.e., ai1 is 0).  Initializes all of the hook's relevant parameters (no data is used here, due to the
-- small number of necessary parameters).
local function initialize(v)
	local data = v.data
	-- Set the flag that the hook has been initialized
	v.ai1 = 1

	-- The current "state" of the hook's pseudo-elliptical path.
	-- 0: Not initialized.
	-- 1: Initial curve upward.
	-- 2: Horizontal movement away from the bro.
	-- 3: Curving back, first half.
	-- 4: Curving back, second half.
	-- 5: Horizontal movement back toward the bro.
	data.state = 1

	-- The timer for each phase of the hook path.  Once it reaches zero, the hook goes to the next state.
	data.timer = math.floor(math.pi * sampleNPCSettings.riseheight / (0.8 * speedTotal))
	data.killTimer = data.killTimer or 0

	-- Owner is assumed to be set to the NPC which spawned the hook
	-- to be able to detect whether the hook intersects with the original thrower while in state 5, and delete it if that's the case.
	-- data.ownerBro = nil
end

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
end

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.ai1 == 0 then
		initialize(v)
	elseif data.state == 1 then
		-- The hook is rising upward.  Adjust the speeds so that the hook follows a quarter circle path upward with speed
		-- v_SPEED.

		v.speedX = v.direction * speedTotal

		if data.timer > 0 then
			data.timer = data.timer - 1
		else
			data.state = 2
			data.timer = math.floor(sampleNPCSettings.trajectorywidth / speedTotal)
		end
	elseif data.state == 2 then
		-- The hook is moving away, following a horizontal path.

		v.speedX = v.direction * speedTotal

		if data.timer > 0 then
			data.timer = data.timer - 1
		else
			data.state = 3
			data.timer = math.floor(math.pi * sampleNPCSettings.fallheight / (2 * speedTotal))
		end
	elseif data.state == 3 then
		-- The hook is following the top half of a half-circle path to turn back.

		v.speedX = v.direction * speedTotal * math.sin(speedTotal * data.timer / sampleNPCSettings.fallheight)

		if data.timer > 0 then
			data.timer = data.timer - 1
		else
			data.state = 4
			data.timer = math.floor(math.pi * sampleNPCSettings.fallheight / (2 * speedTotal))

			-- Turn the hook around.

			v.direction = -v.direction
		end
	elseif data.state == 4 then
		-- The hook is following the bottom half of a half-circle path to turn back.

		v.speedX = v.direction * speedTotal * math.cos(speedTotal * data.timer / sampleNPCSettings.fallheight)

		if data.timer > 0 then
			data.timer = data.timer - 1
		else
			data.state = 5
		end
	else
		-- The hook is following a horizontal path back in the direction it initially came.

		v.speedX = v.direction * speedTotal
	end

	v.ai2 = v.ai2 + 1
	if v.ai2 % 16 == 0 then
		SFX.play("Wing flap.wav")
	end

	if data.state < 4 then
		if Colliders.collide(Player.getNearest(v.x,v.y),v) then
			data.state = 5
			v.direction = -v.direction
		end
	end
end

return sampleNPC