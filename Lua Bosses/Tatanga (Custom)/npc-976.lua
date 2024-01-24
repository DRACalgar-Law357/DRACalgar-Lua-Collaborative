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
	gfxwidth = 116,
	gfxheight = 70,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 52,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 16,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	jumphurt = false,
	spinjumpsafe = false,
	hammerID = 617,
	enemyID = 137,
	holdX = 36,
	holdY = 12,



	luahandlesspeed=true,

	hp = 5
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=npcID,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=800,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local spawnOffset = {}
spawnOffset[-1] = (0)
spawnOffset[1] = (70)
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then 

	end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.bossActivated = false
		return
	end

	--Initialize
	if not data.bossActivated then
		--Initialize necessary data.
		data.bossActivated = true
		data.bossState = 7
		--[[0 = Shooting Lasers, 
		1 = Throwing Hammers, 
		2 = Random Jumping
		3 = Throw Bob-Omb
		4 = Swing Melee hammer
		5 = Walk
		6 = Ground Pound
		7 = Activate Shield
		8 = Exhausted
		9 = Hurt
		10 = Jump and throw mines
		11 = Friendly State]]
		
		data.jumpType = 0
		data.hammerOffset = 0
		data.thrownFrames = 0

		data.hp = sampleNPCSettings.hp
		data.walkDelay = RNG.randomInt(90, 150)

		data.stateTimer = 0
		data.stateRNG = 0
		
		data.statelimit = 0
	end
	
	data.stateTimer = data.stateTimer + 1
	if data.bossState == 0 then --Shoot lasers
		v.dontMove = true
		if data.stateTimer % 64 <= 4 then
			v.animationFrame = 0
		elseif data.stateTimer % 64 <= 10 then
			v.animationFrame = 12
		elseif data.stateTimer % 64 == 11 then
			v.animationFrame = 12
		else
			v.animationFrame = 0
		end
	
		if data.stateTimer % 64 == 9 then
			local missile = NPC.spawn(npcID + 24, v.x - 20 + spawnOffset[v.direction], v.y + 24)
			missile.direction = v.direction
			missile.speedX = 5 * v.direction
			missile.speedY = (player.y - missile.y) / 78
			SFX.play("Item_157.wav")
		end
			
		if data.stateTimer >= 128 then
			data.stateTimer = 0
			local options = {}
			if data.statelimit ~= 2 then
				table.insert(options,2)
			end
			if data.statelimit ~= 5 then
				table.insert(options,5)
			end
			if data.statelimit ~= 6 then
				table.insert(options,6)
			end
			if data.statelimit ~= 10 then
				table.insert(options,10)
			end
			if #options > 0 then
			    data.bossState = RNG.irandomEntry(options)
			end
			data.statelimit = data.bossState
			v.dontMove = false
		end
		
	elseif data.bossState == 1 then --Throw hammers
		v.dontMove = true
		if data.stateTimer <= 45 then
			v.animationFrame = 8
		elseif data.stateTimer > 50 and data.stateTimer <= 65 then
			v.animationFrame = 9
		else
			v.animationFrame = 9
		end
		if data.stateTimer == 50 then
			for i = 0,3 do
				local d = i * 1.75
				local n = NPC.spawn(617, v.x - 20 + spawnOffset[v.direction], v.y - 8)
				n.direction = v.direction
				n.speedX = (0.5 + d) * n.direction
				n.speedY = -12
			end
			SFX.play(25)
		elseif data.stateTimer >= 180 then
		    local options = {}
			if data.statelimit ~= 2 then
				table.insert(options,2)
			end
			if data.statelimit ~= 5 then
				table.insert(options,5)
			end
			if data.statelimit ~= 6 then
				table.insert(options,6)
			end
			if data.statelimit ~= 10 then
				table.insert(options,10)
			end
			if #options > 0 then
			    data.bossState = RNG.irandomEntry(options)
			end
			data.statelimit = data.bossState
			data.stateTimer = 0
			v.dontMove = false
		end
	elseif data.bossState == 2 then --Random Jump
		if data.stateTimer <= 8 then
			v.animationFrame = 0
		else
			if v.speedY <= 0 then
				v.animationFrame = 5
			else
				v.animationFrame = 6
			end
			if data.stateTimer > 9 then
				if v.collidesBlockBottom then
        			local options = {}
        			if data.statelimit ~= 0 then
        				table.insert(options,0)
        			end
        			if data.statelimit ~= 1 then
        				table.insert(options,1)
        			end
        			if data.statelimit ~= 3 then
        				table.insert(options,3)
        				table.insert(options,3)
        			end
        			if data.statelimit ~= 4 then
        				table.insert(options,4)
        			end
        			if #options > 0 then
        			    data.bossState = RNG.irandomEntry(options)
        			end
        			data.statelimit = data.bossState
					data.stateTimer = 0
					v.speedX = 0
				end
			end
		end
		if data.stateTimer == 9 then
			v.speedY = -9
			SFX.play(1)
			v.speedX = 3 * v.direction
		end
	elseif data.bossState == 3 then --Throw Bob-Ombs
		v.dontMove = true
		if data.stateTimer <= 20 then
			v.animationFrame = 8
		elseif data.stateTimer > 25 and data.stateTimer <= 50 then
			v.animationFrame = 9
		else
			v.animationFrame = 9
		end
		if data.stateTimer == 50 then
			for i = 0,0 do
				local d = i * 1.3
				local n = NPC.spawn(sampleNPCSettings.enemyID, v.x - 20 + spawnOffset[v.direction], v.y - 8)
				n.direction = v.direction
				local bombxspeed = vector.v2(Player.getNearest(v.x + v.width/2, v.y + v.height).x + 0.5 * Player.getNearest(v.x + v.width/2, v.y + v.height).width - (v.x + 0.5 * v.width))
				n.speedX = bombxspeed.x / 50
				n.speedY = -9
			end
			SFX.play("S3K_51.wav")
		elseif data.stateTimer >= 300 then
		    local options = {}
			if data.statelimit ~= 2 then
				table.insert(options,2)
			end
			if data.statelimit ~= 5 then
				table.insert(options,5)
			end
			if data.statelimit ~= 6 then
				table.insert(options,6)
			end
			--Choice of Throwing Mines excluded
			if #options > 0 then
			    data.bossState = RNG.irandomEntry(options)
			end
			data.statelimit = data.bossState
			data.stateTimer = 0
			v.dontMove = false
		end
	elseif data.bossState == 4 then
		if data.stateTimer <= 30 or data.stateTimer >= 45 then
			v.animationFrame = 11
		elseif data.stateTimer > 30 and data.stateTimer <= 45 then
			v.animationFrame = 10
		end
		if data.stateTimer < 29 then
			v.dontMove = true
		else
			v.dontMove = false
		end
		if data.stateTimer >= 30 then
			v.speedX = v.speedX
			if v.collidesBlockBottom then
				v.speedX = v.speedX - 0.1 * v.direction
			end
				
			if v.speedX <= 0.5 and v.speedX >= -0.5 then
    		    local options = {}
    			if data.statelimit ~= 2 then
    				table.insert(options,2)
    			end
    			if data.statelimit ~= 5 then
    				table.insert(options,5)
    			end
    			if data.statelimit ~= 6 then
    				table.insert(options,6)
    			end
    			if data.statelimit ~= 10 then
    				table.insert(options,10)
    			end
    			if #options > 0 then
    			    data.bossState = RNG.irandomEntry(options)
    			end
    			data.statelimit = data.bossState
				data.stateTimer = 0
				v.dontMove = false
			end
		elseif data.stateTimer == 29 then
			SFX.play("hammer_swing.wav")
			local n
			if v.direction == DIR_LEFT then
				n = NPC.spawn(npcID + 1, v.x - 48, v.y + 24)
			else
				n = NPC.spawn(npcID + 1, v.x + 32, v.y + 24)
			end
			v.speedX = 6 * v.direction
		end
	elseif data.bossState == 5 then
		v.speedX = 4 * v.direction
		v.animationFrame = math.floor(lunatime.tick() / 8) % 4 + 1
		if data.stateTimer == data.walkDelay then
			data.walkDelay = RNG.randomInt(90, 150)
			data.stateTimer = 0
        	local options = {}
        	if data.statelimit ~= 0 then
        		table.insert(options,0)
        	end
        	if data.statelimit ~= 1 then
    			table.insert(options,1)
        	end
        	if data.statelimit ~= 3 then
        		table.insert(options,3)
    			table.insert(options,3)
        	end
        	if data.statelimit ~= 4 then
        		table.insert(options,4)
        	end
        	if #options > 0 then
        		data.bossState = RNG.irandomEntry(options)
        	end
        	data.statelimit = data.bossState
			v.speedX = 0
		end
	elseif data.bossState == 6 then
		if data.stateTimer <= 8 then
			v.animationFrame = 0
		else
			if data.stateTimer < 60 then
				v.animationFrame = 5
			elseif data.stateTimer > 60 then
				v.speedY = 9
				v.animationFrame = 7
				v.speedX = 0
				if v.collidesBlockBottom then
        			local options = {}
        			if data.statelimit ~= 0 then
        				table.insert(options,0)
        			end
        			if data.statelimit ~= 1 then
        				table.insert(options,1)
        			end
        			if data.statelimit ~= 3 then
        				table.insert(options,3)
        				table.insert(options,3)
        			end
        			if data.statelimit ~= 4 then
        				table.insert(options,4)
        			end
        			if #options > 0 then
        			    data.bossState = RNG.irandomEntry(options)
        			end
        			data.statelimit = data.bossState
					data.stateTimer = 0
					v.speedX = 0
				end
			end
		end
		if data.stateTimer == 9 and v.collidesBlockBottom then
			v.speedY = -11
			SFX.play(1)
			--Bit of code here by Murphmario
			local bombxspeed = vector.v2(Player.getNearest(v.x + v.width/2, v.y + v.height).x + 0.5 * Player.getNearest(v.x + v.width/2, v.y + v.height).width - (v.x + 0.5 * v.width))
			v.speedX = bombxspeed.x / 55
		end
	elseif data.bossState == 7 then
		v.animationFrame = 14
		if data.stateTimer == 60 then
			if not data.barrier then
				data.barrier = NPC.spawn(949, v.x - (v.width / 3), v.y - (v.height / 4), player.section, false, false)
				data.barrier.layerName = "Spawned NPCs"
				data.barrier.data.parent = v
				data.barrier.data.owner = v
				SFX.play("LightningShield.wav")
			end
		end
		if data.stateTimer >= 100 then
			data.bossState = 0
			data.stateTimer = 3
		end
	elseif data.bossState == 10 then
		if data.stateTimer <= 8 then
			v.animationFrame = 0
		else
			if data.stateTimer >= 55 and data.stateTimer < 210 then
				v.animationFrame = 6
			else
				if v.speedY < 0 then
					v.animationFrame = 5
				else
					v.animationFrame = 6
				end
			end
			if data.stateTimer > 9 then
				if v.collidesBlockBottom then
        			local options = {}
        			if data.statelimit ~= 0 then
        				table.insert(options,0)
        			end
        			if data.statelimit ~= 1 then
        				table.insert(options,1)
        			end
        			if data.statelimit ~= 3 then
        				table.insert(options,3)
        				table.insert(options,3)
        			end
        			if data.statelimit ~= 4 then
        				table.insert(options,4)
        			end
        			if #options > 0 then
        			    data.bossState = RNG.irandomEntry(options)
        			end
        			data.statelimit = data.bossState
					data.stateTimer = 0
					v.speedX = 0
				end
			end
		end
		if data.stateTimer == 9 then
			v.speedY = -13.25
			SFX.play(1)
			v.speedX = 4 * v.direction
		end
		if data.stateTimer == 55 then
			SFX.play("bombThrow.ogg")
			for i = 0,4 do
				local d = i * -2
				local n = NPC.spawn(579, v.x - 20 + spawnOffset[v.direction], v.y - 8)
				n.direction = v.direction
				n.speedX = (4 + d)
				n.speedY = -6
				n.parent = v
				n.ai1 = 160
			end
		end
		if data.stateTimer >= 55 and data.stateTimer < 210 then
			v.speedX = 0
			v.speedY = -defines.npc_grav
		else
		    
		end
	elseif data.bossState == 8 then
		v.dontMove = true
		v.animationFrame = 15
		if data.stateTimer >= 240 then
			data.stateTimer = 0
			data.bossState = 7
			v.dontMove = false
		end
	elseif data.bossState == 9 then
		v.dontMove = true
		v.animationFrame = 13
		if data.stateTimer >= 90 then
			data.stateTimer = 0
			data.bossState = 7
			v.dontMove = false
		end
	else
		v.dontMove = true
		v.animationFrame = 0
	end
	v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
	if data.barrier then
		if data.barrier.isValid then
			data.barrier.x = v.x - 16
			data.barrier.y = v.y - 8
		else
			data.barrier = nil
			data.bossState = 8
			data.stateTimer = 0
		end
	end
	if v.friendly then
		data.bossState = 11
		v.dontMove = true
		v.speedX = 0
	end
	if data.hp <= 0 then
		v:kill(HARM_TYPE_NPC)
		SFX.play("tatanga_defeated2.wav")
		for _,n in ipairs(NPC.get()) do
			if n.id == 977 or n.id == 1000 or n.id == 949 then
				if n.x + n.width > camera.x and n.x < camera.x + camera.width and n.y + n.height > camera.y and n.y < camera.y + camera.height then
					n:kill(HARM_TYPE_OFFSCREEN)
				end
			end
		end
	end
end

function sampleNPC.onDrawNPC(v)
	local data = v.data
	
	if data.bossState == 1 then
		local heldNPC = NPC.config[v.id].hammerID
		if v.direction == 1 then
			if NPC.config[heldNPC].framestyle ~= 0 then
				data.thrownFrames = NPC.config[heldNPC].frames
			end
			if v.width > 32 then
				data.hammerOffset = v.width - 32
			else
				data.hammerOffset = 0
			end
		else
			data.thrownFrames = 0
			data.hammerOffset = 0
		end
		if data.stateTimer <= 45 then
			Graphics.draw{
				type = RTYPE_IMAGE,
				image = Graphics.sprites.npc[heldNPC].img, 
				x = v.x + data.hammerOffset + (NPC.config[v.id].holdX * -v.direction),
				y = v.y - NPC.config[v.id].holdY,
				sceneCoords = true,
				sourceX = 0, 
				sourceY = NPC.config[heldNPC].gfxheight * data.thrownFrames, 
				sourceWidth = NPC.config[heldNPC].gfxwidth,
				sourceHeight = NPC.config[heldNPC].gfxheight,
				priority = -44
			}
		end
	elseif data.bossState == 3 then
		local heldNPC = NPC.config[v.id].enemyID
		if v.direction == 1 then
			if NPC.config[heldNPC].framestyle ~= 0 then
				data.thrownFrames = NPC.config[heldNPC].frames
			end
			if v.width > 32 then
				data.hammerOffset = v.width - 32
			else
				data.hammerOffset = 0
			end
		else
			data.thrownFrames = 0
			data.hammerOffset = 0
		end
		if data.stateTimer <= 50 then
			Graphics.draw{
				type = RTYPE_IMAGE,
				image = Graphics.sprites.npc[heldNPC].img, 
				x = v.x + data.hammerOffset + (NPC.config[v.id].holdX * -v.direction),
				y = v.y - NPC.config[v.id].holdY,
				sceneCoords = true,
				sourceX = 0, 
				sourceY = NPC.config[heldNPC].gfxheight * data.thrownFrames, 
				sourceWidth = NPC.config[heldNPC].gfxwidth,
				sourceHeight = NPC.config[heldNPC].gfxheight,
				priority = -44
			}
		end
	end
end

function sampleNPC.onNPCHarm(e, v, r, o)
	if npcID ~= v.id or v.isGenerator then return end
	if r == 9 or r == HARM_TYPE_LAVA then return end

	local data = v.data
	local config = NPC.config[v.id]
	if data.hp > 0 then
		if not data.barrier then
			if (r == HARM_TYPE_NPC and o and o.id ~= 13 and o.id ~= 958) or r == HARM_TYPE_HELD or r == HARM_TYPE_PROJECTILE_USED or r == HARM_TYPE_SWORD or r == HARM_TYPE_JUMP then
				if data.bossState == 8 then
					data.hp = data.hp - 1
					data.bossState = 9
					if data.hp > 0 then
						SFX.play("tatanga_hurt.wav")
					end
					data.stateTimer = 0
				end
				if type(culprit) == "NPC" then
					culprit:kill(HARM_TYPE_NPC)
				end

			elseif r == HARM_TYPE_NPC and o and o.id == 13 then
				data.hp = data.hp - 0.25
				SFX.play(9)	
				if type(culprit) == "NPC" then
					culprit:kill(HARM_TYPE_NPC)
				end
			end
			for _,n in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
				if NPC.config[n.id].SMLDamageSystem then
					if v:mem(0x156, FIELD_WORD) <= 0 then
						data.hp = data.hp - 0.25
						v:mem(0x156, FIELD_WORD,5)
						SFX.play(9)
						Animation.spawn(75, n.x, n.y)
					end
				end
			end
		end
		e.cancelled = true
	else
		local e = Effect.spawn(npcID, v.x, v.y)
		e.speedX = 4 * -v.direction
		e.speedY = -8
		SFX.play("tatanga_defeated2.wav")
		for _,n in ipairs(NPC.get()) do
			if n.id == 977 or n.id == 1000 or n.id == 949 then
				if n.x + n.width > camera.x and n.x < camera.x + camera.width and n.y + n.height > camera.y and n.y < camera.y + camera.height then
					n:kill(HARM_TYPE_OFFSCREEN)
				end
			end
		end
		if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
			culprit:kill(HARM_TYPE_NPC)
		end
	end
	if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
		culprit:kill(HARM_TYPE_NPC)
	end
end

--Gotta return the library table!
return sampleNPC