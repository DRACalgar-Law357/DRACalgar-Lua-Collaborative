
local npcManager = require("npcManager")

local big = {}

local npcID = NPC_ID

local bigSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 64,
	gfxheight = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 56,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 2,
	--Frameloop-related
	frames = 4,
	framestyle = 1,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	foreground = false, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- LOGIC
	--Movement speed. Only affects speedX by default.
	speed = 2.5,
	luahandlesspeed = true, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = false,
	cliffturn = false, -- Makes the NPC turn on ledges
	staticdirection = false, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = true, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = true, -- The player can walk on the NPC.

	nohurt=false, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = false,
	noiceball = false,
	noyoshi= false, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC

	score = 2, -- Score granted when killed
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

}

--Applies NPC settings
npcManager.setNpcSettings(bigSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
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
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function big.onInitAPI()
	npcManager.registerEvent(npcID, big, "onTickEndNPC")
	npcManager.registerEvent(npcID, big, "onDrawNPC")
end

function big.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	if v.despawnTimer <= 0 then return end

	local data = v.data
	
	--Initialize
	if not data.initialized then
		data.lockedFrame = v.animationFrame -- used to lock the big's frame upon falling
		data.leeway = 0 -- needed to not continuously bounce upon falling from a certain height
		data.fallLength = 0 -- used to check if the ball has fallen long enough or not 
		data.isFalling = false -- explains itself
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		v.animationFrame = data.lockedFrame
		data.fallLength = 32
	end
	
	--if Colliders.collide(v,player) then end -- debug hitbox check
	
	if v.collidesBlockBottom then -- handles moving on the ground
		v.isProjectile = false
		v.speedX = NPC.config[npcID].speed * v.direction
		data.lockedFrame = v.animationFrame
		if data.leeway > 0 then
			data.leeway = data.leeway - 1
			data.fallLength = 0
		end
		if v.collidesBlockLeft or v.collidesBlockRight then -- kills the big upon touching any wall.
			Defines.earthquake = 5
			SFX.play(37)
			v:kill(4)
		end
	end
	
	if v.collidesBlockBottom and data.isFalling and data.fallLength >= 24 then -- handles inital bounce
		v.speedY = -4
		Defines.earthquake = 5
		SFX.play(37)
		data.leeway = 16
		data.fallLength = 0
		data.isFalling = false
	elseif not v.collidesBlockBottom and v.forcedState == 0 then -- handles falling
		if not v.isProjectile then v.speedX = 0 end
		v.speedY = v.speedY + Defines.npc_grav
		v.animationFrame = data.lockedFrame
		if data.leeway <= 0 then
			data.fallLength = data.fallLength + 1
			data.isFalling = true
		end
	end

	for _,n in NPC.iterateIntersecting(v.x - 3,v.y - 3, v.x + v.width + 3, v.y + v.height + 3) do -- handles killing other npcs & bigs bumping into each other
		if n.id ~= v.id then
			n:harm(3)
		elseif not v.isGenerator and v.forcedState == 0 and n.idx ~= v.idx then
			Defines.earthquake = 5
			SFX.play(37)
		end
	end
	
end

--Gotta return the library table!
return big