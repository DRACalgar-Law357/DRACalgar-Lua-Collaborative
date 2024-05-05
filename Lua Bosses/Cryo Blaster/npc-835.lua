--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 26,
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

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	notcointransformable=true,
	ignorethrownnpcs=true,
	staticdirection = true,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Custom local definitions below


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

-- Detects if the player is on the ground, the redigit way. Function by MrDoubleA
local function isOnGround(player)
	return (
		player.speedY == 0 -- "on a block"
		or player:mem(0x176,FIELD_WORD) ~= 0 -- on an NPC
		or player:mem(0x48,FIELD_WORD) ~= 0 -- on a slope
	)
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	v.animationFrame = v.ai1
	
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		v:kill()
	end
	
	v.ai2 = v.ai2 - 1

	
	data.timer = data.timer + 1
	
	if data.timer >= 320 then
		v.ai2 = 0
		v:kill()
	end
	
	for _,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
		if isOnGround(p) and v.isValid then
			v.ai2 = 16
		end
	end
	if v.ai2 > 0 then
		Defines.jumpheight = 1
		Defines.player_walkspeed = 1.5
		Defines.player_runspeed = 3
	else
		Defines.jumpheight = 20
		Defines.player_walkspeed = 3
		Defines.player_runspeed = 6
	end
	for _,n in ipairs(NPC.get(npcID)) do
		n.ai2 = v.ai2
	end
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
end

--Gotta return the library table!
return sampleNPC