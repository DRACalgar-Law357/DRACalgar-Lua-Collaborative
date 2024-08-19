--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local easing = require("ext/easing")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
local freeze = require("freezeHighlight")
local afterimages = require("afterimages")
local playerStun = require("playerstun")
--Create the library table
local pyroBlaster = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

local STATE_CEILING = 0
local STATE_TRAP = 1
local STATE_BARRAGE = 2
local STATE_BOMBS = 3
local STATE_SHOWER = 4
local STATE_BURNER = 5
local STATE_RINKA = 6
local STATE_SPOUT = 7
local STATE_SHOCKWAVE = 8
local STATE_SCORCH = 9
local STATE_KILL = 10
local STATE_RETURN = 11
local STATE_KAMIKAZE = 12 --Spinning Hell

--Defines NPC config for our NPC. You can remove superfluous definitions.
local pyroBlasterSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 64,
	gfxwidth = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = true,
	npcblocktop = true, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = true,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	terminalvelocity = 10,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
	health = 120,
	effectExplosion1ID = 950,
	effectExplosion2ID = 952,
	cannonImg = Graphics.loadImageResolved("npc-"..npcID.."-cannon.png"),
	iFramesSet = 0,
	--An iFrame system that has the boss' frame be turned invisible from the set of frames periodically.
	--Set 0 defines its hurtTimer until it is at its iFramesDelay
	--Set 1 defines the same from Set 0 but whenever the boss has been harmed, it stacks up the iFramesDelay the more. The catch is that when the boss has been left alone after getting harmed, it resets the iFramesStacks so that the player can be able to jump on the boss for some time again.
	iFramesDelay = 32,
	iFramesDelayStack = 48,
	useFreezeHighlight = true,
	pulsex = true, -- controls the scaling of the sprite when firing
	pulsey = true,
	shockwaveid = 824,
	effectid = 131,
	effectoffsetx = -16,
	effectoffsety = -16,
	cannonx = -8,
	cannony = -8,

	fireid = 547,
	mechakoopaID = 368,
	bombID = 134,
	lightningID = 361,
	walkSpeed = 2.5,
	walkRange = 192,
	walkTurnDelay = {min = 40, max = 90},
	idleDelay = {min=120,max=180},
	shockwavetargetxlimit = 800,
	independantAttackTable = {
		attackTable = {
			[1] = {state = STATE_BARRAGE, hpmin = 80, hpmax = 120},
			[2] = {state = STATE_BOMBS, hpmin = 80, hpmax = 120},
			[3] = {state = STATE_TRAP, hpmin = 80, hpmax = 120},
			[4] = {state = STATE_SHOWER, hpmin = 40, hpmax = 80},
			[5] = {state = STATE_BURNER, hpmin = 0, hpmax = 80},
			[6] = {state = STATE_RINKA, hpmin = 0, hpmax = 80},
			[7] = {state = STATE_SPOUT, hpmin = 0, hpmax = 40},
			[8] = {state = STATE_SCORCH, hpmin = 0, hpmax = 40},
			[9] = {state = STATE_SHOCKWAVE, hpmin = 0, hpmax = 40},
			[10] = {state = STATE_SCORCH, hpmin = 0, hpmax = 40},
			[11] = {state = STATE_TRAP, hpmin = 0, hpmax = 40},
			[12] = {state = STATE_SCORCH, hpmin = 0, hpmax = 40},
		},
	},
	giveMushroomIndex = {
		[0] = 80,
		[1] = 40,
	},
}

--Applies NPC settings
npcManager.setNpcSettings(pyroBlasterSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=952,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below

local shoot = Misc.resolveFile("Missile Deploy.wav")
local shower = Misc.resolveFile("Machine Gun-ish.wav")
local lob = Misc.resolveFile("Missile.wav")
local stomp = Misc.resolveFile("Mech Stomp.wav")
local rise = Misc.resolveFile("Mech Rising.wav")
local ready = Misc.resolveFile("Machine Noise.wav")
local bombs = Misc.resolveFile("Small Explosion.wav")
local whoosh = Misc.resolveFile("Small Rocket Woosh.wav")
local hit = Misc.resolveFile("s3k_damage.ogg")
local explode = Misc.resolveFile("s3k_detonate.ogg")
local bigexplode = Misc.resolveFile("Explosion 2.wav")
local noise1 = Misc.resolveFile("sfx_pyroBlasterNoise1.wav")
local swipe = Misc.resolveFile("swipe.ogg")
local fireball = Misc.resolveFile("sfx_pyroBlasterFireball.wav")
local firebarrier = Misc.resolveSoundFile("flame-shield")
local firerelease = Misc.resolveSoundFile("flame-shield-dash")
local noise2 = Misc.resolveFile("sfx_pyroBlasterNoise2.wav")
local shockwave = Misc.resolveFile("Machine Hit.wav")
local pika = {
	Misc.resolveSoundFile("nitro-bounce"),
	Misc.resolveSoundFile("nitro-bounce-1"),
	Misc.resolveSoundFile("nitro-bounce-2"),
	Misc.resolveSoundFile("nitro-bounce-3"),
}
local destruct = Misc.resolveFile("Zany Explosion.wav")

local hurtCooldown = 160
local hpboarder = Graphics.loadImage("hpconboss.png")
local hpfill = Graphics.loadImage("hpfillboss.png")

--Code to manually draw the afterimage
local function drawAfterimage(v)
	local gfxw = NPC.config[v.id].gfxwidth
	local gfxh = NPC.config[v.id].gfxheight
	if gfxw == 0 then gfxw = v.width end
	if gfxh == 0 then gfxh = v.height end
	local frames = Graphics.sprites.npc[v.id].img.height / gfxh
	local framestyle = NPC.config[v.id].framestyle
	local frame = v.animationFrame
	local framesPerSection = frames
	if framestyle == 1 then
		framesPerSection = framesPerSection * 0.5
		if direction == 1 then
			frame = frame + frames
		end
		frames = frames * 2
	elseif framestyle == 2 then
		framesPerSection = framesPerSection * 0.25
		if direction == 1 then
			frame = frame + frames
		end
		frame = frame + 2 * frames
	end
	local p = priority or -46
	afterimages.addAfterImage{
		x = v.x + 0.5 * v.width - 0.5 * gfxw + NPC.config[v.id].gfxoffsetx,
		y = v.y + 0.5 * v.height - 0.5 * gfxh + NPC.config[v.id].gfxoffsety,
		texture = Graphics.sprites.npc[v.id].img,
		priority = p,
		lifetime = 24,
		width = gfxw,
		height = gfxh,
		texOffsetX = 0,
		texOffsetY = frame / frames,
		animWhilePaused = false,
		color = (Color.red .. 0)
	}
end

local function initFire(v, f, dir)
	f.data._basegame = {}
	f.data._basegame.dir = dir
	f.data._basegame.spread = v.data._basegame.spread - 1
	f.data._basegame.wasThrown = v.data._basegame.wasThrown or false
	if v.data._basegame.friendly ~= nil then
		f.friendly = v.data._basegame.friendly
	else
		f.friendly = v.friendly
	end
	f.layerName = "Spawned NPCs"
	return f
end

local function shouldSpawnFire(settings, timer)
    local tps = Misc.GetEngineTPS()
    local lifetimeTicks = math.floor(tps * settings.fireLifetime)
    local downtimeTicks = math.floor(tps * settings.downtime)
    return (timer-10) % ((lifetimeTicks + downtimeTicks) * settings.cycleCount) == (lifetimeTicks + downtimeTicks) * (settings.cycleIndex-1)
end

local function cannonSetAngle(v,data,config,settings,cannon,angle)
	if data.cannon and data.cannonAngle and data.cannon[cannon] and data.cannonAngle[cannon] then
		data.cannonAngle[cannon] = angle
	end
end

local function cannonAngleReset(v,data,config,settings)
	if data.cannon and data.cannonAngle then
		for i=0,3 do
			if data.cannon[i] and data.cannonAngle[i] then
				data.cannonAngle[i] = 0
			end
		end
	end
end

local function getDistance(k,p)
	return k.x + k.width/2 < p.x + p.width/2
end

local function setDir(dir, v)
	if (dir and v.data._basegame.direction == 1) or (v.data._basegame.direction == -1 and not dir) then return end
	if dir then
		v.data._basegame.direction = 1
	else
		v.data._basegame.direction = -1
	end
end

local function chasePlayers(v)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local dir1 = getDistance(v, plr)
	setDir(dir1, v)
end

local function decideAttack(v,data,config,settings)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local px = plr.x + plr.width / 2
	local vx = v.x + v.width / 2
	local options = {}
	local specifiedThreshold
	specifiedThreshold = config.independantAttackTable.attackTable
    if specifiedThreshold and #specifiedThreshold > 0 then
        for i in ipairs(specifiedThreshold) do
            if data.health > specifiedThreshold[i].hpmin and data.health <= specifiedThreshold[i].hpmax then
                if specifiedThreshold[i].state ~= data.selectedAttack then
					table.insert(options,specifiedThreshold[i].state)
				end
            end
        end
    end
    if #options > 0 then
        data.state = RNG.irandomEntry(options)
    	data.selectedAttack = data.state
    end
	data.timer = 0
	v.ai1 = 0
end

--Register events
function pyroBlaster.onInitAPI()
	--npcManager.registerEvent(npcID, pyroBlaster, "onTickNPC")
	npcManager.registerEvent(npcID, pyroBlaster, "onTickEndNPC")
	npcManager.registerEvent(npcID, pyroBlaster, "onDrawNPC")
	registerEvent(pyroBlaster, "onNPCHarm")
end


function pyroBlaster.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	local settings = v.data._settings
	local config = NPC.config[v.id]
	v.collisionGroup = "PyroBlasterStuff"
	Misc.groupsCollide["PyroBlasterStuff"]["PyroBlasterStuff"] = false
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		data.hurtTimer = 0
		data.imgActive = false
		return
	end
	local plr = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 0
		data.hurtTimer = data.hurtTimer or 0
		data.iFrames = false
		data.health = NPC.config[v.id].health
		data.state = STATE_CEILING
		data.hurtCooldownTimer = 0
		data.hurting = false
		data.iFramesDelay = NPC.config[v.id].iFramesDelay
		data.iFramesStack = 0
		data.statelimit = 0
		data.imgActive = true
		data.sprSizex = 1
		data.sprSizey = 1
		data.angle = 0
		data.img = Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = config.frames * (1 + config.framestyle), texture = Graphics.sprites.npc[v.id].img}
		data.cannon = {}
		data.cannonAngle = {}
		data.currentAngle = {}
		data.cannonSizex = {}
		data.cannonSizey = {}
		data.kamikazeangle = 0
		data.selectedAttack = -1
		data.mushroomIndex = 0
		for i=0,3 do
			data.cannon[i] = Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = 1, texture = config.cannonImg, pivot = Sprite.align.RIGHT}
			data.cannonAngle[i] = 0
			data.currentAngle[i] = 0
			data.cannonSizex[i] = 1
			data.cannonSizey[i] = 1
		end
		data.fires = nil
		data.spawndelay = settings.spawndelay * Misc.GetEngineTPS()
		data.spawnFireCooldown = 0
		if settings.fireLifetime == 0 or settings.fireLifetime == math.huge then
            settings.fireLifetime = math.huge
            data.spawndelay = 1
        end
		data.consecutive = 0
		data.locationx = 0
		data.angleVelocity = 0
		data.velocityCap = 9
		data.vector = 0
		data.velocity = 0
		data.dropTick = 1
		--v.walkingtimer is how much Pyro Blaster moves before turning around
		v.walkingtimer = 0
		--v.walkingdirection is the direction Pyro Blaster is moving
		v.walkingdirection = v.direction
		--v.initialdirection is Pyro Blaster's initial direction. If the player is beyond their initial direction then they'll chase the player
		v.initialdirection = v.direction
		v.ai2 = RNG.randomInt(config.idleDelay.min,config.idleDelay.max)
		data.turnDelay = RNG.randomInt(config.walkTurnDelay.min,config.walkTurnDelay.max)
	end
	if data.angle > 360 then
		data.angle = data.angle - 360
	end
	if data.kamikazeangle > 360 then
		data.kamikazeangle = data.kamikazeangle - 360
	end

	data.sprSizex = math.max(data.sprSizex - 0.05, 1)
	data.sprSizey = math.max(data.sprSizey - 0.05, 1)
	for i=0,3 do
		data.cannonSizex[i] = math.max(data.cannonSizex[i] - 0.05, 1)
		data.cannonSizey[i] = math.max(data.cannonSizey[i] - 0.05, 1)
	end
	local vectorAngle = vector(0, -1):rotate(data.angle)
	local center = vector(v.x + v.width/2, v.y + v.height/2)
	if data.mushroomIndex and config.giveMushroomIndex and settings.mushroom == true then
		if config.giveMushroomIndex[data.mushroomIndex] and data.health <= config.giveMushroomIndex[data.mushroomIndex] then
			data.mushroomIndex = data.mushroomIndex + 1
			SFX.play(7)
			local n = NPC.spawn(9, v.x + v.width / 2, v.y + v.height/2)
			n.dontMove = true
			n.speedY = -5
		end
	end
	v.animationFrame = 0
	data.timer = data.timer + 1

	if data.state == STATE_CEILING then
		data.checked = data.checked or false
		v.ai4 = v.ai4 + 1
		v.speedX = config.walkSpeed * v.walkingdirection
		v.speedY = 0
				
		v.walkingtimer = v.walkingtimer - v.walkingdirection
		if data.timer == 1 and data.checked == false then
			if data.dropTick <= 0 then
				local npctable = {}
				table.insert(npctable,config.bombID)
				if data.health <= config.health * 1 / 3 then table.insert(npctable,config.lightningID) end
				if data.health <= config.health * 2 / 3 then table.insert(npctable,config.mechakoopaID) end
				if #npctable > 0 then
					if config.pulsex then
						data.cannonSizex[3] = 1.5
					end
			
					if config.pulsey then
						data.cannonSizey[3] = 1.5
					end
					SFX.play(lob)
					local id = RNG.irandomEntry(npctable)
					-- Spawning the NPC --
					local otherAng = vectorAngle:rotate(180)
	
					v1 = NPC.spawn(id, center.x + (otherAng.x * (v.width + config.cannonx)), center.y + (otherAng.y * (v.height + config.cannony)), v.section, false, true)
	
					npcutils.faceNearestPlayer(v1)
					v1.speedY = otherAng.y * 6
					v1.layerName = "Spawned NPCs"
					v1.friendly = data.friendly
	
					-- Spawning smoke --
					a1 = Animation.spawn(config.effectid, v1.x + 0.5 * v1.width + config.effectoffsetx, v1.y + 0.5 * v1.height + config.effectoffsety)
					a1.speedX, a1.speedY = v1.speedX, v1.speedY
					if config.pulsex then
						data.cannonSizex[3] = 1.5
					end
			
					if config.pulsey then
						data.cannonSizey[3] = 1.5
					end
					data.timer = 0
				end
				data.dropTick = RNG.randomInt(0,1)
			else
				data.dropTick = data.dropTick - 1
			end
			data.checked = true
		end
		if v.walkingtimer == config.walkRange or v.walkingtimer == -config.walkRange or v.ai4 >= data.turnDelay then
			v.walkingdirection = v.walkingdirection * -1
			v.ai4 = 0
			data.turnDelay = RNG.randomInt(config.walkTurnDelay.min,config.walkTurnDelay.max)
		end
		if (v.walkingdirection == -1 and v.collidesBlockLeft) or (v.walkingdirection == 1 and v.collidesBlockRight) then
			v.walkingdirection = v.walkingdirection * -1
		end
        if data.timer >= v.ai2 then
			data.timer = 0
			decideAttack(v,data,config,settings)
			if data.state == STATE_BURNER then v.ai3 = RNG.randomInt(3,4) end
			if data.state == STATE_SHOCKWAVE then v.ai3 = RNG.randomInt(2,3) end
			v.ai1 = 0
            v.ai2 = RNG.randomInt(config.idleDelay.min,config.idleDelay.max)
			cannonAngleReset(v,data,config,settings)
			npcutils.faceNearestPlayer(v)
			data.checked = false
        end
	elseif data.state == STATE_KAMIKAZE then
		vectorAngle = vector(0, -1):rotate(data.kamikazeangle)
		if v.ai1 == 0 then
			if data.timer == 1 then data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] SFX.play(ready) end
			cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 0 - data.currentAngle[0], 30))
			cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], 0 - data.currentAngle[2], 30))
			v.speedX = 0
			if v.y > v.spawnY then
				v.speedY = math.clamp(v.speedY - 0.05, -10, 10)
			else
				v.speedY = math.clamp(v.speedY + 0.05, -10, 10)
			end
			if math.abs(v.spawnY - v.y) <= 4 then
				v.y = v.spawnY
				data.timer = 0
				v.ai1 = 1
				v.speedX = 0
				v.speedY = 0
				cannonAngleReset(v,data,config,settings)
				SFX.play(ready)
			end
		elseif v.ai1 == 1 then
			if data.timer % 26 == 0 and data.timer >= 160 then
				for i = 1, 4 do
					-- Spawning the NPC --
					local otherAng = vectorAngle:rotate(i*360/4)
		
					v1 = NPC.spawn(706, center.x + (otherAng.x * (v.width + config.cannonx)), center.y + (otherAng.y * (v.height + config.cannony)), v.section, false, true)
		
					v1.direction = math.sign(otherAng.x * 4)
		
					v1.speedX, v1.speedY = otherAng.x * 4, otherAng.y * 4
					v1.layerName = "Spawned NPCs"
					v1.friendly = data.friendly
					v1.data._basegame.speedX = v1.speedX
					v1.data._basegame.speedY = v1.speedY
		
					-- Spawning smoke --
					a1 = Animation.spawn(config.effectid, v1.x + 0.5 * v1.width + config.effectoffsetx, v1.y + 0.5 * v1.height + config.effectoffsety)
					a1.speedX, a1.speedY = v1.speedX, v1.speedY
					if config.pulsex then
						data.cannonSizex[i-1] = 1.5
					end
			
					if config.pulsey then
						data.cannonSizey[i-1] = 1.5
					end
				end
		
				SFX.play(16)
			end
			if data.timer >= 450 + 160 then
				data.timer = 0
				v.ai1 = 2
				data.kamikazedirection = nil
				SFX.play(ready)
			end
		elseif v.ai1 == 2 then
			if data.timer % 22 == 0 and data.timer >= 80 then
				Routine.setFrameTimer(6, (function() 
					for i = 1, 4 do
						-- Spawning the NPC --
						local otherAng = vectorAngle:rotate(i*360/4)
			
						v1 = NPC.spawn(706, center.x + (otherAng.x * (v.width + config.cannonx)), center.y + (otherAng.y * (v.height + config.cannony)), v.section, false, true)
			
						v1.direction = math.sign(otherAng.x * 6)
			
						v1.speedX, v1.speedY = otherAng.x * 6, otherAng.y * 6
						v1.layerName = "Spawned NPCs"
						v1.friendly = data.friendly
						v1.data._basegame.speedX = v1.speedX
						v1.data._basegame.speedY = v1.speedY
			
						-- Spawning smoke --
						a1 = Animation.spawn(config.effectid, v1.x + 0.5 * v1.width + config.effectoffsetx, v1.y + 0.5 * v1.height + config.effectoffsety)
						a1.speedX, a1.speedY = v1.speedX, v1.speedY
						if config.pulsex then
							data.cannonSizex[i-1] = 1.5
						end
				
						if config.pulsey then
							data.cannonSizey[i-1] = 1.5
						end
					end
		
					SFX.play(16)
				end), 2, false)
			end

			if data.timer >= 450 + 80 then
				data.timer = 0
				v.ai1 = 3
				data.kamikazedirection = nil
				SFX.play(ready)
			end
		elseif v.ai1 == 3 then
			if data.timer % 60 == 0 then SFX.play(ready) end
			if data.timer % 20 == 0 and data.timer >= 80 and data.timer < 450 then
				Routine.setFrameTimer(4, (function() 
					for i = 1, 4 do
						-- Spawning the NPC --
						local otherAng = vectorAngle:rotate(i*360/4)
			
						v1 = NPC.spawn(706, center.x + (otherAng.x * (v.width + config.cannonx)), center.y + (otherAng.y * (v.height + config.cannony)), v.section, false, true)
			
						v1.direction = math.sign(otherAng.x * 8)
			
						v1.speedX, v1.speedY = otherAng.x * 8, otherAng.y * 8
						v1.layerName = "Spawned NPCs"
						v1.friendly = data.friendly
						v1.data._basegame.speedX = v1.speedX
						v1.data._basegame.speedY = v1.speedY
			
						-- Spawning smoke --
						a1 = Animation.spawn(config.effectid, v1.x + 0.5 * v1.width + config.effectoffsetx, v1.y + 0.5 * v1.height + config.effectoffsety)
						a1.speedX, a1.speedY = v1.speedX, v1.speedY
						if config.pulsex then
							data.cannonSizex[i-1] = 1.5
						end
				
						if config.pulsey then
							data.cannonSizey[i-1] = 1.5
						end
					end
			
					SFX.play(16)
				end), 3, false)
			end
			if data.timer == 450 and data.barrier == nil then
				SFX.play(firebarrier)
				data.barrier = NPC.spawn(903,v.x + v.width / 2, v.y + v.height / 2, v.section, false, true)
				data.barrier.parent = v
			end
			if data.timer >= 450 + 90 then
				data.timer = 0
				v.ai1 = 4
				data.kamikazedirection = nil
				data.velocity = -6
				data.angleVelocity = vector(plr.x+plr.width/2-v.x+(-v.width)*0.5, plr.y+plr.height/2-v.y+(-v.height)*0.5):normalize()
				SFX.play(61)
			end
		elseif v.ai1 == 4 then
			if data.timer % 8 == 0 then SFX.play(RNG.irandomEntry(pika)) end
			v.speedX = data.angleVelocity.x * data.velocity
			v.speedY = data.angleVelocity.y * data.velocity
			data.velocity = math.clamp(data.velocity + 0.4, -data.velocityCap, data.velocityCap)
			if (v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockRight or v.collidesBlockTop) and data.velocity > 2 then
				data.timer = 0
				data.state = STATE_KILL
				v.ai1 = 0
				v.speedX = 0
				v.speedY = 0
				Defines.earthquake = 9
				for i = 1,40 do
					local ptl = Animation.spawn(950, math.random(v.x - v.width / 2, v.x + v.width / 2), math.random(v.y - v.height / 2, v.y + v.height / 2))
					ptl.speedX = RNG.random(-10,10)
					ptl.speedY = RNG.random(-10,10)
					ptl.x=ptl.x-ptl.width/2
					ptl.y=ptl.y-ptl.height/2
				end
				SFX.play(destruct)
				if data.barrier then
					if data.barrier.isValid then
						data.barrier:kill(9)
					end
					data.barrier = nil
				end
			end
		end
		if v.ai1 > 0 then
			if data.kamikazedirection == nil then data.kamikazedirection = RNG.irandomEntry{-1,1} end
			local rotate = RNG.randomInt(2,6)
			if v.ai1 == 2 then rotate = 5 end
			if v.ai1 == 3 then rotate = 7 end
			if v.ai1 == 4 then rotate = 18 end
			if data.kamikazedirection then
				data.kamikazeangle = data.kamikazeangle + rotate * data.kamikazedirection
				for i=0,3 do
					data.cannonAngle[i] =  data.cannonAngle[i] + rotate * data.kamikazedirection
				end
			end
		end
	elseif data.state == STATE_SCORCH then
		v.speedX = 0
		v.speedY = 0
		if v.ai1 == 0 then
			if data.timer == 1 then cannonAngleReset(v,data,config,settings) data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] SFX.play(ready) end
			cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], -60 - data.currentAngle[0], 60))
			cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], 60 - data.currentAngle[2], 60))
			if data.timer >= 60 then
				data.timer = 0
				v.ai1 = 1
				cannonSetAngle(v,data,config,settings,0,-60)
				cannonSetAngle(v,data,config,settings,2,60)
			end
		elseif v.ai1 == 1 then
			if data.timer == 1 then
				SFX.play(bombs)
				for i=0,2 do
					-- Spawning the NPC --
					local otherAng = 0
					if i == 0 then otherAng = vectorAngle:rotate(150) end
					if i == 1 then otherAng = vectorAngle:rotate(210) end
					if i == 2 then otherAng = vectorAngle:rotate(180) end

					v1 = NPC.spawn(876, center.x + (otherAng.x * (v.width + config.cannonx)), center.y + (otherAng.y * (v.height + config.cannony)), v.section, false, true)

					v1.direction = math.sign(otherAng.x * 6)

					v1.speedX, v1.speedY = otherAng.x * 6, otherAng.y * 6
					v1.layerName = "Spawned NPCs"
					v1.friendly = data.friendly
					v1.data._basegame.speedX = v1.speedX
					v1.data._basegame.speedY = v1.speedY

					-- Spawning smoke --
					a1 = Animation.spawn(config.effectid, v1.x + 0.5 * v1.width + config.effectoffsetx, v1.y + 0.5 * v1.height + config.effectoffsety)
					a1.speedX, a1.speedY = v1.speedX, v1.speedY
				end
				if config.pulsex then
					data.cannonSizex[0] = 1.5
					data.cannonSizex[3] = 1.5
					data.cannonSizex[2] = 1.5
				end
		
				if config.pulsey then
					data.cannonSizey[0] = 1.5
					data.cannonSizey[3] = 1.5
					data.cannonSizey[2] = 1.5
				end
			end
			if data.timer == 1 then cannonAngleReset(v,data,config,settings) data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] end
			if data.timer <= 40 then
				cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], -30 - data.currentAngle[0], 40))
				cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], 30 - data.currentAngle[2], 40))
			end
			if data.timer >= 70 then
				data.timer = 0
				v.ai1 = 2
				cannonSetAngle(v,data,config,settings,0,-30)
				cannonSetAngle(v,data,config,settings,2,30)
			end
		elseif v.ai1 == 2 then
			if data.timer == 1 then
				SFX.play(bombs)
				for i=0,1 do
					-- Spawning the NPC --
					local otherAng = 0
					if i == 0 then otherAng = vectorAngle:rotate(120) end
					if i == 1 then otherAng = vectorAngle:rotate(240) end

					v1 = NPC.spawn(876, center.x + (otherAng.x * (v.width + config.cannonx)), center.y + (otherAng.y * (v.height + config.cannony)), v.section, false, true)

					v1.direction = math.sign(otherAng.x * 6)

					v1.speedX, v1.speedY = otherAng.x * 6, otherAng.y * 6
					v1.layerName = "Spawned NPCs"
					v1.friendly = data.friendly
					v1.data._basegame.speedX = v1.speedX
					v1.data._basegame.speedY = v1.speedY

					-- Spawning smoke --
					a1 = Animation.spawn(config.effectid, v1.x + 0.5 * v1.width + config.effectoffsetx, v1.y + 0.5 * v1.height + config.effectoffsety)
					a1.speedX, a1.speedY = v1.speedX, v1.speedY
				end
				if config.pulsex then
					data.cannonSizex[0] = 1.5
					data.cannonSizex[3] = 1.5
					data.cannonSizex[2] = 1.5
				end
		
				if config.pulsey then
					data.cannonSizey[0] = 1.5
					data.cannonSizey[3] = 1.5
					data.cannonSizey[2] = 1.5
				end
			end
			if data.timer >= 30 then
				data.timer = 0
				v.ai1 = 3
				cannonSetAngle(v,data,config,settings,0,-30)
				cannonSetAngle(v,data,config,settings,2,30)
			end
		elseif v.ai1 == 3 then
			if data.timer == 1 then data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] end
			cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 0 - data.currentAngle[0], 30))
			cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], 0 - data.currentAngle[2], 30))
			if data.timer >= 30 then
				data.timer = 0
				v.ai1 = 0
				decideAttack(v,data,config,settings)
				if data.state == STATE_BURNER then v.ai3 = RNG.randomInt(3,4) end
				if data.state == STATE_SHOCKWAVE then v.ai3 = RNG.randomInt(2,3) end
				cannonAngleReset(v,data,config,settings)
			end
		end
	elseif data.state == STATE_SHOCKWAVE then
		local ptl = Animation.spawn(265, math.random(v.x, v.x + v.width) - 4, math.random(v.y, v.y + v.height) - 4)
		ptl.speedY = -2
		if v.ai1 == 0 then
			v.speedX = 0
			v.speedY = 0
			if data.timer == 1 then cannonAngleReset(v,data,config,settings) data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] SFX.play(noise1) v.ai4 = 175 end
			if data.timer <= 30 then
				cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 45 - data.currentAngle[0], 30))
				cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], -45 - data.currentAngle[2], 30))
			elseif data.timer <= 60 then
				cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 0 - data.currentAngle[0], 30))
				cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], 0 - data.currentAngle[2], 30))
			end
			if data.timer == 30 and data.barrier == nil then
				SFX.play(firebarrier)
				data.barrier = NPC.spawn(903,v.x + v.width / 2, v.y + v.height / 2, v.section, false, true)
				data.barrier.parent = v
			end
			if data.timer >= 80 then
				data.timer = 0
				v.ai1 = 1
			end
		elseif v.ai1 == 1 then
			v.speedX = 0
			v.speedY = 0
			npcutils.faceNearestPlayer(v)
			if data.timer == 1 then
				data.locationx = math.clamp(plr.x + plr.width / 2, v.x + v.width / 2 - config.shockwavetargetxlimit, v.x + v.width / 2 + config.shockwavetargetxlimit)
			end
			if data.timer <= 90 then
				v.x = easing.outQuad(data.timer, v.x, (data.locationx - v.width / 2) - (v.x), 90)
			end
			if math.abs((data.locationx - v.width / 2) - (v.x)) <= 4 or v.collidesBlockLeft or v.collidesBlockRight or data.timer >= 180 then
				if math.abs((data.locationx - v.width / 2) - (v.x)) <= 4 then v.x = data.locationx - v.width / 2 end
				v.ai1 = 2
				data.timer = 0
			end
		elseif v.ai1 == 2 then
			if data.feet == nil then
				data.feet = Colliders.Box(0,0,v.width,1)
				data.lastFrameCollision = true
			end
		
				data.feet.x = v.x
				data.feet.y = v.y + v.height
				local collidesWithSolid = false
				local footCollisions = Colliders.getColliding{
				
					a=	data.feet,
					b=	Block.SOLID ..
						Block.PLAYER ..
						Block.SEMISOLID,
					btype = Colliders.BLOCK,
					filter= function(other)
						if (not collidesWithSolid and not other.isHidden and other:mem(0x5A, FIELD_WORD) == 0) then
							if Block.SOLID_MAP[other.id] or Block.PLAYER_MAP[other.id] then
								return true
							end
							if data.feet.y <= other.y + 8 then
								return true
							end
						end
						return false
					end
					
				}
			
			if data.timer == 1 then cannonAngleReset(v,data,config,settings) data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] SFX.play(noise2) v.speedY = -3 end
			if data.timer <= 16 then
				cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 60 - data.currentAngle[0], 16))
				cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], -60 - data.currentAngle[2], 16))
			end
			drawAfterimage(v)
			v.speedX = 0
			v.speedY = math.clamp(v.speedY + 0.4, -3, 10)
			if v.collidesBlockBottom then
				data.timer = 0
				v.ai1 = 3
				local a = Animation.spawn(10,v.x+v.width/5-16,v.y+v.height-16)
				a.speedX = -3
				local a = Animation.spawn(10,v.x+v.width*4/5-16,v.y+v.height-16)
				a.speedX = 3
				cannonSetAngle(v,data,config,settings,0,0)
				cannonSetAngle(v,data,config,settings,2,0)
				v.speedY = 0
				if #footCollisions > 0 then
					collidesWithSolid = true
					
					if not data.lastFrameCollision then
						SFX.play(shockwave)
						defines.earthquake = 8
						local id = NPC.config[v.id].shockwaveid
						local f = NPC.spawn(id, v.x + 0.5 * v.width, footCollisions[1].y - 0.5 * NPC.config[id].height, v:mem(0x146, FIELD_WORD), false, true)
						if NPC.config[id].spread then
							data.spread = NPC.config[id].spread + 20
							initFire(v, f, 0)
						end
						SFX.play("mm5explosion.wav")
						local a = Animation.spawn(823,0,0)
						a.x = v.x + v.width/2 - a.width/2
						a.y = v.y + v.height/2 - a.height/2
						return
					end
				end
			end
			data.lastFrameCollision = collidesWithSolid
		elseif v.ai1 == 3 then
			if data.timer == 1 then data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] end
			cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 0 - data.currentAngle[0], 30))
			cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], 0 - data.currentAngle[2], 30))
			v.speedX = 0
			if v.y > v.spawnY then
				v.speedY = math.clamp(v.speedY - 0.1, -10, 10)
			else
				v.speedY = math.clamp(v.speedY + 0.1, -10, 10)
			end
			if math.abs(v.spawnY - v.y) <= 4 then
				v.y = v.spawnY
				data.timer = 0
				v.speedX = 0
				v.speedY = 0
				cannonAngleReset(v,data,config,settings)
				data.consecutive = data.consecutive + 1
				if data.consecutive >= v.ai3 then
					v.ai3 = 0
					data.consecutive = 0
					v.ai1 = 4
				else
					v.ai1 = 1
				end
			end
		elseif v.ai1 == 4 then
			v.speedX = 0
			v.speedY = 0
			if data.timer == 1 then cannonAngleReset(v,data,config,settings) data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] SFX.play(noise1) v.direction = RNG.irandomEntry{-1,1} end
			if data.timer <= 30 then
				cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 45 - data.currentAngle[0], 30))
				cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], -45 - data.currentAngle[2], 30))
			end
			if data.timer > 60 and v.ai3 <= 12 then
				if v.ai3 == 0 then v.ai5 = RNG.randomInt(-45,45) end
				local dir = -vector.right2:rotate(90 + (v.ai3 * 25) * v.direction + v.ai5)
				local speed = 6.5
				local needles = NPC.spawn(706,v.x + 0.5 * v.width, v.y + 0.5 * v.height,v.section, false, true)
				needles.friendly = v.friendly
				needles.layerName = "Spawned NPCs"
				needles.speedX = dir.x * speed
				needles.speedY = dir.y * speed
				SFX.play(firerelease)
				if v.ai3 < 12 then
					v.ai3 = v.ai3 + 1
					data.timer = 60 - 4
				else
					data.timer = 0
					v.ai1 = 5
					if data.barrier then
						if data.barrier.isValid then
							data.barrier:kill(9)
						end
						data.barrier = nil
					end
					v.ai3 = 0
				end
			end
		elseif v.ai1 == 5 then
			if data.timer == 1 then data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] end
			cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 0 - data.currentAngle[0], 30))
			cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], 0 - data.currentAngle[2], 30))
			if data.timer >= 30 then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_CEILING
				cannonAngleReset(v,data,config,settings)
			end
		end
	elseif data.state == STATE_SPOUT then
		v.speedX = 0
		v.speedY = 0
		if v.ai1 == 0 then
			if data.timer == 1 then cannonAngleReset(v,data,config,settings) data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] SFX.play(noise1) v.ai4 = 175 end
			local angle0 = -90 + v.ai4
			local angle2 = 90 - v.ai4
			if data.timer <= 30 then
				cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], angle0 - data.currentAngle[0], 30))
				cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], angle2 - data.currentAngle[2], 30))
			end
			if data.timer >= 40 then
				data.timer = 0
				v.ai1 = 1
				cannonSetAngle(v,data,config,settings,0,angle0)
				cannonSetAngle(v,data,config,settings,2,angle2)
			end
		elseif v.ai1 == 1 then
			if data.timer == 1 then
				Routine.setFrameTimer(16, (function() 
					SFX.play(fireball)
					for i=0,1 do
						-- Spawning the NPC --
						local otherAng = vectorAngle:rotate(180 + v.ai4 * (-1 + (i * 2)))
	
						v1 = NPC.spawn(899, center.x + (otherAng.x * (v.width + config.cannonx)), center.y + (otherAng.y * (v.height + config.cannony)), v.section, false, true)
	
						v1.direction = math.sign(otherAng.x * 7)
	
						v1.speedX, v1.speedY = otherAng.x * 7, -8
						v1.layerName = "Spawned NPCs"
						v1.friendly = data.friendly
						v1.data._basegame.speedX = v1.speedX
						v1.data._basegame.speedY = v1.speedY
	
						-- Spawning smoke --
						a1 = Animation.spawn(config.effectid, v1.x + 0.5 * v1.width + config.effectoffsetx, v1.y + 0.5 * v1.height + config.effectoffsety)
						a1.speedX, a1.speedY = v1.speedX, v1.speedY
					end
					local angle0 = -90 + v.ai4
					local angle2 = 90 - v.ai4
					cannonSetAngle(v,data,config,settings,0,angle0)
					cannonSetAngle(v,data,config,settings,2,angle2)
					if config.pulsex then
						data.cannonSizex[0] = 1.5
						data.cannonSizex[2] = 1.5
					end
			
					if config.pulsey then
						data.cannonSizey[0] = 1.5
						data.cannonSizey[2] = 1.5
					end
					v.ai4 = v.ai4 - 10
				end), 7, false)
			end
			if data.timer >= 150 then
				data.timer = 0
				v.ai1 = 2
				v.ai4 = 0
			end
		elseif v.ai1 == 2 then
			if data.timer == 1 then data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] end
			cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 0 - data.currentAngle[0], 30))
			cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], 0 - data.currentAngle[2], 30))
			if data.timer >= 30 then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_CEILING
				cannonAngleReset(v,data,config,settings)
			end
		end
	elseif data.state == STATE_RINKA then
		v.speedX = 0
		v.speedY = 0
		if v.ai1 == 0 then
			if data.timer == 1 then cannonAngleReset(v,data,config,settings) data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] SFX.play(noise1) v.ai4 = 105 end
			local angle0 = -90 + v.ai4
			local angle2 = 90 - v.ai4
			if data.timer <= 30 then
				cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], angle0 - data.currentAngle[0], 30))
				cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], angle2 - data.currentAngle[2], 30))
			end
			if data.timer >= 40 then
				data.timer = 0
				v.ai1 = 1
				cannonSetAngle(v,data,config,settings,0,angle0)
				cannonSetAngle(v,data,config,settings,2,angle2)
			end
		elseif v.ai1 == 1 then
			if data.timer == 1 then
				Routine.setFrameTimer(16, (function() 
					SFX.play(shoot)
					for i=0,1 do
						-- Spawning the NPC --
						local otherAng = vectorAngle:rotate(180 + v.ai4 * (-1 + (i * 2)))
	
						v1 = NPC.spawn(210, center.x + (otherAng.x * (v.width + config.cannonx)), center.y + (otherAng.y * (v.height + config.cannony)), v.section, false, true)
	
						v1.direction = math.sign(otherAng.x * 2)
	
						v1.speedX, v1.speedY = otherAng.x * 2, otherAng.y * 2
						v1.layerName = "Spawned NPCs"
						v1.friendly = data.friendly
						v1.data._basegame.speedX = v1.speedX
						v1.data._basegame.speedY = v1.speedY
	
						-- Spawning smoke --
						a1 = Animation.spawn(config.effectid, v1.x + 0.5 * v1.width + config.effectoffsetx, v1.y + 0.5 * v1.height + config.effectoffsety)
						a1.speedX, a1.speedY = v1.speedX, v1.speedY
					end
					local angle0 = -90 + v.ai4
					local angle2 = 90 - v.ai4
					cannonSetAngle(v,data,config,settings,0,angle0)
					cannonSetAngle(v,data,config,settings,2,angle2)
					if config.pulsex then
						data.cannonSizex[0] = 1.5
						data.cannonSizex[2] = 1.5
					end
			
					if config.pulsey then
						data.cannonSizey[0] = 1.5
						data.cannonSizey[2] = 1.5
					end
					v.ai4 = v.ai4 - 15
				end), 5, false)
			end
			if data.timer >= 200 then
				data.timer = 0
				v.ai1 = 2
				cannonSetAngle(v,data,config,settings,0,-45)
				cannonSetAngle(v,data,config,settings,2,45)
				v.ai4 = 0
			end
		elseif v.ai1 == 2 then
			if data.timer == 1 then data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] end
			cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 0 - data.currentAngle[0], 30))
			cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], 0 - data.currentAngle[2], 30))
			if data.timer >= 30 then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_CEILING
				cannonAngleReset(v,data,config,settings)
			end
		end
	elseif data.state == STATE_BURNER then
		if v.ai1 == 0 then
			v.speedX = 0
			v.speedY = 0
			if data.timer % 4 == 0 then
				SFX.play(16)
				local otherAng = vectorAngle:rotate(180)
				-- Spawning smoke --
				a1 = Animation.spawn(265, center.x + (otherAng.x * (v.width + config.cannonx)) - 4, center.y + (otherAng.y * (v.height + config.cannony)) - 4)
				a1.speedX, a1.speedY = 0, 3
			end
			if data.timer >= 60 then
				data.timer = 0
				v.ai1 = 1
			end
		elseif v.ai1 == 1 then
			local timer = lunatime.tick()
			chasePlayers(v)
			v.speedX = math.clamp(v.speedX + 0.15 * v.data._basegame.direction, -5, 5)
			v.speedY = math.sin(-data.timer/12)*6 / 3.5
			if (v.speedX < 0 and v.collidesBlockLeft) or (v.speedX > 0 and v.collidesBlockRight) then v.speedX = -v.speedX end
			if data.consecutive >= v.ai3 then
				data.consecutive = 0
				data.timer = 0
				v.ai1 = 2
				v.ai3 = 0
				v.speedX = 0
				data.spawndelay = settings.spawndelay * Misc.GetEngineTPS()
				return
			end
			if shouldSpawnFire(settings, timer) then
				data.spawndelay = settings.spawndelay * Misc.GetEngineTPS()
			elseif data.spawnFireCooldown > 0 then
				data.spawndelay = 1
				data.spawnFireCooldown = data.spawnFireCooldown - 1
			end
			if data.spawndelay > 0 then data.spawndelay = data.spawndelay - 1 end
			if data.fires == nil and data.spawndelay <= 0 and data.spawnFireCooldown <= math.floor(settings.fireLifetime * Misc.GetEngineTPS()) then
				SFX.play(42)
				if data.spawnFireCooldown == 0 then
					data.spawnFireCooldown = math.floor(settings.fireLifetime * Misc.GetEngineTPS())
				end
				local dir = v.direction
				local fireConfig = NPC.config[config.fireid]
				data.fires = {}
				local f = NPC.spawn(config.fireid, v.x, v.y, v.section, false, true)
				local fireData = f.data._basegame
				fireData.originalSize = vector(f.width, f.height * settings.fireScale)
				fireData.scale = settings.fireScale
				f.width = fireData.originalSize.y + v.width
				f.height = f.width
				f.x = v.x + 0.5 * v.width - 0.5 * fireData.originalSize.y - 0.5 * v.width
				f.y = v.y + 0.5 * v.height - 0.5 * fireData.originalSize.y - 0.5 * v.height
				fireData.pivot = vector(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
				fireData.offset = vector(0, -0.5 * v.height)
				fireData.angle = 180
				fireData.speedMultiplier = 0
				f.direction = v.direction
				if data.spawnFireCooldown > 0 and not settings.fireLifetime == math.huge then
					fireData.timer = math.floor(settings.fireLifetime * Misc.GetEngineTPS()) - data.spawnFireCooldown
				else
					fireData.timer = 0
				end
				fireData.lifetime = math.floor(settings.fireLifetime * Misc.GetEngineTPS())
				f.layerName = v.layerName
				f.friendly = true
				f.despawnTimer = 100
				fireData.angleOffset = 0
				fireData.setByParent = true

				table.insert(data.fires, f)
			end
			if data.timer % 8 == 0 then
				if data.fires == nil then
					local otherAng = vectorAngle:rotate(180)
					-- Spawning smoke --
					a1 = Animation.spawn(265, center.x + (otherAng.x * (v.width + config.cannonx)) - 4, center.y + (otherAng.y * (v.height + config.cannony)) - 4)
					a1.speedX, a1.speedY = 0, 3
				else
					if config.pulsex then
						data.cannonSizex[3] = 1.5
					end
			
					if config.pulsey then
						data.cannonSizey[3] = 1.5
					end
				end
			end
		elseif v.ai1 == 2 then
			v.speedX = 0
			if v.y > v.spawnY then
				v.speedY = math.clamp(v.speedY - 0.05, -10, 10)
			else
				v.speedY = math.clamp(v.speedY + 0.05, -10, 10)
			end
			if math.abs(v.spawnY - v.y) <= 4 and data.fires == nil then
				v.y = v.spawnY
				data.timer = 0
				v.ai1 = 0
				v.speedX = 0
				v.speedY = 0
				data.state = STATE_CEILING
				cannonAngleReset(v,data,config,settings)
			end
		end
	elseif data.state == STATE_TRAP then
		if v.ai1 == 0 then
			if data.timer == 1 then cannonAngleReset(v,data,config,settings) data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] SFX.play(swipe) v.speedY = -3 end
			if data.timer <= 16 then
				cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 60 - data.currentAngle[0], 16))
				cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], -60 - data.currentAngle[2], 16))
			end
			drawAfterimage(v)
			v.speedX = 0
			v.speedY = math.clamp(v.speedY + 0.3, -3, 10)
			if v.collidesBlockBottom then
				data.timer = 0
				v.ai1 = 1
				SFX.play(stomp)
				defines.earthquake = 8
				local a = Animation.spawn(10,v.x+v.width/5-16,v.y+v.height-16)
				a.speedX = -3
				local a = Animation.spawn(10,v.x+v.width*4/5-16,v.y+v.height-16)
				a.speedX = 3
				cannonSetAngle(v,data,config,settings,0,0)
				cannonSetAngle(v,data,config,settings,2,0)
				v.speedY = 0
			end
		elseif v.ai1 == 1 then
			v.speedX = 0
			v.speedY = math.clamp(v.speedY + 0.2, -5, 10)
			npcutils.faceNearestPlayer(v)
			if data.timer % 60 == 0 and data.timer > 30 then
				SFX.play(16)
				local speed = 3.5
					-- Spawning the NPC --
					local otherAng = vectorAngle:rotate(90)

					v1 = NPC.spawn(85, center.x + (otherAng.x * (v.width + config.cannonx)), center.y + (otherAng.y * (v.height + config.cannony)), v.section, false, true)

					v1.direction = 1

					v1.speedX, v1.speedY = speed, 0
					v1.layerName = "Spawned NPCs"
					v1.friendly = data.friendly
					v1.data._basegame.speedX = v1.speedX
					v1.data._basegame.speedY = v1.speedY

					-- Spawning smoke --
					a1 = Animation.spawn(config.effectid, v1.x + 0.5 * v1.width + config.effectoffsetx, v1.y + 0.5 * v1.height + config.effectoffsety)
					a1.speedX, a1.speedY = v1.speedX, v1.speedY

					-- Spawning the NPC --
					local otherAng = vectorAngle:rotate(270)

					speed = -4

					v2 = NPC.spawn(85, center.x + (otherAng.x * (v.width + config.cannonx)), center.y + (otherAng.y * (v.height + config.cannony)), v.section, false, true)

					v2.direction = -1

					v2.speedX, v2.speedY = speed, 0
					v2.layerName = "Spawned NPCs"
					v2.friendly = data.friendly
					v2.data._basegame.speedX = v2.speedX
					v2.data._basegame.speedY = v2.speedY

					-- Spawning smoke --
					a2 = Animation.spawn(config.effectid, v2.x + 0.5 * v2.width + config.effectoffsetx, v2.y + 0.5 * v2.height + config.effectoffsety)
					a2.speedX, a2.speedY = v2.speedX, v2.speedY
				if config.pulsex then
					data.cannonSizex[0] = 1.5
					data.cannonSizex[2] = 1.5
				end
		
				if config.pulsey then
					data.cannonSizey[0] = 1.5
					data.cannonSizey[2] = 1.5
				end
			end
			if data.timer % 100 == 20 and data.timer > 30 then
				SFX.play(fireball)
					-- Spawning the NPC --
					local speedx = RNG.random(2,5.5) * v.direction
					local otherAng = vectorAngle:rotate(0)

					v1 = NPC.spawn(899, center.x + (otherAng.x * (v.width + config.cannonx)), center.y + (otherAng.y * (v.height + config.cannony)), v.section, false, true)

					v1.direction = math.sign(otherAng.x * speedx)

					v1.speedX, v1.speedY = speedx, -12
					v1.layerName = "Spawned NPCs"
					v1.friendly = data.friendly
					v1.data._basegame.speedX = v1.speedX
					v1.data._basegame.speedY = v1.speedY

					-- Spawning smoke --
					a1 = Animation.spawn(config.effectid, v1.x + 0.5 * v1.width + config.effectoffsetx, v1.y + 0.5 * v1.height + config.effectoffsety)
					a1.speedX, a1.speedY = v1.speedX, v1.speedY
				if config.pulsex then data.cannonSizex[1] = 1.5 end
				if config.pulsey then data.cannonSizey[1] = 1.5 end
			end
			if data.timer >= 360 then
				data.timer = 0
				v.ai1 = 2
				v.speedY = 0
				cannonSetAngle(v,data,config,settings,0,0)
				cannonSetAngle(v,data,config,settings,2,0)
			end
		elseif v.ai1 == 2 then
			if data.timer == 1 then data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] SFX.play(rise) end
			cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 0 - data.currentAngle[0], 30))
			cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], 0 - data.currentAngle[2], 30))
			v.speedX = 0
			if v.y > v.spawnY then
				v.speedY = math.clamp(v.speedY - 0.05, -10, 10)
			else
				v.speedY = math.clamp(v.speedY + 0.05, -10, 10)
			end
			if math.abs(v.spawnY - v.y) <= 4 then
				v.y = v.spawnY
				data.timer = 0
				v.ai1 = 0
				v.speedX = 0
				v.speedY = 0
				data.state = STATE_CEILING
				cannonAngleReset(v,data,config,settings)
			end
		end
	elseif data.state == STATE_SHOWER then
		v.ai4 = v.ai4 + 1
		v.speedX = config.walkSpeed * v.walkingdirection
		v.speedY = 0
				
		v.walkingtimer = v.walkingtimer - v.walkingdirection
			
		if v.walkingtimer == config.walkRange or v.walkingtimer == -config.walkRange or v.ai4 >= data.turnDelay then
			v.walkingdirection = v.walkingdirection * -1
			v.ai4 = 0
			data.turnDelay = RNG.randomInt(config.walkTurnDelay.min,config.walkTurnDelay.max)
		end
		if (v.walkingdirection == -1 and v.collidesBlockLeft) or (v.walkingdirection == 1 and v.collidesBlockRight) then
			v.walkingdirection = v.walkingdirection * -1
		end
		if v.ai1 == 0 then
			if data.timer == 1 then cannonAngleReset(v,data,config,settings) data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] end
			if data.timer == 1 then
				Routine.setFrameTimer(6, (function() 
					SFX.play(16)
					end), 8, false)
			end
			if data.timer <= 30 then
				cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 45 - data.currentAngle[0], 30))
				cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], -45 - data.currentAngle[2], 30))
			end
			if data.timer >= 60 then
				data.timer = 0
				v.ai1 = 1
				cannonSetAngle(v,data,config,settings,0,45)
				cannonSetAngle(v,data,config,settings,2,-45)
			end
		elseif v.ai1 == 1 then
			if data.timer % 8 == 0 then
				SFX.play(shower)
				for i=1,3 do
					local speed = RNG.random(3,9)
					-- Spawning the NPC --
					local otherAng = vectorAngle:rotate(-90+45*i)

					v1 = NPC.spawn(276, center.x + (otherAng.x * (v.width + config.cannonx)), center.y + (otherAng.y * (v.height + config.cannony)), v.section, false, true)

					v1.direction = math.sign(otherAng.x * speed)

					v1.speedX, v1.speedY = otherAng.x * speed, otherAng.y * speed
					v1.layerName = "Spawned NPCs"
					v1.friendly = data.friendly
					v1.data._basegame.speedX = v1.speedX
					v1.data._basegame.speedY = v1.speedY

					-- Spawning smoke --
					a1 = Animation.spawn(config.effectid, v1.x + 0.5 * v1.width + config.effectoffsetx, v1.y + 0.5 * v1.height + config.effectoffsety)
					a1.speedX, a1.speedY = v1.speedX, v1.speedY
				end
				if config.pulsex then
					data.cannonSizex[0] = 1.5
					data.cannonSizex[1] = 1.5
					data.cannonSizex[2] = 1.5
				end
		
				if config.pulsey then
					data.cannonSizey[0] = 1.5
					data.cannonSizey[1] = 1.5
					data.cannonSizey[2] = 1.5
				end
			end
			if data.timer >= 150 then
				data.timer = 0
				v.ai1 = 2
				cannonSetAngle(v,data,config,settings,0,45)
				cannonSetAngle(v,data,config,settings,2,-45)
			end
		elseif v.ai1 == 2 then
			if data.timer == 1 then data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] end
			if data.timer <= 30 then
				cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 0 - data.currentAngle[0], 30))
				cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], 0 - data.currentAngle[2], 30))
			end
			if data.timer > 30 then
				data.timer = 0
				v.ai1 = 3
				cannonAngleReset(v,data,config,settings)
			end
		elseif v.ai1 == 3 then
			if (data.timer) % 90 < 45 then
				if (data.timer) % 90 == 44 then data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] end
				cannonSetAngle(v,data,config,settings,0,easing.outQuad((data.timer) % 90, data.currentAngle[0], 0 - data.currentAngle[0], 30))
				cannonSetAngle(v,data,config,settings,2,easing.outQuad((data.timer) % 90, data.currentAngle[2], 0 - data.currentAngle[2], 30))

			else
				if (data.timer) % 90 == 89 then data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] end
				cannonSetAngle(v,data,config,settings,0,easing.outQuad((data.timer) % 90 - 45, data.currentAngle[0], 45 - data.currentAngle[0], 30))
				cannonSetAngle(v,data,config,settings,2,easing.outQuad((data.timer) % 90 - 45, data.currentAngle[2], -45 - data.currentAngle[2], 30))
			end
			if (data.timer) % 90 == 45 and not data.barrier then
				SFX.play(firebarrier)
				data.barrier = NPC.spawn(903,v.x + v.width / 2, v.y + v.height / 2, v.section, false, true)
				data.barrier.parent = v
			end
			if (data.timer) % 90 == 0 and data.barrier and data.barrier.isValid then
				SFX.play(firerelease)
				local chasePlayer = player
				if player2 then
					local d1 = player.x + player.width * 0.5
					local d2 = player2.x + player2.width * 0.5
					local dr = v.x + v.width * 0.5
					if (v.direction == 1 and d1 < dr)
					or (v.direction == -1 and d1 > dr)
					or RNG.randomInt(0,1) == 1 then
						chasePlayer = player2
					end
				end
				local dir = vector.v2(chasePlayer.x + 0.5 * chasePlayer.width  - (data.barrier.x + 0.5 * data.barrier.width), 
									  chasePlayer.y + 0.5 * chasePlayer.height - (data.barrier.y + 0.5 * data.barrier.height)):normalize()
									  
				dir.y = dir.y
										   
				SFX.play(42)
				
				data.barrier.speedX = dir.x * 5
				data.barrier.speedY = dir.y * 5
				data.barrier.parent = nil
				data.barrier = nil
			end
			if data.timer >= 300 then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_CEILING
				cannonAngleReset(v,data,config,settings)
			end
		end
	elseif data.state == STATE_BARRAGE then
		v.speedX = 0
		v.speedY = 0
		if v.ai1 == 0 then
			if data.timer == 1 then cannonAngleReset(v,data,config,settings) data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] SFX.play(noise1) end
			if data.timer <= 30 then
				cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], -45 - data.currentAngle[0], 30))
				cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], 45 - data.currentAngle[2], 30))
			end
			if data.timer >= 40 then
				data.timer = 0
				v.ai1 = 1
				cannonSetAngle(v,data,config,settings,0,-45)
				cannonSetAngle(v,data,config,settings,2,45)
			end
		elseif v.ai1 == 1 then
			if data.timer % 8 == 0 and data.timer < 90 then
				SFX.play(shoot)
				for i=1,3 do
					-- Spawning the NPC --
					local otherAng = vectorAngle:rotate(90+45*i)

					v1 = NPC.spawn(348, center.x + (otherAng.x * (v.width + config.cannonx)), center.y + (otherAng.y * (v.height + config.cannony)), v.section, false, true)

					v1.direction = math.sign(otherAng.x * 5)

					v1.speedX, v1.speedY = otherAng.x * 5, otherAng.y * 5
					v1.layerName = "Spawned NPCs"
					v1.friendly = data.friendly
					v1.data._basegame.speedX = v1.speedX
					v1.data._basegame.speedY = v1.speedY

					-- Spawning smoke --
					a1 = Animation.spawn(config.effectid, v1.x + 0.5 * v1.width + config.effectoffsetx, v1.y + 0.5 * v1.height + config.effectoffsety)
					a1.speedX, a1.speedY = v1.speedX, v1.speedY
				end
				if config.pulsex then
					data.cannonSizex[0] = 1.5
					data.cannonSizex[3] = 1.5
					data.cannonSizex[2] = 1.5
				end
		
				if config.pulsey then
					data.cannonSizey[0] = 1.5
					data.cannonSizey[3] = 1.5
					data.cannonSizey[2] = 1.5
				end
			end
			if data.timer >= 150 then
				data.timer = 0
				v.ai1 = 2
				cannonSetAngle(v,data,config,settings,0,-45)
				cannonSetAngle(v,data,config,settings,2,45)
			end
		elseif v.ai1 == 2 then
			if data.timer == 1 then data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] end
			cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 0 - data.currentAngle[0], 30))
			cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], 0 - data.currentAngle[2], 30))
			if data.timer >= 30 then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_CEILING
				cannonAngleReset(v,data,config,settings)
			end
		end
	elseif data.state == STATE_BOMBS then
		v.speedX = 0
		v.speedY = 0
		if v.ai1 == 0 then
			if data.timer == 1 then cannonAngleReset(v,data,config,settings) data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] SFX.play(ready) end
			cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], -45 - data.currentAngle[0], 60))
			cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], 45 - data.currentAngle[2], 60))
			if data.timer >= 60 then
				data.timer = 0
				v.ai1 = 1
				cannonSetAngle(v,data,config,settings,0,-45)
				cannonSetAngle(v,data,config,settings,2,45)
			end
		elseif v.ai1 == 1 then
			if data.timer == 1 then
				SFX.play(bombs)
				for i=1,3 do
					-- Spawning the NPC --
					local otherAng = vectorAngle:rotate(90+45*i)

					v1 = NPC.spawn(901, center.x + (otherAng.x * (v.width + config.cannonx)), center.y + (otherAng.y * (v.height + config.cannony)), v.section, false, true)

					v1.direction = math.sign(otherAng.x * 6)

					v1.speedX, v1.speedY = otherAng.x * 6, otherAng.y * 6
					v1.layerName = "Spawned NPCs"
					v1.friendly = data.friendly
					v1.data._basegame.speedX = v1.speedX
					v1.data._basegame.speedY = v1.speedY

					-- Spawning smoke --
					a1 = Animation.spawn(config.effectid, v1.x + 0.5 * v1.width + config.effectoffsetx, v1.y + 0.5 * v1.height + config.effectoffsety)
					a1.speedX, a1.speedY = v1.speedX, v1.speedY
				end
				if config.pulsex then
					data.cannonSizex[0] = 1.5
					data.cannonSizex[3] = 1.5
					data.cannonSizex[2] = 1.5
				end
		
				if config.pulsey then
					data.cannonSizey[0] = 1.5
					data.cannonSizey[3] = 1.5
					data.cannonSizey[2] = 1.5
				end
			end
			if data.timer >= 40 then
				data.timer = 0
				v.ai1 = 2
				cannonSetAngle(v,data,config,settings,0,-45)
				cannonSetAngle(v,data,config,settings,2,45)
			end
		elseif v.ai1 == 2 then
			if data.timer == 1 then data.currentAngle[0] = data.cannonAngle[0] data.currentAngle[2] = data.cannonAngle[2] end
			cannonSetAngle(v,data,config,settings,0,easing.outQuad(data.timer, data.currentAngle[0], 0 - data.currentAngle[0], 30))
			cannonSetAngle(v,data,config,settings,2,easing.outQuad(data.timer, data.currentAngle[2], 0 - data.currentAngle[2], 30))
			if data.timer >= 30 then
				data.timer = 0
				v.ai1 = 0
				data.state = STATE_CEILING
				cannonAngleReset(v,data,config,settings)
			end
		end
	elseif data.state == STATE_KILL then
		v.speedX = 0
		v.speedY = 0
		v.friendly = true
		if data.timer % 8 <= 4 then
			v.animationFrame = -50
		end
		if data.barrier then
			if data.barrier.isValid then
				data.barrier:kill(9)
			end
			data.barrier = nil
		end
		if data.timer % 16 == 0 then
			SFX.play(explode)
			local a = Animation.spawn(pyroBlasterSettings.effectExplosion1ID,v.x+v.width/2,v.y+v.height/2)
			a.x=a.x-a.width/2+RNG.randomInt(-pyroBlasterSettings.width/2,pyroBlasterSettings.width/2)
			a.y=a.y-a.height/2+RNG.randomInt(-pyroBlasterSettings.height/2,pyroBlasterSettings.height/2)
		end
		if data.timer >= 200 then
			SFX.play(bigexplode)
			local a = Animation.spawn(pyroBlasterSettings.effectExplosion2ID,v.x+v.width/2,v.y+v.height/2)
			v:kill(HARM_TYPE_NPC)
			a.x=a.x-a.width/2
			a.y=a.y-a.height/2
		end
	end	
	if data.barrier then
		if data.barrier.isValid then
			data.barrier.x = v.x + v.width / 2 - data.barrier.width / 2
			data.barrier.y = v.y + v.height / 2 - data.barrier.height / 2 + 2
		else
			data.barrier = nil
		end
	end
	if data.fires then
        local allInvalid = true
        for k,f in ipairs(data.fires) do
            if f.isValid then
                v.despawnTimer = math.max(f.despawnTimer, v.despawnTimer)
                f.despawnTimer = v.despawnTimer
                f.data._basegame.pivot = vector(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
                f.data._basegame.angle = 180 + f.data._basegame.angleOffset
                allInvalid = false
            end
        end
        if allInvalid then
            data.fires = nil
			data.consecutive = data.consecutive + 1
			data.spawndelay = settings.spawndelay * Misc.GetEngineTPS()
        end
    end
	--Give Pyro Blaster some i-frames to make the fight less cheesable
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
		    SFX.play("s3k_damage.ogg")
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
			frames = config.frames
		});
	end
	--Prevent Pyro Blaster from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	if Colliders.collide(plr, v) and not v.friendly and data.state ~= STATE_KILL and not Defines.cheat_donthurtme then
		plr:harm()
	end
end

function pyroBlaster.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data._basegame
	if v.id ~= npcID then return end

			if data.iFrames == false and data.state ~= STATE_KILL and data.state ~= STATE_KAMIKAZE then
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
				if v.data._settings.kamikaze == false then
					data.state = STATE_KILL
				else
					data.state = STATE_KAMIKAZE
					data.kamikaze = true
				end
				data.timer = 0
				v.ai1 = 0
				cannonAngleReset(v,data,config,settings)
				if NPC.config[v.id].useFreezeHighlight == true then
					freeze.set(48)
				end
				--[[for _,n in ipairs(NPC.get()) do
					if n.id == NPC.config[v.id].shockwaveID or n.id == NPC.config[v.id].bombArray or n.id == NPC.config[v.id].phantoNormalID or n.id == NPC.config[v.id].phantoAggroID or n.id == NPC.config[v.id].phantoFuriousID or n.id == NPC.config[v.id].orbID or n.id == NPC.config[v.id].projectileID then
						if n.x + n.width > camera.x and n.x < camera.x + camera.width and n.y + n.height > camera.y and n.y < camera.y + camera.height then
							n:kill(9)
							Animation.spawn(10, n.x, n.y)
						end
					end
				end]]
			elseif data.health > 0 then
				v:mem(0x156,FIELD_WORD,60)
			end
	eventObj.cancelled = true
end

local lowPriorityStates = table.map{1,3,4}
function pyroBlaster.onDrawNPC(v)
	local data = v.data._basegame
	local settings = v.data._settings
	local config = NPC.config[v.id]
	data.w = math.pi/65
	if v.legacyBoss == true and data.state ~= STATE_KILL and data.state ~= STATE_KAMIKAZE and data.health and v.despawnTimer > 0 then
		Graphics.drawImage(hpboarder, 740, 120)
		local healthoffset = 126
		healthoffset = healthoffset-(126*(data.health/config.health))
		Graphics.drawImage(hpfill, 748, 128+healthoffset, 0, 0, 12, 126-healthoffset)
	end

	if data.imgActive == true then
		--Setup code by Mal8rk
		local pivotOffsetX = 0
		local pivotOffsetY = 0

		local opacity = 1

		local priority = 1
		if lowPriorityStates[v:mem(0x138,FIELD_WORD)] then
			priority = -75
		elseif v:mem(0x12C,FIELD_WORD) > 0 then
			priority = -30
		end

		--Text.print(v.x, 8,8)
		--Text.print(data.timer, 8,32)

		if data.iFrames or data.state == STATE_KILL then
			opacity = math.sin(lunatime.tick()*math.pi*0.25)*0.75 + 0.9
		end

		if data.cannon then
			for i=0,3 do
				if data.cannon[i] then
					-- Setting some properties --
					data.cannon[i].x, data.cannon[i].y = v.x + v.width / 2, v.y + v.height / 2
					data.cannon[i].transform.scale = vector(data.cannonSizex[i], data.cannonSizey[i])
					data.cannon[i].rotation = data.cannonAngle[i] + 90 * i

					local p = -46

					-- Drawing --
					
					data.cannon[i]:draw{frame = 0, sceneCoords = true, priority = p, color = Color.white..opacity}
				end
			end
		end

		if data.img then
			-- Setting some properties --
			data.img.x, data.img.y = v.x + 0.5 * v.width + config.gfxoffsetx, v.y + 0.5 * v.height --[[+ config.gfxoffsety]]
			if config.framestyle == 1 then
				data.img.transform.scale = vector(data.sprSizex * -v.direction, data.sprSizey)
			else
				data.img.transform.scale = vector(data.sprSizex, data.sprSizey)
			end
			data.img.rotation = data.angle

			local p = -45

			-- Drawing --
			
			data.img:draw{frame = v.animationFrame, sceneCoords = true, priority = p, color = Color.white..opacity}
			npcutils.hideNPC(v)
		end
	end
end

--Gotta return the library table!
return pyroBlaster