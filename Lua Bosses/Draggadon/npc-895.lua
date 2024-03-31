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
	gfxheight = 128,
	gfxwidth = 222,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 126,
	height = 128,
	--Frameloop-related
	frames = 4,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = true, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	ignorethrownnpcs = true,
	destroyblocktable = {90, 4, 188, 60, 293, 667, 457, 666, 686, 667, 668, 526, 226}
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

local spawnOffsetX = {}

spawnOffsetX[-1] = (-sampleNPCSettings.width / 4)
spawnOffsetX[1] = (sampleNPCSettings.width -sampleNPCSettings.width / 8)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC,"onTick")
end

--Variable to track which player is riding the NPC
local playerRiding = 0
local saveMount = 0
local playStationarySound = false
local playStartSound = false
local playDriveSound = false
local driven = false
local knockback = 0

local stationary = Misc.resolveSoundFile("stationary.wav")
local start = Misc.resolveSoundFile("starting.wav")
local drive = Misc.resolveSoundFile("drive.wav")

function sampleNPC.onTick()
	if playStationarySound then
		-- Create the looping sound effect for all of the NPC's
		if stationarySoundObj == nil then
			stationarySoundObj = SFX.play{sound = stationary,loops = 0}
		end
	elseif stationarySoundObj ~= nil then -- If the sound is still playing but there's no NPC's, stop it
		stationarySoundObj:stop()
		stationarySoundObj = nil
	end
	
	-- Clear playStationarySound for the next tick
	playStationarySound = false
	
	
	if playDriveSound then
	-- Create the looping sound effect for all of the NPC's
	if driveSoundObj == nil then
		driveSoundObj = SFX.play{sound = drive,loops = 0}
	end
	elseif driveSoundObj ~= nil then -- If the sound is still playing but there's no NPC's, stop it
		driveSoundObj:stop()
		driveSoundObj = nil
	end
	
	-- Clear playDriveSound for the next tick
	playDriveSound = false
	
	
	
	if playStartSound then
		-- Create the looping sound effect for all of the NPC's
		if startSoundObj == nil then
			startSoundObj = SFX.play{sound = start,loops = 1}
		end
	elseif startSoundObj ~= nil then -- If the sound is still playing but there's no NPC's, stop it
		startSoundObj:stop()
		startSoundObj = nil
	end
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	local config = NPC.config[v.id]

	if data.frameSpeed == nil then
		data.frameSpeed = 0
		data.timer = 0
	end

	--Timer to determine if a player can exit or not
	v.ai1 = v.ai1 - 1
	--Delay between projectile shots
	v.ai3 = v.ai3 - 1
	
	--When not in use just sit still and detect who's about to enter it
	if v.ai2 == 0 then
		v.animationFrame = 1
		v.speedX = 0
		playStartSound = false
		data.timer = 0
		if Player.getNearest(v.x,v.y).standingNPC == v and v.ai1 <= 0 and Player.getNearest(v.x,v.y).mount == 0 and Player.getNearest(v.x,v.y).keys.down then
		
			SFX.play(2)
			data.timer = 1
			
			if Player.getNearest(v.x,v.y) == player then
				playerRiding = player
			else
				playerRiding = player2
				
			end

			if not playerRiding.isInside then
				v.ai1 = 8
			    v.ai2 = 1
			end
			
		end
	else
        --Stop the sampleNPC if player is dead
		if player.deathTimer > 0 then 
		   v.speedX = 0
		   return
		end
	
		--Don't let it despawn, it'll softlock the player inside
		v:mem(0x12A, FIELD_WORD, 180)
		
		--Make it look like the player's inside it
		playerRiding.frame = -9999
		playerRiding.x = v.x + v.width / 3
		playerRiding.y = v.y - v.height / 7
		playerRiding:mem(0x50, FIELD_BOOL, false)
		playerRiding:mem(0x56, FIELD_WORD, 0) --Set combo counter to 0 so we cant just farm 1-ups
		
		playerRiding.isInside = true
		
		v:mem(0x120, FIELD_BOOL, false)

		--Allow the player to move the vehicle
		if playerRiding.keys.left or playerRiding.keys.right then
			if playerRiding.keys.left then
				if v.speedX > -3 then
					v.speedX = v.speedX - 0.1
				else
					v.speedX = -3
				end
			elseif playerRiding.keys.right then
				if v.speedX < 3 then
					v.speedX = v.speedX + 0.1
				else
					v.speedX = 3
				end
			end
		else
			if math.abs(v.speedX) > 0.1 then
				v.speedX = v.speedX - 0.1 * v.direction
			else
				v.speedX = 0
			end
		end
		
		if playerRiding.keys.jump and v.collidesBlockBottom then
			v.speedY = -7
		end
		
		if v.collidesBlockBottom then
			if v.speedX ~= 0 then
				v.animationFrame = math.floor((data.frameSpeed * v.direction) / 8) % 3 + 1
				data.frameSpeed = data.frameSpeed + math.floor(v.speedX)
			else
				data.frameSpeed = 0
				v.animationFrame = math.floor(lunatime.tick() / 8) % 2
			end
		else
			v.animationFrame = 1
		end

		if math.abs(knockback) >= 0.2 then
			knockback = math.abs(knockback) - 0.2
		else
			knockback = 0
		end
		
		--Shoot missiles
		if playerRiding.keys.run == KEYS_PRESSED then
			if v.ai3 <= 0 then
				local n = NPC.spawn(npcID + 1, v.x + spawnOffsetX[v.direction], v.y + v.height / 2)
				n.direction = v.direction
				n.speedX = 7 * v.direction
				v.ai3 = 128
				SFX.play(RNG.irandomEntry{"fire1.wav","fire2.wav","fire3.wav"})
				for i = 0,1 do
					local d = i * 32
					local e = Effect.spawn(10, v.x + spawnOffsetX[v.direction], v.y + v.height / 2 - (d) + 16)
				end
				knockback = 5
			end
		end
		
		v.x = v.x - knockback * v.direction
		
		--Stuff to prevent the player attacking and grabbing items when in the vehicle
		if playerRiding.holdingNPC ~= nil then
			playerRiding.holdingNPC:kill()
		end
		playerRiding:mem(0x160, FIELD_WORD, 1)
		playerRiding:mem(0x162, FIELD_WORD, 1)
		playerRiding:mem(0x164, FIELD_WORD, -1)

		v:mem(0x5C, FIELD_FLOAT, 0)
		
		--Collider that makes NPCs interact with it
		local collBox = Colliders.Box(v.x - (v.width * 1), v.y - (v.height * 1), v.width * 1.1, v.height)
		collBox.x = v.x - v.width * 0
		collBox.y = v.y + v.height * 0.1
		
		for _,n in ipairs(NPC.get()) do
			if Colliders.collide(n,collBox) then
				if n.idx ~= v.idx and n:mem(0x138, FIELD_WORD) == 0 then
					--Collect if an item
					if (NPC.config[n.id].isinteractable or NPC.config[n.id].iscoin) then
						n.x = playerRiding.x
						n.y = playerRiding.y
					--Trample if an enemy
					elseif not n.friendly and not n.isHidden and v.speedX ~= 0 and NPC.HITTABLE_MAP[n.id] then
						n:kill()
					end
				end
			end
		end
		
		-- Handle destroying blocks
		local list = Colliders.getColliding{
		a = collBox,
		b = sampleNPCSettings.destroyblocktable,
		btype = Colliders.BLOCK,
		filter = function(other)
			if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
				return false
			end
			return true
		end
		}
		for _,b in ipairs(list) do
			b:remove(true)
		end
		
		--Bit of code to make the player exit
		if playerRiding.keys.altJump and v.ai1 <= 0 then
			v.ai1 = 8
			v.ai2 = 0
			playerRiding.speedY = -9
			playerRiding.speedX = 0
			SFX.play(35)
			playerRiding.isInside = false
			driven = false
			playerRiding:mem(0x164, FIELD_WORD, 0)
		end
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames
	});
	
end

--Draw the player inside
function sampleNPC.onDrawNPC(v)
	local config = NPC.config[v.id]
	if v.ai2 == 1 and playerRiding ~= 0 and player.deathTimer == 0 then
		playerRiding:render {
			frame = 1,
			direction = v.direction,
			powerup = playerRiding.powerup,
			mount = 0,
			character = playerRiding.character,
			x = v.x + v.width / 3,
			y = v.y - v.height / 5,
			drawplayer = true,
			ignorestate = true,
			sceneCoords = true,
			priority = -50,
		}
	end
	
	local data = v.data
	
	if v.speedX == 0 then
		playDriveSound = false
		if data.timer > 0 then
			data.timer = data.timer + 1
		end
		
		if not driven then
			if v.ai2 ~= 0 then
				if data.timer <= 1016 then
					playStartSound = true
				else
					playStartSound = false
					playStationarySound = true
				end
			end
		else
			playStartSound = false
			playStationarySound = true
		end
	else
		data.timer = 0
		playStartSound = false
		playStationarySound = false
		playDriveSound = true
		driven = true
	end
end

--Gotta return the library table!
return sampleNPC