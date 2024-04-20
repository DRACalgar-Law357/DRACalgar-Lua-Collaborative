--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local colliders = require("colliders")


--*******************************************************
--Code by Minus and Saturn Yoshi - Taken from npc-615.lua
--*******************************************************


--Create the library table
local boomerang = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local boomerangSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 16,
	height = 16,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 8,
	framestyle = 0,
	framespeed = 4, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	riseheight = 96,
	trajectorywidth = 32,
	fallheight = 48
}

--Applies NPC settings
npcManager.setNpcSettings(boomerangSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


local v_SPEED = 4
local speedTotal = boomerangSettings.speed * v_SPEED

-- Called when first spawned or respawned (i.e., ai1 is 0).  Initializes all of the projectile's relevant parameters (no data is used here, due to the
-- small number of necessary parameters).
local function initialize(v)
	local data = v.data
	-- Set the flag that the projectile has been initialized
	v.ai1 = 1

	-- The current "state" of the projectile's pseudo-elliptical path.
	-- 0: Not initialized.
	-- 1: Initial curve upward.
	-- 2: Horizontal movement away from the bro.
	-- 3: Curving back, first half.
	-- 4: Curving back, second half.
	-- 5: Horizontal movement back toward the bro.
	data.state = 1

	-- The timer for each phase of the projectile path.  Once it reaches zero, the projectile goes to the next state.
	data.timer = math.floor(math.pi * boomerangSettings.riseheight / (2 * speedTotal))
	data.killTimer = data.killTimer or 0

	-- Owner is assumed to be set to the NPC which spawned the projectile
	-- to be able to detect whether the projectile intersects with the original thrower while in state 5, and delete it if that's the case.
	-- data.ownerBro = nil
end

--Register events
function boomerang.onInitAPI()
	npcManager.registerEvent(npcID, boomerang, "onTickNPC")
end

function boomerang.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.ai1 == 0 then
		initialize(v)
	elseif data.state == 1 then
		-- The projectile is rising upward.  Adjust the speeds so that the projectile follows a quarter circle path upward with speed
		-- v_SPEED.

		v.speedX = v.direction * speedTotal * math.cos(speedTotal * data.timer / boomerangSettings.riseheight)
		v.speedY = -speedTotal * math.sin(speedTotal * data.timer / boomerangSettings.riseheight) * 1.5

		if data.timer > 0 then
			data.timer = data.timer - 1
		else
			data.state = 2
			data.timer = math.floor(boomerangSettings.trajectorywidth / speedTotal)
		end
	elseif data.state == 2 then
		-- The projectile is moving away, following a horizontal path.

		v.speedX = v.direction * speedTotal
		v.speedY = 0

		if data.timer > 0 then
			data.timer = data.timer - 1
		else
			data.state = 3
			data.timer = math.floor(math.pi * boomerangSettings.fallheight / (2 * speedTotal))
		end
	elseif data.state == 3 then
		-- The projectile is following the top half of a half-circle path to turn back.

		v.speedX = v.direction * speedTotal * math.sin(speedTotal * data.timer / boomerangSettings.fallheight)
		v.speedY = speedTotal * math.cos(speedTotal * data.timer / boomerangSettings.fallheight) * 1.5

		if data.timer > 0 then
			data.timer = data.timer - 1
		else
			data.state = 4
			data.timer = math.floor(math.pi * boomerangSettings.fallheight / (2 * speedTotal))

			-- Turn the projectile around.

			v.direction = -v.direction
		end
	elseif data.state == 4 then
		-- The projectile is following the bottom half of a half-circle path to turn back.

		v.speedX = v.direction * speedTotal * math.cos(speedTotal * data.timer / boomerangSettings.fallheight)
		v.speedY = speedTotal * math.sin(speedTotal * data.timer / boomerangSettings.fallheight) * 1.5

		if data.timer > 0 then
			data.timer = data.timer - 1
		else
			data.state = 5
		end
	else
		-- The projectile is following a horizontal path back in the direction it initially came.

		v.speedX = v.direction * speedTotal
		v.speedY = 0
		
		if (v.x >= v.spawnX and v.direction == 1) or (v.x <= v.spawnX and v.direction == -1) then v:kill(9) end

		if data.owner ~= nil and data.owner.isValid then
			-- If the projectile intersects with the bro that originally threw it, destroy it.
			if colliders.collide(v, data.owner) then
				data.killTimer = data.killTimer + 1
				if data.killTimer >= 10.5 then
					v:kill(9)
				end
			end
		end
	end
	
end

--Gotta return the library table!
return boomerang