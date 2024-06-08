--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
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
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
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

	nohurt=false,
	nogravity = true,
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
	staticdirection = true,
	ignorethrownnpcs = true,

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
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
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
		[HARM_TYPE_NPC]=100,
		[HARM_TYPE_PROJECTILE_USED]=100,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=100,
		[HARM_TYPE_TAIL]=100,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=100,
	}
);

--Custom local definitions below


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
end

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	v.collisionGroup = "FrankProjectile"
    Misc.groupsCollide["FrankBoss"]["FrankProjectile"] = false
    Misc.groupsCollide["FrankProjectile"]["FrankProjectile"] = false
	Misc.groupsCollide["FrankProjectile"]["FrankBall"] = false
	Misc.groupsCollide["FrankProjectile"]["FrankEnemy"] = false
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
		data.rotation = 0
	end
	local speed = 0
	if (math.abs(v.speedX) > math.abs(v.speedY)) or (math.abs(v.speedX) == math.abs(v.speedY)) then
		speed = v.speedX
	elseif math.abs(v.speedX) < math.abs(v.speedY) then
		speed = v.speedY
	end
	if v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockRight or v.collidesBlockUp then
		v:kill(9)
		SFX.play(4)
		Animation.spawn(100,v.x+v.width/2+8,v.y+v.height/2+8)
		for i=0,5 do
			local dir = -vector.right2:rotate(0 + (i * 60) * v.direction)
			local n = NPC.spawn(850,v.x+v.width/2,v.y+v.height/2,v.section,false,true)
			n.speedX = dir.x * 4.5
			n.speedY = dir.y * 4.5
		end
	end
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end

	data.rotationSpeed = speed * 4
	data.rotation = data.rotation + data.rotationSpeed

	if data.rotation > 360 then
		data.rotation = 0
	elseif data.rotation < 0 then
		data.rotation = 360
	end
end

local function isDespawned(v)
	return v.despawnTimer <= 0
end

function sampleNPC.onDrawNPC(v)
	local data = v.data
	local config = NPC.config[v.id]

	if not isDespawned(v) then
		local gfxw = NPC.config[v.id].gfxwidth
		local gfxh = NPC.config[v.id].gfxheight
		if gfxw == 0 then gfxw = v.width end
		if gfxh == 0 then gfxh = v.height end
		local frames = Graphics.sprites.npc[v.id].img.height / gfxh
		local framestyle = NPC.config[v.id].framestyle
		local frame = v.animationFrame
		local framesPerSection = frames
		if framestyle == 1 then
			framesPerSection = framesPerSection * 0.5
			if direction == 1 then
				frame = frame + frames
			end
			frames = frames * 2
		elseif framestyle == 2 then
			framesPerSection = framesPerSection * 0.25
			if direction == 1 then
				frame = frame + frames
			end
			frame = frame + 2 * frames
		end
		local p = priority or -46
		Graphics.drawBox{
			texture = Graphics.sprites.npc[v.id].img,
			x = v.x + (v.width / 2), y = v.y + v.height-(config.gfxheight / 2),
			sourceX = 0, sourceY = v.animationFrame * config.gfxheight,
			sourceWidth = config.gfxwidth, sourceHeight = config.gfxheight,
			priority = -45, rotation = data.rotation,
			centered = true, sceneCoords = true,
		}
	end

	npcutils.hideNPC(v)
end

--Gotta return the library table!
return sampleNPC