--[[

	Written by MrDoubleA
	Please give credit!
	
	Credit to Novarender for helping with the logic for the movement of the bullets

	Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local bullet = {}
local npcID = NPC_ID

local deathEffectID = (npcID-3)

local bulletSettings = {
	id = npcID,
	
	gfxwidth = 42,
	gfxheight = 42,

	gfxoffsetx = 0,
	gfxoffsety = 5,
	
	width = 32,
	height = 32,
	
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	lifetime = 448,
}

npcManager.setNpcSettings(bulletSettings)
npcManager.registerDefines(npcID,{NPC.UNHITTABLE})


--- Custom Explosion Stuff ---
function bullet.onInitAPI()
	registerEvent(bullet,"onPostExplosion")
	npcManager.registerEvent(npcID, bullet, "onTickEndNPC")
	npcManager.registerEvent(npcID, bullet, "onDrawNPC")
end

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

function bullet.onTickEndNPC(v)
    if Defines.levelFreeze then return end
    
    local config = NPC.config[v.id]
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.timer = nil
		return
	end

	if not data.timer then
        data.timer = 0

        data.belongsToPlayer = false
    end


	if v:mem(0x12C,FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136,FIELD_BOOL)        --Thrown
	or v:mem(0x138,FIELD_WORD) > 0    --Contained within
    then
        if v:mem(0x12C,FIELD_WORD) > 0 then
            data.belongsToPlayer = true
        elseif data.belongsToPlayer then
            v:mem(0x136,FIELD_BOOL,false)
        end

		data.rotation = 0
        return
    end

	local tbl = Block.SOLID .. Block.PLAYER
	collidingBlocks = Colliders.getColliding {
		a = v,
		b = tbl,
		btype = Colliders.BLOCK
	}

	if #collidingBlocks > 0 then --Not colliding with something
		v:kill()
		Effect.spawn(10,v.x,v.y)
	end

	data.rotation = (data.rotation or 0) + v.ai3
end

function bullet.onDrawNPC(v)
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

return bullet