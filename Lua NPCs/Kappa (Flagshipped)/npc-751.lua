--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 48,
	gfxwidth = 48,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 40,
	height = 40,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 3,
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
	cliffturn = false,
	walkSpeed = 1,
	sfx_mockliquid = 72,
	sfx_jumpout = 1,
	sfx_jumpin = 24,
	jumpCooldown = 320,
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
		[HARM_TYPE_JUMP]=npcID,
		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]=npcID,
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=npcID,
	}
);

--Custom local definitions below
local STATE_HIDE = 0
local STATE_WALK = 1
local STATE_JUMP = 2

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
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
			--Initially hides in place, readying to jump out and walk around
			data.state = STATE_HIDE
			data.positionY = v.y
			v.y = camera.y + 640
			data.holdY = v.y
		elseif settings.behaviorSet == 1 then
			--Initially starts walking
			data.state = STATE_WALK
		elseif settings.behaviorSet == 2 then
			--It'll hide in place under the screen and jumps up and down periodically.
			data.state = STATE_HIDE
			data.positionY = v.y
			v.y = camera.y + 640
			data.holdY = v.y
		end
		data.timer = 0
		data.jumpOut = false
		data.falling = false
		data.jumpCooldown = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_WALK
		data.timer = 0
		return
	end

	data.timer = data.timer + 1
	if data.jumpCooldown > 0 then
		data.jumpCooldown = data.jumpCooldown - 1
	else
		data.jumpCooldown = 0
	end

	if data.state == STATE_WALK then
		--Simply walk about
		v.speedX = config.walkSpeed * v.direction
		data.turnTimer = 0
		
		if data.timer >= settings.walkDelay and v:mem(0x12C, FIELD_WORD) == 0 and v.collidesBlockBottom then
			data.timer = 0
			local options = {}
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
		--Animation stays consistent regardless of what happens
		v.animationFrame = math.floor(data.timer / 8) % 2
	elseif data.state == STATE_JUMP then
		--Animation
		v.speedX = 0
		if v.noblockcollision then
			v.animationFrame = 2
		else
			v.animationFrame = 2
		end
		--Make it jump offscreen, then when at the bottom have it come back up
		if not v.collidesBlockBottom then data.timer = 0 end
		if v.y >= camera.y + 640 then
			data.state = STATE_HIDE
			data.holdY = v.y
			if NPC.config[v.id].sfx_mockliquid then SFX.play(NPC.config[v.id].sfx_mockliquid) end
		end
		--Right at the start of the state, jump offscreen
		if v.collidesBlockBottom then
			v.speedY = -5
			data.jumpCooldown = NPC.config[v.id].jumpCooldown
			data.positionY = v.y
			v.noblockcollision = true
			if NPC.config[v.id].sfx_jumpin then SFX.play(NPC.config[v.id].sfx_jumpin) end
		end
	elseif data.state == STATE_HIDE then
		--Animation
		if data.jumpOut then
			v.animationFrame = 3
		else
			v.animationFrame = 3
		end
		if settings.behaviorSet == 0 or settings.behaviorSet == 1 then
			if data.jumpOut then
				if data.timer == 1 and NPC.config[v.id].sfx_jumpout then SFX.play(NPC.config[v.id].sfx_jumpout) end
				--If not at the same y-coords as when it got hit
				if v.y > data.positionY then
					if v.noblockcollision then
						v.speedY = -6
					end
				else
					--When there, start the next part of the state
					v.noblockcollision = false
				end
				
				--Animation
				if v.noblockcollision then
					v.animationFrame = 2
				else
					v.animationFrame = 2
					--When finally touching the ground at the end of the state, go back to walking
					if v.collidesBlockBottom then
						data.timer = 0
						data.state = STATE_WALK
						data.jumpOut = false
					end
				end
			else
				--When offscreen, linger there a bit before coming back up
				v.despawnTimer = 180
				v.animationFrame = -50
				v.y = data.holdY
				if math.abs((plr.x + plr.width/2) - (v.x + v.width / 2)) <= settings.leapRange and data.jumpCooldown <= 0 then
					data.timer = 0
					data.falling = false
					data.jumpOut = true
					if NPC.config[v.id].sfx_jumpout then SFX.play(NPC.config[v.id].sfx_jumpout) end
					npcutils.faceNearestPlayer(v)
				end
				v.noblockcollision = true
			end
		else
			if data.jumpOut then
				--If not at the same y-coords as when it got hit
				if v.y > data.positionY then
					if data.falling == false then
						v.speedY = -6
					end
				else
					--When there, start falling again
					data.falling = true
				end
				
				--Animation
				if data.falling == false then
					v.animationFrame = 2
				else
					v.animationFrame = 2
					--When finally touching the bottom of the screen at the end of the state, go back to hiding
					if v.y >= camera.y + 640 then
						data.timer = 0
						data.jumpOut = false
						data.falling = false
						if NPC.config[v.id].sfx_mockliquid then SFX.play(NPC.config[v.id].sfx_mockliquid) end
					end
				end
			else
				--When offscreen, linger there a bit before coming back up
				v.despawnTimer = 180
				v.animationFrame = -50
				v.y = data.holdY
				if data.timer >= settings.leapDelay then
					data.falling = false
					data.timer = 0
					data.jumpOut = true
					if NPC.config[v.id].sfx_jumpout then SFX.play(NPC.config[v.id].sfx_jumpout) end
					npcutils.faceNearestPlayer(v)
				end
			end
			v.noblockcollision = true
		end
	end
	
	--Flip animation if it changes direction
	if v.animationFrame >= 0 then
		v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
	end
end

--Gotta return the library table!
return sampleNPC
