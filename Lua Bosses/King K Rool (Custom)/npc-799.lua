local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}
local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxwidth = 186,
	gfxheight = 148,

	width = 64,
	height = 96,

	gfxoffsetx = 0,
	gfxoffsety = 30,

	frames = 35,
	framestyle = 1,
	framespeed = 8,

	foreground = false,

	speed = 1,
	luahandlesspeed = false,
	nowaterphysics = false,
	cliffturn = false,
	staticdirection = false,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,

	score = 0,

	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	nowalldeath = false,

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	health=9,

	fireImage = Graphics.loadImageResolved("npc-"..npcID.."-fire.png"),
	airImage = Graphics.loadImageResolved("npc-"..npcID.."-air.png"),

	fireOffsetXRight = -18,
	fireOffsetXLeft = 102,
	fireOffsetXOGLeft = 102,
	fireOffsetY = 72,

	fireFrames = 2,
	fireFramespeed = 6,
	fireHeight = 26,

	airOffsetXRight = -54,
	airOffsetXLeft = 138,
	airOffsetXLeftOG = 138,
	airOffsetY = 48,

	airFrames = 6,
	airFramespeed = 4,
	airHeight = 90,
}

npcManager.setNpcSettings(sampleNPCSettings)

npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

local STATE_INTRO = 0
local STATE_SHOOT = 1
local STATE_PROPEL1 = 2
local STATE_PROPEL2 = 3
local STATE_PROPEL3 = 4
local STATE_VACCUM = 5
local STATE_BACKFIRE = 6
local STATE_SHOOT2 = 7
local STATE_SHOOT3 = 8
local STATE_FAKEOUT = 9
local STATE_SHOOTSTRAIGHT = 10
local STATE_SHOOTBOUNCY = 11
local STATE_SHOOTCIRCLE = 12
local STATE_STUNCLOUD = 13
local STATE_SLOWCLOUD = 14
local STATE_REVERSECLOUD = 15
local STATE_APPEARDISAPPEAR = 16
local STATE_ATTACK = 17
local STATE_DEFEATED = 18

local spawnOffset = {
	[-1] = -64,
	[1] = sampleNPCSettings.width / 2 + 68
}

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

function isNearPit(v)
	--This function either returns false, or returns the direction the npc should go to. numbers can still be used as booleans.
	local testblocks = Block.SOLID.. Block.SEMISOLID.. Block.PLAYER

	local centerbox = Colliders.Box(v.x-64, v.y, 8, v.height + 10)
	local l = centerbox
	if v.direction == DIR_RIGHT then
		l.x = l.x + 192
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
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = data.state or STATE_INTRO
		data.pullbox = data.pullbox or Colliders.Box(0, 0, 1, 1)
		data.blunderbox = data.blunderbox or Colliders.Box(0, 0, 1, 1)
		data.hurtbox = data.hurtbox or Colliders.Box(0, 0, 1, 1)
		data.attackbox = data.attackbox or Colliders.Box(0, 0, 1, 1)
		data.timer = data.timer or 0
		data.animTimer = 0
		data.cannonBall = data.cannonBall or nil
		data.secondCannonBall = data.secondCannonBall or nil
		data.fireFrame = 0
		data.fireScale = 0
		data.airFrame = 0
		data.airScale = 0
		data.health = config.health
		data.opacity = 1
		data.timesTeleported = 0
	end

	if v.heldIndex ~= 0
	or v.isProjectile
	or v.forcedState > 0
	then
		-- Handling
	end

	data.timer = data.timer + 1
	data.fireFrame = math.floor(lunatime.tick()/config.fireFramespeed) % config.fireFrames
	data.airFrame = math.floor(lunatime.tick()/config.airFramespeed) % config.airFrames

	data.pullbox.width = v.width +512
	data.pullbox.height = v.height + 900

	data.pullbox.y = v.y-600

	if v.direction == 1 then
		data.pullbox.x = v.x
	else
		data.pullbox.x = v.x-512
	end

	data.blunderbox.width = v.width-32
	data.blunderbox.height = v.height-64

	data.blunderbox.y = v.y+32

	if v.direction == 1 then
		data.blunderbox.x = v.x+96
	else
		data.blunderbox.x = v.x-48
	end

	data.hurtbox.width = v.width
	data.hurtbox.height = v.height

	data.hurtbox.x = v.x
	data.hurtbox.y = v.y

	--data.pullbox:Debug(true)
	--data.blunderbox:Debug(true)
	--data.hurtbox:Debug(true)
	--data.attackbox:Debug(true)

	data.attackbox.width = v.width-32
	data.attackbox.height = v.height

	data.attackbox.y = v.y

	if v.direction == 1 then
		data.attackbox.x = v.x+64
	else
		data.attackbox.x = v.x-24
	end

	if v.direction == 1 then
		config.fireOffsetXLeft = config.fireOffsetXRight
		config.airOffsetXLeft = config.airOffsetXLeftOG
	else
		config.fireOffsetXLeft = config.fireOffsetXOGLeft
		config.airOffsetXLeft = config.airOffsetXRight
	end

	local vaccumSound = nil

	if data.state == STATE_INTRO then
		v.animationFrame = math.floor(data.timer/14)%4

		if data.timer > 150 then
			data.state = STATE_SHOOT
			v.animationFrame = 12
			data.timer = 0
		elseif data.timer > 78 then
			v.animationFrame = math.floor(data.timer/14)%4+8
		elseif data.timer > 48 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%4+4
		end
	elseif data.state == STATE_SHOOT then
		if data.timer > 180 then
			data.state = STATE_PROPEL1 
			data.timer = 0
		elseif data.timer > 16 then
			v.animationFrame = math.floor(data.timer/14)%4+8
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer/8)%3+12
		end

		if data.timer == 1 then
			local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
			e.speedX = 2*v.direction
			data.cannonBall = NPC.spawn(npcID+1, v.x + spawnOffset[v.direction], v.y-16 + v.height / 2, player.section, false)
			data.cannonBall.direction = v.direction
			data.cannonBall.speedX = 8.5*v.direction
			SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
		end
	elseif data.state == STATE_PROPEL1 then
		v.friendly = true

		if Colliders.collide(player, data.hurtbox) then
			player:harm()
		end

		local e = Effect.spawn(74,0,0)

		e.x = v.x+(v.width/2)+(e.width/2)-v.speedX+RNG.random(-v.width/10,v.width/10)
		e.y = v.y+v.height-e.height * 0.5

		if data.health == 3 then
			v.speedX = math.clamp((v.speedX+(math.sign(5*v.direction)*0.1)),-1,1)
		else
			v.speedX = math.clamp((v.speedX+(math.sign(5*v.direction)*0.1)),-5.5,5.5)
		end

		if data.timer > 7 then
			v.animationFrame = 18
			data.fireScale = 1

			if isNearPit(v) then
				data.fireScale = 0
				v.animationFrame = math.floor(data.timer/14)%4+8
				v.speedX = 0

				if data.health == 9 then
					data.state = STATE_VACCUM
					v.friendly = false
				elseif data.health == 8 then
					data.state = STATE_PROPEL2
				elseif data.health == 7 then
					data.state = STATE_PROPEL2
				elseif data.health == 5 then
					data.state = STATE_SHOOTBOUNCY
				elseif data.health == 4 then
					data.state = STATE_SHOOTCIRCLE
				elseif data.health == 3 then
					data.state = STATE_PROPEL2
				elseif data.health == 2 then
					data.state = STATE_SLOWCLOUD
				elseif data.health == 1 then
					data.state = STATE_REVERSECLOUD
				end
	
				v.direction = -v.direction
				data.timer = 0
			end
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer/3)%4+15
		end
	elseif data.state == STATE_VACCUM then
		v.animationFrame = math.floor(data.timer/14)%4+8

		if data.health < 4 then
			data.opacity = data.opacity + 0.064

			if data.opacity > 1 then
				data.opacity = 1
			end
		end

		if data.health == 3 or data.health == 2 or data.health == 1 then
			if data.timer > 50 then
				v.animationFrame = math.floor(data.timer/14)%4+8
			elseif data.timer > 30 then
				v.animationFrame = math.floor(data.timer/8)%3+12
			end
		
			if data.timer == 31 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				data.cannonBall = NPC.spawn(npcID+1, v.x + spawnOffset[v.direction], v.y-16 + v.height / 2, player.section, false)
				data.cannonBall.direction = v.direction
				data.cannonBall.speedX = 8.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		end

		if data.timer > 180 then
			v.animationFrame = 11
			data.airScale = 1

			Text.print(vaccumSound,100,100)

			if not vaccumSound then
				vaccumSound = SFX.create{x=v.x,y=v.y,sound="Kaptain K. Rool SFX/Kaptain King Rool Vaccum.mp3",falloffRadius=128}
			end

			if Colliders.collide(player, data.pullbox) then
				player.speedX = 2.5*-v.direction

				if player.keys.right and v.direction == 1 then
					player.speedX = 1.3*-v.direction
				elseif player.keys.left and v.direction == 1 then
					player.speedX = 4*-v.direction
				end

				if player.keys.left and v.direction == -1 then
					player.speedX = 1.3*-v.direction
				elseif player.keys.right and v.direction == -1 then
					player.speedX = 4*-v.direction
				end
			end

			if Colliders.collide(player, data.attackbox) then
				data.state = STATE_ATTACK
				data.airScale = 0
				v.animationFrame = 32
				data.timer = 0

				if vaccumSound and vaccumSound.isValid and vaccumSound.playing then
					vaccumSound:destroy()
					vaccumSound = nil
				end
			end

			for _,p in ipairs(NPC.getIntersecting(data.blunderbox.x - 6, data.blunderbox.y - 6, data.blunderbox.x + data.blunderbox.width + 6, data.blunderbox.y + data.blunderbox.height + 6)) do
				if p.isProjectile and not p.friendly and p.id == npcID+1 then
					p:kill(HARM_TYPE_VANISH)
					Effect.spawn(792, data.blunderbox.x, data.blunderbox.y-16)
					SFX.play("Kaptain K. Rool SFX/Cannon ball in Cauldron.mp3")
					data.state = STATE_BACKFIRE
					data.airScale = 0
					v.animationFrame = 12
					data.timer = 0
					
					if vaccumSound and vaccumSound.isValid and vaccumSound.playing then
						vaccumSound:destroy()
						vaccumSound = nil
					end
				end

				if p.isProjectile and not p.friendly and p.id == npcID+1 and data.health == 1 then
					p:kill(HARM_TYPE_VANISH)
					Effect.spawn(792, data.blunderbox.x, data.blunderbox.y-16)
					SFX.play("Kaptain K. Rool SFX/Cannon ball in Cauldron.mp3")
					data.state = STATE_DEFEATED
					data.airScale = 0
					v.animationFrame = 12
					data.timer = 0

					if vaccumSound and vaccumSound.isValid and vaccumSound.playing then
						vaccumSound:destroy()
						vaccumSound = nil
					end
				end
			end
		end
	elseif data.state == STATE_BACKFIRE then

		if data.secondCannonBall and data.secondCannonBall.isValid then
			data.secondCannonBall:kill(HARM_TYPE_NPC)
		end

		if data.timer > 300 then
			if data.health == 8 then
				data.state = STATE_SHOOT2
				data.timer = 0
			elseif data.health == 7 then
				data.state = STATE_SHOOT3
				data.timer = 0
			elseif data.health == 5 then
				data.state = STATE_PROPEL1
				data.timer = 0
			elseif data.health == 4 then
				data.state = STATE_PROPEL1
				data.timer = 0
			elseif data.health == 2 then
				data.state = STATE_PROPEL1
				data.timer = 0
			elseif data.health == 1 then
				data.state = STATE_PROPEL1
				data.timer = 0
			end
		elseif data.timer > 260 then
			v.animationFrame = math.floor(data.timer/14)%4+8

			if data.health == 6 then
				data.state = STATE_FAKEOUT
				data.timer = 0
			elseif data.health == 3 then
				data.state = STATE_FAKEOUT
				data.timer = 0
			end
		elseif data.timer > 220 then
			v.animationFrame = 20

			if data.timer%4 > 0 and data.timer%4 < 3 then
				v.x = v.x + 2
			else
				v.x = v.x - 2
			end

			if RNG.randomInt(1,4) == 1 then
				local e = Effect.spawn(npcID+1, v.x - 8 + RNG.randomInt(0,v.width), v.y + RNG.randomInt(0,v.height))
		
				e.x = e.x - e.width *0.5
				e.y = e.y - e.height*0.5
				e.speedY = -1.6
			end
		elseif data.timer > 180 then
			v.animationFrame = 20
		elseif data.timer > 150 then
			v.animationFrame = math.floor(data.timer/12)%4+20
		elseif data.timer > 110 then
			v.animationFrame = 20
		elseif data.timer == 109 then
			Effect.spawn(npcID+2, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
			data.cannonBall = NPC.spawn(npcID+2, v.x + spawnOffset[v.direction], v.y-16 + v.height / 2, player.section, false)
			data.cannonBall.direction = v.direction
			data.cannonBall.speedX = 8.5*v.direction
			SFX.play("Kaptain K. Rool SFX/TNT DKC2.mp3")
			data.health = data.health - 1
			v.animationFrame = 19

			local e = Effect.spawn(npcID+2, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
			e.speedX = 6*-v.direction
			e.speedY = -1.5

			local e2 = Effect.spawn(npcID+2, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
			e2.speedX = 6*-v.direction
			e2.speedY = 1.5
		elseif data.timer > 60 then
			v.animationFrame = 19
			if data.timer == 61 then SFX.play("Kaptain K. Rool SFX/Kaptain King Rool gun play up.mp3") end
		elseif data.timer > 16 then
			v.animationFrame = 11
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer/8)%3+12
		end
	elseif data.state == STATE_SHOOT2 then
		if data.timer > 180 then
			data.state = STATE_PROPEL1
			data.timer = 0
		elseif data.timer > 16 then
			v.animationFrame = math.floor(data.timer/14)%4+8
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer/8)%3+12
		end

		if data.cannonBall and data.cannonBall.isValid then
			if data.timer == 48 then
				data.cannonBall.data.state = 1
				data.cannonBall.data.timer = 0
			end
		end
	
		if data.timer == 1 then
			local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
			e.speedX = 2*v.direction
			data.cannonBall = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y-16 + v.height / 2, player.section, false)
			data.cannonBall.direction = v.direction
			data.cannonBall.speedX = 8.5*v.direction
			SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
		end
	elseif data.state == STATE_SHOOT3 then
		if data.timer > 180 then
			data.state = STATE_PROPEL1
			data.timer = 0
		elseif data.timer > 48 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 32 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12

			if data.timer == 33 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				data.cannonBall = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y-16 + v.height / 2, player.section, false)
				data.cannonBall.direction = v.direction
				data.cannonBall.speedX = 6.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 16 then
			v.animationFrame = math.floor(data.timer/14)%4+8
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer/8)%3+12
		end

		if data.cannonBall and data.cannonBall.isValid then
			if data.timer == 80 then
				data.cannonBall.data.state = 1
				data.cannonBall.data.timer = 0
			end
		end

		if data.secondCannonBall and data.secondCannonBall.isValid then
			if data.timer == 80 then
				data.secondCannonBall.data.state = 1
				data.secondCannonBall.data.timer = 0
			end
		end
	
		if data.timer == 1 then
			local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
			e.speedX = 2*v.direction
			data.secondCannonBall = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y-16 + v.height / 2, player.section, false)
			data.secondCannonBall.direction = v.direction
			data.secondCannonBall.speedX = 11.5*v.direction
			SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
		end
	elseif data.state == STATE_PROPEL2 then
		v.friendly = true

		if Colliders.collide(player, data.hurtbox) then
			player:harm()
		end

		local e = Effect.spawn(74,0,0)

		e.x = v.x+(v.width/2)+(e.width/2)-v.speedX+RNG.random(-v.width/10,v.width/10)
		e.y = v.y+v.height-e.height * 0.5

		v.speedX = math.clamp((v.speedX+(math.sign(6*v.direction)*0.1)),-6.5,6.5)

		if data.health == 3 then
			data.opacity = 0.5
		end

		if data.timer > 7 then
			v.animationFrame = 18
			data.fireScale = 1

			if isNearPit(v) then
				data.fireScale = 0
				v.animationFrame = math.floor(data.timer/14)%4+8
				v.speedX = 0

				if data.health == 8 then
					data.state = STATE_VACCUM
				elseif data.health == 7 then
					data.state = STATE_PROPEL3
				elseif data.health == 3 then
					data.state = STATE_PROPEL3
				end
				v.direction = -v.direction
				v.friendly = false
				data.timer = 0

				if data.health == 8 then
					if data.cannonBall and data.cannonBall.isValid then
						data.cannonBall.data.state = 2
						data.cannonBall.data.timer = 0
					end
				end
			end
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer/3)%4+15
		end
	elseif data.state == STATE_PROPEL3 then
		v.friendly = true

		if Colliders.collide(player, data.hurtbox) then
			player:harm()
		end

		v.speedX = math.clamp((v.speedX+(math.sign(8*v.direction)*0.1)),-8.5,8.5)

		local e = Effect.spawn(74,0,0)

		e.x = v.x+(v.width/2)+(e.width/2)-v.speedX+RNG.random(-v.width/10,v.width/10)
		e.y = v.y+v.height-e.height * 0.5

		if data.health < 4 then
			data.opacity = data.opacity - 0.064

			if data.opacity < 0 then
				data.opacity = 0
			end
		end

		if data.timer > 7 then
			v.animationFrame = 18
			data.fireScale = 1

			if isNearPit(v) then
				data.fireScale = 0
				v.animationFrame = math.floor(data.timer/14)%4+8
				v.speedX = 0
	
				data.state = STATE_VACCUM
				v.direction = -v.direction
				v.friendly = false
				data.timer = 0

				if data.cannonBall and data.cannonBall.isValid then
					data.cannonBall.data.state = 2
					data.cannonBall.data.timer = 0
				end
			end
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer/3)%4+15
		end
	elseif data.state == STATE_FAKEOUT then
		v.friendly = true
		v.animationFrame = math.floor(data.timer/14)%4

		if data.timer > 220 then
			if data.health == 6 then
				data.state = STATE_SHOOTSTRAIGHT
			elseif data.health == 3 then
				data.state = STATE_STUNCLOUD
			end
			v.friendly = false
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.timer = 0
		elseif data.timer > 176 then
			v.animationFrame = math.floor(data.timer/14)%4+8
		elseif data.timer > 172 then
			v.animationFrame = 31
		elseif data.timer > 168 then
			v.animationFrame = 30
		elseif data.timer > 162 then
			v.animationFrame = 29
		elseif data.timer > 156 then
			v.animationFrame = 28
		elseif data.timer > 150 then
			v.animationFrame = 27
		elseif data.timer > 90 then
			v.animationFrame = 28
		elseif data.timer > 12 then
			v.animationFrame = 27
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer/6)%4+24
			if data.timer == 2 then 
				SFX.play("Kaptain K. Rool SFX/Kaptain King Rool hurt.mp3")
			end
		end
	elseif data.state == STATE_SHOOTSTRAIGHT then
		if data.timer > 600 then
			data.state = STATE_VACCUM
			data.timer = 0
		elseif data.timer > 460 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 440 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 441 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local b = NPC.spawn(834, v.x + spawnOffset[v.direction], v.y-16 + v.height / 2, player.section, false)
				b.data.state = 0
				b.direction = v.direction
				b.speedX = 2.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 380 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 360 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 361 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y-48 + v.height / 2, player.section, false)
				c.data.state = 3
				c.direction = v.direction
				c.speedX = 4.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 350 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 330 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 331 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 3
				c.direction = v.direction
				c.speedX = 4.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 320 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 300 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 301 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y-48 + v.height / 2, player.section, false)
				c.data.state = 3
				c.direction = v.direction
				c.speedX = 4.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 280 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 260 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 261 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 3
				c.direction = v.direction
				c.speedX = 4.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 240 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 220 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 221 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y-16 + v.height / 2, player.section, false)
				c.data.state = 3
				c.direction = v.direction
				c.speedX = 4.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 200 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 180 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 181 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y-16 + v.height / 2, player.section, false)
				c.data.state = 3
				c.direction = v.direction
				c.speedX = 4.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 140 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 120 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 121 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y-48 + v.height / 2, player.section, false)
				c.data.state = 3
				c.direction = v.direction
				c.speedX = 4.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 100 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 80 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 81 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 3
				c.direction = v.direction
				c.speedX = 4.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 16 then
			v.animationFrame = math.floor(data.timer/14)%4+8
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer/8)%3+12
		end

		if data.timer == 1 then
			local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
			e.speedX = 2*v.direction
			local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y-16 + v.height / 2, player.section, false)
			c.data.state = 3
			c.direction = v.direction
			c.speedX = 4.5*v.direction
			SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
		end
	elseif data.state == STATE_SHOOTBOUNCY then
		if data.timer > 860 then
			data.state = STATE_VACCUM
			data.timer = 0
		elseif data.timer > 700 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 680 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 681 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local b = NPC.spawn(834, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				b.data.state = 1
				b.direction = v.direction
				b.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 610 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 590 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 591 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 6
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 550 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 530 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 531 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 5
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 490 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 470 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 471 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 6
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 430 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 410 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 411 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 5
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 370 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 350 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 351 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 6
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 310 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 290 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 291 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 5
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 250 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 230 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 231 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 4
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 180 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 160 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 161 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 5
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 70 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 50 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 51 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 4
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer/14)%4+8
		end
	elseif data.state == STATE_SHOOTCIRCLE then
		if data.timer > 1100 then
			data.state = STATE_VACCUM
			data.timer = 0
		elseif data.timer > 990 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 972 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 973 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local b = NPC.spawn(834, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				b.data.state = 2
				b.direction = v.direction
				b.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Cannon ball spin.mp3")
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 830 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 812 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 813 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 9
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Cannon ball spin.mp3")
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 810 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 790 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 791 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 9
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Cannon ball spin.mp3")
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 660 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 642 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 643 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 8
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Cannon ball spin.mp3")
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 640 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 620 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 621 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 8
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Cannon ball spin.mp3")
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 520 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 502 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 503 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 7
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Cannon ball spin.mp3")
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 500 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 480 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 481 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 7
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Cannon ball spin.mp3")
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 310 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 290 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 291 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 9
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Cannon ball spin.mp3")
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 180 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 160 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 161 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 8
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Cannon ball spin.mp3")
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 70 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 50 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 51 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 7
				c.direction = v.direction
				c.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Cannon ball spin.mp3")
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer/14)%4+8
		end
	elseif data.state == STATE_STUNCLOUD then
		if data.timer > 170 then
			data.state = STATE_PROPEL1
			data.timer = 0
		elseif data.timer > 130 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 110 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 111 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local stunCloud = NPC.spawn(npcID+4, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				stunCloud.direction = v.direction
				stunCloud.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 100 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 80 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 81 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local stunCloud = NPC.spawn(npcID+4, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				stunCloud.direction = v.direction
				stunCloud.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 70 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 50 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 51 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local stunCloud = NPC.spawn(npcID+4, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				stunCloud.direction = v.direction
				stunCloud.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer/14)%4+8
		end
	elseif data.state == STATE_SLOWCLOUD then
		if data.timer > 400 then
			data.state = STATE_VACCUM
			data.timer = 0
		elseif data.timer > 320 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 300 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 301 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 3
				c.direction = v.direction
				c.speedX = 2*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 270 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 250 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 251 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 3
				c.direction = v.direction
				c.speedX = 2*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 220 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 200 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 201 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local c = NPC.spawn(npcID+3, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				c.data.state = 3
				c.direction = v.direction
				c.speedX = 2*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 130 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 110 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 111 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local slowCloud = NPC.spawn(npcID+5, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				slowCloud.direction = v.direction
				slowCloud.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 100 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 80 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 81 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local slowCloud = NPC.spawn(npcID+5, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				slowCloud.direction = v.direction
				slowCloud.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 70 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 50 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 51 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local slowCloud = NPC.spawn(npcID+5, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				slowCloud.direction = v.direction
				slowCloud.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer/14)%4+8
		end
	elseif data.state == STATE_REVERSECLOUD then
		if data.timer > 480 then
			data.state = STATE_APPEARDISAPPEAR
			data.timer = 0
		elseif data.timer > 400 then
			v.animationFrame = 11
			data.airScale = 1

			local vaccumSound = SFX.create{x=v.x,y=v.y,sound="Kaptain K. Rool SFX/Kaptain King Rool Vaccum.mp3",falloffRadius=128}

			if data.timer > 140 then
				data.airScale = 0
	
				data.opacity = data.opacity - 0.064
	
				if data.opacity < 0 then
					data.opacity = 0
				end
	
				if vaccumSound.playing then
					vaccumSound:stop()
				end
			end

			if Colliders.collide(player, data.pullbox) then
				player.speedX = 5*-v.direction

				if player.keys.right and v.direction == 1 then
					player.speedX = 2*-v.direction
				elseif player.keys.left and v.direction == 1 then
					player.speedX = 6.5*-v.direction
				end

				if player.keys.left and v.direction == -1 then
					player.speedX = 2*-v.direction
				elseif player.keys.right and v.direction == -1 then
					player.speedX = 6.5*-v.direction
				end
			end

			if Colliders.collide(player, data.attackbox) then
				data.state = STATE_ATTACK
				data.airScale = 0
				v.animationFrame = 32
				data.timer = 0
			end
		elseif data.timer > 130 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 110 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 111 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local reverseCloud = NPC.spawn(npcID+6, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				reverseCloud.direction = v.direction
				reverseCloud.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Cannon ball spin.mp3")
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 100 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 80 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 81 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local reverseCloud = NPC.spawn(npcID+6, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				reverseCloud.direction = v.direction
				reverseCloud.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Cannon ball spin.mp3")
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 70 then
			v.animationFrame = math.floor(data.timer/14)%4+8
			data.animTimer = 0
		elseif data.timer > 50 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer/8)%3+12
	
			if data.timer == 51 then
				local e = Effect.spawn(npcID, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
				e.speedX = 2*v.direction
				local reverseCloud = NPC.spawn(npcID+6, v.x + spawnOffset[v.direction], v.y + v.height / 2, player.section, false)
				reverseCloud.direction = v.direction
				reverseCloud.speedX = 3.5*v.direction
				SFX.play("Kaptain K. Rool SFX/Cannon ball spin.mp3")
				SFX.play("Kaptain K. Rool SFX/Barrel_blast.mp3")
			end
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer/14)%4+8
		end
	elseif data.state == STATE_APPEARDISAPPEAR then
		v.animationFrame = 11
		if data.timer > 160 then
			data.state = STATE_APPEARDISAPPEAR
			data.timesTeleported = data.timesTeleported + 1
			data.timer = 0
		elseif data.timer > 80 then
			data.airScale = 1

			local vaccumSound = SFX.create{x=v.x,y=v.y,sound="Kaptain K. Rool SFX/Kaptain King Rool Vaccum.mp3",falloffRadius=128}

			if data.timer > 140 then
				data.airScale = 0
	
				data.opacity = data.opacity - 0.064
	
				if data.opacity < 0 then
					data.opacity = 0
				end
	
				if vaccumSound.playing then
					vaccumSound:stop()
				end
			end

			if Colliders.collide(player, data.pullbox) then
				player.speedX = 5*-v.direction

				if player.keys.right and v.direction == 1 then
					player.speedX = 2*-v.direction
				elseif player.keys.left and v.direction == 1 then
					player.speedX = 6.5*-v.direction
				end

				if player.keys.left and v.direction == -1 then
					player.speedX = 2*-v.direction
				elseif player.keys.right and v.direction == -1 then
					player.speedX = 6.5*-v.direction
				end
			end

			if Colliders.collide(player, data.attackbox) then
				data.state = STATE_ATTACK
				data.airScale = 0
				v.animationFrame = 32
				data.timer = 0
			end
		elseif data.timer > 62 then
			data.opacity = data.opacity + 0.064

			if data.timesTeleported > 5 then
				data.state = STATE_VACCUM
				data.timesTeleported = 0
				data.timer = 0
			end

			v.friendly = false

			if data.opacity > 1 then
				data.opacity = 1
			end
			v.animationFrame = 11
			v.speedX = 0
			if v.x > player.x then
				v.direction = -1
			else
				v.direction = 1
			end
		elseif data.timer > 1 then
			v.friendly = true
		end

		if data.timer == 1 then
			if v.direction == 1 then
				v.speedX = RNG.randomEntry({0,10})
			else
				v.speedX = RNG.randomEntry({0,-10})
			end
		end
	elseif data.state == STATE_DEFEATED then
		v.friendly = true

		if data.secondCannonBall and data.secondCannonBall.isValid then
			data.secondCannonBall:kill(HARM_TYPE_NPC)
		end
		
		if data.timer > 211 and v.collidesBlockBottom then
			v.animationFrame = math.floor(data.timer/6)%4+24

			if v.collidesBlockBottom then
				data.animTimer = data.animTimer + 1

				if data.animTimer == 1 then SFX.play("Kaptain K. Rool SFX/Kaptain King Rool hurt.mp3") end

				if data.animTimer > 11 then
					v.animationFrame = 27
				end

				if data.animTimer == 90 then
					local orb = NPC.spawn(354, v.x-32+v.width*0.5, v.y+v.height*0.5, player.section, false)
					orb.speedY = -6
					orb.speedX = 5.1*v.direction
					SFX.play(20)
					v.animationFrame = 27
				end
			end
		elseif data.timer > 210 then
			v.animationFrame = 25
			if lunatime.tick() % 8 == 0 then
				Effect.spawn(801, v.x-12 + v.width*0.5, v.y + v.height*0.5)
			end
		elseif data.timer == 210 then
			Effect.spawn(npcID+2, v.x + spawnOffset[v.direction], v.y-24 + v.height / 2, player.section, false)
			SFX.play("Kaptain K. Rool SFX/TNT DKC2.mp3")
			SFX.play("Kaptain K. Rool SFX/Kaptain King Rool hurt.mp3")
			data.health = data.health - 1
			v.speedY = -20

			local e = Effect.spawn(npcID+2, v.x, v.y-24 + v.height / 2, player.section, false)
			e.speedX = 6*-v.direction
			e.speedY = -1.5

			local e2 = Effect.spawn(npcID+2, v.x, v.y-24 + v.height / 2, player.section, false)
			e2.speedX = 6*-v.direction
			e2.speedY = 1.5

			local e3 = Effect.spawn(npcID+2, v.x, v.y-24 + v.height / 2, player.section, false)
			e3.speedX = 6*v.direction
			e3.speedY = -1.5

			local e4 = Effect.spawn(npcID+2, v.x, v.y-24 + v.height / 2, player.section, false)
			e4.speedX = 6*v.direction
			e4.speedY = 1.5
		elseif data.timer > 160 then
			v.animationFrame = 19
			if data.timer == 161 then SFX.play("Kaptain K. Rool SFX/Kaptain King Rool gun play up.mp3") end
		elseif data.timer > 140 then
			v.animationFrame = 11
		elseif data.timer > 120 then
			v.animationFrame = 19
		elseif data.timer > 90 then
			v.animationFrame = 11
		elseif data.timer > 60 then
			v.animationFrame = 19
		elseif data.timer > 16 then
			v.animationFrame = 11
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer/8)%3+12
		end
	elseif data.state == STATE_ATTACK then
		if data.cannonBall and data.cannonBall.isValid then
			data.cannonBall:kill(HARM_TYPE_NPC)
		end
		if data.secondCannonBall and data.secondCannonBall.isValid then
			data.secondCannonBall:kill(HARM_TYPE_NPC)
		end
		if data.timer > 100 then
			data.timer = 0
			if data.health == 9 then
				data.state = STATE_SHOOT
			elseif data.health == 8 then
				data.state = STATE_SHOOT2
			elseif data.health == 7 then
				data.state = STATE_SHOOT3
			elseif data.health == 6 then
				data.state = STATE_SHOOTSTRAIGHT
			elseif data.health == 5 then
				data.state = STATE_SHOOTBOUNCY
			elseif data.health == 4 then
				data.state = STATE_SHOOTCIRCLE
			elseif data.health == 3 then
				data.state = STATE_STUNCLOUD
			elseif data.health == 2 then
				data.state = STATE_SLOWCLOUD
			elseif data.health == 1 then
				data.state = STATE_REVERSECLOUD
			end
		elseif data.timer > 40 then
			v.animationFrame = math.floor(data.timer/14)%4+8
		elseif data.timer > 26 then
			v.animationFrame = 34
		elseif data.timer > 24 then
			v.animationFrame = 33
			if data.timer == 25 then
				player:harm()
				player.speedX = 40*v.direction
				player.speedY = -6
			end
		elseif data.timer > 1 then
			v.animationFrame = 32
			player.speedX = 0

			if data.timer == 2 then SFX.play(35) end
		end
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = data.frames
	});
end

function sampleNPC.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local config = NPC.config[v.id]
	local data = v.data

	local priority = -15

	Text.print(data.health,8,8)
	Text.print(data.timer,8,32)
	Text.print(data.timesTeleported,8,64)

	local img = config.fireImage
	local headHeight = img.height/config.fireFrames

	local opacity = data.opacity
	
	Graphics.drawBox{
		texture = img,
		x = v.x+config.fireOffsetXLeft,
		y = v.y+config.fireOffsetY,
		width = 38*data.fireScale*-v.direction,
		height = 26*data.fireScale,
		sourceY = data.fireFrame * config.fireHeight,
		sourceHeight = config.fireHeight,
		sceneCoords = true,
		centered = true,
		priority = priority+10,
		color = Color.white.. opacity
	}
	
	local img = config.airImage
	local headHeight = img.height/config.airFrames
	
	Graphics.drawBox{
		texture = img,
		x = v.x+config.airOffsetXLeft,
		y = v.y+config.airOffsetY,
		width = 50*data.airScale*-v.direction,
		height = config.airHeight*data.airScale,
		sourceY = data.airFrame * config.airHeight,
		sourceHeight = config.airHeight,
		sceneCoords = true,
		centered = true,
		priority = priority+10,
		color = Color.white.. opacity
	}

	local img = Graphics.sprites.npc[v.id].img

    Graphics.drawBox{
        texture = img,
        x = v.x + v.width/2,
        y = v.y + v.height-44,
        width = config.gfxwidth,
        sourceY = v.animationFrame * config.gfxheight,
        sourceHeight = config.gfxheight,
        sourceWidth = config.gfxwidth,
        sceneCoords = true,
        centered = true,
        priority = priority-30,
		color = Color.white.. opacity
    }

	npcutils.hideNPC(v)
end

return sampleNPC