--------------------------------------------------------------------
--          Icicle from Super Mario Maker 2 by Nintendo           --
--                    Recreated by IAmPlayer                      --
--------------------------------------------------------------------

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local icicle = {}
local npcID = NPC_ID

local fallSFX = Misc.resolveFile("icicle_fall.wav")

local icicleSettings = {
	id = npcID,
	gfxheight = 64,
	gfxwidth = 32,
	width = 24,
	height = 64,
	gfxoffsetx = 0,
	gfxoffsety = 6,
	frames = 1,
	framestyle = 0,
	framespeed = 8,

	speed = 1,
	npcblocktop = true,
	playerblocktop = true,

	nohurt=true,
	nogravity = true,
	noblockcollision = false,
	nofireball = false,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	ignorethrownnpcs = true,
	
	effectID = 751,
	notcointransformable = true,
}

local configFile = npcManager.setNpcSettings(icicleSettings)

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

function icicle.onInitAPI()
	npcManager.registerEvent(npcID, icicle, "onTickNPC")
	npcManager.registerEvent(npcID, icicle, "onDrawNPC")
end

local pSwitches = {32}

function icicle.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	data.state = data.state or 0 --0 is idle, 1 is shaking, 2 is falling, 3 is respawning
	data.timer = data.timer or 0 --used for shaking and respawning
	data.rotation = data.rotation or 0 --welp, rotation
	data.isRespawnable = false
	
	if data._settings.respawnable == nil then
		data._settings.respawnable = true
	end
	
	data.type = data._settings.type or 0 --0 is falling and fragile, 1 is falling and durable, 2 is sticking on the ceiling.
	
	data.scale = data.scale or 1
	data.lifetime = data.lifetime or 0
	
	if data.lifetime == 0 then
		data.origin = data.origin or vector(v.x, v.y)
	end
	
	data.sprite = Sprite{
		image = Graphics.sprites.npc[npcID].img,
		x = (v.x + v.width / 2 + 4) - (data.scale * 2 + 2) + configFile.gfxoffsetx,
		y = v.y - (data.scale * 2 + 4) + configFile.gfxoffsety,
		width = configFile.gfxwidth * data.scale,
		height = configFile.gfxheight * data.scale,
		frames = configFile.frames,
		align = Sprite.align.TOP
	}
	
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.initialized = false
		data.timer = 0
		data.rotation = 0
		data.lifetime = 0
		data.state = 0
		v.speedY = -Defines.npc_grav
		
		if data.origin ~= nil then
			v.x = data.origin.x
			v.y = data.origin.y
		end
		return
	end
	
	if data.scale > 1 then
		data.scale = 1
	end

	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	if not data.initialized then
		data.scale = 0
		data.initialized = true
		data.state = 3
	end

	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--AI
	v.speedX = 0 --because it's super weird when used alongside bumpers
	v.animationTimer = 0
	data.lifetime = data.lifetime + 1
	
	if v:mem(0x64, FIELD_BOOL) then
		data.isRespawnable = false
	end
	
	--stuff with blocks, man it sucks
	if data.state == 0 then
		if data.origin ~= nil then
			v.x = data.origin.x
			v.y = data.origin.y
		end
	end
	
	if data.state == 3 then
		if data.timer % lunatime.toTicks(1 * 0.05) == 0 then
			data.scale = data.scale + 0.05
		end
		v.friendly = true
		data.timer = data.timer + 1
		if data.timer >= lunatime.toTicks(1) then
			data.state = 0
			data.timer = 0
		end
	else
		v.friendly = false
	end
	
	--Triggering the fall
	if data.type < 2 then
	
		if data.state == 0 then
			data.state = 1
		end
	
		if data.state == 1 then
			if v.direction == DIR_LEFT then
				data.rotation = data.rotation - 2
			else
				data.rotation = data.rotation + 2
			end
		
			data.timer = data.timer + 1
		end
	
		if data.state == 2 then
			v.speedY = v.speedY + 0.08
		else
			v.speedY = 0
		end
	
		if v.speedY >= 6 then
			v.speedY = 6
		end
	
		if data.timer >= 32 and data.state == 1 then
			data.state = 2
			data.timer = 0
			data.rotation = 0
			
			SFX.play(fallSFX)
		end
	end
	
	if data.rotation <= -5 then
		v.direction = DIR_RIGHT
	elseif data.rotation >= 5 then
		v.direction = DIR_LEFT
	end
	
	--slide destroy and getting hurt upon contact thing
	if Player.getNearest(v.x + v.width/2, v.y + v.height):mem(0x3C, FIELD_BOOL) and Colliders.collide(Player.getNearest(v.x + v.width/2, v.y + v.height), v) and not v.friendly then
		v:kill()
		Effect.spawn(configFile.effectID, v.x, v.y)
	elseif not Player.getNearest(v.x + v.width/2, v.y + v.height):mem(0x3C, FIELD_BOOL) and Colliders.collide(Player.getNearest(v.x + v.width/2, v.y + v.height), v) and not v.friendly then
		if Player.getNearest(v.x + v.width/2, v.y + v.height).deathTimer == 0 and not Player.getNearest(v.x + v.width/2, v.y + v.height):mem(0x13C, FIELD_BOOL) then
			Player.getNearest(v.x + v.width/2, v.y + v.height):harm()
			v:kill()
			Effect.spawn(configFile.effectID, v.x, v.y)
		end
	end
	
	--break for type 0 and 1
	if data.type == 0 then
		if v.collidesBlockBottom and data.state == 2 then
			v:kill()
			Effect.spawn(configFile.effectID, v.x, v.y)
		end
	elseif data.type == 1 then
		if v.collidesBlockBottom and data.state == 2 then
			v.speedY = 0
		end
	end
	
	--Handling scale and stuff, because they broke sometimes
	if data.state ~= 3 then
		if data.scale < 1 then
			data.scale = data.scale + 0.01
		end
	end
	
	-- Interactions: we're going big fellas --
	
	--P-Switches
	for _, s in ipairs(NPC.get(pSwitches)) do
		if Colliders.bounce(v, s) then
			Misc.doPSwitch(true)
			s:kill()
		end
	end
	
	--Grrrols
	for _,s in ipairs(NPC.get({531, 532})) do
		if Colliders.collide(v, s) then
			if s.direction == DIR_LEFT then
				v:kill()
				Effect.spawn(configFile.effectID, v.x, v.y)
				s.direction = DIR_LEFT
			else
				v:kill()
				Effect.spawn(configFile.effectID, v.x, v.y)
				s.direction = DIR_RIGHT
			end
		end
	end
end

function icicle.onDrawNPC(v)
	if v:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	local data = v.data
	
	if not Misc.isPaused() then
		if not Defines.levelFreeze then
			if data.sprite ~= nil then
				data.sprite:rotate(data.rotation)
			end
		end
	end
	
	if data.type == 2 then
		v.animationFrame = 2
	elseif data.type == 1 then
		v.animationFrame = 3
	else
		v.animationFrame = 1
	end
	
	local p = -45
    if configFile.foreground then
        p = -15
    end
	
	v.ai3 = v.ai3 + 1
	
	if data.sprite ~= nil and v.ai3 > 4 then
		data.sprite:draw{
			priority = p,
			sceneCoords = true,
			frame = v.animationFrame,
		}
	end
	
	npcutils.hideNPC(v)
end

--Gotta return the library table!
return icicle