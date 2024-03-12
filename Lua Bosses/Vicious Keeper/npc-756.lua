--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
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
	frames = 2,
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
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	ishot = true,
	lightradius = 100,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.orange,
	effectID = 265,
	lockindelay = 0
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local data = v.data
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end
	if not data.initialized then
		--Initialize necessary data.
		data.targeting = false
		data.markedX = 0
		data.markedY = 0
		data.lockintimer = 0
		data.initialized = true
	end
	if v.ai2 == 0 then
		v.ai1 = v.ai1 + 1
		if v.ai1 <= 60 then
			v.animationFrame = math.floor(v.ai1 / 6) % 2
			if v.ai2 == 1 then
				if v.ai1 == 60 then
					v.targetX = data.dirVectr.x
					v.targetY = data.dirVectr.y
					SFX.play(16)
				end
			end
		else
			v.animationFrame = 1
			if math.abs(v.speedX) <= 5.5 then
				v.speedX = ((v.ai1 - 60) * 0.1) * v.direction
			else
				v.speedX = 5.5 * v.direction
			end
		end
		if v.ai1 % RNG.randomInt(4,12) == 0 then
			local e = Effect.spawn(NPC.config[v.id].effectID, v.x, v.y)
			e.speedY = -0.5
		end
	else
		if data.targeting == false then
			data.lockintimer = data.lockintimer + 1
			if data.lockintimer >= sampleNPCSettings.lockindelay then
				data.lockintimer = 0
				local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
								
				local startX = p.x + p.width / 2
				local startY = p.y + p.height / 2
				local X = v.x + v.width / 2
				local Y = v.y + v.height / 2
				
				local angle = math.atan2((Y - startY), (X - startX))
				
	
				data.markedX = -5 * math.cos(angle)
				data.markedY = -5 * math.sin(angle)
				data.targeting = true
			end
		else
			v.speedX = data.markedX
			v.speedY = data.markedY
		end
	
		
		local ptl = Animation.spawn(265, math.random(v.x, v.x + v.width)-4, math.random(v.y, v.y + v.height)-4)
	end
end

--Gotta return the library table!
return sampleNPC