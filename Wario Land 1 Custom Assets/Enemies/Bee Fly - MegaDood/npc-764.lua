--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxwidth = 48,
	gfxheight = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 48,
	height = 32,
	--Frameloop-related
	frames = 4,
	framestyle = 1,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	speed = 1,
	luahandlesspeed = true, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = true,
	staticdirection = true, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = false,
	noiceball = false,
	noyoshi= false, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	
	--Various interactions
	jumphurt = false, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	
	coinID = 844,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=npcID,
		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

local STATE_SIT = 0
local STATE_FLY = 1
local STATE_HIT = 2

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = 0
		data.state = STATE_SIT
		data.fleeCollider = Colliders.Circle(v.x, v.y, v.width * 2, v.height * 2)
	end
	
	data.fleeCollider.x = v.x + v.width * 0.5
	data.fleeCollider.y = v.y + v.height * 0.5

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		data.state = 1
		if not v.isProjectile then
			data.timer = 0
		end
	end
	
	if data.state == STATE_SIT then
	
		v.animationFrame = math.floor(lunatime.tick() / 8) % 2 + ((v.direction + 1) * sampleNPCSettings.frames * 0.5)
		
		for _,p in ipairs(Player.get()) do
			if Colliders.collide(p, data.fleeCollider) and not (p.keys.down and p.powerup > 1) then
				if p.x < v.x then v.direction = 1 else v.direction = -1 end
				data.state = 1
			end
			
			if Colliders.collide(p, v) or Defines.earthquake >= 3 then data.state = STATE_FLY end
		end
			
	elseif data.state == STATE_FLY then
		v.noblockcollision = true
		v.animationFrame = math.floor(lunatime.tick() / 6) % 2 + 2 + ((v.direction + 1) * sampleNPCSettings.frames * 0.5)
		v.speedX = 4 * v.direction
		data.timer = data.timer + 0.25
		v.speedY = math.clamp(-data.timer, -8, 0)
	else
		v.friendly = true
		v.animationFrame = 2 + ((v.direction + 1) * sampleNPCSettings.frames * 0.5)
		data.timer = data.timer + 1
		v.speedX = 0
		v.speedY = -Defines.npc_grav
		if data.timer >= 32 then
			local n = NPC.spawn(sampleNPCSettings.coinID, v.x, v.y, player.section, false)
			n.speedX = 2 * -v.direction
			n.speedY = -5
			n.ai1 = 1
			v:kill(HARM_TYPE_NPC)
		end
	end
end

function sampleNPC.onNPCHarm(e, v, r, c)
	if v.id ~= npcID then return end
	local data = v.data
	if r == HARM_TYPE_JUMP or r == HARM_TYPE_SPINJUMP then
		if data.state ~= STATE_HIT then
			data.timer = 0
			data.state = STATE_HIT
			SFX.play(2)
		end
		e.cancelled = true
	end
end

--Gotta return the library table!
return sampleNPC