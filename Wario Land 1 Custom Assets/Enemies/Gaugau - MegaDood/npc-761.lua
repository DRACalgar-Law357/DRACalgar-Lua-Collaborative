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
	gfxheight = 12,
	gfxwidth = 24,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 24,
	height = 12,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
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

	ignorethrownnpcs=true,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
end

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local tbl = Block.SOLID .. Block.PLAYER
	collidingBlocks = Colliders.getColliding {
		a = v,
		b = tbl,
		btype = Colliders.BLOCK
	}

		if #collidingBlocks > 0 and v.ai2 == 0 then --Not colliding with something
			v.ai2 = 1
			v.speedX = 0
			SFX.play(3)
			v.ai3 = 1
		end
	
	if v.ai3 > 0 then
		v.ai3 = v.ai3 + 1
		if v.ai3 >= 192 then
			v:kill(HARM_TYPE_OFFSCREEN)
		end
	end
	
	for _,p in ipairs(Player.get()) do
		if Colliders.collide(v,p) and v.speedX ~= 0 then
			p:harm()
		end
	end
	
end

--Gotta return the library table!
return sampleNPC