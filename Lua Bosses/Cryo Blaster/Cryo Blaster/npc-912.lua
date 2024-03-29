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
	gfxheight = 48,
	gfxwidth = 78,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 78,
	height = 48,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 32,
	--Frameloop-related
	frames = 2,
	framestyle = 0,
	framespeed = 4, --# frames between frame change
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
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	staticdirection = true,
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
		data.targeting = false
		data.markedX = 0
		data.markedY = 0
		data.timer = 0
		SFX.play("smrpg_enemy_diamondsaw1.wav")
		if v.direction == 0 then v.direction = -1 end
		v.speedX = 6 * v.direction
	end
	
	if v.ai1 <= 0 then
		v.speedX = v.speedX - 0.1 * v.direction
		if math.abs(v.speedX) <= 0.01 then
			v.speedX = 0
			SFX.play("smrpg_enemy_diamondsaw1.wav")
			v.ai1 = 1
		end
	else
		v.ai2 = v.ai2 + 1
		if v.ai2 >= 16 then
			if data.targeting == false then
				local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
								
				local startX = p.x + p.width / 2
				local startY = p.y + p.height / 2
				local X = v.x + v.width / 2
				local Y = v.y + v.height / 2
				
				local angle = math.atan2((Y - startY), (X - startX))
				
	
				data.markedX = -6 * math.cos(angle)
				data.markedY = -6 * math.sin(angle)
				data.targeting = true
			else
				v.speedX = data.markedX
				v.speedY = data.markedY
			end
		end
	end
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
end
--Gotta return the library table!
return sampleNPC