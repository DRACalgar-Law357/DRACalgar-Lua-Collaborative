--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 68,
	gfxheight = 68,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 2,
	--Frameloop-related
	frames = 4,
	framestyle = 1,
	framespeed = 6, -- number of ticks (in-game frames) between animation frame changes

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

	nohurt=false, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = true,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC

	score = 0, -- Score granted when killed
	--  1 = 10,    2 = 100,    3 = 200,  4 = 400,  5 = 800,
	--  6 = 1000,  7 = 2000,   8 = 4000, 9 = 8000, 10 = 1up,
	-- 11 = 2up,  12 = 3up,  13+ = 5-up, 0 = 0

	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	nowalldeath = false, -- If true, the NPC will not die when released in a wall

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,
	-- Various interactions
	ishot = true,
	durability = -1, -- Durability for elemental interactions like ishot and iscold. -1 = infinite durability

	--Emits light if the Darkness feature is active:
	lightradius = 120,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.white,
	ignorethrownnpcs = true,

	--Define custom properties below
	slowRate = 0.97,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})
--Custom local definitions below


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
		v:kill(9)
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.img = data.img or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = 2, texture = Graphics.loadImageResolved("rainingfireballindicator.png")}
		if v.ai1 == 1 then
			v.ai2 = 130
			v.ai3 = 50
			v.ai4 = 0
		end
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
	if v.ai1 == 1 then v.ai2 = v.ai2 - 1 v.ai3 = v.ai3 - 1 end
	if v.ai3 > 0 and v.ai1 == 1 and v.ai4 == 0 then
		v.speedY = -Defines.npc_grav
	end
	if v.ai3 <= 0 and v.ai1 == 1 and v.ai4 == 0 then
		v.speedY = 3
		v.ai4 = 1
	end
	if math.abs(v.speedX) <= 0.1 then
		v.speedX = 0
	else
		v.speedX = v.speedX * sampleNPCSettings.slowRate
	end
end

function sampleNPC.onDrawNPC(v)
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]
	data.w = math.pi/65

	--Setup code by Mal8rk

	local opacity = 1

	if data.img and v.ai1 == 1 and v.ai2 > 0 then
		-- Setting some properties --
		data.img.x, data.img.y = v.x + v.width/2 - 16, camera.y + camera.height/4 - 16
		data.img.transform.scale = vector(1, 1)

		local p = -5
		local animationFrame = math.floor(lunatime.tick() / 8) % 2 + 1
		-- Drawing --
		data.img:draw{frame = animationFrame, sceneCoords = true, priority = p, color = Color.white..opacity}
	end
end

--Gotta return the library table!
return sampleNPC