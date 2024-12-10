--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local wario = require("warioLand1NPC")

--Create the library table
local goom = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local goomSettings = {
	id = npcID,
	gfxwidth = 64,
	gfxheight = 34,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 2,
	--Frameloop-related
	frames = 2,
	framestyle = 1,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes
	
	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = false, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = false, -- The player can walk on the NPC.

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	noblockcollision = true,
	
	speed = 2,
	luahandlesspeed = true,
	
	--Wario Land specific
	transformID = npcID + 1, --The NPC to transform into when either getting stunned or transfortming back
	bigEnemy = false, --If big, you move slower when holding it and it dies when it hits a wall when thrown
	
}

--Applies NPC settings
npcManager.setNpcSettings(goomSettings)

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

function goom.onInitAPI()
	npcManager.registerEvent(npcID, goom, "onTickNPC")
end
	
function goom.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.hurtBox = Colliders.Box(v.x, v.y, 16, v.height)
	end
	
	data.hurtBox.x = v.x - 16 + ((v.direction + 1) * ((v.width / 2) + 8))
	data.hurtBox.y = v.y
	
	--Interaction with the player
	for _,p in ipairs(Player.get()) do
		if not data.forceBumpState then
			if (p.character == 7 or p.character == 8) then
				if p.y > v.y + v.height * 0.5 and p.y < v.y + v.height + 8  then
					data.forceBumpState = true
					v.speedY = -6
				else
					data.forceBumpState = false
				end
			end
		else
			v.speedX = 0
			v.speedY = v.speedY + Defines.npc_grav
			if Colliders.collide(p, v) then
				data.forceBumpState = false
				v:transform(config.transformID)
				SFX.play(9)
			end
		end
		
		--Follow the player
		if math.abs(v.y - p.y) <= 8 then
			v.speedY = 0
		else
			v.speedY = 1 * math.clamp(p.y - v.y, -1, 1)
		end
		
		--Hurt the player if they touch the spike
		if Colliders.collide(p, data.hurtBox) and not v.friendly and not v.isHidden then
			if p.y < data.hurtBox.y and p:mem(0x50, FIELD_BOOL) and p.deathTimer <= 0 then
				SFX.play(2)
				Colliders.bounceResponse(p)
			else
				p:harm()
			end
		end
		
	end
	
	v.speedX = config.speed * v.direction
end

--Gotta return the library table!
return goom