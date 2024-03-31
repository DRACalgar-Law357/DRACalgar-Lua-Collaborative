--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local bulletBills = require("bulletBills_ai")
--NPCutils for rendering
local npcutils = require("npcs/npcutils")

--Create the library table
local draggadonBG = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

-- The Shooting SFX File --
sfx_fire = 42

--Defines NPC config for our NPC. You can remove superfluous definitions.
local draggadonBGSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 160,
	gfxwidth = 160,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 160,
	height = 160,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 80,
	--Frameloop-related
	frames = 8,
	framestyle = 1,
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
	firebreathID=872,
	firerainID=873,
	headOffset = {
		[-1] = {
			x = -96,
			y = -36,
		},
		[1] = {
			x = 96,
			y = -36,
		}
	},
	headFrames = 16,
	headFrameStyle = 1,
}

--Applies NPC settings
local draggadonConfig = npcManager.setNpcSettings(draggadonBGSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function draggadonBG.onInitAPI()
	npcManager.registerEvent(npcID, draggadonBG, "onTickNPC")
	--npcManager.registerEvent(npcID, draggadonBG, "onTickEndNPC")
	npcManager.registerEvent(npcID, draggadonBG, "onDrawNPC")
	registerEvent(draggadonBG, "onCameraUpdate")
	--registerEvent(draggadonBG, "onNPCKill")
end
function initialiseBullet(v,data,config,settings)
	if data.originalFriendly == nil then
		data.originalFriendly = v.friendly
	end
	
	v.friendly = true

	data.startDepth = settings.depth
	data.depth = data.startDepth

	data.rotation = config.enterRotation

	data.initialized = true
end
local function tryFire(v,data,config,settings)
	-- Don't shoot if winning
	if Level.endState() > 0 then
		return
	end

	if config.fireBreathID <= 0 then
		return
	end

	-- Shoot!
	local npc = NPC.spawn(config.fireBreathID, v.x + 0.5 * v.width + config.gfxoffsetx + config.headOffset[v.direction].x, v.y + 0.5 * v.height + config.headOffset[v.direction].y, v.section, false, true)

	npc.direction = v.direction
	npc.spawnDirection = npc.direction

	npc.layerName = "Spawned NPCs"
	npc.friendly = data.originalFriendly

	local bulletConfig = NPC.config[npc.id]
	local bulletData = npc.data

	initialiseBullet(npc,bulletData,bulletConfig,npc.data._settings)

	bulletData.startDepth = 32
	bulletData.depth = bulletData.startDepth


	data.blastEffectTimer = config.blastEffectDuration

	SFX.play(sfx_fire)
end
local onCameraUpdateHasRun = false
function draggadonBG.onCameraUpdate()
	onCameraUpdateHasRun = true
end

function draggadonBG.onTickNPC(v)
	--Don't act during time freeze --
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	
	--If despawned --
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary --
		data.initialized = false
		return
	end

	--Initialize --
	if not data.initialized then
		--Initialize necessary data. --
		data.initialized = true
		data.bodyimg = data.bodyimg or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = draggadonConfig.frames, texture = Graphics.sprites.npc[v.id].img}
		data.headimg = data.headimg or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = draggadonConfig.headFrames * (1 + draggadonConfig.headFrameStyle), texture = Graphics.loadImageResolved("npc-"..npcID.."-head.png")}
	end

	--Depending on the NPC, these checks must be handled differently --
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		return
	end

	-- Custom Animations: Variables --
	data.headcurrentFrame = data.headcurrentFrame or 1
	data.headframeTimer = data.headframeTimer or 8
	data.headcurrentAnim = data.headcurrentAnim or 1
	data.headanimTables = data.headanimTables or {{1, 8}, {4, 5, 6, 5, 8}}
	data.currentFrame = data.currentFrame or 1
	data.frameTimer = data.frameTimer or 8
	data.currentAnim = data.currentAnim or 1
	data.animTables = data.animTables or {{1,2,3,4,5,6, 6}}

	local cAnim = data.animTables[data.currentAnim]
	
	-- Custom Animations: Handling --
	data.frameTimer = data.frameTimer - 1

	if data.frameTimer <= 0 then
		if data.currentFrame < #cAnim - 1 then
			data.currentFrame = data.currentFrame + 1
		else
			if data.currentAnim == 2 then
				data.currentAnim = 1
			end
			data.currentFrame = 1
		end
		data.frameTimer = cAnim[#cAnim]
	end

	local headcAnim = data.headanimTables[data.headcurrentAnim]
	
	-- Custom Animations: Handling Head--
	data.headframeTimer = data.headframeTimer - 1

	if data.headframeTimer <= 0 then
		if data.headcurrentFrame < #headcAnim - 1 then
			data.headcurrentFrame = data.headcurrentFrame + 1
		else
			if data.headcurrentAnim == 2 then
				data.headcurrentAnim = 1
			end
			data.headcurrentFrame = 1
		end
		data.headframeTimer = headcAnim[#headcAnim]
	end

	-- Let's set custom settings --
	local cfg = v.data._settings

	--Shooting stuff --
	data.shootTimer = data.shootTimer or lunatime.toTicks(cfg.Cooldown)
	data.shootsFired = data.shootsFired or 0
	data.rotation = data.rotation or 0

	data.limiteIzq = data.limiteIzq or v.x - (cfg.limitL*32)
	data.limiteDer = data.limiteDer or (v.x + v.width) + (cfg.limitR*32)
	data.limiteArr = data.limiteArr or v.y - (cfg.limitU*32)
	data.limiteAbj = data.limiteAbj or (v.y + (v.height) + cfg.limitD*32)

	v.y = v.y + math.sin(lunatime.tick()/6)
	data.shootTimer = data.shootTimer - 1
	if not v.friendly then
		if data.shootTimer <= 0 then
            tryFire(v,data,config,cfg)
			if data.shootsFired >= cfg.FPRB - 1 then
				data.shootTimer = lunatime.toTicks(cfg.Cooldown)
				data.shootsFired = 0
			else
				data.shootTimer = lunatime.toTicks(cfg.DBFB)
				data.shootsFired = data.shootsFired + 1
			end
			data.headcurrentAnim = 2
			data.headcurrentFrame = 1
		end
	end

	--Parallax stuff
	if onCameraUpdateHasRun == true then
		data.cameraComparex = data.cameraComparex or camera.x
		data.cameraComparey = data.cameraComparey or camera.y
		if data.cameraComparex ~= camera.x then
			v.x = v.x + ((camera.x - data.cameraComparex) * cfg.depthX)
			data.cameraComparex = camera.x
		end
		if data.cameraComparey ~= camera.y then
			v.y = v.y + ((camera.y - data.cameraComparey) * cfg.depthY)
			data.cameraComparey = camera.y
		end
	end

	--Limits --
	v.x = math.clamp(v.x, data.limiteIzq, data.limiteDer)
	v.y = math.clamp(v.y, data.limiteArr, data.limiteAbj)
end

function draggadonBG.onDrawNPC(v)
	local data = v.data
	local opacity = 1
	if data.headimg then
		-- Setting some properties --
		data.headimg.x, data.headimg.y = v.x + 0.5 * v.width + draggadonConfig.gfxoffsetx + draggadonConfig.headOffset[v.direction].x, v.y + 0.5 * v.height + draggadonConfig.headOffset[v.direction].y --[[+ draggadonConfig.gfxoffsety]]
		data.headimg.transform.scale = vector(1, 1)
		data.headimg.rotation = data.rotation

		local p = -96

		-- Drawing --
		data.headimg:draw{frame = data.headanimTables[data.headcurrentAnim][data.headcurrentFrame] - 1, sceneCoords = true, priority = p, color = Color.white..opacity}
	end
	if data.bodyimg then
		-- Setting some properties --
		data.bodyimg.x, data.bodyimg.y = v.x + 0.5 * v.width + draggadonConfig.gfxoffsetx, v.y + 0.5 * v.height --[[+ draggadonConfig.gfxoffsety]]
		data.bodyimg.transform.scale = vector(1, 1)

		local p = -96.1

		-- Drawing --
		data.bodyimg:draw{frame = data.animTables[data.currentAnim][data.currentFrame] - 1, sceneCoords = true, priority = p, color = Color.white..opacity}
	end
	npcutils.hideNPC(v)
end

--Gotta return the library table!
return draggadonBG