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
	gfxoffsety = 4,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 24,
	height = 24,
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
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--[[************************
Rotation code by MrDoubleA
**************************]]

local function drawSprite(args) -- handy function to draw sprites
	args = args or {}

	args.sourceWidth  = args.sourceWidth  or args.width
	args.sourceHeight = args.sourceHeight or args.height

	if sprite == nil then
		sprite = Sprite.box{texture = args.texture}
	else
		sprite.texture = args.texture
	end

	sprite.x,sprite.y = args.x,args.y
	sprite.width,sprite.height = args.width,args.height

	sprite.pivot = args.pivot or Sprite.align.TOPLEFT
	sprite.rotation = args.rotation or 0

	if args.texture ~= nil then
		sprite.texpivot = args.texpivot or sprite.pivot or Sprite.align.TOPLEFT
		sprite.texscale = args.texscale or vector(args.texture.width*(args.width/args.sourceWidth),args.texture.height*(args.height/args.sourceHeight))
		sprite.texposition = args.texposition or vector(-args.sourceX*(args.width/args.sourceWidth)+((sprite.texpivot[1]*sprite.width)*((sprite.texture.width/args.sourceWidth)-1)),-args.sourceY*(args.height/args.sourceHeight)+((sprite.texpivot[2]*sprite.height)*((sprite.texture.height/args.sourceHeight)-1)))
	end

	sprite:draw{priority = args.priority,color = args.color,sceneCoords = args.sceneCoords or args.scene}
end

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
end

function sampleNPC.onTickEndNPC(v)
	local config = NPC.config[v.id]
	local data = v.data
	local settings = v.data._settings

	v.animationFrame = 0
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.rotation = nil
		return
	end
	
	if settings.spread == nil then settings.spread = 3 end

	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		return
	end

	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 0
	end

	if not data.rotation then
		data.rotation = 0
	end
	
	data.timer = data.timer + 1
	if data.timer == 3 then 
		Effect.spawn(npcID, v.x + math.random(-6, 6), v.y + math.random(-6, 6))
		data.timer = 0
	end
	
	data.rotation = ((data.rotation or 0) + math.deg((v.speedX*config.speed)/((v.width+v.height)/4)))
	if v.collidesBlockBottom then
		for _,npc in ipairs (NPC.getIntersecting(v.x - 8, v.y - 8, v.x + v.width + 8, v.y + v.height + 8)) do
			if npc.id == npcID + 1 then
				break
			else
				for i = 0,settings.spread - 1 do
					local g = i * 32
					local n = NPC.spawn(npcID + 1,(v.x + g - 4) - (settings.spread * 16 - 16), v.y - 8, player.section, false)
					if settings.spread == 1 then
						n.ai1 = 3
					else
						if i == 0 then
							n.ai1 = 0
						elseif i == settings.spread - 1 then
							n.ai1 = 2
						else
							n.ai1 = 1
						end
					end
				end
			end
		end
		Effect.spawn(npcID + 1, v.x - 36, v.y + 26)
		v:kill(HARM_TYPE_OFFSCREEN)
		SFX.play(72)
	end
end

function sampleNPC.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation or data.rotation == 0 then return end

	local priority = -45
	if config.priority then
		priority = -15
	end

	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth,height = config.gfxheight,

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = priority,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}

	npcutils.hideNPC(v)
end

return sampleNPC