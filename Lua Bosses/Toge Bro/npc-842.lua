--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
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
	gfxheight = 128,
	gfxwidth = 128,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 58,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 38,
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

	nohurt=false,
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

	--Define custom properties below
	hp = 24,
	idletime = 180,
  shellReadyDelay = 32,
  shellGroundedDelay = 240,
  shellAirDelay = 240,
  descendHeight = 3.5,
  descendDelay = 80
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
		data.health = NPC.config[id].hp
		data.state = STATE_IDLE
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
  if data.state == STATE_SHELL and (v.ai1 == 2 or v.ai1 == 1) then
    v.nogravity = true
  else
    v.nogravity = false
  end
	if data.state == STATE_IDLE then --Wait for a set amount of time before doing something else
		npcutils.faceNearestPlayer(v)
		if data.timer < config.idletime - 8 then
			v.animationFrame = math.floor(lunatime.tick() / 10) % 2
		else
			v.animationFrame = 2
		end
		if data.timer >= config.idletime then
			data.timer = 0
			v.ai1 = 0
			data.state = STATE_SHELL
		end
  elseif data.state == STATE_SHELL then --Shell Attack where it chases the player horizontally.
    if v.ai1 == 0 then --Prepare Shell attack and then chase the player horizontally on the ground

    elseif v.ai1 == 1 then --Descend in the air

    elseif v.ai1 == 2 then --Prepares to fly over the player's vertical position in attempt to crush them

    elseif v.ai1 == 3 then
      
    end
	elseif data.state == STATE_HURT then
		v.animationFrame = 11
		if data.timer == 1 then
			v.speedX = 0
			v.speedY = -3
			SFX.play("WL1 Boss Hit.wav")
		end
		if data.timer >= 56 then
			data.timer = 0
			data.state = STATE_SHELL
			v.ai1 = 0
		end
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
	
	if Colliders.collide(p, v) and not v.friendly and data.state ~= STATE_KILL and not Defines.cheat_donthurtme then
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
