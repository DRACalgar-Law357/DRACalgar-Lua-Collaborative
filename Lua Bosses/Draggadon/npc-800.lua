--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
--Create the library table
local draglet = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local dragletSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 5,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 0.8,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = true,
	--iswaternpc = false,
	--isshell = false,
	staticdirection = true,
	luahandlesspeed = true,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(dragletSettings)

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
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=10,
		[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below

local STATE_WAIT = 0
local STATE_PREP = 1
local STATE_SPIT = 2

--Register events
function draglet.onInitAPI()
	npcManager.registerEvent(npcID, draglet, "onTickEndNPC")
end

local function facePlayer(v)
	if (player.x + player.width) < v.x then
		v.direction = -1
	elseif player.x > (v.x + v.width) then
		v.direction = 1
	end
end	

function draglet.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local cfg = NPC.config[v.id]
	
	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_WAIT
		data.timer = data.timer or 0
		data.sinTimer = data.sinTimer or 0
		data.spit = false
		data.frame = 0
	end

	
	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end

	data.sinTimer = data.sinTimer + 1

	v.speedY = math.cos(data.sinTimer * 0.05) * 0.5
	
	v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = data.frame})
	
	--Text.print(data.state, 10, 10)
	--Text.print(data.timer, 10, 30)
	
	if data.state == STATE_WAIT then
		v.speedX = cfg.speed * v.direction
		
		facePlayer(v)
		
		--Animation
		if lunatime.tick() % 14 < 7 then
			data.frame = 0
		elseif lunatime.tick() % 14 < 15 then
			data.frame = 1
		end
		
		if not v.friendly then
			data.timer = data.timer + 1
			
			if data.timer >= 100 then
				data.state = STATE_PREP
				data.timer = 0
			end
		end
	end
	
	if data.state == STATE_PREP then
		data.timer = data.timer + 1
		
		v.speedX = 0.3 * v.direction
		
		facePlayer(v)
		
		--Animation
		if lunatime.tick() % 14 < 7 then
			data.frame = 2
		elseif lunatime.tick() % 14 < 15 then
			data.frame = 3
		end
		
		if data.timer >= 50 then
			data.state = STATE_SPIT
			data.timer = 0
			facePlayer(v)
		end
	end
	
	if data.state == STATE_SPIT then
		data.timer = data.timer + 1
		
		--v.speedX = 0
		
		if lunatime.tick() % 10 < 17 then
			data.frame = 4
		end
		
		if not data.spit then
			if v.direction == -1 then
				local n = NPC.spawn(414, v.x - 20, v.y)
			elseif v.direction == 1 then
				local n = NPC.spawn(414, v.x + 20, v.y)
			end
			
			SFX.play(18)
			data.spit = true
		end
		
		if data.timer >= 15 then
			data.state = STATE_WAIT
			data.timer = 0
			data.spit = false
		end
	end
end

--Gotta return the library table!
return draglet