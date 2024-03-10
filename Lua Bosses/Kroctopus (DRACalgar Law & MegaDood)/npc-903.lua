--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 374,
	gfxheight = 208,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 256,
	height = 160,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 4,
	framestyle = 0,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	foreground = false, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- LOGIC
	--Movement speed. Only affects speedX by default.
	speed = 1,
	luahandlesspeed = false, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = true,
	cliffturn = false, -- Makes the NPC turn on ledges
	staticdirection = false, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = false, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = false, -- The player can walk on the NPC.

	nohurt=false, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	noblockcollision = true,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC

	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	nowalldeath = false, -- If true, the NPC will not die when released in a wall
	grabside=false,
	grabtop=false,
	health = 9,
	clawID = 904,
	targetSet = 0 --0 preset position, 1 player position
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below

local STATE_PHASE0 = 0
local STATE_PHASE1 = 1
local STATE_PHASE2 = 2
local STATE_SUBMERGE = 3
local STATE_KILL = 4
local STATE_HURT = 5

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	data.clawPosition = {
		--Center
		[0] = vector.v2(
			v.x + v.width / 2,
			v.y - 48
			),
		--Left
		[1] = vector.v2(
			v.x,
			v.y + v.height / 2 - 64
			),
		--Right
		[2] = vector.v2(
			v.x + v.width,
			v.y + v.height / 2 - 64
			),
	}
	data.clawTimer = {
		[0] = 0,
		[1] = 0,
		[2] = 0,
	}
	data.clawState = {
		[0] = 0,
		[1] = 0,
		[2] = 0,
	}
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
		data.bossColour = 0
		data.phase = 0
		data.hp = NPC.config[v.id].health
		data.state = 0
		data.claw = {
			--Claw Pincers
			[0] = NPC.spawn(sampleNPCSettings.clawID,data.clawPosition[0].x,data.clawPosition[0].y,v.section,true,true),
			[1] = NPC.spawn(sampleNPCSettings.clawID,data.clawPosition[1].x,data.clawPosition[1].y,v.section,true,true),
			[2] = NPC.spawn(sampleNPCSettings.clawID,data.clawPosition[2].x,data.clawPosition[2].y,v.section,true,true),
		}
		data.claw[0]:mem(0x124, FIELD_BOOL, true)
		data.claw[0].data.parent = v
		data.claw[0].data.rotation = 0
		data.claw[1]:mem(0x124, FIELD_BOOL, true)
		data.claw[1].data.parent = v
		data.claw[1].data.rotation = -45
		data.claw[2]:mem(0x124, FIELD_BOOL, true)
		data.claw[2].data.parent = v
		data.claw[2].data.rotation = 45
	end

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		v:kill(HARM_TYPE_OFFSCREEN)
	end

	for i=0,2 do
		if data.claw[i] and data.claw[i].isValid then
			data.claw[i].spawnPositionX = data.clawPosition[i].x
			data.claw[i].spawnPositionY = data.clawPosition[i].y
			data.claw[i].state = data.claw[i].state
			data.claw[i].timer = data.claw[i].timer
			if data.claw[i].clawOffsetX and data.claw[i].clawOffsetY then
				data.claw[i].x = data.clawPosition[i].x - data.claw[i].width/2 + data.claw[i].clawOffsetX
				data.claw[i].y = data.clawPosition[i].y - data.claw[i].height/2 + data.claw[i].clawOffsetY
			end
			if data.claw[i].state and data.claw[i].state > 0 then
				data.claw[i].timer = data.claw[i].timer + 1
			end
		end
	end
	if data.claw[0] then
		Text.print(data.claw[0].state,110,110)
		Text.print(data.claw[0].timer,110,126)
	end
	if data.state == STATE_SUBMERGE or data.state == STATE_KILL or data.state == STATE_HURT then
		v.friendly = true
		for i=0,2 do
			if data.claw[i] and data.claw[i].isValid then
				data.claw[i].friendly = true
			end
		end
	else
		v.friendly = false
		for i=0,2 do
			if data.claw[i] and data.claw[i].isValid then
				data.claw[i].friendly = false
			end
		end
	end
	data.timer = data.timer + 1
	
	v.animationFrame = data.bossColour
	data.eyeFrame = v.animationFrame
	
	if data.state == STATE_PHASE0 then
		--Stuff that controls the arms to attack where the player is, if towards the middle it uses its middle arm, if left or right it uses its left or right arm, and if below it uses its left or right bottom arm
		if data.timer % 160 == 80 then
			if data.claw[0] and data.claw[0].isValid and data.claw[0].state and data.claw[0].state < 1 then
				data.claw[0].state = 1
			end
		end
	elseif data.state == STATE_PHASE1 then
		--Same as phase 1, just modify the arms to move a bit faster
	elseif data.state == STATE_PHASE2 then
		--Same as phase 2, but always make the middle arm move
	elseif data.state == STATE_SUBMERGE then
		--Go underwater for a bit then come back up
	elseif data.state == STATE_KILL then
		--Fancy death animation that MegaDood will do
		for i=0,2 do
			if data.claw[i] and data.claw[i].isValid and data.claw[i].state ~= 4 then
				data.claw[i].state = 4
			end
		end
	else
		--Hurt animation and retract claws
		for i=0,2 do
			if data.claw[i] and data.claw[i].isValid and data.claw[i].state ~= 4 then
				data.claw[i].state = 4
			end
		end
		if data.timer >= 120 then
			data.timer = 0
			data.state = STATE_PHASE0
			for i=0,2 do
				if data.claw[i] and data.claw[i].isValid and data.claw[i].state ~= 0 then
					data.claw[i].state = 0
				end
			end
		end
	end
	if data.hp > config.health*2/3 then
		data.phase = 0
	elseif data.hp <= config.health*2/3 and data.hp > config.health*1/3 then
		data.phase = 1
	else
		data.phase = 2
	end
	if data.state == STATE_HURT or data.state == STATE_KILL then
		data.bossColour = 3
	else
		data.bossColour = data.phase
	end
	Text.print(data.hp,110,200)
end

local cornea = Graphics.loadImageResolved("kroctopus_eyes.png")
local pupil = Graphics.loadImageResolved("kroctopus_pupils.png")

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
	if v.id ~= npcID then return end
	local data = v.data
	
	eventObj.cancelled = true
	if v:mem(0x156, FIELD_WORD) <= 0 then
		data.hp = data.hp - 1
		SFX.play(39)
		v:mem(0x156, FIELD_WORD,25)
		if data.hp <= 0 then
			data.state = 4
			data.timer = 0
			return
		else
			data.state = 5
			data.timer = 0
		end
	end
	--[[Increment data.hp by 1 when the boss is hit 3 times
	if parent.data.hp % 2 == 1 and parent.data.hp > 1 then
		parent.data.bossColour = parent.data.bossColour + 1
	end]]
end

function sampleNPC.onDrawNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end

	--Render the boss in the background so it can hide underwater and stuff
	if not v.isHidden then
		npcutils.drawNPC(v,{priority = -75})
		npcutils.hideNPC(v)
	end

	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)

	if not data.initialized then return end
	--Draw the cornea
	data.eyeFrames = data.eyeFrames or Sprite{texture = cornea, frames = 4}
	data.eyeFrames.position = vector(v.x - 59, v.y - 48)
	data.eyeFrames:draw{sceneCoords = true, frame = data.eyeFrame, priority = -77}
	
	--Draw the pupils and have them track the player's position
	data.pupilFrames = data.pupilFrames or Sprite{texture = pupil, frames = 1}
	data.w = math.pi/65
	data.xTimer = (v.x - plr.x) / 4
	data.yTimer = (v.y - plr.y) / 4
	if data.xTimer >= 0 then data.xTimer = 0 elseif data.xTimer <= -70 then data.xTimer = -70 end
	if data.yTimer >= 48 then data.yTimer = 48 elseif data.yTimer <= -38 then data.yTimer = -38 end
	if not (data.state == STATE_KILL or data.state == STATE_HURT) then
		data.pupilFrames.position = vector(v.x - 67+v.width/2 + 100 * -data.w * math.cos(data.w*data.xTimer), v.y + 44 + 100 * -data.w * math.sin(data.w*data.yTimer))
		data.pupilFrames:draw{sceneCoords = true, frame = 1, priority = -77}
		data.pupilFrames.position = vector(v.x + 46+v.width/2 + 100 * -data.w * math.cos(data.w*data.xTimer), v.y + 44 + 100 * -data.w * math.sin(data.w*data.yTimer))
		data.pupilFrames:draw{sceneCoords = true, frame = 1, priority = -77}
	end
end

--Gotta return the library table!
return sampleNPC