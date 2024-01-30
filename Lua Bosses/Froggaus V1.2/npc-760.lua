--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
--Create the library table
local Froggaus = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
local id = NPC_ID
--Defines NPC config for our NPC. You can remove superfluous definitions.
local FroggausSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 128,
	gfxwidth = 128,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 58,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 38,
	--Frameloop-related
	frames = 19,
	framestyle = 0,
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
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Define custom properties below
	hp = 45,
	bubble1ID = id + 1,
	bubble2ID = id + 2,
	shockwaveID = id + 3,
	idletime = 180,
	jumpheight1 = -10,
	jumpheight2 = -12,
}

--Applies NPC settings
npcManager.setNpcSettings(FroggausSettings)

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
		[HARM_TYPE_NPC]=850,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local STATE_IDLE = 1
local STATE_JUMP1 = 2
local STATE_JUMP2 = 3
local STATE_BUBBLE1 = 4
local STATE_BUBBLE2 = 5
local STATE_HURT = 6
local STATE_KILL = 7

local sfx_killed = Misc.resolveFile("FroggausSounds/bomb explode.wav")

--Register events
function Froggaus.onInitAPI()
	npcManager.registerEvent(npcID, Froggaus, "onTickNPC")
	npcManager.registerEvent(npcID, Froggaus, "onTickEndNPC")
	--npcManager.registerEvent(npcID, Froggaus, "onDrawNPC")
	registerEvent(Froggaus, "onNPCHarm")
end
local config = NPC.config[id]


function Froggaus.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	local data = v.data
	local settings = data._settings
	local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
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
		data.phase = 0
		data.harmframe = 0
		data.harmtimer = 120
		data.invisibleharm = false
		data.harmed = false
		data.fallSFX = false
		data.SFXTick = 0
		data.health = NPC.config[id].hp
		data.consecutive = 0
		data.state = STATE_IDLE
		data.direct = 5
	end

		--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
		data.state = STATE_IDLE
		data.timer = 0
		return
	end
	data.timer = data.timer + 1
	if data.state == STATE_IDLE then
		npcutils.faceNearestPlayer(v)
		if data.timer < config.idletime - 8 then
			v.animationFrame = math.floor(lunatime.tick() / 10) % 2
		else
			v.animationFrame = 2
		end
		if data.timer >= config.idletime then
			data.timer = 0
			data.consecutive = 0
			data.SFXTick = 0
			data.fallSFX = false
			v.ai1 = 0
			if data.phase == 0 then
				data.state = STATE_JUMP1
			else
				data.state = STATE_JUMP2
			end
		end
	elseif data.state == STATE_HURT then
		v.animationFrame = math.floor(lunatime.tick() / 8) % 3 + 16
		if data.timer == 1 then
			v.speedX = 0
			v.speedY = 2
			SFX.play("FroggausSounds/boss hit.wav")
		end
		if data.timer >= 45 then
			data.timer = config.idletime
			data.state = STATE_IDLE
			data.consecutive = 0
			data.SFXTick = 0
			data.fallSFX = false
			v.ai1 = 0
		end
	elseif data.state == STATE_JUMP1 then
		if data.timer < 10 and not v.collidesBlockBottom then data.timer = 0 end
		if data.timer == 10 and v.collidesBlockBottom then
			v.speedY = config.jumpheight1
			SFX.play("FroggausSounds/bounce.wav")
			npcutils.faceNearestPlayer(v)
		end

		if data.timer > 10 then
			v.speedX = 2 * v.direction
		end
		if data.timer >= 15 and v.collidesBlockBottom then
			data.timer = 0
			v.speedX = 0
			data.consecutive = data.consecutive + 1
		end
		if data.consecutive == 3 then
			data.consecutive = 0
			data.timer = 0
			data.state = STATE_IDLE
		end
		if data.timer < 10 then
			v.animationFrame = 9
		else
			v.animationFrame = 10
		end
	elseif data.state == STATE_JUMP2 then
		if data.timer < 32 and not v.collidesBlockBottom then data.timer = 0 end


		if data.timer < 32 then
			v.animationFrame = 9
		elseif data.timer < 40 then
			v.animationFrame = 10
		elseif data.timer < 48 then
			v.animationFrame = 11
		elseif data.timer < 56 then
			v.animationFrame = 12
		elseif data.timer < 64 then
			v.animationFrame = 13
		else
			if v.speedY < 0 then
				v.animationFrame = math.floor(lunatime.tick() / 8) % 2 + 14
			else
				v.animationFrame = math.floor(lunatime.tick() / 6) % 2 + 3
				v.speedY = 6
				data.fallSFX = true
			end
			v.speedX = v.speedX * 0.9
		end
		if data.fallSFX == true and data.SFXTick == 0 then
			data.SFXTick = 1
			SFX.play("FroggausSounds/fall.wav")
		end
		if data.timer == 32 and v.collidesBlockBottom then
			local bombxspeed = vector.v2(Player.getNearest(v.x + v.width/2, v.y + v.height).x + 0.5 * Player.getNearest(v.x + v.width/2, v.y + v.height).width - (v.x + 0.5 * v.width))
			v.speedX = bombxspeed.x / 40
			if v.speedX > 10 then v.speedX = 10 end
			if v.speedX < -10 then v.speedX = -10 end
			v.speedY = config.jumpheight2
			SFX.play("FroggausSounds/bounce.wav")
		end

		if data.timer >= 33 and v.collidesBlockBottom then
			if data.phase == 1 then data.timer = 0 data.consecutive = data.consecutive + 1 end
			v.speedX = 0
			data.SFXTick = 0
			data.fallSFX = false
			defines.earthquake = 10
			SFX.play("FroggausSounds/ram.wav")
			local shockwave1 = NPC.spawn(config.shockwaveID, v.x + v.width/2 - NPC.config[config.shockwaveID].width/2, v.y + v.height*2/3 - NPC.config[config.shockwaveID].height/2)
			local shockwave2 = NPC.spawn(config.shockwaveID, v.x + v.width/2 - NPC.config[config.shockwaveID].width/2, v.y + v.height*2/3 - NPC.config[config.shockwaveID].height/2)
			shockwave1.friendly = v.friendly
			shockwave1.layerName = "Spawned NPCs"
			shockwave2.friendly = v.friendly
			shockwave2.layerName = "Spawned NPCs"
			shockwave1.speedX = 6
			shockwave2.speedX = -6
		end
		if (data.phase == 1 and data.consecutive == 3) or (data.phase == 2 and data.timer >= 33 and v.collidesBlockBottom) then
			if data.phase == 1 then data.consecutive = 0 end
			data.timer = 0
			if data.phase == 2 then data.consecutive = data.consecutive + 1 end
			if data.phase == 2 then
				if data.consecutive <= 2 then
					data.state = RNG.irandomEntry{STATE_BUBBLE1,STATE_BUBBLE2}
				else
					data.state = STATE_IDLE
				end
			else
				data.state = STATE_IDLE
			end
		end
	elseif data.state == STATE_BUBBLE1 then
		if data.timer < 6 then
			v.animationFrame = 1
		elseif data.timer < 12 then
			v.animationFrame = 0
		elseif data.timer < 18 then
			v.animationFrame = 5
		elseif data.timer < 24 then
			v.animationFrame = 6
		elseif data.timer < 30 then
			v.animationFrame = 5
		elseif data.timer < 52 then
			v.animationFrame = 1
		elseif data.timer < 56 then
			v.animationFrame = 0
		elseif data.timer < 60 then
			v.animationFrame = 5
		elseif data.timer < 64 then
			v.animationFrame = 6
		elseif data.timer < 68 then
			v.animationFrame = 5
		elseif data.timer < 72 then
			v.animationFrame = 7
		else
			v.animationFrame = 8
		end
		if data.timer == 72 then
			local bubble = NPC.spawn(config.bubble1ID, v.x + v.width/2 - NPC.config[config.bubble1ID].width/2, v.y + v.height/2 - NPC.config[config.bubble1ID].width/2)
			local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
								
			local startX = p.x + p.width / 2
			local startY = p.y + p.height / 2
			local X = v.x + v.width / 2
			local Y = v.y + v.height / 2
						
			local angle = math.atan2((Y - startY), (X - startX))

			bubble.speedX = -3.5 * math.cos(angle)
			bubble.speedY = -3.5 * math.sin(angle)
			bubble.friendly = v.friendly
			bubble.layerName = "Spawned NPCs"
			SFX.play(38)
		end
		if data.timer >= 80 then
			if v.ai1 >= 3 then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_JUMP2
			else
				v.ai1 = v.ai1 + 1
				data.timer = 48
			end
		end
	elseif data.state == STATE_BUBBLE2 then
		if data.timer < 6 then
			v.animationFrame = 1
		elseif data.timer < 12 then
			v.animationFrame = 0
		elseif data.timer < 18 then
			v.animationFrame = 7
		elseif data.timer < 24 then
			v.animationFrame = 8
		elseif data.timer < 30 then
			v.animationFrame = 7
		elseif data.timer < 52 then
			v.animationFrame = 1
		elseif data.timer < 56 then
			v.animationFrame = 0
		elseif data.timer < 60 then
			v.animationFrame = 5
		elseif data.timer < 64 then
			v.animationFrame = 6
		elseif data.timer < 68 then
			v.animationFrame = 5
		elseif data.timer < 72 then
			v.animationFrame = 7
		else
			v.animationFrame = 8
		end
		if data.timer == 72 then
			SFX.play(62)
		end
		if data.timer == 1 then data.direct = 5 end
		if data.timer >= 72 then npcutils.faceNearestPlayer(v) end
		if data.timer >= 72 and data.timer % 8 == 0 then
			local bubble = NPC.spawn(config.bubble2ID, v.x + v.width/2 - NPC.config[config.bubble1ID].width/2, v.y + v.height/2 - NPC.config[config.bubble1ID].width/2)
			data.direct = data.direct - 0.2
			bubble.speedX = (data.direct + RNG.random(-0.75,0.75)) * v.direction
			bubble.speedY = -13 - RNG.random(-0.75,0.75)
			bubble.friendly = v.friendly
			bubble.layerName = "Spawned NPCs"
		end
		if data.timer >= 210 then
			data.state = STATE_JUMP2
			data.timer = 0
		end
	elseif data.state == STATE_KILL then
		v.speedX = 0
		v.friendly = true
		v.nohurt = true
		v.nogravity = true
		v.speedY = 0
		v.animationFrame = math.floor(lunatime.tick() / 8) % 3 + 16
		if data.timer % 24 == 0 then
            SFX.play(sfx_killed, 1)
            Animation.spawn(850, math.random(v.x, v.x + v.width), math.random(v.y, v.y + v.height))
        end
        if data.timer >= 240 then
            v:kill(HARM_TYPE_NPC)
			if v.legacyBoss then
				local ball = NPC.spawn(16, v.x, v.y)
				ball.x = ball.x + ((v.width - ball.width) / 2)
				ball.y = ball.y + ((v.height - ball.height) / 2)
				ball.speedY = -6
				ball.despawnTimer = 100
				
				SFX.play(20)
			end
        end
	end

		
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = config.frames
		});
	end
	
	--Prevent Froggaus from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end

	if data.health > config.hp*2/3 and data.health <= config.hp then
		data.phase = 0
	elseif data.health > config.hp*1/3 and data.health <= config.hp*2/3 then
		data.phase = 1
	else
		data.phase = 2
	end
	
	if Colliders.collide(p, v) and not v.friendly and data.state ~= STATE_KILL and not Defines.cheat_donthurtme then
		p:harm()
	end
end


function Froggaus.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end
	if data.state ~= STATE_KILL then
		if data.state == STATE_IDLE then
			if reason ~= HARM_TYPE_LAVA then
				if reason == HARM_TYPE_JUMP or killReason == HARM_TYPE_SPINJUMP or killReason == HARM_TYPE_FROMBELOW then
					SFX.play(2)
					data.state = STATE_HURT
					data.timer = 0
					data.health = data.health - 5
				elseif reason == HARM_TYPE_SWORD then
					if v:mem(0x156, FIELD_WORD) <= 0 then
						data.health = data.health - 5
						data.state = STATE_HURT
						data.timer = 0
						SFX.play(89)
						v:mem(0x156, FIELD_WORD,20)
					end
					if Colliders.downSlash(player,v) then
						player.speedY = -6
					end
				elseif reason == HARM_TYPE_NPC then
					if culprit then
						if type(culprit) == "NPC" then
							if culprit.id == 13  then
								SFX.play(9)
								data.health = data.health - 1
							else
								data.health = data.health - 5
								data.state = STATE_HURT
								data.timer = 0
							end
						else
							data.health = data.health - 5
							data.state = STATE_HURT
							data.timer = 0
						end
					else
						data.health = data.health - 5
						data.state = STATE_HURT
						data.timer = 0
					end
				elseif reason == HARM_TYPE_LAVA and v ~= nil then
					v:kill(HARM_TYPE_OFFSCREEN)
				elseif v:mem(0x12, FIELD_WORD) == 2 then
					v:kill(HARM_TYPE_OFFSCREEN)
				else
					data.state = STATE_HURT
					data.timer = 0
					data.health = data.health - 5
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
					SFX.play("FroggausSounds/boss dies.wav")
				elseif data.health > 0 then
					v:mem(0x156,FIELD_WORD,60)
				end
			else
				v:kill(HARM_TYPE_LAVA)
			end
		else
			if culprit then
				if Colliders.collide(culprit, v) then
					if culprit.y < v.y and culprit:mem(0x50, FIELD_BOOL) and player.deathTimer <= 0 then
						SFX.play(2)
						--Bit of code taken from the basegame chucks
						if (culprit.x + 0.5 * culprit.width) < (v.x + v.width*0.5) then
							culprit.speedX = -5
						else
							culprit.speedX = 5
						end
					else
						culprit:harm()
					end
				end
				if type(culprit) == "NPC" and (NPC.HITTABLE_MAP[culprit.id] or culprit.id == 45) and culprit.id ~= 50 and v:mem(0x138, FIELD_WORD) == 0 then
					culprit:kill(HARM_TYPE_NPC)
				end
			end
		end
	end
	eventObj.cancelled = true
end

--Gotta return the library table!
return Froggaus