--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
--Create the library table
local actor = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local actorSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 64,
	gfxheight = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 13,
	framestyle = 0,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	foreground = false, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- LOGIC
	--Movement speed. Only affects speedX by default.
	speed = 1,
	luahandlesspeed = true, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = false,
	cliffturn = false, -- Makes the NPC turn on ledges
	staticdirection = false, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = false, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = false, -- The player can walk on the NPC.

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	notcointransformable = true, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	ignorethrownnpcs = true,

	score = 0, -- Score granted when killed
	--  1 = 10,    2 = 100,    3 = 200,  4 = 400,  5 = 800,
	--  6 = 1000,  7 = 2000,   8 = 4000, 9 = 8000, 10 = 1up,
	-- 11 = 2up,  12 = 3up,  13+ = 5-up, 0 = 0

	--Various interactions
	jumphurt = false, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	nowalldeath = false, -- If true, the NPC will not die when released in a wall

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	isinteractable = true,

	--Define custom properties below
	--The frameStates is a main staple of the actor NPC. It runs through frames over configurations and can be looped. The states will also specify behaviorStates to apply an action to them such as idle or walking.
	frameStates = {
		[0] = {
			frames = {0},
			framespeed = 8,
			loopFrames = false,
			behaviorState = 0,
		},
		[1] = {
			frames = {1},
			framespeed = 8,
			loopFrames = false,
			behaviorState = 0,
		},
		[2] = {
			frames = {2},
			framespeed = 8,
			loopFrames = false,
			behaviorState = 0,
		},
		[3] = {
			frames = {6,3,4,3},
			framespeed = 8,
			loopFrames = true,
			behaviorState = 0,
		},
		[4] = {
			frames = {7,8,9,10},
			framespeed = 6,
			loopFrames = true,
			behaviorState = 1,
		},
		[5] = {
			frames = {5},
			framespeed = 8,
			loopFrames = false,
			behaviorState = 0,
		},
		[6] = {
			frames = {11},
			framespeed = 8,
			loopFrames = false,
			behaviorState = 0,
		},
		[7] = {
			frames = {12},
			framespeed = 8,
			loopFrames = false,
			behaviorState = 0,
		},
	},
	flipSpriteWhenFacingDirection = true, --flips the sprite by a scale
	priority = -55,
	--Here ends the main staples of the actor NPC

	--Other configs
	forwardMouthX = {
		[-1] = -6,
		[1] = 6,
	},
	forwardMouthY = -4,
}

--Applies NPC settings
npcManager.setNpcSettings(actorSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})
--Custom local definitions below

--Handles changing states
local function changeState(v,data,settings,config,state)
	data.timer = 0
	data.frameTimer = 0
	data.state = state
	data.currentFrameTimer = 0
	data.frameTimer = 0
	data.frameCounter = 1
end
--Register events
function actor.onInitAPI()
	npcManager.registerEvent(npcID, actor, "onTickEndNPC")
	npcManager.registerEvent(npcID, actor, "onDrawNPC")
end

function actor.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.state = 0
		data.timer = 0
		data.frameTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		--The main staples of an actor
		data.state = settings.animateState
		data.timer = 0
		data.frameTimer = 0

		--Handling sprites
		data.img = data.img or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = actorSettings.frames, texture = Graphics.sprites.npc[v.id].img}
		data.angle = 0
		data.sprSizex = 1
		data.sprSizey = 1

		--Handling animations
		data.currentFrame = 0
		data.currentFrameTimer = 0
		data.frameCounter = 1
		data.frameTimer = 0
		--Ends the main staples of an actor
		data.drawForwardMouth = false
		data.forwardMouth = data.forwardMouth or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = 4, texture = Graphics.loadImageResolved("doccroctalkfront.png")}
		data.forwardMouthFrame = 1
	end

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		data.state = 0
		data.timer = 0
		data.frameTimer = 0
		return
	end
	
	v.friendly = true
	--Timer stuff
	data.timer = data.timer + 1
	--Behavior stuff
	--Behavior State 0 and 1 are default states in which are used in generality
	if config.frameStates[data.state].behaviorState == 0 then
		v.speedX = 0
	elseif config.frameStates[data.state].behaviorState == 1 then
		v.speedX = 2 * v.direction
		if v.collidesBlockLeft and v.direction == -1 or v.collidesBlockRight and v.direction == 1 then
			v.direction = -v.direction
		end
	end
	--Handling frames (animation code by Murphmario)

	data.currentFrame = config.frameStates[data.state].frames[data.frameCounter]
	data.currentFrameTimer = config.frameStates[data.state].framespeed
	data.frameTimer = data.frameTimer - data.currentFrameTimer

	v.animationFrame = data.currentFrame
	
	if data.frameTimer <= 0 then
		data.frameTimer = 60
		if data.frameCounter < #config.frameStates[data.state].frames then
			data.frameCounter = data.frameCounter + 1
		else
			data.currentFrameTimer = 0
			data.frameTimer = 0
			data.frameCounter = 1
		end
	end
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = actorSettings.frames
		});
	end
	if config.frameStates[data.state] ~= 2 and config.frameStates[data.state] ~= 6 and config.frameStates[data.state] ~= 7 and settings.talk then
		data.drawForwardMouth = true
	else

	end
	--Prevent actor from turning around when it hits NPCs because they make it get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
end
function actor.onDrawNPC(v)
	local data = v.data
	local settings = v.data._settings
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

	--[[if data.iFrames then
		opacity = math.sin(lunatime.tick()*math.pi*0.25)*0.75 + 0.9
	end]]

	if data.img then
		-- Setting some properties --
		data.img.x, data.img.y = v.x + 0.5 * v.width + config.gfxoffsetx, v.y + 0.5 * v.height --[[+ config.gfxoffsety]]
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
	if data.forwardMouth then
		data.forwardMouth.x, data.forwardMouth.y = v.x + 0.5 * v.width + config.gfxoffsetx + config.forwardMouthX[v.direction], v.y + 0.5 * v.height + config.forwardMouthY --[[+ config.gfxoffsety]]
		data.forwardMouth.transform.scale = vector(data.sprSizex * -v.direction, data.sprSizey)
		local p = config.priority + 0.01
		data.forwardMouthFrame = math.floor(data.timer / 8) % 4 + 1
		if data.drawForwardMouth == true then
			data.forwardMouth:draw{frame = data.forwardMouthFrame, sceneCoords = true, priority = p, color = Color.white..1}
		end
	end
end
--Gotta return the library table!
return actor