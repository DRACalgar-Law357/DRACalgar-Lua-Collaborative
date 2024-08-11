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
	gfxwidth = 28,
	gfxheight = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 28,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 4,
	framestyle = 0,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	foreground = false, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- LOGIC
	--Movement speed. Only affects speedX by default.
	speed = 1,
	luahandlesspeed = true, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = true,
	cliffturn = false, -- Makes the NPC turn on ledges
	staticdirection = false, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = false, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = false, -- The player can walk on the NPC.

	nohurt=false, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	noblockcollision = true,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= false, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	ignorethrownnpcs = true,

	score = 1, -- Score granted when killed
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
	-- iscold = true,
	durability = -1, -- Durability for elemental interactions like ishot and iscold. -1 = infinite durability
	-- weight = 2,
	isstationary = true, -- gradually slows down the NPC
	nogliding = true, -- The NPC ignores gliding blocks (1f0)

	--Emits light if the Darkness feature is active:
	lightradius = 100,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.white,

	--Define custom properties below
	comeUpSpeed = 6.5,
	fallDownSpeed = 6.5,
	cameraTopOffsetY = -4,
	showerBGOID = 877,
	despawnDelay = 420,
}

--Applies NPC settings
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
		[HARM_TYPE_JUMP]=10,
		[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

function sampleNPC.onTickNPC(v)
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
		data.bgoTable = BGO.get(sampleNPCSettings.showerBGOID)
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
	v.ai2 = v.ai2 + 1
	if v.ai1 == 0 then
		v.animationFrame = math.floor(v.ai2 / 8) % 2
		if v.speedY >= 0 then v.speedY = -sampleNPCSettings.comeUpSpeed end
		if v.y + v.height / 2 <= camera.y + sampleNPCSettings.cameraTopOffsetY then
			v.ai2 = 0
			v.ai1 = 1
			if #data.bgoTable > 0 then
				local location = RNG.irandomEntry(data.bgoTable)
				v.x = location.x + 16 - v.width / 2
				v.y = camera.y + sampleNPCSettings.cameraTopOffsetY - v.height / 2
				SFX.play(16)
			end
		end
		if v.ai2 % 3 == 0 then
			local ptl = Animation.spawn(265, math.random(v.x, v.x + v.width)-8, math.random(v.y, v.y + v.height)-8)
			ptl.speedY = 2
		end
	elseif v.ai1 == 1 then
		v.animationFrame = math.floor(v.ai2 / 8) % 2 + 2
		if v.speedY <= 0 then v.speedY = sampleNPCSettings.fallDownSpeed end
		if v.ai2 % 3 == 0 then
			local ptl = Animation.spawn(265, math.random(v.x, v.x + v.width)-8, math.random(v.y, v.y + v.height)-8)
			ptl.speedY = -2
		end
		if v.ai2 >= sampleNPCSettings.despawnDelay then v:kill(HARM_TYPE_NPC) end
	else
		v.ai1 = 0
		v.ai2 = 0
	end

	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
	end
end

--Gotta return the library table!
return sampleNPC