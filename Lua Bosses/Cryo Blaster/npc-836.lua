--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local easing = require("ext/easing")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
local freeze = require("freezeHighlight")
--Create the library table
local cryoBlaster = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
--Defines NPC config for our NPC. You can remove superfluous definitions.
local cryoBlasterSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 72,
	height = 72,
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
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	ignorethrownnpcs = true,

	grabside=false,
	grabtop=false,
	staticdirection = false,
	prop1Image = Graphics.loadImageResolved("npc-833-prop1.png"),
	prop2Image = Graphics.loadImageResolved("npc-833-prop2.png"),
	prop1OffsetX = 36,
	prop1OffsetY = 36,
	prop2OffsetX = 36,
	prop2OffsetY = 36,
	prop1Height = 192,
	prop2Height = 192
}

--Applies NPC settings
npcManager.setNpcSettings(cryoBlasterSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})
--Register events
function cryoBlaster.onInitAPI()
	npcManager.registerEvent(npcID, cryoBlaster, "onTickEndNPC")
	npcManager.registerEvent(npcID, cryoBlaster, "onDrawNPC")
end
local function getDistance(k,p)
	return k.x < p.x
end

local function setDir(dir, v)
	if (dir and v.data._basegame.direction == 1) or (v.data._basegame.direction == -1 and not dir) then return end
	if dir then
		v.data._basegame.direction = 1
	else
		v.data._basegame.direction = -1
	end
end

local function chasePlayers(v)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local dir1 = getDistance(v, plr)
	setDir(dir1, v)
end

function cryoBlaster.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height/2)
	local config = NPC.config[v.id]
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initalized = false
		data.timer = 0
		data.hurtTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true

		data.timer = data.timer or 0
		data.state = 0
		data.shurikenDisplay = true
		v.ai1 = 0
		v.ai2 = 0
		v.ai3 = 0
		data.prop1rotation = 0
		data.prop2rotation = 0
		data.prop1Timer = 0
		data.prop2Timer = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE.IDLE
		v.ai1 = 0
		data.timer = 0
	end
	data.timer = data.timer + 1
	if v.parent then
		data.dirVectr = vector.v2(
			(v.parent.x + v.parent.width/2) - (v.x + v.width * 0.5),
			(v.parent.y + v.parent.height/2) - (v.y + v.height * 0.5)
			):normalize() * 5
	else
		v:kill(9)
	end
	if data.state == 0 then
		if v.collidesBlockBottom then
			SFX.play("S3K_spikethud.wav")
			v.speedX = 0
			data.state = 1
			data.timer = 0
		end
	elseif data.state == 1 then
		local prop1rotator = 0
		local prop1rotatedirection = v.direction
		local prop2rotator = 0
		local prop2rotatedirection = -v.direction
		if data.shurikenDisplay then
			prop1rotator = 7
			prop2rotator = 7
			data.prop1rotation = data.prop1rotation + prop1rotator * prop1rotatedirection
			data.prop2rotation = data.prop2rotation + prop2rotator * prop2rotatedirection
		else

		end
		v.speedX = math.clamp(v.speedX + 0.3 * v.direction, -8, 8)	
		if data.timer % 8 == 0 and v.collidesBlockBottom then SFX.play("S3K_spikethud.wav") end
		if data.timer > 4 then
			if v.collidesBlockLeft or v.collidesBlockRight then
				v.speedX = 0
				data.timer = 0
				if v.ai1 >= 1 then
					v.ai1 = 0
					data.state = 2
					SFX.play("s3k_shoot.ogg")
					v.speedY = -11
					Defines.earthquake = 7
					v.speedX = 2 * -v.direction
					v.direction = -v.direction
					v.ai1 = 0
				else
					v.ai1 = v.ai1 + 1
					v.direction = -v.direction
				end
			end
		end
	elseif data.state == 2 then
		local prop1rotator = 0
		local prop1rotatedirection = v.direction
		local prop2rotator = 0
		local prop2rotatedirection = -v.direction
		if data.shurikenDisplay then
			prop1rotator = 9
			prop2rotator = 9
			data.prop1rotation = data.prop1rotation + prop1rotator * prop1rotatedirection
			data.prop2rotation = data.prop2rotation + prop2rotator * prop2rotatedirection
		else

		end
		chasePlayers(v)
		v.speedX = math.clamp(v.speedX + 0.2 * v.data._basegame.direction, -6, 6)
		if v.collidesBlockBottom then
			SFX.play("s3k_shoot.ogg")
			v.speedY = -10
			Defines.earthquake = 7
			if v.ai1 >= 2 then
				v.ai1 = 0
				data.state = 3
				v.speedX = 0
				v.speedY = 0
			else
				v.ai1 = v.ai1 + 1
			end
		end
	elseif data.state == 3 then
		v.friendly = true
		data.prop1rotation = 0
		data.prop2rotation = 0
		if v.parent then
			v.speedX = data.dirVectr.x
			v.speedY = data.dirVectr.y
		end
	end

	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = cryoBlasterSettings.frames
		});
	end
	
	--Prevent Cryo Blaster from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
end
local lowPriorityStates = table.map{1,3,4}
function cryoBlaster.onDrawNPC(v)
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]

	--Setup code by Mal8rk
	local pivotOffsetX = 0
	local pivotOffsetY = 0

	local opacity = 1

	local priority = 1
	if lowPriorityStates[v:mem(0x138,FIELD_WORD)] then
		priority = -75
	elseif v:mem(0x12C,FIELD_WORD) > 0 then
		priority = -30
	elseif config.foreground then
		priority = -125
	end

	--Text.print(v.x, 8,8)
	--Text.print(data.timer, 8,32)

	if v:mem(0x156,FIELD_WORD) > 0 then
		opacity = math.sin(lunatime.tick()*math.pi*0.25)*0.1 + 0.9
	end

	if data.shurikenDisplay then
		local img = config.prop1Image

		Graphics.drawBox{
			texture = img,
			x = v.x+config.prop1OffsetX + config.gfxoffsetx,
			y = v.y+config.prop1OffsetY + config.gfxoffsety,
			width = -img.width,
			sourceY = 0,
			sourceHeight = config.prop1Height,
			sceneCoords = true,
			centered = true,
			priority = -45.1,
			rotation = data.prop1rotation,
		}

		local img = config.prop2Image
		
		Graphics.drawBox{
			texture = img,
			x = v.x+config.prop2OffsetX + config.gfxoffsetx,
			y = v.y+config.prop2OffsetY + config.gfxoffsety,
			width = -img.width,
			sourceY = 0,
			sourceHeight = config.prop2Height,
			sceneCoords = true,
			centered = true,
			priority = -45.2,
			rotation = data.prop2rotation,
		}
	end

	npcutils.hideNPC(v)
end

--Gotta return the library table!
return cryoBlaster
