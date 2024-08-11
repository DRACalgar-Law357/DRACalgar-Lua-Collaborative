--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local sprite

--*******************************************************
--Code by Minus and Saturn Yoshi - Taken from npc-615.lua
--*******************************************************


--Create the library table
local bone = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local boneSettings = {
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
	framestyle = 1,
	framespeed = 4, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	ignorethrownnpcs = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false
}

--Applies NPC settings
npcManager.setNpcSettings(boneSettings)

--Custom local definitions below



-- Called when first spawned or respawned (i.e., ai1 is 0).  Initializes all of the bone's relevant parameters (no data is used here, due to the
-- small number of necessary parameters).
local function initialize(v)
	local data = v.data
	-- Set the flag that the bone has been initialized
	v.ai1 = 1

	data.killTimer = data.killTimer or 0

	-- Owner is assumed to be set to the NPC which spawned the bone
	-- to be able to detect whether the bone intersects with the original thrower while in state 5, and delete it if that's the case.
	-- data.ownerBro = nil
end

--Register events
function bone.onInitAPI()
	npcManager.registerEvent(npcID, bone, "onTickNPC")
end

function bone.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data

	
	if v.ai1 == 0 then
		initialize(v)
	end
    data.killTimer = data.killTimer + 1
    if data.killTimer >= 320 then
        v:kill(9)
        Animation.spawn(10,v.x,v.y)
        SFX.play(3)
    end
end
--Gotta return the library table!
return bone