--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local utils = require("npcs/npcutils")
--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 80,
	gfxwidth = 124,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 72,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 11,
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
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

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
	bigjump = 10,
	smalljump = 7.5,
	projectileID = 811,
	hp = 6,
	promin = 6,
	promax = 12,
	pinpromin = 8,
	pinpromax = 18,
	prodelay = 8,
	pinprodelay = 5,
	deathtime = 240,
	explosionID = 10,
	invincibilitytime = 90,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
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
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
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
local STATE_CLOSEIN = 2
local STATE_FIRE = 3
local STATE_DEAD = 4
local STATE_PINCH = 5
local STATE_INTRO = 6


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	local config = NPC.config[v.id]
	local data = v.data
	local settings = v.data._settings
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		settings.enemyID = settings.enemyID or 166
		settings.enemyIDPinch = settings.enemyIDPinch or 19
		settings.projectileID = settings.projectileID or 811
		settings.projectileIDPinch = settings.projectileIDPinch or 811
		settings.jumpHeight = settings.jumpHeight or 7.5
		settings.jumpHeightHigh = settings.jumpHeightHigh or 11
		settings.jumpHeightPinch = settings.jumpHeightPinch or 6.5
		settings.jumpHeightHighPinch = settings.jumpHeightHighPinch or 10
		settings.jumpSpeed = settings.jumpSpeed or 3
		settings.jumpSpeedHigh = settings.jumpSpeedHigh or 3
		settings.jumpSpeedPinch = settings.jumpSpeedPinch or 4
		settings.jumpSpeedHighPinch = settings.jumpSpeedHighPinch or 5
		settings.projectileSpeedX = settings.projectileSpeedX or 4
		settings.projectileSpeedYMin = settings.projectileSpeedYMin or 5
		settings.projectileSpeedYMax = settings.projectileSpeedYMax or 7
		settings.projectileSpeedXPinch = settings.projectileSpeedXPinch or 5
		settings.projectileSpeedYMinPinch = settings.projectileSpeedYMinPinch or 6
		settings.projectileSpeedYMaxPinch = settings.projectileSpeedYMaxPinch or 8
		settings.hp = settings.hp or 6
		if settings.intro == nil then
			settings.intro = settings.intro or true
		end

		v.pinch = false
		v.defeat = false
		v.harmed = false
		v.closeinconsecutive = 0
		v.closeinlimit = RNG.randomInt(1,3)
		v.decision = 0
		v.jumped = false
		v.invisibleharm = false
		v.consecutive = 0
		v.projectilelimit = RNG.randomInt(config.promin, config.promax)
		v.statetimer = 0
		v.harmframe = 0
		v.hp = settings.hp
		v.harmtimer = config.invincibilitytime
		if settings.intro == false then
			v.state = STATE_IDLE
		else
			v.state = STATE_INTRO
		end
		
		data.initialized = true
	end
	if (v.collidesBlockLeft or v.collidesBlockRight) and (v.state == STATE_CLOSEIN or v.state == STATE_JUMP) then
		v.direction = -v.direction
	end
	if (v.harmed == true and v.state ~= STATE_DEAD) or v.state == STATE_DEAD then
		v.harmtimer = v.harmtimer - 1
		v.harmframe = v.harmframe + 1
		if v.harmframe == 6 then
			v.harmframe = 0
		end
		if v.harmframe > 3 then
			v.invisibleharm = true
		else
			v.invisibleharm = false
		end
		if v.harmtimer == 0 then
			v.harmtimer = config.invincibilitytime
			v.harmframe = 0
			v.harmed = false
		end
	end
	local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
		
	if v.state == STATE_IDLE then
		v.statetimer = v.statetimer + 1
		if v.statetimer == 45 then
			v.statetimer = 0
			v.decision = RNG.randomInt(0,1)
			if v.decision == 0 then
				if v.jumped == false then
					v.state = STATE_JUMP
				else
					v.state = STATE_CLOSEIN
					v.closeinlimit = RNG.randomInt(1,3)
				end
			else
				v.state = STATE_CLOSEIN
			end
		end
	elseif v.state == STATE_JUMP then
		v.statetimer = v.statetimer + 1
		if v.jumped == false then
			if (v.pinch == true and v.statetimer >= 44) or (v.pinch == false and v.statetimer >= 64) then
				if (v.x + v.width / 2) > (p.x + p.width / 2) then
					v.direction = -1
				else
					v.direction = 1
				end
				if v.pinch == false then
					v.speedX = settings.jumpSpeedHigh * v.direction
					v.speedY = -settings.jumpHeightHigh
				else
					v.speedX = settings.jumpSpeedHighPinch * v.direction
					v.speedY = -settings.jumpHeightHighPinch
				end
				v.jumped = true
				SFX.play(Misc.resolveSoundFile("bowlingball"))
				local pl = Animation.spawn(10,v.x+v.width/4,v.y+v.height)
				local pr = Animation.spawn(10,v.x+v.width*3/4,v.y+v.height)
				pl.speedX = -2
				pr.speedX = 2
				pl.x=pl.x-pl.width/2
				pl.y=pl.y-pl.height/2
				pr.x=pr.x-pr.width/2
				pr.y=pr.y-pr.height/2
			end
		else
			if v.collidesBlockBottom then
				v.statetimer = 0
				v.speedX = 0
				v.state = STATE_IDLE
				SFX.play(Misc.resolveSoundFile("bowlingball"))
				local pl = Animation.spawn(10,v.x+v.width/4,v.y+v.height)
				local pr = Animation.spawn(10,v.x+v.width*3/4,v.y+v.height)
				pl.speedX = -2
				pr.speedX = 2
				pl.x=pl.x-pl.width/2
				pl.y=pl.y-pl.height/2
				pr.x=pr.x-pr.width/2
				pr.y=pr.y-pr.height/2
			end
		end
	elseif v.state == STATE_CLOSEIN then
		v.statetimer = v.statetimer + 1
		if v.statetimer == 30 then
			if (v.x + v.width / 2) > (p.x + p.width / 2) then
				v.direction = -1
			else
				v.direction = 1
			end
			if v.pinch == false then
				v.speedX = settings.jumpSpeed * v.direction
				v.speedY = -settings.jumpHeight
			else
				v.speedX = settings.jumpSpeedPinch * v.direction
				v.speedY = -settings.jumpHeightPinch
			end
		end
		if v.statetimer > 36 and v.collidesBlockBottom then
			v.speedX = 0
			if v.closeinconsecutive < v.closeinlimit then
				v.statetimer = 0
				v.closeinconsecutive = v.closeinconsecutive + 1
				v.decision = RNG.randomInt(1, 2)
				if v.decision == 1 and v.jumped == false and v.pinch == false then
					v.state = STATE_JUMP
				end
			else
				v.statetimer = 0
				v.jumped = false
				v.closeinconsecutive = 0
				v.state = STATE_FIRE
				if v.pinch == false then
					v.projectilelimit = RNG.randomInt(config.promin, config.promax)
				else
					v.projectilelimit = RNG.randomInt(config.pinpromin, config.pinpromax)
				end
			end
		end
	elseif v.state == STATE_FIRE then
		v.statetimer = v.statetimer + 1
		if v.statetimer == 90 then
			if v.consecutive < v.projectilelimit then
				local bullet
				if v.pinch == false then
					bullet = NPC.spawn(settings.projectileID, v.x + v.width/2, v.y, v.section)
					bullet.speedX = RNG.random(-settings.projectileSpeedX, settings.projectileSpeedX)
					bullet.speedY = -RNG.random(settings.projectileSpeedYMin, settings.projectileSpeedYMax)
				else
					bullet = NPC.spawn(settings.projectileIDPinch, v.x + v.width/2, v.y, v.section)
					bullet.speedX = RNG.random(-settings.projectileSpeedXPinch, settings.projectileSpeedXPinch)
					bullet.speedY = -RNG.random(settings.projectileSpeedYMinPinch, settings.projectileSpeedYMaxPinch)
				end
				bullet.despawnTimer = 100
				bullet.friendly = v.friendly
				bullet.layerName = "Spawned NPCs"
				bullet.x=bullet.x-bullet.width/2
				bullet.y=bullet.y-bullet.height/2
				SFX.play(18)
			end
			if v.consecutive == v.projectilelimit-1 then
				if v.pinch == false then
					local bullet = NPC.spawn(settings.enemyID, v.x + v.width/2, v.y, v.section)
					bullet.speedX = RNG.random(-1, 1)
					bullet.speedY = -RNG.random(6, 10)
					bullet.despawnTimer = 100
					bullet.friendly = v.friendly
					bullet.layerName = "Spawned NPCs"
					bullet.x=bullet.x-bullet.width/2
					bullet.y=bullet.y-bullet.height/2
				else
					local bullet = NPC.spawn(settings.enemyIDPinch, v.x + v.width/2, v.y, v.section)
					bullet.speedX = RNG.random(-1, 1)
					bullet.speedY = -RNG.random(6, 10)
					bullet.despawnTimer = 100
					bullet.friendly = v.friendly
					bullet.layerName = "Spawned NPCs"
					bullet.x=bullet.x-bullet.width/2
					bullet.y=bullet.y-bullet.height/2
				end
				SFX.play(38)
			end
			v.statetimer = 80
			v.consecutive = v.consecutive + 1
		end
		if v.statetimer == 85 and v.consecutive == v.projectilelimit then
			v.statetimer = 0
			v.consecutive = 0
			v.state = STATE_IDLE
			if v.pinch == false then
				v.projectilelimit = RNG.randomInt(config.promin, config.promax)
			else
				v.projectilelimit = RNG.randomInt(config.pinpromin, config.pinpromax)
			end
		end
	elseif v.state == STATE_DEAD then
		v.statetimer = v.statetimer + 1
		if v.statetimer == 300 then
			v:kill(HARM_TYPE_NPC)
			Animation.spawn(71,v.x+v.width/2-8,v.y+v.height/2-8)
			SFX.play(43)
		end
		if v.statetimer % 12 == 2 then
			local prt = Animation.spawn(config.explosionID, math.random(v.x, v.x + v.width), math.random(v.y, v.y + v.height))
			prt.speedX = RNG.random(-5, 5)
			prt.speedY = RNG.random(-5, 5)
			prt.x=prt.x-prt.width/2
			prt.y=prt.y-prt.height/2
			SFX.play(36)
		end
		v.friendly = true
		v.speedX = 0
		v.harm = true
	elseif v.state == STATE_INTRO or v.state == STATE_PINCH then
		v.speedX = 0
		v.statetimer = v.statetimer + 1
		v.friendly = true
		if v.statetimer == 128 then
			if v.state == STATE_INTRO then
				local pl = Animation.spawn(10,v.x+v.width/2,v.y+v.height/2)
				local pr = Animation.spawn(10,v.x+v.width/2,v.y+v.height/2)
				pl.speedX = -2
				pr.speedX = 2
				pl.x=pl.x-pl.width/2
				pl.y=pl.y-pl.height/2
				pr.x=pr.x-pr.width/2
				pr.y=pr.y-pr.height/2
			else
				local pl = Animation.spawn(10,v.x+v.width/2,v.y+v.height/2)
				local pr = Animation.spawn(10,v.x+v.width/2,v.y+v.height/2)
				pl.speedX = -2
				pr.speedX = 2
				pl.x=pl.x-pl.width/2
				pl.y=pl.y-pl.height/2
				pr.x=pr.x-pr.width/2
				pr.y=pr.y-pr.height/2
				Routine.setTimer(.00001, (function() 
					local ptl = Animation.spawn(10, math.random(v.x, v.x + v.width), math.random(v.y, v.y + v.height))
					ptl.speedX = RNG.random(-3,3)
					ptl.speedY = RNG.random(-3,3)
					ptl.x=ptl.x-ptl.width/2
					ptl.y=ptl.y-ptl.height/2
					v.ai1 = v.ai1 + 1
					end), 40, false)
				v.ai1 = 0
				v.pinch = true
			end
			SFX.play(72)
		end
		if v.statetimer >= 220 then
			v.statetimer = 0
			v.state = STATE_IDLE
			v.friendly = false
		end
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	if v.hp <= settings.hp / 2 and v.pinch == false and v.collidesBlockBottom and v.state ~= STATE_PINCH then
		v.state = STATE_PINCH
		v.statetimer = 0
		v.speedX = 0
		v.speedY = 0
	end
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
end
function sampleNPC.onDrawNPC(v)
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]
	utils.restoreAnimation(v)
	idle = utils.getFrameByFramestyle(v, {
		frames = 1,
		gap = 10,
		offset = 0
	})
	jump = utils.getFrameByFramestyle(v, {
		frames = 1,
		gap = 9,
		offset = 1
	})
	open = utils.getFrameByFramestyle(v, {
		frames = 1,
		gap = 8,
		offset = 2
	})
	fire = utils.getFrameByFramestyle(v, {
		frames = 2,
		gap = 6,
		offset = 3
	})
	pinchidle = utils.getFrameByFramestyle(v, {
		frames = 1,
		gap = 5,
		offset = 5
	})
	pinchjump = utils.getFrameByFramestyle(v, {
		frames = 1,
		gap = 4,
		offset = 6
	})
	pinchopen = utils.getFrameByFramestyle(v, {
		frames = 1,
		gap = 3,
		offset = 7
	})
	pinchfire = utils.getFrameByFramestyle(v, {
		frames = 2,
		gap = 1,
		offset = 8
	})
	defeat = utils.getFrameByFramestyle(v, {
		frames = 1,
		gap = 0,
		offset = 10
	})
	
	if v.invisibleharm == false then
		if v.defeat == false then
			if v.pinch == false then
				if v.state == STATE_IDLE then
					v.animationFrame = idle
				elseif v.state == STATE_JUMP then
					v.animationFrame = jump
				elseif v.state == STATE_CLOSEIN then
					if v.statetimer < 30 then
						v.animationFrame = idle
					else
						v.animationFrame = jump
					end
				elseif v.state == STATE_FIRE then
					if v.statetimer < 80 then
						v.animationFrame = open
					else
						v.animationFrame = fire
					end
				elseif v.state == STATE_INTRO or v.state == STATE_PINCH then
					if v.statetimer < 64 then
						v.animationFrame = idle
					elseif v.statetimer >= 64 and v.statetimer < 128 then
						v.animationFrame = jump
					else
						v.animationFrame = idle
					end
				end
			else
				if v.state == STATE_IDLE then
					v.animationFrame = pinchidle
				elseif v.state == STATE_JUMP then
					v.animationFrame = pinchjump
				elseif v.state == STATE_CLOSEIN then
					if v.statetimer < 30 then
						v.animationFrame = pinchidle
					else
						v.animationFrame = pinchjump
					end
				elseif v.state == STATE_FIRE then
					if v.statetimer < 80 then
						v.animationFrame = pinchopen
					else
						v.animationFrame = pinchfire
					end
				elseif v.state == STATE_INTRO or v.state == STATE_PINCH then
					if v.statetimer < 64 then
						v.animationFrame = pinchidle
					elseif v.statetimer >= 64 and v.statetimer < 128 then
						v.animationFrame = pinchjump
					else
						if v.statetimer % 6 < 3 then
							v.animationFrame = pinchidle
						else
							v.animationFrame = idle
						end
					end
				end
			end
		else
			v.animationFrame = defeat
		end
	else
		v.animationFrame = -999
	end
end

function sampleNPC.onNPCHarm(eventObj, v, killReason, culprit)
	local data = v.data
	local settings = v.data._settings
	if v.id ~= npcID then return end

	if killReason == HARM_TYPE_NPC or HARM_TYPE_PROJECTILE_USED or HARM_TYPE_SWORD then
		if v.state == STATE_FIRE then
			if v:mem(0x156,FIELD_WORD) == 0 and v.harmed == false then
				if culprit then
					if culprit.id == 13 then
						v.hp = v.hp - 0.25
						SFX.play(9)
					else
						v.hp = v.hp - 1
						v.harmed = true
						SFX.play(39)
					end
				else
					v.hp = v.hp - 1
					v.harmed = true
					SFX.play(39)
				end
			end
		else
			if v:mem(0x156, FIELD_WORD) <= 0 then
				SFX.play(85)
				if culprit then
					Animation.spawn(75, culprit.x, culprit.y)
					culprit.speedX = -(culprit.speedX + 2)
					culprit.speedY = -8
					if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
						culprit:kill(HARM_TYPE_NPC)
					end
				end
				v:mem(0x156, FIELD_WORD,3)
			end
			
		end
	else
		return
	end
	if v.hp == 0 then
		v.statetimer = 0
		v.state = STATE_DEAD
		v.defeat = true
	end	
	eventObj.cancelled = true

end

--Gotta return the library table!
return sampleNPC