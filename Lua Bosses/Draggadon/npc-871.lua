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
	notcointransformable = true,

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
	fireBreathID=872,
	fireRainID=873,
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
	spawnOffset = {
		[-1] = {
			x = -72,
			y = -40,
		},
		[1] = {
			x = 72,
			y = -40,
		}
	},
	breathOffset = {
		[-1] = {
			x = -70,
			y = -14,
		},
		[1] = {
			x = 70,
			y = -14,
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
	npcManager.registerEvent(npcID, draggadonBG, "onTickEndNPC")
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
	local npc = NPC.spawn(config.fireBreathID, v.x + 0.5 * v.width + config.gfxoffsetx + config.headOffset[v.direction].x + config.breathOffset[v.direction].x, v.y + 0.5 * v.height + config.headOffset[v.direction].y + config.breathOffset[v.direction].y, v.section, false, true)
	local bombxspeed = vector.v2(Player.getNearest(npc.x + npc.width/2, npc.y + npc.height).x + 0.5 * Player.getNearest(npc.x + npc.width/2, npc.y + npc.height).width - (npc.x + 0.5 * npc.width))
	local bombyspeed = vector.v2(Player.getNearest(npc.x + npc.width, npc.y + npc.height/2).y + 0.5 * Player.getNearest(npc.x + npc.width, npc.y + npc.height/2).height - (npc.y + 0.5 * npc.height))
	npc.speedX = bombxspeed.x / 39.5
	npc.speedY = bombyspeed.y / 39.5
	npc.direction = v.direction
	npc.spawnDirection = npc.direction

	npc.layerName = "Spawned NPCs"
	npc.friendly = data.originalFriendly

	local bulletConfig = NPC.config[npc.id]
	local bulletData = npc.data

	initialiseBullet(npc,bulletData,bulletConfig,npc.data._settings)

	bulletData.startDepth = 32
	bulletData.depth = bulletData.startDepth
	bulletData.beNotFriendly = true


	data.blastEffectTimer = config.blastEffectDuration

	SFX.play(sfx_fire)
end
local function tryFireRain(v,data,config,settings)
	-- Don't shoot if winning
	if Level.endState() > 0 then
		return
	end

	if config.fireRainID <= 0 then
		return
	end
	

	-- Shoot!
	local npc = NPC.spawn(config.fireRainID, v.x + 0.5 * v.width + config.gfxoffsetx + config.headOffset[v.direction].x + config.spawnOffset[v.direction].x, v.y + 0.5 * v.height + config.headOffset[v.direction].y + config.spawnOffset[v.direction].y, v.section, false, true)
	npc.speedX = 0
	npc.speedY = -4
	npc.direction = v.direction
	npc.spawnDirection = npc.direction

	npc.layerName = "Spawned NPCs"
	npc.friendly = data.originalFriendly

	local bulletConfig = NPC.config[npc.id]
	local bulletData = npc.data

	initialiseBullet(npc,bulletData,bulletConfig,npc.data._settings)

	bulletData.startDepth = 32
	bulletData.depth = bulletData.startDepth
	bulletData.beNotFriendly = true


	data.blastEffectTimer = config.blastEffectDuration

	SFX.play(sfx_fire)
end
local onCameraUpdateHasRun = false
function draggadonBG.onCameraUpdate()
	onCameraUpdateHasRun = true
end

function draggadonBG.onTickEndNPC(v)
	--Don't act during time freeze --
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	local cfg = v.data._settings
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height/2)
	local currentSection = v:mem(0x146, FIELD_WORD)
	--If despawned --
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary --
		data.initialized = false
		data.isLeaving = false data.hangAround = false data.cameraOffsetY = -camera.height
		data.attacking = false
		data.selectedAttack = nil
		data.isLeaving = false
		data.hangAround = false
		data.targetPlayer = nil
		data.rainState = 0
		data.rainTimer = 0
		data.rotation = 0
		data.rotationTick = 0
		data.shootTimer = lunatime.toTicks(cfg.Cooldown)
		data.shootsFired = 0
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
	data.attacking = data.attacking or false
	data.cameraOffsetX = data.cameraOffsetX or 0
	data.cameraOffsetY = data.cameraOffsetY or -camera.height
	data.flyAroundTimer = data.flyAroundTimer or 1
	data.headcurrentFrame = data.headcurrentFrame or 1
	data.headframeTimer = data.headframeTimer or 8
	data.headcurrentAnim = data.headcurrentAnim or 0
	data.currentFrame = data.currentFrame or 1
	data.frameTimer = data.frameTimer or 8
	data.currentAnim = data.currentAnim or 1
	data.selectedAttack = data.selectedAttack or nil
	data.rainState = data.rainState or 0
	data.rainTimer = data.rainTimer or 0
	data.headOffsetY = data.headOffsetY or 0
	data.startSection = data.startSection or currentSection
	data.targetPlayer = data.targetPlayer or plr
	data.hangAround = data.hangAround or false
	data.isLeaving = data.isLeaving or false
	
	-- Custom Animations: Handling --
	data.frameTimer = data.frameTimer + 1

	data.currentFrame = math.floor(data.frameTimer / 6) % 8
	
	-- Custom Animations: Handling Head--
	data.headframeTimer = data.headframeTimer + 1
	if data.headcurrentAnim == 0 then
		if data.headframeTimer < 40 then
			data.headcurrentFrame = 0
		elseif data.headframeTimer < 48 then
			data.headcurrentFrame = 1
		else
			data.headframeTimer = 0
			data.headcurrentFrame = 0
		end
	elseif data.headcurrentAnim == 1 then
		if data.headframeTimer < 4 then
			data.headcurrentFrame = 3
		elseif data.headframeTimer < 8 then
			data.headcurrentFrame = 4
		elseif data.headframeTimer < 12 then
			data.headcurrentFrame = 5
		elseif data.headframeTimer < 16 then
			data.headcurrentFrame = 4
		elseif data.headframeTimer < 20 then
			data.headcurrentFrame = 3
		else
			data.headframeTimer = 0
			data.headcurrentFrame = 3
			data.headcurrentAnim = 0
		end
	end
	-- Let's set custom settings --
	--Shooting stuff --
	data.shootTimer = data.shootTimer or lunatime.toTicks(cfg.Cooldown)
	data.shootsFired = data.shootsFired or 0
	data.rotation = data.rotation or 0
	data.rotationTick = data.rotationTick or 0

	v.x = Camera.get()[1].x + Camera.get()[1].width/2 - v.width/2 + data.cameraOffsetX
	v.y = Camera.get()[1].y + Camera.get()[1].height/2 - v.height/2 + data.cameraOffsetY


		if not data.hangAround then
			if not data.isLeaving then
				data.cameraOffsetY = data.cameraOffsetY + 3
				if data.cameraOffsetY >= 0 then
					data.cameraOffsetY = 0
					data.hangAround = true
				end
			else
				data.cameraOffsetY = data.cameraOffsetY - 5
			end
		else
			local horizontalDistance = cfg.flyAroundHorizontalDistance*0.5*v.spawnDirection
			local verticalDistance = cfg.flyAroundVerticalDistance*0.5
			local horizontalTime = cfg.flyAroundHorizontalTime / math.pi / 2
			local verticalTime   = cfg.flyAroundVerticalTime   / math.pi / 2
			data.cameraOffsetX = data.cameraOffsetX + math.cos(data.flyAroundTimer / horizontalTime)*horizontalDistance / horizontalTime
			data.cameraOffsetY = data.cameraOffsetY + math.sin(data.flyAroundTimer / verticalTime  )*verticalDistance   / verticalTime
			if not data.attacking then
				if math.cos(data.flyAroundTimer / horizontalTime)*horizontalDistance / horizontalTime < 0 then
					v.direction = -1
				else
					v.direction = 1
				end
			end

			data.flyAroundTimer = data.flyAroundTimer + 1
			data.shootTimer = data.shootTimer - 1
			if not v.friendly then
				if data.shootTimer <= 0 then
					if data.attacking then
						if data.selectedAttack == 0 then
							tryFire(v,data,config,cfg)
							data.headcurrentAnim = 1
							data.headcurrentFrame = 3
							data.headframeTimer = 0
							if data.shootsFired >= cfg.FPRB - 1 then
								data.shootTimer = lunatime.toTicks(cfg.Cooldown)
								data.shootsFired = 0
								data.attacking = false
								data.selectedAttack = nil
							else
								data.shootTimer = lunatime.toTicks(cfg.DBFB)
								data.shootsFired = data.shootsFired + 1
								data.attacking = true
							end
						elseif data.selectedAttack == 1 then
							if data.rainState == 0 then
								data.rotation = data.rotation + 2
								data.rotationTick = data.rotationTick + 2
								data.headOffsetY = data.headOffsetY + 4/5
								if data.rotationTick >= 50 then
									data.rotation = 50
									data.rainState = 1
									data.shootTimer = 30
									data.headOffsetY = 20
								end
							elseif data.rainState == 1 then
								data.headcurrentAnim = 1
								data.headcurrentFrame = 3
								data.headframeTimer = 0
								tryFireRain(v,data,config,cfg)
								if data.shootsFired >= cfg.FPRR - 1 then
									data.shootsFired = 0
									data.rainState = 2
								else
									data.shootTimer = lunatime.toTicks(cfg.DBFR)
									data.shootsFired = data.shootsFired + 1
									data.attacking = true
								end
							elseif data.rainState == 2 then
								data.rotation = data.rotation - 2
								data.rotationTick = data.rotationTick - 2
								data.headOffsetY = data.headOffsetY - 4/5
								if data.rotationTick <= 0 then
									data.rotation = 0
									data.rotationTick = 0
									data.rainState = 0
									data.shootTimer = lunatime.toTicks(cfg.Cooldown)
									data.shootsFired = 0
									data.attacking = false
									data.selectedAttack = nil
									data.headOffsetY = 0
								end
							end
						end
					else
						local options = {}
						if cfg.FPRB > 0 then table.insert(options,0) end
						if cfg.FPRR > 0 then table.insert(options,1) end
						if #options > 0 then
							data.selectedAttack = RNG.irandomEntry(options)
							data.attacking = true
						end
					end
				end
			end
		end
	if data.targetPlayer and data.targetPlayer.isValid then
		if data.targetPlayer.forcedState == 7 or data.targetPlayer.forcedState == 3 then
			data.isLeaving = true
			data.hangAround = false
			data.targetPlayer = nil

		else
			if data.isLeaving then data.isLeaving = false data.hangAround = false data.cameraOffsetY = -camera.height end
		end
	else
		if plr.section == v.section then
			data.targetPlayer = plr
			data.isLeaving = false data.hangAround = false data.cameraOffsetY = -camera.height
		end
	end
end

function draggadonBG.onDrawNPC(v)
	local data = v.data
	local opacity = 1
	if data.headimg then
		-- Setting some properties --
		data.headimg.x, data.headimg.y = v.x + 0.5 * v.width + draggadonConfig.gfxoffsetx + draggadonConfig.headOffset[v.direction].x, v.y + 0.5 * v.height + draggadonConfig.headOffset[v.direction].y - data.headOffsetY --[[+ draggadonConfig.gfxoffsety]]
		data.headimg.transform.scale = vector(-v.direction, 1)
		data.headimg.rotation = data.rotation * -v.direction

		local p = -96

		-- Drawing --
		data.headimg:draw{frame = data.headcurrentFrame + 1, sceneCoords = true, priority = p, color = Color.white..opacity}
	end
	if data.bodyimg then
		-- Setting some properties --
		data.bodyimg.x, data.bodyimg.y = v.x + 0.5 * v.width + draggadonConfig.gfxoffsetx, v.y + 0.5 * v.height --[[+ draggadonConfig.gfxoffsety]]
		data.bodyimg.transform.scale = vector(-v.direction, 1)

		local p = -96.1

		-- Drawing --
		data.bodyimg:draw{frame = data.currentFrame + 1, sceneCoords = true, priority = p, color = Color.white..opacity}
	end
	npcutils.hideNPC(v)
end

--Gotta return the library table!
return draggadonBG