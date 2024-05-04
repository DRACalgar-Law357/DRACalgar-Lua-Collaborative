--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local colliders = require("colliders")
local sprite

--Create the library table
local guy = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local guySettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 42,
	width = 32,
	height = 32,
	frames = 14,
	framestyle = 1,
	framespeed = 8,
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi = false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(guySettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=npcID,
		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Register events
function guy.onInitAPI()
	npcManager.registerEvent(npcID, guy, "onTickEndNPC")
	npcManager.registerEvent(npcID, guy, "onDrawNPC")
end

function guy.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local config = NPC.config[v.id]
	local data = v.data
	v.dontMove = false
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		data.changeTimer = 16
		data.rotation = nil
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 0
	end
	
	if data.changeTimer == nil then
		data.changeTimer = data.changeTimer or 16
	end

	if not data.rotation then
		data.rotation = 0
	end
	
	if v.ai2 == 0 then
		v.ai2 = 752
	end
	
	if v:mem(0x12C, FIELD_WORD) == 0 then
		data.timer = data.timer + 1
	end
		data.rotation = ((data.rotation or 0) + math.deg((v.speedX*config.speed)/((v.width+v.height)/4)))
		for _,p in ipairs(NPC.getIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1)) do
			if p:mem(0x12A, FIELD_WORD) > 0 and p:mem(0x138, FIELD_WORD) == 0 and v:mem(0x138, FIELD_WORD) == 0 and (not p.isHidden) and (not p.friendly) and p:mem(0x12C, FIELD_WORD) == 0 and p.idx ~= v.idx and v:mem(0x12C, FIELD_WORD) == 0 and NPC.HITTABLE_MAP[p.id] then
				p:harm(HARM_TYPE_HELD)
				v:harm(HARM_TYPE_HELD)
			end
		end
		if v:mem(0x138, FIELD_WORD) == 0 then
			for _,p in ipairs(Player.getIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1)) do
				if data.timer >= 32 then
					v:harm(HARM_TYPE_HELD)
				end
			end
			if v.collidesBlockLeft or v.collidesBlockRight then
				v:harm(HARM_TYPE_HELD)
			end
			
			data.destroyCollider = data.destroyCollider or colliders.Box(v.x - 1, v.y + 1, v.width + 1, v.height - 1);
			data.destroyCollider.x = v.x + 0.5 * (2/v.width) * v.direction;
			
			local list = colliders.getColliding{
			a = data.destroyCollider,
			btype = colliders.BLOCK,
			filter = function(other)
				if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
					return false
				end
				return true
			end
			}
			for _,b in ipairs(list) do		
				b:hit(true)	
			end
		end
		if v.collidesBlockBottom and v:mem(0x138, FIELD_WORD) == 0 and v:mem(0x12C, FIELD_WORD) == 0 then
			if v.speedX >= -3 and v.direction == DIR_LEFT or v.speedX <= 3 and v.direction == DIR_RIGHT then
				data.changeTimer = data.changeTimer - 1
				if data.changeTimer <= 0 then
					data.timer = 0
					data.changeTimer = 16
					v:transform(v.ai2)
					v.speedX = 0
				end
			end
		else
			data.changeTimer = 16
		end
end

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

	sprite.pivot = args.pivot or Sprite.align.CENTER
	sprite.rotation = args.rotation or 0

	if args.texture ~= nil then
		sprite.texpivot = args.texpivot or sprite.pivot or Sprite.align.CENTER
		sprite.texscale = args.texscale or vector(args.texture.width*(args.width/args.sourceWidth),args.texture.height*(args.height/args.sourceHeight))
		sprite.texposition = args.texposition or vector(-args.sourceX*(args.width/args.sourceWidth)+((sprite.texpivot[1]*sprite.width)*((sprite.texture.width/args.sourceWidth)-1)),-args.sourceY*(args.height/args.sourceHeight)+((sprite.texpivot[2]*sprite.height)*((sprite.texture.height/args.sourceHeight)-1)))
	end

	sprite:draw{priority = args.priority,color = args.color,sceneCoords = args.sceneCoords or args.scene}
end

function guy.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	v.animationFrame = v.ai1
	
	if v.speedX == 0 and v.collidesBlockBottom then
		data.rotation = 0
	end

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation or data.rotation == 0 then return end

	local priority = -45
	if config.priority then
		priority = -15
	end

	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety + 2,
		width = config.gfxwidth,height = config.gfxheight,

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = priority,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}

	npcutils.hideNPC(v)
end

--Gotta return the library table!
return guy