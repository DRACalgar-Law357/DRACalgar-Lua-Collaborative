--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
--Create the library table
local drone = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local droneSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
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
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
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
	targetSpeed = 2,
}

--Applies NPC settings
npcManager.setNpcSettings(droneSettings)

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

function drone.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	data.dirVectr = vector.v2(
		(plr.x + plr.width/2) - (v.x + v.width * 0.5),
		(plr.y + plr.height/2) - (v.y + v.height * 0.5)
		):normalize() * (NPC.config[v.id].targetSpeed)
	v.speedX = data.dirVectr.x
	v.speedY = data.dirVectr.y
	if v.speedX <= 0 then
		v.animationFrame = math.floor(lunatime.tick() / 6) % 2
	else
		v.animationFrame = math.floor(lunatime.tick() / 6) % 2 + 2
	end
end

npcManager.registerEvent(npcID, drone, "onTickEndNPC")

--Gotta return the library table!
return drone