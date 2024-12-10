--[[
					Konotakos by MrNameless
		An NPC from Wario Land 1 that swoops down & sticks to any player or block
			for a short period of time before exploding.
			
	CREDITS:
	Nintendo - Made the sprites for the konotako
	Masterxilo - Made the recolors of the sprites of the konotakos (https://www.deviantart.com/masterxilo/art/Wario-Land-1-Super-Mario-Land-3-sprites-colored-561176088)

	Version 1.0.0
]]--


--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local konotako = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local konotakoSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 48,
	gfxheight = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 6,
	framestyle = 0,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	foreground = true, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- LOGIC
	--Movement speed. Only affects speedX by default.
	speed = 1,
	luahandlesspeed = true, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = false,
	cliffturn = false, -- Makes the NPC turn on ledges
	staticdirection = true, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = false, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = false, -- The player can walk on the NPC.

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	noblockcollision = true,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = false,
	noiceball = false,
	noyoshi= false, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC

	score = 2, -- Score granted when killed
	--  1 = 10,    2 = 100,    3 = 200,  4 = 400,  5 = 800,
	--  6 = 1000,  7 = 2000,   8 = 4000, 9 = 8000, 10 = 1up,
	-- 11 = 2up,  12 = 3up,  13+ = 5-up, 0 = 0

	--Various interactions
	jumphurt = false, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	nowalldeath = false, -- If true, the NPC will not die when released in a wall

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:

	nogliding = true, -- The NPC ignores gliding blocks (1f0)

	--Emits light if the Darkness feature is active:
	lightradius = 48,
	lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	lightcolor = Color.white,

	--Define custom properties below
	
	animData = { -- needed as a reference for what animation is playing & what frames are to be played in whatever speed & order is set
		fly = {frames = {0,1}, framespeed = 8, loops = true},
		lit = {frames = {2,3}, framespeed = 4, loops = true},
		flicker = {frames = {2,4,3,5}, framespeed = 2, loops = true},
	}
	
}

--Applies NPC settings
npcManager.setNpcSettings(konotakoSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=npcID,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=npcID,
		--[HARM_TYPE_OFFSCREEN]=npcID,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below

local tickSFX = Misc.resolveSoundFile("sound/extended/beat-warn.ogg")


local function switchAnim(v, animName, forced) -- animation switching (taken from MrDoubleA's SMW Costumes)
    local animData = NPC.config[v.id].animData[animName]
    local data = v.data
	
    if data.curAnim == animName and not forced then return end
    
    data.curAnim = animName
    data.curFrame = animData.frames[1]
    data.frameTimer = 0
end


local function animationHandling(v) -- (taken from MrDoubleA's SMW Costumes)
	local data = v.data
	local frameData = NPC.config[v.id].animData[data.curAnim]
	local frameCount = #frameData.frames
	local frameIndex = math.floor(data.frameTimer / frameData.framespeed)

	data.frameTimer = data.frameTimer + 1
		
	if frameIndex >= frameCount then
		if frameData.loops then
			frameIndex = frameIndex % frameCount
		else
			frameIndex = frameCount - 1
		end
	end
		
	data.curFrame = frameData.frames[frameIndex + 1]
end


--Register events
function konotako.onInitAPI()
	--npcManager.registerEvent(npcID, konotako, "onTickNPC")
	npcManager.registerEvent(npcID, konotako, "onTickEndNPC") -- all custom NPC animation related code must be in either onTickEndNPC/onDrawNPC only
	--npcManager.registerEvent(npcID, konotako, "onDrawNPC")
	registerEvent(konotako, "onNPCHarm")
end

function konotako.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0	--Despawned
	or v.heldIndex ~= 0 	--Negative when held by NPCs, positive when held by players
	or v.isProjectile   	--Thrown
	or v.forcedState > 0	--Various forced states
	then
		--Reset our properties, if necessary
		v.animationFrame = 0
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.curAnim = "fly" -- <<
		data.curFrame = 0 -- << animation initializing
		data.frameTimer = 0 -- <<
		
		data.stuckObject = nil
		data.initialY = v.y
		data.flyTimer = data._settings.initWaitTime
		data.countdown = 65 * 4
		data.state = 0
		data.initialized = true
	end
	
	animationHandling(v) -- does the actual animating itself
	
	if data.state == 0 then -- flying state
		v.speedY = math.sin(data._settings.initWaitTime - data.flyTimer * 0.1) * 1 
		data.flyTimer = math.max(data.flyTimer - 1,0)
		if data.flyTimer <= 0 then
			v.y = data.initialY
			v.speedX = data._settings.swoopSpeedX * v.direction
			data.state = 1
		end
	end
	
	if data.state == 1 then -- swooping state
		data.flyTimer = data.flyTimer + 1
		--v.speedY = math.sin(data.flyTimer * 0.075) * 4 -- stole this from deltom lol,
		if data.flyTimer <= 5 then
			v.speedY = data._settings.swoopSpeedY 
		else
			v.speedY = math.max(v.speedY - 0.1, -data._settings.swoopSpeedY)
		end
		
		if v.y <= data.initialY and data.flyTimer > 1 then
			v.direction = v.direction * -1
			v.y = data.initialY
			v.speedY = 0
			v.speedX = 0
			data.state = 0
			data.flyTimer = data._settings.initWaitTime
		end
	end
	
	if data.state == 2 then
		if type(data.stuckObject) == "Player" then
			for _,b in Block.iterateIntersecting((v.x+v.width*0.5)-2,(v.y+v.height*0.5)-2,(v.x+v.width*0.5)+2,(v.y+v.height*0.5)+2) do
				if b.isValid and not b.isHidden and Block.SOLID_MAP[b.id] and not Block.SEMISOLID_MAP[b.id]
				and not Block.PLAYERSOLID_MAP[b.id] and not Block.LAVA_MAP[b.id] then
					data.stuckObject = b
					data.distance = vector(
						b.x - v.x,
						b.y - v.y
					)
					v.x = b.x - data.distance.x
					v.y = b.y - data.distance.y
				end
				break
			end
		end
		local obj = data.stuckObject
		v.despawnTimer = 180
		v.speedX = obj.speedX
		v.speedY = obj.speedY
		v.x = obj.x - data.distance.x
		v.y = obj.y - data.distance.y
		data.countdown = math.max(data.countdown - 1,-1)
		if data.countdown == 0 then
			Routine.run(function()
				local x = v.x+v.width*0.5
				local y = v.y+v.height*0.5
				v:kill(9)
				SFX.play(88)
				Effect.spawn(76,x,y)
				Routine.waitFrames(5)
				local e = Effect.spawn(131,x,y)
				e.x = e.x - e.width*0.5
				e.y = e.y - e.height*0.5
				Routine.waitFrames(25)
				local newExplosion = Explosion.spawn(x,y,3)
			end)
		elseif data.countdown <= 65 and data.countdown > 0 then
			switchAnim(v,"flicker")
			if data.countdown % 4 == 0 then
				SFX.play(26, 0.75) 
			end
		else
			if data.countdown % 32 == 0 then
				SFX.play(26, 0.75) 
			end
		end
	else
		for _,p in ipairs(Player.getIntersecting(v.x-2,v.y+v.height*0.75,v.x+v.width+2,v.y+v.height+2)) do
			if p.deathTimer == 0 and v.forcedState == 0 then
				data.state = 2
				data.stuckObject = p
				data.distance = vector(
					p.x - v.x,
					p.y - v.y
				)
				v.x = p.x - data.distance.x
				v.y = p.y - data.distance.y
				v.friendly = true
				switchAnim(v,"lit")
				SFX.play(23)
				break
			end
		end
	end

	v.animationTimer = 0
	v.animationFrame = data.curFrame -- sets the final frame chosen.

	if NPC.config[v.id].framestyle == 1 and v.direction == 1 then
		v.animationFrame = v.animationFrame + NPC.config[v.id].frames -- sets the final frame to the corresponding direction of the npc if they have their framestyle set to 1.
	end
	
end

function konotako.onNPCHarm(token,v,harm,c)
	if v.id ~= npcID then return end
	
	if v.data.state == 2 then token.cancelled = true return end
end

--Gotta return the library table!
return konotako