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
	centerRange = 384,
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

local function clawCheck(v)
	local data = v.data
	for i=0,2 do
		if data.claw[i] and data.claw[i].isValid and data.claw[i].state and data.claw[i].state < 1 then
			data.clawChecks = data.clawChecks + 1
		end
	end
	if data.clawChecks >= 3 then
		data.clawChecks = 0
		return true
	else
		data.clawChecks = 0
		return false
	end
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

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

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = 0
		--Used to make the corneas of the boss animate correctly and make the claws display correctly
		data.bossColour = 0
		--Tracks the phase, for use with the claw to increase its speed after 3 hits and to actually change into a different phase once it submerges
		data.trackPhase = 0
		--The colour of the boss, counts separately to its actual battle phase
		data.saveColour = data.bossColour
		--Boss's hit points
		data.hp = NPC.config[v.id].health
		--Progress of the fight
		data.state = 0
		--Checks if all three claws are idling
		data.clawChecks = 0
		
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
	Text.print(data.hp,110,110)
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
	if data.state > 2 then
		if data.state ~= STATE_HURT then
			v.friendly = true
		else
			v.friendly = false
		end
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
		if data.timer % 120 == 60 and clawCheck(v) then
			--Phase 1 (0) and 2 (1). It'd direct its one claw at the player
			local clawDirect1
			local clawDirect2
			local clawDirect3

			if data.trackPhase < 2 then
				if plr.x <= v.x + v.width/2 - config.centerRange/2 then
					clawDirect = 1
				elseif plr.x >= v.x + v.width/2 + config.centerRange/2 then
					clawDirect = 2
				else
					clawDirect = 0
				end
				if data.claw[clawDirect] and data.claw[clawDirect].isValid and data.claw[clawDirect].state and data.claw[clawDirect].state < 1 then
					data.claw[clawDirect].state = 1
				end
			else
				--Phase 3 (2). It'd direct one claw at the player and the other at a BGO point.
				if plr.x <= v.x + v.width/2 - config.centerRange/2 then
					clawDirect = 1
				elseif plr.x >= v.x + v.width/2 + config.centerRange/2 then
					clawDirect = 2
				else
					clawDirect = 0
				end
				if data.claw[clawDirect] and data.claw[clawDirect].isValid and data.claw[clawDirect].state and data.claw[clawDirect].state < 1 then
					data.claw[clawDirect].state = 1
				end
			end
		end
		
	end

	data.timer = data.timer + 1
	
	v.animationFrame = data.bossColour
	data.eyeFrame = v.animationFrame
	
	if data.state == STATE_KILL then
		--Fancy death animation that MegaDood will do
		for i=0,2 do
			if data.claw[i] and data.claw[i].isValid and data.claw[i].state ~= 4 then
				data.claw[i].state = 4
			end
		end
		
		if data.timer <= 192 then
			v.x = v.x + 45 * -data.w * math.sin(math.pi/4*data.timer)
			v.y = v.y - 56 * -data.w * math.sin(math.pi/2*data.timer)
		else
			if data.timer >= 240 then
				v.y = v.y + 2
				if data.timer == 368 then
					v:kill(HARM_TYPE_OFFSCREEN)
				end
			end
		end
		
		if data.timer % 16 == 0 then
			SFX.play(36)
			Effect.spawn(10, RNG.random(v.x - (v.width / 2) + v.width / 2, v.x + (v.width / 2) + v.width / 2), RNG.random(v.y - v.height / 4, v.y + v.height))
		end
		
	elseif data.state == STATE_HURT then
		--Hurt animation and retract claws
		for i=0,2 do
			if data.claw[i] and data.claw[i].isValid and data.claw[i].state ~= 4 then
				data.claw[i].state = 4
			end
		end
		v.x = v.x + 45 * -data.w * math.sin(math.pi/4*data.timer)
		v.y = v.y - 56 * -data.w * math.sin(math.pi/2*data.timer)
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
	
	if data.state == STATE_HURT or data.state == STATE_KILL then
		data.bossColour = 3
	else
		data.bossColour = data.saveColour
	end
	
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
		
		--Increment data.hp by 1 when the boss is hit 3 times
		if data.hp % 3 == 0 and data.hp > 1 then
			data.saveColour = data.saveColour + 1
		end
		
		--Increase the boss's AI phase every 3 hits
		if data.hp % 3 == 0 then
			data.trackPhase = data.state
			data.state = STATE_SUBMERGE
		end
		
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