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
	--Sprite size
	gfxheight = 64,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 48,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 5,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	cliffturn = true,
	walkSpeed = 1,
	jumpDelay = 6,
	landDelay = 12,
	bulletID = 752,
	bulletDelay = 48,
	sfx_jumpout = 0,
	sfx_shoot = 0,
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
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=899,
		[HARM_TYPE_FROMBELOW]=899,
		[HARM_TYPE_NPC]=899,
		[HARM_TYPE_PROJECTILE_USED]=899,
		[HARM_TYPE_LAVA]=899,
		[HARM_TYPE_HELD]=899,
		[HARM_TYPE_TAIL]=899,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=899,
	}
);

--Custom local definitions below
local STATE_HIDE = 0
local STATE_WALK = 1
local STATE_JUMP = 2
local STATE_SHOOT = 3

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

function isNearPit(v)
	--This function either returns false, or returns the direction the npc should go to. numbers can still be used as booleans.
	local testblocks = Block.SOLID.. Block.SEMISOLID.. Block.PLAYER

	local centerbox = Colliders.Box(v.x + 8, v.y, 8, v.height + 10)
	local l = centerbox
	if v.direction == DIR_RIGHT then
		l.x = l.x + 38
	end
	
	for _,centerbox in ipairs(
	  Colliders.getColliding{
		a = testblocks,
		b = l,
		btype = Colliders.BLOCK
	  }) do
		return false
	end
	
	return true
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]
	
	local list
	local npcs
	
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
		if settings.behaviorSet == 0 then
			data.state = STATE_HIDE
		elseif settings.behaviorSet == 1 then
			data.state = STATE_WALK
		elseif settings.behaviorSet == 2 or settings.behaviorSet == 3 then
			data.state = STATE_HIDE
			v.y = camera.y + 640
			data.rise = 1
		end
		data.timer = 0
		data.jumpOut = false
		data.falling = false
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_WALK
		data.timer = 0
		return
	end

	data.timer = data.timer + 1

	if data.state == STATE_WALK then
	
		--If it's about to walk off a cliff or run into a wall, begin the turn ai
		if isNearPit(v) and v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockRight then
			data.isTurning = true
			data.turnTimer = data.turnTimer or 0
		end
	
		if not data.isTurning then
			--Simply walk about
			v.speedX = config.walkSpeed * v.direction
			data.turnTimer = 0
			
			if data.timer >= settings.walkDelay and v:mem(0x12C, FIELD_WORD) == 0 then
				data.timer = 0
				local options = {}
				if settings.doShoot > 0 then
					for i=1,settings.doShoot do
						table.insert(options,STATE_SHOOT)
					end
				end
				if settings.doJump > 0 then
					for i=1,settings.doJump do
						table.insert(options,STATE_JUMP)
					end
				end
				if settings.doWalk > 0 then
					for i=1,settings.doWalk do
						table.insert(options,STATE_WALK)
					end
				end
				if #options > 0 then
					data.state = RNG.irandomEntry(options)
				end
			end
		else
			--Turning thing
			data.turnTimer = data.turnTimer + 1
			v.speedX = 0
			if data.turnTimer == 32 then
				v.direction = -v.direction
			elseif data.turnTimer == 64 then
				data.isTurning = false
				data.timer = 0
			end
		end
		
		--Animation stays consistent regardless of what happens
		v.animationFrame = math.floor(data.timer / 10) % 2
	elseif data.state == STATE_JUMP then
		--Animation
		if data.rise == nil then
			v.animationFrame = 3
			--Make it jump offscreen, then when at the bottom have it come back up
			if not v.collidesBlockBottom then data.timer = 0 end
			if v.y >= camera.y + 640 then
				data.rise = 1
				data.holdY = v.y
			end
		else
			if settings.behaviorSet == 0 or settings.behaviorSet == 1 then
				if data.timer >= 96 then
					if data.timer == 96 then SFX.play(24) end
					--If not at the same y-coords as when it got hit
					if v.y > data.hitY then
						if v.noblockcollision then
							v.speedY = -6
						end
					else
						--When there, start the next part of the state
						v.noblockcollision = false
					end
					
					--Animation
					if v.noblockcollision then
						v.animationFrame = 3
					else
						v.animationFrame = 4
						--When finally touching the ground at the end of the state, go back to walking
						if v.collidesBlockBottom then
							data.timer = 0
							v.friendly = false
							data.state = STATE_WALK
							data.rise = nil
						end
					end
				else
					--When offscreen, linger there a bit before coming back up
					v.despawnTimer = 180
					v.animationFrame = -50
					v.y = data.holdY
				end
			else
				if data.jumpOut then
					if data.timer == 96 then SFX.play(24) end
					--If not at the same y-coords as when it got hit
					if v.y > data.hitY then
						if data.falling == false then
							v.speedY = -6
						end
					else
						--When there, start falling again
						data.falling = true
					end
					
					--Animation
					if v.falling == false then
						v.animationFrame = 3
					else
						v.animationFrame = 4
						--When finally touching the ground at the end of the state, go back to walking
						if v.y >= camera.y + 640 then
							data.timer = 0
						end
					end
				else
					--When offscreen, linger there a bit before coming back up
					v.despawnTimer = 180
					v.animationFrame = -50
					v.y = data.holdY
				end
			end
		end
		--Right at the start of the state, jump offscreen
		if data.timer >= 33 and v.collidesBlockBottom then
			v.speedY = -5
			v.noblockcollision = true
			SFX.play(1)
		end
	end
	
	--Flip animation if it changes direction
	if v.animationFrame >= 0 then
		v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
	end
end

--Gotta return the library table!
return sampleNPC
