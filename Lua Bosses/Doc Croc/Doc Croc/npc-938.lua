--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local cannonBall = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local cannonBallSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 24,
	height = 24,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 4,
	--Frameloop-related
	frames = 4,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
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
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	iselectric=true,
	lightradius = 48,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.cyan,
	transformTargetNPCID = 939,
	targetDelay = 60,
	targetSpeed = 3.5,
}

--Applies NPC settings
npcManager.setNpcSettings(cannonBallSettings)

function cannonBall.onTickEndNPC(v)
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	if Defines.levelFreeze then return end
		--If despawned
		if v.despawnTimer <= 0 then
			--Reset our properties, if necessary
			data.initalized = false
			return
		end
		--Initialize
		if not data.initialized then
			--Initialize necessary data.
			data.initialized = true
			v.ai1 = 0
		end
	if v.despawnTimer > 0 and v:mem(0x12C, FIELD_WORD) == 0 and v:mem(0x138, FIELD_WORD) == 0 then
		if v.speedX == 0 and v.speedY == 0 then
			v.speedX = NPC.config[v.id].speed * v.direction
		end
	end
	if v.ai1 then
		v.ai1 = v.ai1 + 1
		if v.ai1 >= NPC.config[v.id].targetDelay then
			data.dirVectr = vector.v2(
				(plr.x + plr.width/2) - (v.x + v.width * 0.5),
				(plr.y + plr.height/2) - (v.y + v.height * 0.5)
				):normalize() * (NPC.config[v.id].targetSpeed)
			v:transform(NPC.config[v.id].transformTargetNPCID)
			v.speedX = data.dirVectr.x
			v.speedY = data.dirVectr.y
		end
	end
end

npcManager.registerEvent(npcID, cannonBall, "onTickEndNPC")

--Gotta return the library table!
return cannonBall