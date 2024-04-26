--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local wario = require("warioLand1NPC")

--Create the library table
local stabbyPete = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local stabbyPeteSettings = {
	id = npcID,
	gfxwidth = 72,
	gfxheight = 48,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 40,
	height = 40,
	--Frameloop-related
	frames = 9,
	framestyle = 1,
	framespeed = 6, -- number of ticks (in-game frames) between animation frame changes
	
	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = false, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = false, -- The player can walk on the NPC.

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	
	speed = 1.1,
	cliffturn = true,
	luahandlesspeed = true,
	
	--Wario Land specific
	transformID = npcID + 1, --The NPC to transform into when either getting stunned or transfortming back
	throwID = npcID + 2,
	bigEnemy = true, --If big, you move slower when holding it and it dies when it hits a wall when thrown
	
}

--Applies NPC settings
npcManager.setNpcSettings(stabbyPeteSettings)

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

function stabbyPete.onInitAPI()
	npcManager.registerEvent(npcID, stabbyPete, "onTickNPC")
	npcManager.registerEvent(npcID, stabbyPete, "onDrawNPC")
end

local STATE_WALK = 0
local STATE_PREPARE = 1
local STATE_THROWN = 2

local detectOffset = {
[-1] = -stabbyPeteSettings.width * 8,
[1] = 0
}

function stabbyPete.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[npcID]

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.leeway = 0
		data.turnTimer = 0
		data.initialized = true
		data.timer = 0
		data.state = 0
		data.detectBox = Colliders.Box(v.x, v.y, v.width * 8, v.height *3)
	end
	
	data.detectBox.x = v.x + detectOffset[v.direction]
	data.detectBox.y = v.y - v.height * 2
	
	data.timer = data.timer + 1
	
	for _,p in ipairs(Player.get()) do
		if data.isBumped and Colliders.collide(v,p) and (p.character ~= 7 and p.character ~= 8) then
			p:harm()
			data.isBumped = nil
		end
	end
	
	-- Main AI
	if data.state == 0 then
		if v.collidesBlockBottom and (not v.isProjectile) and data.turnTimer <= 0 then
			v.speedX = config.speed * v.direction
		end
		
		if data.turnTimer <= 0 and data.leeway > 0 then -- data.leeway is needed to prevent the npc from re-initating the pause whenever unpausing from a ledge
			data.leeway = data.leeway - 1
		end
		
		if v:mem(0x120, FIELD_BOOL) and data.turnTimer <= 0 and data.leeway <= 0 then -- initiates pausing when hitting a wall or ledge
			data.leeway = 12
			data.turnTimer = 64
		end
		
		if data.turnTimer > 0 then -- does the pausing of the npc
			v.speedX = 0
			data.turnTimer = data.turnTimer - 1
			return
		end
		
		--Prepare the knife
		if data.timer >= 48 then
			for _,p in ipairs(Player.get()) do
				if Colliders.collide(p, data.detectBox) then
					data.timer = 0
					data.state = 1
					v.speedX = 0
				end
			end
		end
	elseif data.state == 1 then
		--Stand in place and play a sound
		if data.timer % 2 == 0 then
			SFX.play("Aim.wav")
		end
		if data.timer >= 64 then
			data.state = 2
			data.timer = 0
		end
	else
		--Wait for a bit to start walking again
		if data.timer == 17 then
			SFX.play(25)
			local n = NPC.spawn(NPC.config[npcID].throwID, v.x, v.y + v.height / 4)
			n.direction = v.direction
			n.speedX = 6 * n.direction
			n.friendly = v.friendly
		elseif data.timer == 24 then
			data.timer = 0
			data.state = 0
		end
	end
end

function stabbyPete.onDrawNPC(v)
	if not v.data.initialized then return end
	local data = v.data
	--Animation stuff
	if v.data.turnTimer > 0 then
		v.animationFrame = 0 + ((v.direction + 1) * NPC.config[npcID].frames / 2)
	else
		if data.state == 0 then
			v.animationFrame = math.floor(data.timer / 6) % 4 + ((v.direction + 1) * NPC.config[npcID].frames / 2)
		elseif data.state == 1 then
			v.animationFrame = math.floor(data.timer / 6) % 2 + 4 + ((v.direction + 1) * NPC.config[npcID].frames / 2)
		else
			v.animationFrame = math.floor(data.timer / 8) % 3 + 6 + ((v.direction + 1) * NPC.config[npcID].frames / 2)
		end
	end
end

--Gotta return the library table!
return stabbyPete