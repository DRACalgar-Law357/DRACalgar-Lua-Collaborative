--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local colliders = require("colliders")
local playerStun = require("playerstun")
--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 96,
	gfxheight = 96,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 42,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 5,
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
	noblockcollision = false,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = false,
	noiceball = false,
	noyoshi= true, -- If false, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC

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

	nogliding = false, -- The NPC ignores gliding blocks (1f0)

	--Define custom properties below

	--Sound Settings

	sfx_cannon = 22,

	--Launched NPC Settings
	cannonID = 697,
	cannony = 16,
	dontMoveLaunchDelay = 160,

	--Hitbox Settings
	idledetectboxx = 288,
	idledetectboxy = 272,
	anglecheckdistance = 64,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
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
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=npcID,
		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=npcID,
	}
);

--Custom local definitions below
local spawnOffset = {
[-1] = -24,
[1] = sampleNPCSettings.width+24,
}
--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		v.ai2 = 0
		v.ai3 = 0
		data.initialized = false
		return
	end
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		--ai1 = state, ai2 = timer, ai3 = weapon jump timer, ai4 = frame timer, ai5 = wander
		if v.dontMove == false then
			v.ai1 = 0
		else
			v.ai1 = 3
		end
		v.ai5 = v.direction
		data.angleSet = 0
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
		v.ai2 = 0
		v.ai3 = 0
		v.spawnX = v.x
		return
	end
	v.ai2 = v.ai2 + 1
	if v.ai1 == 1 then
		v.ai3 = v.ai3 + 1
	end
	v.ai4 = v.ai4 + 1
	--frametimer = v.ai4
	--timer = v.ai2
	--state = v.ai1
	--weapontimer = v.ai3
	--wander = v.ai5

	--Behaviour Code
	if (plr.y + plr.height/2) - (v.y + v.height/2) >= sampleNPCSettings.anglecheckdistance then
		data.angleSet = 2
	elseif (plr.y + plr.height/2) - (v.y + v.height/2) <= -sampleNPCSettings.anglecheckdistance then
		data.angleSet = 1
	else
		data.angleSet = 0
	end
	if v.ai1 == 0 then
		v.speedX = 1 * v.direction
		if v.direction == 1 then
			if v.x >= v.spawnX + 96 then
				v.direction = -v.direction
			end
		elseif v.ai5 == -1 then
			if v.x <= v.spawnX - 96 then
				v.direction = -v.direction
			end
		end
		if math.abs((plr.x + plr.width/2) - (v.x + v.width/2)) <= sampleNPCSettings.idledetectboxx and math.abs((plr.y + plr.height/2) - (v.y + v.height/2)) <= sampleNPCSettings.idledetectboxy then
			v.ai1 = 1
			v.ai3 = 0
			npcutils.faceNearestPlayer(v)
		end
	elseif v.ai1 == 1 then
		if v.ai2 % 64 == 32 then
			v.speedX = RNG.randomEntry{-1,1}
		end
		if math.abs((plr.x + plr.width/2) - (v.x + v.width/2)) <= sampleNPCSettings.idledetectboxx and math.abs((plr.y + plr.height/2) - (v.y + v.height/2)) <= sampleNPCSettings.idledetectboxy and v.ai2 % 80 == 0 then
			v.speedX = 0
			v.ai1 = 2
			v.ai2 = 0
			npcutils.faceNearestPlayer(v)
		end
		if math.abs((plr.x + plr.width/2) - (v.x + v.width/2)) > sampleNPCSettings.idledetectboxx and math.abs((plr.y + plr.height/2) - (v.y + v.height/2)) > sampleNPCSettings.idledetectboxy then
			v.ai1 = 0
			v.ai2 = 0
			v.ai3 = 0
			v.ai5 = v.direction
			v.spawnX = v.x
		end	
	elseif v.ai1 == 2 then
		if v.ai2 == 1 then v.speedX = 0 end
		if v.ai2 == 32 then
			SFX.play(sampleNPCSettings.sfx_cannon)
			local n = NPC.spawn(sampleNPCSettings.cannonID, v.x + spawnOffset[v.direction], v.y + sampleNPCSettings.cannony)
			n.x=n.x-n.width/2
			n.y=n.y-n.height/2
			local a = Animation.spawn(10, v.x + spawnOffset[v.direction], v.y + sampleNPCSettings.cannony)
			a.x=a.x-a.width/2
			a.y=a.y-a.height/2
			if data.angleSet == 0 then
				n.speedX = 2.5 * v.direction
			elseif data.angleSet == 1 then
				n.speedX = 2 * v.direction
				n.speedY = -0.6
			elseif data.angleSet == 2 then
				n.speedX = 2 * v.direction
				n.speedY = 0.6
			end
		end
		if v.ai2 >= 64 then
			if v.dontMove == false then
				v.ai1 = 1
			else
				v.ai1 = 3
			end
			v.ai2 = 0
			v.speedX = 0
			npcutils.faceNearestPlayer(v)
		end
	elseif v.ai1 == 3 then
		if v.ai2 >= sampleNPCSettings.dontMoveLaunchDelay then
			v.ai2 = 0
			v.ai1 = 2
		end
	end
	--Animation Code
	if v.ai1 == 0 or v.ai1 == 1 then
		if v.ai4 < 8 then
			v.animationFrame = 0
		elseif v.ai4 < 16 then
			v.animationFrame = 1
		elseif v.ai4 < 24 then
			v.animationFrame = 2
		elseif v.ai4 < 32 then
			v.animationFrame = 3
		else
			v.animationFrame = 0
			v.ai4 = 0
		end
	elseif v.ai1 == 3 then
		if v.ai4 < 8 then
			v.animationFrame = 0
		elseif v.ai4 < 16 then
			v.animationFrame = 1
		else
			v.animationFrame = 0
			v.ai4 = 0
		end
	else
		v.animationFrame = 4
	end
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
	end
	
	--Prevent Skuttler Cannoneer from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
end

--Gotta return the library table!
return sampleNPC