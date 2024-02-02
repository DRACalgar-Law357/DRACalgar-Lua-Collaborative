--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local whistle = require("npcs/ai/whistle")
local rng = require("rng")

--local textplus = require("textplus");    --for debugging


local idList  = {}
--local effectMap = {basic=1,aggro=1,furious=1}



--Create the library table
local phantoServants = {}

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sharedSettings = {

	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 3,
	framestyle = 0,
	framespeed = 4, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false


	--Define custom properties below
	awakenoffscreen = true,

	flashstartframe=0,
	flashendframe=2,

	sleepstartframe=0,
	sleependframe=0,

	chasestartframe=0,
    chaseendframe=0,
    
    aggroLevel = 0, -- behaviour when chasing the player: 0=chases as a phanto would, 1=chases and attempts to outsmart the player, 2=chases faster

	chaseDuration = 540
}

function phantoServants.register(config)
    table.insert(idList, config.id)
	local config = table.join(config, sharedSettings)
	npcManager.setNpcSettings(config)
	npcManager.registerEvent(config.id, phantoServants, "onTickEndNPC")
	npcManager.registerEvent(config.id, phantoServants, "onDrawNPC")
end


--Custom local definitions below
local STATE = {INACTIVE=1, AWAKEN=2, SHAKE=3, FOLLOW=4, HOSTAGE=5 , OUTSMART = 6}
local soundfx = {
	awaken = Misc.resolveSoundFile("phanto-awaken"),
	shake = Misc.resolveSoundFile("phanto-shake"),
	move = Misc.resolveSoundFile("phanto-move")
}





local function setAnimBounds(v, typestr)
	local data = v.data._basegame
	local config = NPC.config[v.id]

	data.startframe = config[typestr.."startframe"]
	data.endframe = config[typestr.."endframe"]
end




function phantoServants.onTickEndNPC(v)
	--Don't act during time freeze
	if  Defines.levelFreeze then  return  end

	local data = v.data._basegame
	local config = NPC.config[v.id]
	local cam = camera
	local currentSection = v:mem(0x146, FIELD_WORD)
	local canActivateOffscreen = (config.awakenoffscreen  and  player.section == currentSection)


	--If despawned OR not able to spawn offscreen when in the same section
	if  v:mem(0x12A, FIELD_WORD) <= 0  and  not canActivateOffscreen  then
		--Reset our properties, if necessary
		data.initialized = false
		return;
	end

	local settings = v.data._settings

	--Initialize
	if  not data.initialized  then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE.INACTIVE
		data.startframe = nil
		data.endframe = nil
		v.ai1 = 0
		v.ai2 = 0
		v.ai3 = 0
		v.ai4 = 0
		v.ai5 = 0
		data.startSection = currentSection
		data.currentScreenLeft = v.x
		data.targetPlayer = nil
		data.exitSide = -1
		if  data.startedFriendly == nil  then
			data.startedFriendly = v.friendly
		end
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
		data.state = STATE.HOSTAGE
	end


	-------- Execute main AI -----------
	local center = vector.v2(v.x+0.5*v.width, v.y+0.5*v.height)


	-- STATE-AGNOSTIC BEHAVIOR
	local sectionObj = Section(currentSection)  or  Section(player.section)

	-- Animation handling
	data.startframe = nil
	data.endframe = nil

	-- General-purpose AI timer countdown
	v.ai1 = math.max(0, v.ai1-1)

	-- prevent from despawning when offscreen
	if  data.state ~= STATE.INACTIVE  or  canActivateOffscreen  then
		v:mem(0x124, FIELD_BOOL, true)
		v:mem(0x12A, FIELD_WORD, 180)
		v:mem(0x126, FIELD_BOOL, false)
		v:mem(0x128, FIELD_BOOL, false)
	end

	-- Handle the move sound effect, determining the target player and following them across sections
	if  data.state == STATE.AWAKEN  or  data.state == STATE.SHAKE  or  data.state == STATE.FOLLOW  or data.state == STATE.OUTSMART  then
		-- Reset target player
		local sectionToCheck = currentSection

		local heldDetected = false
		heldDetected = true
		data.targetPlayer = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)

		-- If a player took a target item to another section, or I'm just stubborn, follow them
		local stubbornTarget = data.targetPlayer  or  player
		if  data.targetPlayer ~= nil  or  config.aggroLevel == 2  then
			if  stubbornTarget.section ~= currentSection  and  (heldDetected  or  config.aggroLevel == 2)  then
				v:mem(0x146, FIELD_WORD, stubbornTarget.section)
				currentSection = v:mem(0x146, FIELD_WORD)
				v.speedY = rng.random(-3,0)
				local rngFactor = 200
				if config.aggroLevel == 2 then rngFactor = 150 end
				data.startTick = lunatime.tick()-rng.randomInt(rngFactor)
				data.state = STATE.FOLLOW
			end

		elseif  stubbornTarget.section ~= currentSection  then
			data.initialized = false
			return;
		end

		-- Moving sound effect
		v.ai2 = (v.ai2 + 1)%128
		if  v.ai2 == 0  and  data.targetPlayer ~= nil  then
			SFX.play(soundfx.move)
		end
		--Chasing Duration
		v.ai3 = v.ai3 + 1
		if v.ai3 >= config.chaseDuration then
			v:kill(9)
			local a = Animation.spawn(10,v.x+v.width/2,v.y+v.height/2)
			a.x=a.x-a.width/2
			a.y=a.y-a.height/2
			SFX.play(64)
		end
	else
		if math.abs(v.speedY) >= 1 then
			v.speedY = v.speedY / 16
		else
			v.speedY = 0
		end
		if math.abs(v.speedX) >= 1 then
			v.speedX = v.speedX / 16
		else
			v.speedX = 0
		end
		data.currentScreenLeft = v.x
	end

	-- Friendly if not tracking the player
	v.friendly = (data.targetPlayer == nil)  or  data.startedFriendly



	-- INACTIVE
	if  data.state == STATE.INACTIVE  then
		setAnimBounds(v, "sleep")
		data.state = STATE.AWAKEN
		SFX.play(soundfx.move)
		v.ai1 = 32


	-- AWAKENING
	elseif  data.state == STATE.AWAKEN  then
		setAnimBounds(v, "flash")

		if  v.ai1 <= 0  then
			SFX.play(soundfx.shake)
			data.state = STATE.SHAKE
			v.ai1 = 65
		end


	-- SHAKING
	elseif  data.state == STATE.SHAKE  then
		setAnimBounds(v, "chase")

		if  v.ai1 <= 0  then
			data.state = STATE.FOLLOW
			data.startTick = lunatime.tick()
		end


	-- FOLLOWING
	elseif  data.state == STATE.FOLLOW  then
		setAnimBounds(v, "chase")

		-- Manage chasing and hovering behavior
		local boundary = sectionObj.boundary
		local sectionW = boundary.right - boundary.left

		local targetCenter
		if  data.targetPlayer ~= nil  then
			local targetP = data.targetPlayer
			targetCenter = vector.v2(targetP.x+0.5*targetP.width, targetP.y+targetP.height-32)
			data.exitSide = -math.sign(targetCenter.y-center.y)
			if  data.exitSide == 0  then
				data.exitSide = 1
			end

		else
			targetCenter = vector.v2(cam.x+cam.width*0.5, cam.y + 0.5*cam.width + cam.width*data.exitSide)
		end

		local toTarget = vector.v2(targetCenter.x-center.x, targetCenter.y-center.y)
		local verticalMovement = 0.15
		if config.aggroLevel == 2 then verticalMovement = 0.2 end
		v.speedY = v.speedY + verticalMovement*math.sign(toTarget.y)
		v.speedY = math.clamp(v.speedY, -5,5)


		-- Horizontal movement
		local chaseAcceleration = 0.15
		local direction = 1
		if config.aggroLevel == 2 then verticalMovement = 0.2 end
		local targetP = data.targetPlayer
		if v.x + v.width/2 < targetP.x+0.5*targetP.width then
			direction = 1
		else
			direction = -1
		end
		
		if v.ai5 % 240 < 120 then
			if math.abs(targetP.x+0.5*targetP.width - (v.x + v.width/2)) < 256 then
				chaseAcceleration = chaseAcceleration * -direction
			else
				chaseAcceleration = chaseAcceleration * direction
			end
		else
			chaseAcceleration = chaseAcceleration * direction
		end

		v.speedX = math.clamp(v.speedX + chaseAcceleration, -5, 5)
		center = vector.v2(v.x+0.5*v.width, v.y+0.5*v.height)
		v.ai5 = v.ai5 + 1
		if NPC.config[v.id].aggroLevel == 1 then
			v.ai4 = v.ai4 + 1
			if v.ai4 == 240 then
				v.ai4 = 0
				v.speedX = 0
				v.speedY = 0
				data.state = STATE.OUTSMART
			end
		end


	-- HOSTAGE
	elseif  data.state == STATE.HOSTAGE  then
		local pID = v:mem(0x12C,FIELD_WORD)
		if  pID > 0  then
			data.targetPlayer = Player(pID)
		end
		setAnimBounds(v, "chase")

		if  v:mem(0x12C, FIELD_WORD) <= 0  then
			v:mem(0x136, FIELD_BOOL, false)
			data.currentScreenLeft = v.x
			data.state = STATE.FOLLOW
			data.startTick = lunatime.tick()
		end
	--OUTSMART
	elseif  data.state == STATE.OUTSMART  then
		v.ai4 = v.ai4 + 1
		if v.ai4 == 1 then v.speedX = 0 v.speedY = 0 end
		if v.ai4 == 32 then
			v.speedX = RNG.irandomEntry{-2.5,0,2.5}
			v.speedY = RNG.irandomEntry{-2.5,0,2.5}
			SFX.play(soundfx.move)
		elseif v.ai4 == 64 then
			v.speedX = 0
			v.speedY = 0
		elseif v.ai4 >= 96 then
			v.ai4 = 0
			data.state = STATE.OUTSMART
		end
	end



	-- DEBUG
	--[[
	--data.pos = vector.v2(math.floor(center.x), math.floor(center.y))
	--data.speed = vector.v2(math.floor(v.speedX), math.floor(v.speedY))
	local str = ""
	for  key,val in pairs(data)  do
		str = str .. key .. ": " .. tostring(val) .. "<br>"
	end
	textplus.print {text=str, x=20, y=20, priority = 0.985, color=Color.white, font=FONT_BASIC, align="topleft", pivot={0,0}, xscale=1, yscale=1}
	--data.pos = nil
	--data.speed = nil
	--]]

end

function phantoServants.onDrawNPC(v)
	local data = v.data._basegame
	local config = NPC.config[v.id]

	local shakeExtra = 0
	if  data.state == STATE.SHAKE and Defines.levelFreeze == false then
		shakeExtra = math.floor((lunatime.tick()%8)/4)
	end

	local animlength = 1
	if  data.startframe ~= nil  and  data.endframe ~= nil  then
		animlength = data.endframe - data.startframe + 1
	end

	npcutils.drawNPC(v, {
		frame=npcutils.getFrameByFramestyle(v, {
			offset = (data.startframe or 0),
			frames = animlength - (data.startframe or 0)}), 
		xOffset=config.gfxoffsetx + shakeExtra})
	npcutils.hideNPC(v)
end




--Gotta return the library table!
return phantoServants