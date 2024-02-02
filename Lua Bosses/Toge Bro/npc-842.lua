--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
local colliders = require("colliders")
klonoa.UngrabableNPCs[NPC_ID] = true
--Create the library table
local togeBro = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
local id = NPC_ID
--Defines NPC config for our NPC. You can remove superfluous definitions.
local togeBroSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 80,
	gfxwidth = 104,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 58,
	height = 40,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 12,
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
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	score = 5,

	--Define custom properties below
	idletime = 180,
	shellReadyDelay = 32,
	shellGroundedDelay = 240,
	shellAirDelay = 240,
	descendHeight = 2,
	descendDelay = 80,
	descendWaitDelay = 40,
	shellAcceleration = 0.2,
	accelerationCap = 5,
	--Set debug = true to view his belly hitbox where the player can jump into it to damage him
	debug = false
}

--Applies NPC settings
npcManager.setNpcSettings(togeBroSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
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
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local STATE_IDLE = 1
local STATE_SHELL = 2
local STATE_HURT = 3
local STATE_FRIENDLY = 4

--Register events
function togeBro.onInitAPI()
	--npcManager.registerEvent(npcID, togeBro, "onTickNPC")
	npcManager.registerEvent(npcID, togeBro, "onTickEndNPC")
	registerEvent(togeBro, "onNPCKill")
	registerEvent(togeBro, "onNPCHarm")
end
local config = NPC.config[id]


function togeBro.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	local data = v.data
	local settings = data._settings
	local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)

	data.bellyBox = Colliders.Box(v.x - (v.width * 2), v.y - (v.height * 1.5), NPC.config[v.id].width - 4, NPC.config[v.id].height/2 + 2)
	data.bellyBox.x = v.x + v.width/2 - data.bellyBox.width/2
	data.bellyBox.y = v.y + v.height - data.bellyBox.height/2
	if NPC.config[v.id].debug == true then
		data.bellyBox:Debug(true)
	end
	
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
		settings.health = settings.health or 24
		settings.pinchShell = settings.pinchShell or false

		data.timer = 0
		data.health = settings.health
		if v.friendly == false then
			data.state = STATE_IDLE
		else
			data.state = STATE_FRIENDLY
		end
		data.accel = 0
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
	v.ai5 = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2).idx
	
	local p = Player(v.ai5)
	
	local px = p.x + p.width / 2
	local vx = v.x + v.width / 2
	data.timer = data.timer + 1
	if data.state == STATE_IDLE then --Wait for a set amount of time before doing something else
		if px < v.x then
			v.direction = -1
		else
			v.direction = 1
		end
		if data.timer < config.idletime - 8 then
			v.animationFrame = math.floor(data.timer / 12) % 2
		else
			v.animationFrame = 2
		end
		if data.timer >= config.idletime then
			data.timer = 0
			v.ai1 = 0
			v.ai2 = 0
			data.state = STATE_SHELL
		end
	elseif data.state == STATE_SHELL then --Shell Attack where it chases the player horizontally.
		if v.ai1 == 0 then --Prepare Shell attack and then chase the player horizontally on the ground
			if data.timer < NPC.config[v.id].shellReadyDelay then
				v.speedX = 0
				data.accel = 0
			else
				if px < v.x then
					v.direction = -1
				else
					v.direction = 1
				end
				data.accel = data.accel + (NPC.config[v.id].shellAcceleration * v.direction)
				v.speedX = v.speedX + data.accel
				
				data.accel = math.clamp(data.accel, -NPC.config[v.id].accelerationCap, NPC.config[v.id].accelerationCap)
			end
			v.animationFrame = math.floor(data.timer / 6) % 4 + 3
			if data.timer >= NPC.config[v.id].shellReadyDelay + NPC.config[v.id].shellGroundedDelay then
				data.timer = 0
				if settings.pinchShell == true and data.health <= settings.health / 2 then
					v.ai1 = 4
				else
					v.ai1 = 1
				end
				v.speedX = 0
			end
		elseif v.ai1 == 1 then --Descend in the air
			v.animationFrame = math.floor(data.timer / 6) % 4 + 3
			if data.timer >= NPC.config[v.id].descendDelay then
				v.speedY = -defines.npc_grav
			else
				v.speedY = -NPC.config[v.id].descendHeight - defines.npc_grav
			end
			if data.timer >= NPC.config[v.id].descendWaitDelay + NPC.config[v.id].descendDelay then
				v.ai1 = 2
				data.timer = 0
				data.accel = 0
			end
			if Colliders.collide(p,data.bellyBox) and not v.friendly and p:mem(0x140,FIELD_WORD) <= 0 then
				data.state = STATE_HURT
				data.timer = 0
				data.health = data.health - 8
			end
		elseif v.ai1 == 2 then --Prepares to fly over the player's vertical position in attempt to crush them
			if px < v.x then
				v.direction = -1
			else
				v.direction = 1
			end
			data.accel = data.accel + (NPC.config[v.id].shellAcceleration * v.direction)
			v.speedX = v.speedX + data.accel
			v.speedY = -defines.npc_grav
			data.accel = math.clamp(data.accel, -NPC.config[v.id].accelerationCap, NPC.config[v.id].accelerationCap)
			v.animationFrame = math.floor(data.timer / 6) % 4 + 7
			if data.timer >= NPC.config[v.id].shellReadyDelay + NPC.config[v.id].shellGroundedDelay then
				data.timer = 0
				v.ai1 = 3
				v.speedX = 0
			end
		elseif v.ai1 == 3 then --Drop to the ground
			v.animationFrame = math.floor(data.timer / 6) % 4 + 7
			v.speedY = 6
			if v.collidesBlockBottom then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_IDLE
			end
		elseif v.ai1 == 4 then --Pinch: Crushes the player
			v.ai2 = v.ai2 + 1
			if v.ai2 > 32 and v.ai2 <= 80 then
				v.speedY = -Defines.npc_grav
				v.speedX = 0
			end
			if v.ai2 > 80 then
				v.speedY = 9
				v.speedX = 0
				if v.collidesBlockBottom then
					Defines.earthquake = 2
					SFX.play(37)
					Animation.spawn(10, v.x, v.y + v.height)
					Animation.spawn(10, v.x + v.width, v.y + v.height)
					v.ai2 = 0
					v.speedX = 0
				end
			end
			if v.ai2 == 9 and v.collidesBlockBottom then
				--Bit of code here by Murphmario
				local bombxspeed = vector.v2(Player.getNearest(v.x + v.width/2, v.y + v.height).x + 0.5 * Player.getNearest(v.x + v.width/2, v.y + v.height).width - (v.x + 0.5 * v.width))
				v.speedX = bombxspeed.x / 24
			end
			v.animationFrame = math.floor(data.timer / 6) % 4 + 3
			if v.ai2 >= 9 and v.ai2 <= 32 then
				v.speedY = -7 - Defines.npc_grav
			end
			if data.timer >= 300 and v.collidesBlockBottom then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_IDLE
				v.ai2 = 0
			end
		end
		if v.ai1 <= 2 then
			for k, n in  ipairs(Colliders.getColliding{a = v, b = NPC.HITTABLE, btype = Colliders.NPC, filter = npcFilter}) do
		       	n:harm(HARM_TYPE_NPC)
			end
		end
	elseif data.state == STATE_HURT then
		v.animationFrame = 11
		if data.timer == 1 then
			v.speedX = 0
			v.speedY = -3
			SFX.play("WL1 Boss Hit.wav")
		end
		if data.timer >= 64 then
			data.timer = 0
			data.state = STATE_SHELL
			v.ai1 = 0
		end
	elseif data.state == STATE_FRIENDLY then
		v.friendly = true
		v.speedX = 0
		v.animationFrame = math.floor(data.timer / 12) % 2
	end

		
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = config.frames
		});
	end
	
	--Prevent Toge Bro from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	
	if Colliders.collide(p, v) and not v.friendly and data.state ~= STATE_HURT and not Defines.cheat_donthurtme then
		p:harm()
	end
end


function togeBro.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end

	if data.state == STATE_IDLE then
		if reason ~= HARM_TYPE_LAVA then
			if reason == HARM_TYPE_JUMP or killReason == HARM_TYPE_SPINJUMP or killReason == HARM_TYPE_FROMBELOW then
				SFX.play(2)
				data.state = STATE_HURT
				data.timer = 0
				data.health = data.health - 8
			elseif reason == HARM_TYPE_SWORD then
				if v:mem(0x156, FIELD_WORD) <= 0 then
					data.health = data.health - 8
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
							data.health = data.health - 8
							data.state = STATE_HURT
							data.timer = 0
						end
					else
						data.health = data.health - 8
						data.state = STATE_HURT
						data.timer = 0
					end
				else
					data.health = data.health - 8
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
				data.health = data.health - 8
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
				v:kill(HARM_TYPE_NPC)
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
	eventObj.cancelled = true
end

function togeBro.onNPCKill(eventObj,v,reason)
	local data = v.data
	if v.id ~= npcID then return end
  if reason == HARM_TYPE_LAVA or reason == HARM_TYPE_OFFSCREEN then return end
	if v.legacyBoss then
	  local ball = NPC.spawn(16, v.x, v.y)
		ball.x = ball.x + ((v.width - ball.width) / 2)
		ball.y = ball.y + ((v.height - ball.height) / 2)
		ball.speedY = -6
		ball.despawnTimer = 100
				
		SFX.play(20)
	end
  SFX.play("WL1 Boss Dead.wav")
end

--Gotta return the library table!
return togeBro
