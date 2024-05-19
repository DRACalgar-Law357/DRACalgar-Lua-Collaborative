--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 32,
	gfxheight = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 1,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	foreground = false, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- LOGIC
	--Movement speed. Only affects speedX by default.
	speed = 1,
	luahandlesspeed = false, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = false,
	cliffturn = false, -- Makes the NPC turn on ledges
	staticdirection = false, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = false, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = false, -- The player can walk on the NPC.

	nohurt=false, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= false, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC


	score = 1, -- Score granted when killed
	--  1 = 10,    2 = 100,    3 = 200,  4 = 400,  5 = 800,
	--  6 = 1000,  7 = 2000,   8 = 4000, 9 = 8000, 10 = 1up,
	-- 11 = 2up,  12 = 3up,  13+ = 5-up, 0 = 0

	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	nowalldeath = true, -- If true, the NPC will not die when released in a wall

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	--Define custom properties below
	fallNoClipDuration = 48,
	bouncesBeforeFall = 4,
	stayInPlaceInstances = 4,
	harmNPCs = false,
}


--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

--Custom local definitions below

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

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		v.ai1 = v.ai1 or 0 --consecutive bounces
		v.ai2 = v.ai2 or 0 --timer
		v.ai3 = v.ai3 or 0 --overall consecutive
		v.ticking = v.ticking or false
	end

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		-- Handling of those special states. Most NPCs want to not execute their main code when held/coming out of a block/etc.
		-- If that applies to your NPC, simply return here.
		-- return
	end
	
	--Text.print(v.ai2,110,110)
	--Text.print(v.ai3,110,126)
	--Text.print(v.ai1,110,142)
	--Text.print(v.noblockcollision,110,158)
	-- Put main AI below here
	if v.ticking == true then v.ai2 = v.ai2 + 1 end
	if v.ai4 == 0 then v.ai4 = RNG.irandomEntry{-2,2} end
	
	data.rotation = ((data.rotation or 0) + math.deg(v.ai4/((v.width+v.height)/4)))
	if v.ai1 >= sampleNPCSettings.bouncesBeforeFall and v.ai3 < sampleNPCSettings.stayInPlaceInstances then
		if v.ai2 < sampleNPCSettings.fallNoClipDuration then
			v.noblockcollision = true
		else
			v.noblockcollision = false
			v.ai1 = 0
		end
	end
	if v.ai3 < sampleNPCSettings.stayInPlaceInstances then
		if v.collidesBlockBottom then
			npcutils.faceNearestPlayer(v)
			v.speedX = RNG.random(0.2,2) * v.direction
			v.speedY = -4
			SFX.play(3)
			v.ai1 = v.ai1 + 1
			if v.ai1 >= sampleNPCSettings.bouncesBeforeFall then
				v.ai3 = v.ai3 + 1
				v.ai2 = 0
				if not v.ticking then v.ticking = true end
			end
			if sampleNPCSettings.harmNPCs then
				for _,n in ipairs(NPC.getIntersecting(v.x - 5, v.y - 5, v.x + v.width + 5, v.y + v.height + 5)) do
					if Colliders.collide(n,v) and not NPC.config[n.id].hp and not NPC.config[n.id].isCoin and not NPC.config[n.id].isInteractable and NPC.HITTABLE_MAP[n.id] and n.idx ~= v.idx then
						n:harm(HARM_TYPE_NPC)
					end
				end
			end
		end
	else
		v.noblockcollision = true
	end
end

function sampleNPC.onDrawNPC(v)
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
return sampleNPC