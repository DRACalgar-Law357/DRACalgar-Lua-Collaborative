--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local Buckicle = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local BuckicleSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 36,
	gfxwidth = 36,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 28,
	height = 28,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 4,
	--Frameloop-related
	frames = 2,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 3,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	iscold = true,
	durability = 10,

	lightradius = 36,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.teal,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(BuckicleSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=77,
	}
);

--Custom local definitions below


--Register events
function Buckicle.onInitAPI()
	npcManager.registerEvent(npcID, Buckicle, "onTickNPC")
	--npcManager.registerEvent(npcID, Buckicle, "onTickEndNPC")
	--npcManager.registerEvent(npcID, Buckicle, "onDrawNPC")
	--registerEvent(Buckicle, "onNPCKill")
end

function Buckicle.onTickNPC(v)
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
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Execute main AI.
	if v.collidesBlockLeft or v.collidesBlockRight then
		v:kill(4)
	end
	v.speedX = v.direction
	v:mem(0x120, FIELD_BOOL, false)
end

--Gotta return the library table!
return Buckicle