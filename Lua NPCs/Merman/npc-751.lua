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
	gfxheight = 64,
	gfxwidth = 48,
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
	bulletID = 752,
	bulletDelay = 48,
	sfx_mockliquid = 72,
	sfx_jumpout = 2,
	sfx_jumpin = 24,
	sfx_shoot = nil,
	projectilespeed = 4,
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

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]
	
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
			v.y = camera.y + 640
			data.holdY = v.y
		elseif settings.behaviorSet == 1 then
			--Initially starts walking
			data.state = STATE_WALK
		elseif settings.behaviorSet == 2 or settings.behaviorSet == 3 then
			--It'll hide in place under the screen and jumps up and down periodically, set the behaviorSet to 3 and it'll shoot a projectile when it starts falling down.
			data.state = STATE_HIDE
			v.y = camera.y + 640
			data.holdY = v.y
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
		--Animation stays consistent regardless of what happens
		v.animationFrame = math.floor(data.timer / 10) % 2
	elseif data.state == STATE_JUMP then
		--Animation
		if v.noblockcollision then
			v.animationFrame = 3
		else
			v.animationFrame = 4
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
			data.hitY = v.y
			v.noblockcollision = true
			if NPC.config[v.id].sfx_jumpin then SFX.play(NPC.config[v.id].sfx_jumpin) end
		end
	elseif data.state == STATE_HIDE then
		--Animation
		if data.jumpOut then
			v.animationFrame = 4
		else
			v.animationFrame = 3
		end
		if settings.behaviorSet == 0 or settings.behaviorSet == 1 then
			if data.jumpOut then
				if data.timer == 1 and NPC.config[v.id].sfx_jumpout then SFX.play(NPC.config[v.id].sfx_jumpout) end
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
						data.state = STATE_WALK
						data.jumpOut = false
					end
				end
			else
				--When offscreen, linger there a bit before coming back up
				v.despawnTimer = 180
				v.animationFrame = -50
				v.y = data.holdY
				if (plr.x + plr.width/2) - (v.x + v.width / 2) <= math.abs(settings.jumpRange) then
					data.timer = 0
					data.jumpOut = true
					if NPC.config[v.id].sfx_jumpout then SFX.play(NPC.config[v.id].sfx_jumpout) end
				end
			end
		else
			if data.jumpOut then
				--If not at the same y-coords as when it got hit
				if v.y > data.hitY then
					if data.falling == false then
						v.speedY = -6
					end
				else
					--When there, start falling again and if behaviorSet is set to 3, shoot a projectile
					local targetedplayer = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)

					if data.falling == false and settings.behaviorSet == 3 then
						local originX = v.x + 0.5 * v.width
						local originY = v.y + 0.5 * v.height + 8
						local projectile = NPC.spawn(NPC.config[v.id].bulletID, originX, originY,
													 targetedplayer.section, false, true)
						if NPC.config[v.id].sfx_shoot then SFX.play(NPC.config[v.id].sfx_shoot) end
						if v.direction == DIR_LEFT then
							projectile.direction = DIR_LEFT
						else
							projectile.direction = DIR_RIGHT
						end
			
						projectile.speedX = NPC.config[v.id].projectilespeed * v.direction
						local traveltime = math.max((targetedplayer.x - originX) / projectile.speedX, 1)
						projectile.speedY = (targetedplayer.y - originY) / traveltime
						projectile.speedY = math.min(math.max(projectile.speedY, -2), 2)
					end

					data.falling = true
				end
				
				--Animation
				if data.falling == false then
					v.animationFrame = 3
				else
					v.animationFrame = 4
					--When finally touching the bottom of the screen at the end of the state, go back to hiding
					if v.y >= camera.y + 640 then
						data.timer = 0
						data.jumpOut = false
						if NPC.config[v.id].sfx_mockliquid then SFX.play(NPC.config[v.id].sfx_mockliquid) end
					end
				end
			else
				--When offscreen, linger there a bit before coming back up
				v.despawnTimer = 180
				v.animationFrame = -50
				v.y = data.holdY
				if data.timer >= settings.leapDelay then
					data.timer = 0
					data.jumpOut = true
					if NPC.config[v.id].sfx_jumpout then SFX.play(NPC.config[v.id].sfx_jumpout) end
				end
			end
		end
	elseif data.state == STATE_SHOOT then
		v.animationFrame = 2
		v.speedX = 0
		local targetedplayer = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)

		if data.timer >= NPC.config[v.id].bulletDelay then
			local originX = v.x + 0.5 * v.width
			local originY = v.y + 0.5 * v.height + 8
			local projectile = NPC.spawn(NPC.config[v.id].bulletID, originX, originY,
										 targetedplayer.section, false, true)
			if NPC.config[v.id].sfx_shoot then SFX.play(NPC.config[v.id].sfx_shoot) end
			if v.direction == DIR_LEFT then
				projectile.direction = DIR_LEFT
			else
				projectile.direction = DIR_RIGHT
			end

			projectile.speedX = NPC.config[v.id].projectilespeed * v.direction
			local traveltime = math.max((targetedplayer.x - originX) / projectile.speedX, 1)
			projectile.speedY = (targetedplayer.y - originY) / traveltime
			projectile.speedY = math.min(math.max(projectile.speedY, -2), 2)
			data.timer = 0
			data.state = STATE_WALK
		end
	end
	
	--Flip animation if it changes direction
	if v.animationFrame >= 0 then
		v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
	end
end

--Gotta return the library table!
return sampleNPC
