--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local wario = require("warioLand1NPC")

--Create the library table
local crab = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local crabSettings = {
	id = npcID,
	gfxwidth = 50,
	gfxheight = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 2,
	--Frameloop-related
	frames = 5,
	framestyle = 1,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes
	
	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = false, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = false, -- The player can walk on the NPC.

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	jumphurt = true,
	
	speed = 1,
	cliffturn = true,
	luahandlesspeed = true,
	
	--Wario Land specific
	transformID = npcID + 1, --The NPC to transform into when either getting stunned or transfortming back
	bigEnemy = false, --If big, you move slower when holding it and it dies when it hits a wall when thrown
	cantPush = true,
	
}

--Applies NPC settings
npcManager.setNpcSettings(crabSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
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

function crab.onInitAPI()
	npcManager.registerEvent(npcID, crab, "onTickEndNPC")
end
	
function crab.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[npcID]

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.leeway = 0
		data.turnTimer = 0
		data.timer = 0
		data.initialized = true
	end	
	
	-- Main AI
	if v.collidesBlockBottom and (not v.isProjectile) and data.turnTimer <= 0 then
		v.speedX = config.speed * v.direction
	end
	
	v.animationFrame = math.floor(data.timer / 6) % 4 + ((v.direction + 1) * NPC.config[v.id].frames / 2)
	
	data.timer = data.timer + 1
	
	for _,p in ipairs(Player.get()) do
		if Colliders.collide(v,p) then 
			if (p.character ~= 7 and p.character ~= 8) then
				if p:mem(0x50, FIELD_BOOL) then
					Colliders.bounceResponse(p)
				else
					p:harm()
				end
			else
				if ((p.x >= v.x + v.width / 4 and v.direction == -1) or (p.x <= v.x - v.width / 4 and v.direction == 1)) and (v.animationFrame ~= 4 and v.animationFrame ~= 9) and p.deathTimer <= 0 then
					v:transform(config.transformID)
					SFX.play(9)
					v.speedX = -5 * math.sign(p.x + p.width/2 - v.x - v.width/2)
					v.speedY = -2
				else
					p:harm()
				end
			end
		end
	end
	
	if data.turnTimer <= 0 and data.leeway > 0 then -- data.leeway is needed to prevent the npc from re-initating the pause whenever unpausing from a ledge
		data.leeway = data.leeway - 1
		if data.leeway == 11 then
			v.animationFrame = 4 + ((v.direction + 1) * NPC.config[v.id].frames / 2)
		end
		data.timer = 0
	end
	
	if v:mem(0x120, FIELD_BOOL) and data.turnTimer <= 0 and data.leeway <= 0 then -- initiates pausing when hitting a wall or ledge
		data.leeway = 12
		data.turnTimer = 80
	end
	
	if data.turnTimer > 0 then -- does the pausing of the npc
		v.speedX = 0
		data.turnTimer = data.turnTimer - 1
		if data.turnTimer >= 40 then
			v.animationFrame = 0 + ((v.direction + 1) * NPC.config[v.id].frames / 2)
		else
			v.animationFrame = 4 + ((v.direction + 1) * NPC.config[v.id].frames / 2)
		end
	end
	
end

--Gotta return the library table!
return crab