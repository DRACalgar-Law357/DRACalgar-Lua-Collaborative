--[[
	This template can be used to make your own custom NPCs!
	Copy it over into your level or episode folder and rename it to use an ID between 751 and 1000. For example: npc-751.lua
	Please pay attention to the comments (lines with --) when making changes. They contain useful information!
	Refer to the end of onTickNPC to see how to stop the NPC talking to you.
	

]]


-- redirecting code is from Emral's SMW Urchins (https://www.smbxgame.com/forums/viewtopic.php?t=24260)



--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local pouncer = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local pouncerSettings = {
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
	frames = 2,
	framestyle = 0,
	framespeed = 16, -- number of ticks (in-game frames) between animation frame changes

	foreground = true, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- LOGIC
	--Movement speed. Only affects speedX by default.
	
	speed = 3, -- should be 1 by default, but currently 3 to test if it still works with redirectors despite it being faster.
	
	
	luahandlesspeed = true, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = false,
	cliffturn = false, -- Makes the NPC turn on ledges
	staticdirection = false, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = true, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = true, -- The player can walk on the NPC.

	nohurt=false, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	noblockcollision = false,
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

	weight = 2,
	nogliding = true, -- The NPC ignores gliding blocks (1f0)
	--Define custom properties below
	
	instakill = true -- (not yet implemented) config that allows the pouncer to instantly kill the player upon touching it.
}

--Applies NPC settings
npcManager.setNpcSettings(pouncerSettings)

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

local OVERLAP_NONE = 0
local OVERLAP_NEW = 1

local redirector_ids = table.map{191, 192, 193, 194, 195, 196, 197, 198, 199, 221}

local function getSpeed(x,y)
    local v = vector(x,y):normalize() * NPC.config[npcID].speed
    return v.x, v.y
end

local overlapEvents = { -- changes the pouncer's x & y speed depending on the redirector it touched
    [191] = function(v)
        v.speedX, v.speedY = getSpeed(0,-1)
    end,
    [192] = function(v)
        v.speedX, v.speedY = getSpeed(0,1)
    end,
    [193] = function(v)
        v.speedX, v.speedY = getSpeed(-1, 0)
    end,
    [194] = function(v)
        v.speedX, v.speedY = getSpeed(1, 0)
    end,
    [195] = function(v)
        v.speedX, v.speedY = getSpeed(-1, -1)
    end,
    [196] = function(v)
        v.speedX, v.speedY = getSpeed(1, -1)
    end,
    [197] = function(v)
        v.speedX, v.speedY = getSpeed(1, 1)
    end,
    [198] = function(v)
        v.speedX, v.speedY = getSpeed(-1, 1)
    end,
    [199] = function(v)
        v.speedX, v.speedY = getSpeed(0,0)
		v.data.state = 0
    end,
    [221] = function(v)
        v.speedX, v.speedY = getSpeed(-v.data.last.x,-v.data.last.y)
    end
}

local function overlapCondition(v, terminus)
    local cx, cy, dx, dy = v.x + 0.5 * 32, v.y + 0.5 * 32, terminus.x + 0.5 * terminus.width, terminus.y + 0.5 * terminus.height

    local consider =  math.abs(cx - dx) < 8 and math.abs(cy - dy) < 8
	SFX.play(1)
    if not consider then return false end

    if v.speedX ~= 0 and v.speedY ~= 0 then
        return ((v.speedX > 0 and cx > dx) or (v.speedX < 0 and cx < dx)) or ((v.speedY > 0 and cy > dy) or (v.speedY < 0 and cy < dy))
    elseif v.speedX ~= 0 then
        return (v.speedX > 0 and cx > dx) or (v.speedX < 0 and cx < dx)
    elseif v.speedY ~= 0 then
        return (v.speedY > 0 and cy > dy) or (v.speedY < 0 and cy < dy)
    else
        return true
    end
end


--Register events
function pouncer.onInitAPI()
	registerEvent(pouncer, "onTick")
	npcManager.registerEvent(npcID, pouncer, "onTickEndNPC")
	registerEvent(pouncer, "onEvent")
end

function pouncer.onTick()
	for _,p in ipairs(Player.get()) do -- handles making the pouncer move upon the player standing on it
		local n = p.standingNPC
		if n and n.id == npcID and n.data.state ~= 1 and n.data._settings.behaviour == 0 then
			--v.speedX, v.speedY = getSpeed(v.data._settings.xdir - 1, v.data._settings.ydir - 1)
			n.speedX, n.speedY = getSpeed(1 * n.direction, 1 - 1)
			n.data.state = 1
		end
	end
end

function pouncer.onEvent(eventName)
	for _,n in NPC.iterate(npcID) do
		if eventName == n.data._settings.event then
			n.data.state = 1
		end
	end
end

function pouncer.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
	--If despawned
	if v.despawnTimer <= 0 or v.forcedState ~= 0 or v.heldIndex ~= 0 then
		--Reset our properties, if necessary
		data.state = 0
		data.isOverlapping = false
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		--v.collisionGroup = "Pouncer"
		
        v.data.overlapping = OVERLAP_NONE
        v.data.timer = 0
        v.data.overlappingID = nil
        v.data.last = vector(0,0)
		data.collidingCurrently = 0

        --v.speedX, v.speedY = getSpeed(v.data._settings.xdir - 1, v.data._settings.ydir - 1)
		
		data.isVertical = false -- does nothing atm.
		if settings.behaviour == 0 then data.behaviour = 0 if settings.touch then data.state = 0 else data.state = 1 end else data.behaviour = 1 end
		data.initialized = true
	end

	
	-- Put main AI below here	

	if data.behaviour == 0 then
		if data.state == 0 then -- stand-still state
			v.speedX = 0
			v.speedY = 0
			v.animationFrame = 0
			return
		end
		
		if data.state == 1 then -- moving state
			v.noblockcollision = true
			for k,t in BGO.iterateIntersecting(v.x + v.width * 0.5, v.y + v.height * 0.5, v.x + v.width * 0.5, v.y + v.height * 0.5) do -- handles changing the direction the pouncer is going to upon touching a redirector
				if t.isValid and redirector_ids[t.id] and data.overlappingID ~= t.id then
					--if data.overlappingTerminus == nil or overlapCondition(t, overlappingTerminus, v.speedX, v.speedY) then -- (needs solving as the second condition gets the "terminus" as nil for some reason.)
						--Text.print("IT'S WORKING", 100 ,125)
						data.collidingCurrently = data.collidingCurrently + 1
						if data.collidingCurrently >= math.ceil(16 / pouncerSettings.speed) then
							overlapEvents[t.id](v)
							data.overlappingID = t.id
							data.overlapping = OVERLAP_NEW
							data.overlappingTerminus = t
							data.collidingCurrently = 0
							break
						end
					--end
				end
			end
			
		end
	else
		data.timer = data.timer + 1
		if data.state == 0 then
			v.animationFrame = 0
			if data.timer >= 48 then
				data.timer = 0
				data.state = 1
				data.yPos = v.y
			end
		elseif data.state == 1 then
			v.animationFrame = 1
			if data.timer >= 16 then
				v.speedY = math.clamp(v.speedY + 0.5, 0, 8)
				if v.collidesBlockBottom then
					data.state = 2
					data.timer = 0
					Defines.earthquake = 3
					SFX.play(37)
					for _,n in NPC.iterate() do
						if not NPC.config[n.id].nogravity and n.collidesBlockBottom and n.id ~= v.id then
							n.speedY = -4
						end
						if Colliders.collide(v, n) and n:mem(0x12A, FIELD_WORD) > 0 and n:mem(0x138, FIELD_WORD) == 0 and v:mem(0x138, FIELD_WORD) == 0 and (not n.isHidden) and (not n.friendly) and n:mem(0x12C, FIELD_WORD) == 0 and n.idx ~= v.idx and v:mem(0x12C, FIELD_WORD) == 0 and NPC.HITTABLE_MAP[n.id] then
							n:harm(HRM_TYPE_NPC)
						end
					end
				end
			end
		else
			if data.timer <= 64 then
				v.animationFrame = 1
			else
				v.animationFrame = 0
				v.speedY = -3
				if v.collidesBlockUp or v.y <= data.yPos then
					data.timer = 0
					data.state = 0
					v.speedX = 0
					v.speedY = 0
				end
			end
		end
		
	end
	
end

--Gotta return the library table!
return pouncer