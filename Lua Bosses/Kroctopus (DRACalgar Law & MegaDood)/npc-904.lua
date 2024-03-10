--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local imagic = require("imagic")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 64,
	gfxheight = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 16,
	framestyle = 0,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	nohurt=false, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	noblockcollision = true,
	notcointransformable = true, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC

	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	nowalldeath = false, -- If true, the NPC will not die when released in a wall

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,
	aimDelay = 16,
	clawSpeed = 3,
	stackSpeed = 1,
	armWidth=64,
	armHeight=64,
	armOffsetX=0,
	armOffsetY=0,
	extendRange = 386,
	retractRange = 4,
	snipSFX = Misc.resolveFile("kroctopus_snip.ogg")
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
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


function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = npcutils.getNearestPlayer(v)
	local config = NPC.config[v.id]
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
		data.rotation = data.rotation or 0
		data.fadeOut = 100
		data.locationX = plr.x
		data.locationY = plr.y
		v.clawOffsetX = 0
		v.clawOffsetY = 0
		v.timer = 0
		v.state = 0
		v.spawnPositionX = 0
		v.spawnPositionY = 0
		v.stackSpeed = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		-- Handling of those special states. Most NPCs want to not execute their main code when held/coming out of a block/etc.
		-- If that applies to your NPC, simply return here.
		-- return
	end
	local parent = data.parent
	if parent.data.phase >= 1 then
		v.stackSpeed = config.stackSpeed
	else
		v.stackSpeed = 0
	end
	data.dirVectr = vector.v2(
		(data.locationX) - (v.x + v.width * 0.5),
		(data.locationY) - (v.y + v.height * 0.5)
		):normalize() * (config.clawSpeed + v.stackSpeed)
	data.spawnVectr = vector.v2(
		(v.spawnPositionX) - (v.x + v.width * 0.5),
		(v.spawnPositionY) - (v.y + v.height * 0.5)
		):normalize() * (config.clawSpeed + v.stackSpeed)
		local playerDistanceX,playerDistanceY,playerDistance = math.huge,math.huge,math.huge
		playerDistanceX = (data.locationX)-(v.x+(v.width /2))
        playerDistanceY = (data.locationY)-(v.y+(v.height/2))
        playerDistance  = math.abs(playerDistanceX)+math.abs(playerDistanceY)
		local clawDistanceX,clawDistanceY,clawDistance = math.huge,math.huge,math.huge
		clawDistanceX = (v.x+(v.width /2))-(v.spawnPositionX)
        clawDistanceY = (v.y+(v.height/2))-(v.spawnPositionY)
        clawDistance  = math.abs(clawDistanceX)+math.abs(clawDistanceY)
		local spawnDistanceX,spawnDistanceY,spawnDistance = math.huge,math.huge,math.huge
		spawnDistanceX = (v.spawnPositionX)-(v.x+(v.width /2))
        spawnDistanceY = (v.spawnPositionY)-(v.y+(v.height/2))
        spawnDistance  = math.abs(spawnDistanceX)+math.abs(spawnDistanceY)
	if not parent or not parent.isValid then
		data.parent = nil
		v:kill(9)
		return
	else
		if v.state == 0 then --Idle
			v.animationFrame = math.floor(lunatime.tick() / 8) % 4 + 4 * parent.data.bossColour
		elseif v.state == 1 then --Aim
			v.animationFrame = 0 + 4 * parent.data.bossColour
			data.locationX = plr.x
			data.locationY = plr.y
			if v.timer >= config.aimDelay then
				v.timer = 0
				v.state = 2
			end
		elseif v.state == 2 then --Extend
			v.animationFrame = 0 + 4 * parent.data.bossColour
			v.clawOffsetX = v.clawOffsetX + data.dirVectr.x
			v.clawOffsetY = v.clawOffsetY + data.dirVectr.y
			if (clawDistance >= config.extendRange) or (playerDistance <= 8) then
				v.state = 3
				v.timer = 0
			end
			Text.print(playerDistance,110,142)
			Text.print(clawDistance,110,158)
		elseif v.state == 3 then --Pinch
			v.animationFrame = math.clamp(math.floor(v.timer / 8), 0, 3) + 4 * parent.data.bossColour
			if v.timer >= 32 then
				v.timer = 0
				v.state = 4
			end
			if v.timer == 16 and config.snipSFX then SFX.play(config.snipSFX) end
		elseif v.state == 4 then --Retract
			v.animationFrame = 0 + 4 * parent.data.bossColour
			v.clawOffsetX = v.clawOffsetX + data.spawnVectr.x
			v.clawOffsetY = v.clawOffsetY + data.spawnVectr.y
			if spawnDistance <= config.retractRange then
				v.state = 0
				v.timer = 0
			end
			Text.print(spawnDistance,110,142)
		end
	end
end
local lowPriorityStates = table.map{1,3,4}
function sampleNPC.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local config = NPC.config[v.id]
	local data = v.data

	--Imagic sprite code setup by Murphmario
	imagic.Draw{
		texture = Graphics.sprites.npc[v.id].img,
		sourceWidth = sampleNPCSettings.gfxwidth,
		sourceHeight = sampleNPCSettings.gfxheight,
		sourceY = v.animationFrame * sampleNPCSettings.gfxheight,
		scene = true,
		x = v.x + sampleNPCSettings.gfxoffsetx + sampleNPCSettings.gfxwidth * 0.5,
		y = v.y - sampleNPCSettings.gfxoffsety + sampleNPCSettings.gfxheight * 0.5,
		rotation = data.rotation,
		width = sampleNPCSettings.gfxwidth,
		height = sampleNPCSettings.gfxheight,
		align = imagic.ALIGN_CENTRE,
		priority = -75
	}
	npcutils.hideNPC(v)
	local img = Graphics.loadImageResolved("kroctopus_arm.png")
	--Claw Arms
	local parent = data.parent
	local armColour
	if parent.data.bossColour then
		armColour = parent.data.bossColour
	end
	if (parent or parent.isValid) and v.state > 1 then
		Graphics.drawImageToSceneWP( --Arm Pivot
			img,
			v.spawnPositionX - config.armWidth / 2 + config.armOffsetX,
			v.spawnPositionY - config.armHeight / 2 + config.armOffsetY,
			0,
			config.armHeight * armColour,
			config.armWidth,
			config.armHeight,
			data.fadeOut / 100,
			-79.5
		)
		Graphics.drawImageToSceneWP( --Arm 1
			img,
			v.x - ((v.x - 3 - v.spawnPositionX) / 1.2) - config.armWidth / 2 + config.armOffsetX,
			v.y - ((v.y - v.spawnPositionY) / 1.2) - config.armHeight / 2 + config.armOffsetY,
			0,
			config.armHeight * armColour,
			config.armWidth,
			config.armHeight,
			data.fadeOut / 100,
			-79
		)
		Graphics.drawImageToSceneWP( --Arm 2
			img,
			v.x - ((v.x - 9 - v.spawnPositionX) / 1.6) - config.armWidth / 2 + config.armOffsetX,
			v.y - ((v.y - v.spawnPositionY) / 1.5) - config.armHeight / 2 + config.armOffsetY,
			0,
			config.armHeight * armColour,
			config.armWidth,
			config.armHeight,
			data.fadeOut / 100,
			-78
		)
		Graphics.drawImageToSceneWP( --Arm 3
			img,
			v.x - ((v.x - 24 - v.spawnPositionX) / 2.45) - config.armWidth / 2 + config.armOffsetX,
			v.y - ((v.y - v.spawnPositionY) / 2) - config.armHeight / 2 + config.armOffsetY,
			0,
			config.armHeight * armColour,
			config.armWidth,
			config.armHeight,
			data.fadeOut / 100,
			-77
		)
		Graphics.drawImageToSceneWP( --Arm 4
			img,
			v.x - ((v.x - 66 - v.spawnPositionX) / 5.3) + 1 - config.armWidth / 2 + config.armOffsetX,
			v.y - ((v.y - v.spawnPositionY) / 3) - config.armHeight / 2 + config.armOffsetY,
			0,
			config.armHeight * armColour,
			config.armWidth,
			config.armHeight,
			data.fadeOut / 100,
			-76
		)
	end
end
function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
	if v.id ~= npcID then return end
	local data = v.data
	
	eventObj.cancelled = true
	
	local parent = data.parent
	parent:harm(HARM_TYPE_NPC)
		--[[Increment data.hp by 1 when the boss is hit 3 times
		if parent.data.hp % 2 == 1 and parent.data.hp > 1 then
			parent.data.bossColour = parent.data.bossColour + 1
		end]]
end

--Gotta return the library table!
return sampleNPC