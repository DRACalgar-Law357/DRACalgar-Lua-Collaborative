--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
--Create the library table
local Bathin = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
--Defines NPC config for our NPC. You can remove superfluous definitions.
local BathinSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 128,
	gfxwidth = 128,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 96,
	height = 96,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 16,
	--Frameloop-related
	frames = 11,
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
	nogravity = true,
	noblockcollision = rue,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	staticdirection = true,
	hp = 150,
	projectileID = npcID + 1,
	phanto1ID = nil,
	phanto2ID = nil,
	phanto3ID = nil,
	iFramesSet = 0,
	--An iFrame system that has the boss' frame be turned invisible from the set of frames periodically.
	--Set 0 defines its hurtTimer until it is at its iFramesDelay
	--Set 1 defines the same from Set 0 but whenever the boss has been harmed, it stacks up the iFramesDelay the more. The catch is that when the boss has been left alone after getting harmed, it resets the iFramesStacks so that the player can be able to jump on the boss for some time again.
	iFramesDelay = 32,
	iFramesDelayStack = 48,
	
	--A config that uses Enjil's/Emral's freezeHighlight.lua; if set to true the lua file of it needs to be in the local or episode folder.
	useFreezeHightLight = false
}

--Applies NPC settings
npcManager.setNpcSettings(BathinSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
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
		[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

local STATE = {
	IDLE = 0,
	SUMMON = 1,
	FLOAT = 2,
	CALLEVENT = 3,
	SHOOT = 4,
	HURT = 5,
	PHASE = 6,
	KILL = 7,
}

local hurtCooldown = 160

local hpboarder = Graphics.loadImage("hpconboss.png")
local hpfill = Graphics.loadImage("hpfillboss.png")
--Register events
function Bathin.onInitAPI()
	npcManager.registerEvent(npcID, Bathin, "onTickEndNPC")
	npcManager.registerEvent(npcID, Bathin, "onStartNPC")
	npcManager.registerEvent(npcID, Bathin, "onDrawNPC")
	registerEvent(Bathin, "onNPCHarm")
end

local bgoTable

function Bathin.onStartNPC(v)
	bgoTable = BGO.get(NPC.config[v.id].jumpPointBGO)
end

function Bathin.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		data.hurtTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 0
		data.hurtTimer = data.hurtTimer or 0
		data.iFrames = false
		data.health = NPC.config[v.id].hp
		data.state = STATE_IDLE
		data.hurtCooldownTimer = 0
		data.hurting = false
		data.iFramesDelay = NPC.config[v.id].iFramesDelay
		data.iFrameStack = 0
		data.statelimit = 0
		v.ai1 = 0
		v.ai2 = 0
		v.ai3 = 0
		data.mushroom = false
		data.rndTimer = RNG.randomInt(80,144)
		data.frameTimer = 0
		data.hurtPlayer = false
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_JUMP
		v.ai1 = 0
		data.timer = 0
		data.jumpTimer = 0
	end
	if data.health <= NPC.config[v.id].hp/2 and data.mushroom == false then
		data.mushroom = true
		SFX.play(7)
		local n = NPC.spawn(9, v.x + v.width / 2, v.y + v.height/2)
		n.dontMove = true
		n.speedY = -5
	end
	data.timer = data.timer + 1
 
	if data.state == STATE_IDLE then
		data.frameTimer = data.frameTimer + 1
		if data.frameTimer < 9 then
			v.animationFrame = 0
		elseif data.frameTimer < 18 then
			v.animationFrame = 1
		elseif data.frameTimer < 24 then
			v.animationFrame = 0
		elseif data.frameTimer < 76 then
			v.animationFrame = math.floor(data.timer / 5) % 2 + 2
		else
			data.frameTimer = 0
			v.animationFrame = 0
		end
		npcutils.faceNearestPlayer(v)
		if data.timer >= data.rndTimer then
			local options = {}
			if data.statelimit ~= STATE_JUMP then
				table.insert(options,STATE_JUMP)
			end
			if data.statelimit ~= STATE_MINE then
				table.insert(options,STATE_MINE)
			end
			if data.statelimit ~= STATE_CHARGE then
				table.insert(options,STATE_CHARGE)
			end
			if data.statelimit ~= STATE_CRUSH then
				table.insert(options,STATE_CRUSH)
			end
			if data.statelimit ~= STATE_EARTH_PRISON then
				table.insert(options,STATE_EARTH_PRISON)
			end
			if data.statelimit ~= STATE_ATTACH_TO_WALL then
				table.insert(options,STATE_ATTACH_TO_WALL)
			end
			if data.statelimit ~= STATE_TAIL_LIGHTNING then
				table.insert(options,STATE_TAIL_LIGHTNING)
			end
			
            data.state = RNG.irandomEntry(options)
			data.statelimit = data.state
			data.timer = 0
			data.rndTimer = RNG.randomInt(80,144)
		end
		if v.collidesBlockBottom then
            v.speedX = 0
		end
	elseif data.state == STATE_JUMP then
		if v.ai1 == 0 or v.ai1 == 2 then
			if data.timer < 20 and not v.collidesBlockBottom and v.ai1 == 0 then
				data.timer = 0
			end
			if v.collidesBlockBottom then
				v.speedX = 0
			end
			if data.timer >= 20 and v.collidesBlockBottom and v.ai1 == 0 then
				if v.x+v.width/2 <= camera.x + camera.width/3 then
					v.speedX = RNG.irandomEntry{2,4}
				elseif v.x+v.width/2 >= camera.x + camera.width*2/3 then
					v.speedX = RNG.irandomEntry{-2,-4}
				else
					v.speedX = RNG.irandomEntry{-2,-4,2,4}
				end
				v.speedY = -8.25
				data.timer = 0
				v.ai1 = 1
			end
			if data.timer >= 16 and v.ai1 == 2 then
				v.ai1 = 0
				data.timer = 0
				data.state = STATE_IDLE
			end
			v.animationFrame = 4
		elseif v.ai1 == 1 then
			if v.direction == -1 then
				if v.speedX < 0 then
					v.animationFrame = math.floor(data.timer / 6) % 4 + 5
				else
					v.animationFrame = math.floor(data.timer / 6) % 4 + 9
				end
			else
				if v.speedX > 0 then
					v.animationFrame = math.floor(data.timer / 6) % 4 + 5
				else
					v.animationFrame = math.floor(data.timer / 6) % 4 + 9
				end
			end
			if v.collidesBlockBottom then
				v.ai1 = 2
				data.timer = 0
				v.speedX = 0
			end
		end
	elseif data.state == STATE_MINE then
		v.animationFrame = math.floor(data.timer / 6) % 4 + 5
		if data.timer == 1 then v.speedY = -11 end
		if data.timer == 88 then
			for i=0,4 do
				local n = NPC.spawn(NPC.config[v.id].mineID,v.x + spawnOffset[v.direction],v.y + v.height/2)
				n.x=n.x-n.width/2
				n.y=n.y-n.height/2
				n.speedX = (2 + (1.8 * i)) * v.direction
				n.speedY = 4
			end
			SFX.play(25)
		end
		if data.timer >= 40 and data.timer < 100 then
			v.speedY = -Defines.npc_grav
		end
		if data.timer > 1 and v.collidesBlockBottom then
			data.timer = 0
			data.state = STATE_IDLE
		end
	elseif data.state == STATE_CRUSH then
		if data.health > NPC.config[v.id].hp/2 then
			v.ai2 = 0
		else
			v.ai2 = 1
		end
		if v.ai1 == 0 then
			if data.timer == 1 then
				SFX.play(14)
				Animation.spawn(80,v.x + spawnOffset[v.direction],v.y + v.height/2)
			end
			if data.timer < 40 then
				v.animationFrame = 4
				if not v.collidesBlockBottom then
					data.timer = 0
				else
					v.speedX = 0
				end
				npcutils.faceNearestPlayer(v)
			else
				v.animationFrame = math.floor(data.timer / 4) % 2 + 42
			end
			if data.timer == 40 and v.collidesBlockBottom then
				v.speedY = -11
				--Bit of code here by Murphmario
				local bombxspeed = vector.v2(Player.getNearest(v.x + v.width/2, v.y + v.height).x + 0.5 * Player.getNearest(v.x + v.width/2, v.y + v.height).width - (v.x + 0.5 * v.width))
				v.speedX = bombxspeed.x / 57
			end
			if data.timer >= 100 then
				data.timer = 0
				v.ai1 = 1
				v.speedX = 0
			end
			if (data.timer > 40 and v.collidesBlockBottom) then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_IDLE
			end
		elseif v.ai1 == 1 then
			v.animationFrame = math.floor(data.timer / 4) % 2 + 44
			v.speedY = -Defines.npc_grav + 11
			if v.collidesBlockBottom then
				SFX.play(37)
				Defines.earthquake = 5
				data.timer = 0
				v.ai1 = 2
				Animation.spawn(1,v.x+v.width/2,v.y+v.height)
			end
		elseif v.ai1 == 2 then
			v.animationFrame = math.floor(data.timer / 4) % 2 + 46
			v.speedX = 0
			if data.timer >= 32 then
				data.timer = 0
				if v.ai3 >= v.ai2 then
					v.ai3 = 0
					v.ai1 = 0
					data.state = STATE_IDLE
				else
					v.ai3 = v.ai3 + 1
					v.ai1 = 0
					data.timer = 36
				end
			end
		end
	elseif data.state == STATE_CHARGE then
		if v.ai1 == 0 then
			v.animationFrame = math.floor(data.timer / 6) % 4 + 5
			if data.timer == 1 then SFX.play(26) end
			if data.timer == 56 then
				v.speedX = 10 * v.direction
				SFX.play(61)
			end
			if data.timer >= 104 then
				data.timer = 0
				v.speedX = 0
				v.ai1 = 1
			end
		elseif v.ai1 == 1 then
			v.animationFrame = 4
			v.speedX = 0
			npcutils.faceNearestPlayer(v)
			if data.timer >= 20 then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_IDLE
			end
		end
	elseif data.state == STATE_EARTH_PRISON then
		if v.ai1 == 0 then
			if data.timer < 8 then
				v.animationFrame = 13
			elseif data.timer < 60 then
				v.animationFrame = math.floor(data.timer / 3) % 4 + 14
			elseif data.timer < 64 then
				v.animationFrame = 18
			elseif data.timer < 68 then
				v.animationFrame = 19
			elseif data.timer < 114 then
				v.animationFrame = math.floor(data.timer / 4) % 2 + 20
			else
				v.animationFrame = 22
			end
			v.speedX = 0
			npcutils.faceNearestPlayer(v)
			if data.timer >= 118 then
				data.timer = 0
				v.ai1 = 1
			end
		elseif v.ai1 == 1 then
			v.animationFrame = math.floor(data.timer / 4) % 3 + 23
			SFX.play(Misc.resolveSoundFile("thunder-shield-jump"), 100, 1, 16)
			if data.timer % 40 == 0 then
				for i=0,1 do
					local n = NPC.spawn(NPC.config[v.id].shockwaveID,v.x + spawnOffset[-v.direction],v.y+v.height)
					n.x=n.x-n.width/2
					n.y=n.y-n.height/2
					n.speedX = -6 + (12 * i)
				end
			end
			v.speedX = 0
			if data.timer >= 140 then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_IDLE
			end
		end
	elseif data.state == STATE_ATTACH_TO_WALL then
	
		v.animationFrame = math.floor(data.timer / 8) % 8 + 5
		
		if v.ai1 == 0 then
			if data.timer > 48 then
				if data.jumpPoint == nil then
					data.jumpPoint = RNG.irandomEntry(bgoTable)
				end
				 data.dirVectr = vector.v2(
					(data.jumpPoint.x) - (v.x + v.width * 0.5),
					(data.jumpPoint.y) - (v.y + v.height * 0.5)
				):normalize() * 10

				v.speedX = data.dirVectr.x
				v.speedY = data.dirVectr.y
				
				if v.collidesBlockLeft or v.collidesBlockRight then
					if v.collidesBlockLeft then
						v.direction = 1
					else
						v.direction = -1
					end
					v.ai1 = 1
					data.timer = 0
					data.jumpPoint = nil
				end
			else
				v.speedY = -6
				if data.timer == 1 then SFX.play(86) end
			end
		else
			v.speedX = 0
			v.speedY = -Defines.npc_grav
			data.state = STATE_TRICK_NEEDLE
			data.timer = 0
			v.ai1 = 0
		end
		
	elseif data.state == STATE_TRICK_NEEDLE then
		v.speedY = -Defines.npc_grav
		if data.timer <= 18 then
			v.animationFrame = math.floor((data.timer - 1) / 6) % 3 + 27
		elseif data.timer > 18 and data.timer <= 78 then
			v.animationFrame = math.floor(data.timer / 6) % 3 + 29
			if data.timer == 60 then
				local n = NPC.spawn(NPC.config[v.id].needleID, v.x + spawnOffset[v.direction], v.y - v.height * 0.5, player.section, false)
				n.direction = v.direction
				SFX.play(18)
			elseif data.timer == 66 then
				local n = NPC.spawn(NPC.config[v.id].needleID, v.x + spawnOffset[v.direction] + (32 * -v.direction), v.y - 64, player.section, false)
				n.direction = v.direction
				SFX.play(18)
			end
		else
			v.animationFrame = math.floor(data.timer / 6) % 5 + 32
			if lunatime.tick() % 12 == 0 then
				local e = Effect.spawn(npcID,0,0)

				e.timer = math.floor(e.timer/2)

				e.x = RNG.random((v.x - v.width / 2), (v.x + v.width))
				e.y = RNG.random((v.y - v.height / 2), (v.y + v.height))
			end
			if data.timer >= 194 then
				data.timer = 0
				data.state = STATE_VELOCITY_BREAK
				Effect.spawn(NPC.config[v.id].velocityBreakEffectID,v.x - v.width,v.y - 64)
				SFX.play(14)
			end
		end
	elseif data.state == STATE_VELOCITY_BREAK then
		if data.timer <= 96 then
			v.speedY = -Defines.npc_grav
			if data.timer <= 12 then
				v.animationFrame = math.floor((data.timer - 1) / 6) % 2 + 37
			elseif data.timer > 12 and data.timer <= 40 then
				v.animationFrame = -1
				v.friendly = true
				v.x = plr.x
			elseif data.timer > 40 and data.timer <= 70 then
				v.friendly = false
				v.animationFrame = math.floor((data.timer + 19) / 6) % 5 + 39
			elseif data.timer > 70 and data.timer <= 96 then
				v.animationFrame = math.floor((data.timer - 1) / 6) % 2 + 42
			end
		else
			v.speedY = 12
			v.animationFrame = math.floor(data.timer / 6) % 2 + 44
			if v.collidesBlockBottom then
				SFX.play(37)
				Defines.earthquake = 6
				Animation.spawn(1,v.x+v.width/2,v.y+v.height)
				data.timer = 0
				data.state = STATE_IDLE
			end
		end
	elseif data.state == STATE_TAIL_LIGHTNING then
		if data.timer <= 80 then
			v.animationFrame = math.floor(data.timer / 6) % 2 + 49
			if data.timer == 1 then 
				data.e = Effect.spawn(NPC.config[v.id].tailLightningEffectID, v.x + spawnOffset[v.direction] - 40, v.y - 48)
				SFX.play("Undertale Beam Charge.ogg")
			end
			data.e.x = v.x + spawnOffset[v.direction] - 40
			data.e.y = v.y - 48
			npcutils.faceNearestPlayer(v)
		else
			if data.timer == 81 then 
				SFX.play("Undertale Beam Blast.ogg") 
				for i = 0,10 do
					local g = i * 144
					local n = NPC.spawn(NPC.config[v.id].tailLightningID, v.x + (tailLightningOffset[v.direction]) + (g * v.direction), v.y - 32, player.section, false)
					n.direction = v.direction
					if i == 0 then
						n.ai1 = 8
						n.ai3 = 2
						n.friendly = true
					end
				end
			elseif data.timer >= 256 then
				data.timer = 0
				data.state = STATE_IDLE
			end
			data.e = false
			v.animationFrame = math.floor(data.timer / 6) % 2 + 51
		end
    else
        if lunatime.tick() % 5 == 0 then
    		Animation.spawn(900, math.random(v.x, v.x + v.width), math.random(v.y, v.y + v.height))
			SFX.play("Explosion 2.wav")
		end
		v.speedX = 0
		v.speedY = -Defines.npc_grav
		v.friendly = true
		if lunatime.tick() % 64 > 4 then 
			v.animationFrame = 53
		else
			v.animationFrame = -50
		end
		if data.timer >= 210 then
		    v:kill(HARM_TYPE_NPC)
		end
	end
	
	--Give Bathin some i-frames to make the fight less cheesable
	--iFrames System made by MegaDood & DRACalgar Law
	if NPC.config[v.id].iFramesSet == 1 then
        if data.hurting == false then
            data.hurtCooldownTimer = 0
            data.iFramesStack = -1
        else
            data.hurtCooldownTimer = data.hurtCooldownTimer + 1
            local stacks = (NPC.config[v.id].iFramesDelayStack * data.iFramesStack)
            if stacks < 0 then
                stacks = 0
            end
            data.iFramesDelay = NPC.config[v.id].iFramesDelay + stacks
            if data.hurtCooldownTimer >= hurtCooldown then
                data.hurtCooldownTimer = 0
                data.hurting = false
                data.iFramesStack = -1
            end
        end
    end
	if data.iFrames then
		v.friendly = true
		data.hurtTimer = data.hurtTimer + 1
		
		if data.hurtTimer == 1 then
		    SFX.play("sfx_playerhurt.wav")
		end
		
		if data.hurtTimer % 8 <= 4 and data.hurtTimer > 8 then
			v.animationFrame = -50
		end
		if data.hurtTimer >= data.iFramesDelay then
			v.friendly = false
			data.iFrames = false
			data.hurtTimer = 0
		end
	end
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = BathinSettings.frames
		});
	end
	
	--Prevent Bathin from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	if Colliders.collide(plr, v) and not v.friendly and data.state ~= STATE_KILL and not Defines.cheat_donthurtme then
		plr:harm()
	end
end
function Bathin.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end

			if data.hurtPlayer == false then
				local fromFireball = (culprit and culprit.__type == "NPC" and culprit.id == 13 )
				local hpd = 10
				if fromFireball then
					hpd = 4
					SFX.play(9)
				elseif reason == HARM_TYPE_LAVA then
					v:kill(HARM_TYPE_LAVA)
				else
					hpd = 10
					data.iFrames = true
					if reason == HARM_TYPE_SWORD then
						if v:mem(0x156, FIELD_WORD) <= 0 then
							SFX.play(89)
							hpd = 8
							v:mem(0x156, FIELD_WORD,20)
						end
						if Colliders.downSlash(player,v) then
							player.speedY = -6
						end
					elseif reason == HARM_TYPE_LAVA and v ~= nil then
						v:kill(HARM_TYPE_OFFSCREEN)
					elseif v:mem(0x12, FIELD_WORD) == 2 then
						v:kill(HARM_TYPE_OFFSCREEN)
					else
						if reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP or reason == HARM_TYPE_FROMBELOW then
							SFX.play(2)
						end
						data.iFrames = true
						hpd = 10
					end
					if data.iFrames then
						data.hurting = true
						data.iFramesStack = data.iFramesStack + 1
						data.hurtCooldownTimer = 0
					end
				end
				
				data.health = data.health - hpd
			else
				if culprit and culprit.__type == "Player" then
					player:harm()
				end
			end
			if culprit then
				if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
					culprit:kill(HARM_TYPE_NPC)
				elseif culprit.__type == "Player" then
					--Bit of code taken from the basegame chucks
					if (culprit.x + 0.5 * culprit.width) < (v.x + v.width*0.5) then
						culprit.speedX = -5
					else
						culprit.speedX = 5
					end
				elseif type(culprit) == "NPC" and (NPC.HITTABLE_MAP[culprit.id] or culprit.id == 45) and culprit.id ~= 50 and v:mem(0x138, FIELD_WORD) == 0 then
					culprit:kill(HARM_TYPE_NPC)
				end
			end
			if data.health <= 0 then
				data.state = STATE_KILL
				data.timer = 0
				freeze.set(48)
				SFX.play("enker-absorb.wav")
				for _,n in ipairs(NPC.get()) do
					if n.id == NPC.config[v.id].crescentID or n.id == NPC.config[v.id].greenOrbID or n.id == NPC.config[v.id].purpleOrbID or n.id == NPC.config[v.id].orangeOrbID or n.id == NPC.config[v.id].matterID or n.id == NPC.config[v.id].swarmID or n.id == NPC.config[v.id].petalID or n.id == NPC.config[v.id].darkWaveID then
						if n.x + n.width > camera.x and n.x < camera.x + camera.width and n.y + n.height > camera.y and n.y < camera.y + camera.height then
							n:kill(9)
							Animation.spawn(10, n.x, n.y)
						end
					end
				end
			elseif data.health > 0 then
				v:mem(0x156,FIELD_WORD,60)
			end
	eventObj.cancelled = true
end

function Bathin.onDrawNPC(v)
	local data = v.data
	local settings = v.data._settings

	if v.legacyBoss == true and data.state ~= STATE_KILL and data.health then
		Graphics.drawImage(hpboarder, 740, 120)
		local healthoffset = 126
		healthoffset = healthoffset-(126*(data.health/NPC.config[v.id].hp))
		Graphics.drawImage(hpfill, 748, 128+healthoffset, 0, 0, 12, 126-healthoffset)
	end
end

--Gotta return the library table!
return Bathin
