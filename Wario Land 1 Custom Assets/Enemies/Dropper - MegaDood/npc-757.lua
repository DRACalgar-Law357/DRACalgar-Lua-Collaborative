--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local wario = require("warioLand1NPC")

--Create the library table
local dropper = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local dropperSettings = {
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Frameloop-related
	frames = 5,
	framestyle = 0,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes
	
	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = false, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = false, -- The player can walk on the NPC.

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	noblockcollision = false,
	
	speed = 0.6,
	luahandlesspeed = true,
	
	--Wario Land specific
	transformID = npcID + 1, --The NPC to transform into when either getting stunned or transfortming back
	bigEnemy = false, --If big, you move slower when holding it and it dies when it hits a wall when thrown
	cantPush = true, --If true, Wario and Bowser cannot push this enemy around
	
}

--Applies NPC settings
npcManager.setNpcSettings(dropperSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=npcID - 1,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

wario.register(npcID)

function dropper.onInitAPI()
	npcManager.registerEvent(npcID, dropper, "onTickNPC")
	npcManager.registerEvent(npcID, dropper, "onDrawNPC")
end

local STATE_WALK = 0
local STATE_DROP = 1

local offset = {
[-1] = 0,
[1] = dropperSettings.width,
}

function dropper.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[npcID]

	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		if data.dontMove then v.dontMove = true end
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.turnTimer = 0
		data.initialized = true
		data.state = 0
		data.blockDetect = data.blockDetect or Colliders.Box(v.x, v.y, v.width / 4, v.height)
		if v.dontMove then data.dontMove = true end
	end
	
	data.blockDetect.x = v.x + offset[v.direction]
	data.blockDetect.y = v.y - 24
	
	--Harm the player cause it spikey
	for _,p in ipairs(Player.get()) do
		if Colliders.collide(p, v) and (p.y >= v.y - 32 or p.speedY <= 0) then
			p:harm()
		end
		--Detect a player and fall
		if math.abs(p.x - v.x) <= 48 and data.state == 0 then
			data.state = 1
			v.speedX = 0
		end
	end
	
	-- Main AI
	if data.state == 0 then
	
		--Walk left and right
		v.speedX = NPC.config[npcID].speed * v.direction
		v.y = v.spawnY
		
		 -- Interact with blocks, to simulate noblockcollision on the ceiling
		local tbl = Block.SOLID .. Block.PLAYER
		local list = Colliders.getColliding{
		a = data.blockDetect,
		b = tbl,
		btype = Colliders.BLOCK,
		filter = function(other)
			if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
				return false
			end
			return true
		end
		}
		data.noTurn = nil
		for _,b in ipairs(list) do
			data.noTurn = true
		end
		
		if not data.noTurn then v.direction = -v.direction end
		
		data.timer = data.timer or 0
		data.timer = data.timer + 1
		if v.data._settings.delay ~= 0 and data.timer >= v.data._settings.delay then
			v.direction = -v.direction
			data.timer = 0
		end
		
	elseif data.state == 1 then
		--Fall down and turn into a stunned version when it lands
		v.speedY = v.speedY + Defines.npc_grav
		if v.collidesBlockBottom then
			v:transform(config.transformID)
			v.dontMove = false
		end
	end
	
end

function dropper.onDrawNPC(v)
	if not v.data.initialized then return end
	local data = v.data
	--Animation stuff
	if data.state == 0 then
		if not v.dontMove then
			v.animationFrame = math.floor(lunatime.tick() / 6) % 3
		else
			v.animationFrame = 2
		end
	else
		v.animationFrame = math.floor(lunatime.tick() / 8) % 2 + 3
	end
end

--Gotta return the library table!
return dropper