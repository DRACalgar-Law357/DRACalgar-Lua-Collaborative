--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
--Create the library table
local Dennis = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
local id = NPC_ID
--Defines NPC config for our NPC. You can remove superfluous definitions.
local DennisSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 206,
	gfxwidth = 190,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 54,
	height = 128,
	miniatureHeight = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 56,
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
	nofireball = true,
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
	hp = 3,
	idleDelay = 64,
	readyJumpDelay = 24,
	--Jump Amount is varied by the jumpCount variable in which is dependent on the number of HP
	jumpAmount = {
		[0] = 2,
		[1] = 3,
		[2] = 4,
	},
	jumpDelay = 48,
	jumpHeight = 12,
	honeSpeed = 8,
	honeRangeX = 12,
	spinDelay = 36,
	landAccelerate = 0,
	landDelay = 24,
	getStuckDelay = 36,
	gettingUnstuckDelay = 180,
	hurtDelay = 36,
	stunDelay = 90,
	walkSpeed = 4,

	sfx_jump = 1,
	sfx_spin = Misc.resolveFile("spin.ogg"),
	sfx_land = 37,
	sfx_hurt = 39,

	sfxTable_voice_ouch = {
		Misc.resolveFile("ouch-dennis.ogg"),
		Misc.resolveFile("ouch-2-dennis.ogg"),
		Misc.resolveFile("ouch-3-dennis.ogg"),
		nil,
		nil,
	},
	sfxTable_voice_unstucked = {
		Misc.resolveFile("felt-dennis.ogg"),
		Misc.resolveFile("enough-dennis.ogg"),
		nil,
		nil,
	},
	sfxTable_voice_anger = {
		Misc.resolveFile("pay-dennis.ogg"),
		nil,
		nil,
	},
	sfxTable_voice_stucked = {
		Misc.resolveFile("grunt-dennis.ogg"),
		nil,
		nil,
	},
	sfxTable_voice_defeated = {
		nil,
		nil,
	},
}

--Applies NPC settings
npcManager.setNpcSettings(DennisSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
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
local STATE_IDLE = 0
local STATE_JUMP = 1
local STATE_STUCK = 2
local STATE_WALK = 3
local STATE_HURT = 4
local STATE_KILL = 5

--Register events
function Dennis.onInitAPI()
	--npcManager.registerEvent(npcID, Dennis, "onTickNPC")
	npcManager.registerEvent(npcID, Dennis, "onTickEndNPC")
	--npcManager.registerEvent(npcID, Dennis, "onDrawNPC")
	registerEvent(Dennis, "onNPCHarm")
end
local config = NPC.config[id]

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

local function SFXPlayTable(sfx)
	--Uses a table variable to choose one of the listed entries and produces a sound of it; if not, then don't play a sound.
	if sfx then
		local sfxChoice = RNG.irandomEntry(sfx)
		if sfxChoice then
			SFX.play(sfxChoice)
		end
	end
end

local function SFXPlay(sfx)
	--Checks a variable if it has a sound and produces a sound of it; if not, then don't play a sound.
	if sfx then
		SFX.play(sfx)
	end
end


function Dennis.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	local data = v.data
	local settings = data._settings
	local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
	local plr = {x = p.x + p.width/2, y = p.y + p.height/2}
	local obj = {x = v.x + v.width/2, y = v.y + v.height/2}
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.timer = 0
		data.hurtTimer = data.hurtTimer or 0
		data.iFrames = false
		data.hitCounter = 0
		data.health = data.health
		data.consecutive = 0
		data.state = STATE_IDLE
		data.useMiniatureHeight = false
		data.necessaryWalk = false
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then

		--Initialize necessary data.
		data.initialized = true
		data.timer = 0
		data.hurtTimer = data.hurtTimer or 0
		data.iFrames = false
		data.hitCounter = 0
		data.health = NPC.config[id].hp
		data.consecutive = 0
		data.state = STATE_IDLE
		data.useMiniatureHeight = false
		data.necessaryWalk = false
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
	local jumpCount = config.jumpAmount[data.hitCounter]
	if (data.state == STATE_JUMP and (v.ai1 == 0 or v.ai1 == 1 or v.ai1 == 3)) or (data.state == STATE_STUCK and v.ai1 == 1) or (data.state == STATE_HURT and v.ai1 == 0) or data.state == STATE_KILL then
		data.useMiniatureHeight = true
	else
		data.useMiniatureHeight = false
	end
	if data.state == STATE_IDLE then
		--Stand before jumping
		v.animationFrame = math.floor(lunatime.tick() / 6) % 8
		if data.timer >= config.idleDelay then
			data.timer = 0
			data.consecutive = 0
			v.ai1 = 0
			if data.necessaryWalk == true then
				v.direction = RNG.irandomEntry{-1,1}
				data.state = STATE_WALK
				SFXPlayTable(config.sfxTable_voice_unstucked)
				data.necessaryWalk = false
			else
				data.state = STATE_JUMP
			end
		end
	elseif data.state == STATE_HURT then
		if v.ai1 == 0 then
			--Hurt animation by flashing
			v.animationFrame = math.floor(lunatime.tick() / 8) % 2 + 35
			if data.timer == 1 then
				v.speedX = 0
				v.speedY = 0
				SFXPlay(config.sfx_hurt)
				SFXPlayTable(config.sfxTable_voice_ouch)
			end
			if data.timer >= 45 then
				if data.health <= 0 then
					data.timer = 0
					data.state = STATE_KILL
				else
					data.timer = 0
					v.ai1 = 1
				end
			end
		elseif v.ai1 == 1 then
			--Idle before walking back
			if data.timer < 36 then
				if data.timer < 6 then
					v.animationFrame = 37
				elseif data.timer < 12 then
					v.animationFrame = 38
				elseif data.timer < 18 then
					v.animationFrame = 39
				elseif data.timer < 24 then
					v.animationFrame = 40
				elseif data.timer < 30 then
					v.animationFrame = 41
				else
					v.animationFrame = 42
				end
			else
				v.animationFrame = math.floor(lunatime.tick() / 6) % 2 + 43
			end
			if data.timer >= 36 + config.stunDelay then
				data.timer = 0
				v.direction = RNG.irandomEntry{-1,1}
				data.state = STATE_WALK
				v.ai1 = 0
				SFXPlayTable(config.sfxTable_voice_anger)
			end
		else
			v.ai1 = 0
			data.timer = 0
		end
	elseif data.state == STATE_WALK then
		--Walk until it is near a pit or hits a wall
		v.animationFrame = math.floor(lunatime.tick() / 4) % 10 + 45
		v.speedX = config.walkSpeed * v.direction
		if isNearPit(v) and v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockRight then
			v.speedX = 0
			v.direction = -v.direction
			data.timer = 0
			data.state = STATE_IDLE
			if data.iFrames == true then data.iFrames = false end
		end
	elseif data.state == STATE_JUMP then
		if v.ai1 == 0 then --Get ready to jump and then jump
			if data.timer < config.readyJumpDelay then
				if data.timer < 12 then
					v.animationFrame = 9
				else
					v.animationFrame = 10
				end
				v.speedX = 0
			else
				v.animationFrame = 11
				if obj.x <= plr.x - config.honeRangeX and v.direction == -1 then
					v.direction = 1
				elseif obj.x >= plr.x + config.honeRangeX and v.direction == 1 then
					v.direction = -1
				end
				v.speedX = config.honeSpeed * v.direction
			end
			if data.timer == config.readyJumpDelay then
				SFXPlay(config.sfx_jump)
				v.speedY = -config.jumpHeight
			end
			if data.timer >= config.readyJumpDelay + config.jumpDelay then
				data.timer = 0
				v.speedX = 0
				v.speedY = -defines.npc_grav
				v.ai1 = 1
			end
		elseif v.ai1 == 1 then --Spin before slamming down
			if data.timer % 16 == 1 then
				SFXPlay(config.sfx_spin)
			end
			v.animationFrame = math.floor(lunatime.tick() / 2) % 6 + 12
			v.speedX = 0
			v.speedY = -defines.npc_grav
			if data.timer >= config.spinDelay then
				data.timer = 0
				v.ai1 = 2
			end
		elseif v.ai1 == 2 then --Slam down
			if data.timer < 2 then
				v.animationFrame = 12
			elseif data.timer < 4 then
				v.animationFrame = 13
			elseif data.timer < 6 then
				v.animationFrame = 14
			elseif data.timer < 6 then
				v.animationFrame = 18
			elseif data.timer < 12 then
				v.animationFrame = 19
			else
				v.animationFrame = 20
			end
			v.speedX = 0
			v.speedY = v.speedY + config.landAccelerate
			if v.collidesBlockBottom then
				SFXPlay(config.sfx_land)
				data.timer = 0
				v.ai1 = 3
				defines.earthquake = 4
				data.destroyCollider = data.destroyCollider or Colliders.Box(v.x - 1, v.y + 1, v.width + 1, v.height - 1);
				data.destroyCollider.x = v.x + 0.5 * (2/v.width) * v.direction;
				data.destroyCollider.y = v.y + 8;
				local list = Colliders.getColliding{
					a = data.destroyCollider,
					btype = Colliders.BLOCK,
					filter = function(other)
						if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
							return false
						end
						return true
					end
					}
				for _,b in ipairs(list) do
					if (Block.config[b.id].smashable ~= nil and Block.config[b.id].smashable == 3) or b.id == 186 then
						b:remove(true)
					else
						b:hit(true)
					end
				end
			end
		elseif v.ai1 == 3 then --Land
			if data.timer < 6 then
				v.animationFrame = 21
			else
				v.animationFrame = 22
			end
			if data.timer >= config.landDelay then
				data.timer = 0
				--Once done landing, do another jump until the consecutive hits up to a specified value depending on HP
				data.consecutive = data.consecutive + 1
				if data.consecutive < jumpCount then
					v.ai1 = 0
					data.timer = config.readyJumpDelay - 1
				else
					data.consecutive = 0
					v.ai1 = 0
					data.state = STATE_STUCK
					SFXPlayTable(config.sfxTable_voice_stucked)
				end
			end
		else
			v.ai1 = 0
			data.timer = 0
		end
	elseif data.state == STATE_STUCK then
		--Tries to get unstuck, this is the chance for the player to attack him
		if data.timer < config.getStuckDelay then
			v.animationFrame = math.floor(lunatime.tick() / 8) % 4 + 23
		else
			v.animationFrame = 	math.floor(lunatime.tick() / 4) % 8 + 27
		end
		if data.timer >= config.getStuckDelay + config.gettingUnstuckDelay then
			data.timer = 0
			data.state = STATE_IDLE
			data.necessaryWalk = true
		end
	elseif data.state == STATE_KILL then
		--Goes bye bye
		v.speedX = 0
		v.friendly = true
		v.nohurt = true
		v.animationFrame = 55
        if data.timer >= 48 then
            v:kill(HARM_TYPE_NPC)
        end
		SFXPlayTable(config.sfxTable_voice_defeated)
	end

	--Give Dennis some i-frames to make the fight less cheesable
	--iFrames System made by MegaDood & DRACalgar Law
	if data.iFrames then
		v.friendly = true
		data.hurtTimer = data.hurtTimer + 1
		if data.hurtTimer % 8 > 4 then
			v.animationFrame = -50
		end
		if data.hurtTimer == 1 and data.health > 0 then
		    SFXPlay(config.sfx_hurt)
			data.state = STATE_HURT
			data.timer = 0
			v.ai1 = 0
			data.consecutive = 0
			data.necessaryWalk = false
		end
		--[[if data.hurtTimer >= data.iFramesDelay then
			v.friendly = false
			data.iFrames = false
			data.hurtTimer = 0
		end]]
	else
		v.friendly = false
		data.hurtTimer = 0
	end
		
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = config.frames
		});
	end
	
	--Prevent Dennis from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end

	if data.health > config.hp*2/3 and data.health <= config.hp then
		data.hitCounter = 0
	elseif data.health > config.hp*1/3 and data.health <= config.hp*2/3 then
		data.hitCounter = 1
	else
		data.hitCounter = 2
	end
	
	if Colliders.collide(p, v) and not v.friendly and data.state ~= STATE_KILL and data.state ~= STATE_HURT and not Defines.cheat_donthurtme then
		p:harm()
	end
	--Part of code by Marioman2007
	if data.useMiniatureHeight then
		local oldHeight = v.height
		if data.useMiniatureHeight == true then
			if oldHeight ~= config.height then v.height = config.height end
		elseif data.useMiniatureHeight == false then
			if oldHeight ~= config.miniatureHeight then v.height = config.miniatureHeight end
		end
		v.y = v.y + oldHeight - v.height
	end
end


function Dennis.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end
	if data.state ~= STATE_KILL then
		if data.state == STATE_STUCK then
			if reason ~= HARM_TYPE_LAVA then
				if reason == HARM_TYPE_JUMP or killReason == HARM_TYPE_SPINJUMP or killReason == HARM_TYPE_FROMBELOW then
					SFX.play(2)
					data.state = STATE_HURT
					data.timer = 0
					data.health = data.health - 1
					if data.iFrames == false then data.iFrames = true end
				elseif reason == HARM_TYPE_SWORD then
					if v:mem(0x156, FIELD_WORD) <= 0 then
						data.health = data.health - 1
						data.state = STATE_HURT
						data.timer = 0
						SFX.play(89)
						v:mem(0x156, FIELD_WORD,20)
						if data.iFrames == false then data.iFrames = true end
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
								data.health = data.health - 1
								data.state = STATE_HURT
								data.timer = 0
								if data.iFrames == false then data.iFrames = true end
							end
						else
							data.health = data.health - 1
							data.state = STATE_HURT
							data.timer = 0
							if data.iFrames == false then data.iFrames = true end
						end
					else
						data.health = data.health - 1
						data.state = STATE_HURT
						data.timer = 0
						if data.iFrames == false then data.iFrames = true end
					end
				elseif reason == HARM_TYPE_LAVA and v ~= nil then
					v:kill(HARM_TYPE_OFFSCREEN)
				elseif v:mem(0x12, FIELD_WORD) == 2 then
					v:kill(HARM_TYPE_OFFSCREEN)
				else
					data.state = STATE_HURT
					data.timer = 0
					data.health = data.health - 1
					if data.iFrames == false then data.iFrames = true end
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
				v:mem(0x156,FIELD_WORD,60)
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
return Dennis