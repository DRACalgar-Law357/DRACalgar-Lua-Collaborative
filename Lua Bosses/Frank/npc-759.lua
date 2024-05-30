
--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local iceblock = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local iceblockSettings = {
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
	framestyle = 0,
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
	playerblocktop = true, -- The player can walk on the NPC.

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	nohurt = true,

	score = 1, -- Score granted when killed
	--  1 = 10,    2 = 100,    3 = 200,  4 = 400,  5 = 800,
	--  6 = 1000,  7 = 2000,   8 = 4000, 9 = 8000, 10 = 1up,
	-- 11 = 2up,  12 = 3up,  13+ = 5-up, 0 = 0

	--Various interactions
	jumphurt = false, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	nowalldeath = false, -- If true, the NPC will not die when released in a wall

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=true,
	grabtop=true,
	isstationary = false, -- gradually slows down the NPC
	ishot = true,
	lightradius = 100,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.white,
}

--Applies NPC settings
npcManager.setNpcSettings(iceblockSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=1,
		[HARM_TYPE_PROJECTILE_USED]=1,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=1,
		[HARM_TYPE_TAIL]=1,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=1,
	}
);

--Custom local definitions below


--Register events
function iceblock.onInitAPI()
	npcManager.registerEvent(npcID, iceblock, "onTickEndNPC", "onTickGrabbed")
end

function iceblock.onTickGrabbed(v)
	if Defines.levelFreeze then return end

	local data = v.data._basegame
	v.collisionGroup = "FrankBall"
    Misc.groupsCollide["FrankBall"]["FrankProjectile"] = false
	Misc.groupsCollide["FrankBall"]["FrankBall"] = false
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 then
		data.previousGrabPlayer = 0
		return
	end

	if data.time == nil then
		data.previousGrabPlayer = 0
		data.dropCooldown = 0
		data.time = 0
		data.sliding = 0
		data.yoshi = v:mem(0x138, FIELD_WORD) == 5
	elseif data.sliding == 0 then
		data.time = data.time + 1
	end

	if data.yoshi and v:mem(134, FIELD_WORD) == 5 then
		v.speedX = 6.5 * v.direction
		v.speedY = 0
		data.sliding = math.sign(v.speedX)
	end

	if data.previousGrabPlayer > 0 and v:mem(0x136, FIELD_WORD) == -1 then
		local p = Player(data.previousGrabPlayer)
		if p and p:mem(0x108, FIELD_WORD) == 0 then
			if p.upKeyPressing then
				v.speedX = p.speedX * 0.5
				v.speedY = - 12
			elseif p.downKeyPressing then
				v.speedX = 0.5 * p.direction
				v.speedY = -0.5
			else
				--[[if p:mem(0x12E, FIELD_WORD) ~= 0 or p.speedX == 0 or (not p.rightKeyPressing and not p.leftKeyPressing) then
					v.speedX = 0.5 * p.FacingDirection
					v.speedY = -0.5
				else
					v.speedY = 0
				end]]
				v.speedX = 6 * p.direction + 0.5 * p.speedX
				v.speedY = -4
				data.sliding = math.sign(v.speedX)
			end
			data.dropCooldown = 16
		end
	end

	if v:mem(0x12C, FIELD_WORD) == 1 then
		v.collidesBlockBottom = false
	end

	if data.sliding ~= 0 then
		for _,n in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
			if Colliders.collide(n,v) and not NPC.config[n.id].isCoin and not NPC.config[n.id].isInteractable and NPC.HITTABLE_MAP[n.id] and n.idx ~= v.idx then
				n:harm(HARM_TYPE_NPC)
			end
		end
		if v.collidesBlockBottom then
			v.speedX = v.speedX * 0.5
			data.sliding = 0
		end
	else
		if v.collidesBlockBottom then
			v.speedX = v.speedX * 0.5
		end
	end

	data.previousGrabPlayer = v:mem(0x12C, FIELD_WORD)
	data.dropCooldown = data.dropCooldown - 1
end

--Gotta return the library table!
return iceblock