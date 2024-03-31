--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local missile = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local missileSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 44,
	gfxwidth = 44,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 44,
	height = 44,
	--Frameloop-related
	frames = 1,
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
	nogravity = true,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(missileSettings)

--Register events
function missile.onInitAPI()
	npcManager.registerEvent(npcID, missile, "onTickNPC")
	registerEvent(missile, "onNPCKill")
end

function missile.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--Kill NPCs
	for k,npc in ipairs(Colliders.getColliding{a = v, atype = Colliders.NPC, b = NPC.HITTABLE}) do
		if (not npc.friendly and not npc.isHidden and not npc.isinteractable and not npc.iscoin) and npc:mem(0x138, FIELD_WORD) == 0 then
			v:kill()
		end
	end
	
	if v.collidesBlockLeft or v.collidesBlockRight then
		v:kill()
	end
	
	--Set its despawn timer to be shorter so it doesnt destroy blocks too far away from the screen
	if (v.x + v.width > camera.x and v.x < camera.x + camera.width and v.y + v.height > camera.y and v.y < camera.y + camera.height) then
		v:mem(0x12A, FIELD_WORD, 48)
	end
end

function missile.onNPCKill(eventObj,v,reason)
	local data = v.data
	if v.id ~= npcID then return end
	if reason ~= HARM_TYPE_OFFSCREEN then
		Explosion.spawn(v.x + 0.5 * v.width, v.y + 0.5 * v.height, 3)
	end
end

--Gotta return the library table!
return missile