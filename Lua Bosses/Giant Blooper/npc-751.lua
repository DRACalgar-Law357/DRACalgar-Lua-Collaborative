--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
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
	frames = 2,
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
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	staticdirection = true,

	--Define custom properties below
	hp = 12,
	underwater = true
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
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=npcID,
		--[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		--[HARM_TYPE_TAIL]=npcID,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=npcID,
	}
);

--Custom local definitions below

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onNPCHarm(e, v, o, c)
	if v.id ~= NPC_ID then return end
	local data = v.data
	if v:mem(0x156, FIELD_WORD) <= 0 then
		if o == HARM_TYPE_JUMP or o == HARM_TYPE_SPINJUMP or o == HARM_TYPE_SWORD or o == HARM_TYPE_FROMBELOW or (type(c) == "NPC" and c.id ~= 13) then
			data.hp = (data.hp or sampleNPCSettings.hp) - 4
	    elseif type(c) == "NPC" and c.id == 13 then
            data.hp = (data.hp or sampleNPCSettings.hp) - 1
        else
            data.hp = (data.hp or sampleNPCSettings.hp) - 4
		end
		if o ~= HARM_TYPE_JUMP and o ~= HARM_TYPE_SPINJUMP then
			if c then
				Animation.spawn(75, c.x+c.width/2-16, c.y+c.width/2-16)
			end
        end
        if data.hp > 0 then
			e.cancelled = true
			data.timer = 0
			if o == HARM_TYPE_JUMP or o == HARM_TYPE_SPINJUMP then
				SFX.play(2)
				v:mem(0x156, FIELD_WORD,15)
			elseif o == HARM_TYPE_SWORD then
				SFX.play(Misc.resolveSoundFile("zelda-hit"))
			    v:mem(0x156, FIELD_WORD,10)
			else
			    if type(c) == "NPC" and c.id == 13 then
				    SFX.play(9)
				    v:mem(0x156, FIELD_WORD,8)
				else
			        SFX.play(39)
					v:mem(0x156, FIELD_WORD,15)
			    end
			end
		end
	else
		e.cancelled = true
	end
end

local function underwater(v)
	return (v.underwater and v:mem(0x04, FIELD_WORD) ~= 2)
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		if settings.swimSpeed == nil then
			settings.swimSpeed = 2
		end
		if settings.riseSpeed == nil then
			settings.riseSpeed = 4
		end


		data.hp = sampleNPCSettings.hp
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
		return
	end
	if (not underwater(v) and sampleNPCSettings.underwater == true) or sampleNPCSettings.underwater == false then
		v.speedX = v.speedX * .7
		
		if v.speedY < -1 then
			v.speedY = -1
		end
		
		v.animationFrame = 0
		
		return
	else
		if math.random() > 0.99 then
			local a = Effect.spawn(113, v.x + v.width * .5, v.y + v.height * .5)
			a.x=a.x-a.width/2
			a.y=a.y-a.height/2
		end
	end

	if plr.x + plr.width * .5 > v.x + v.width * .5 then
		v.direction = 1
	elseif plr.x + plr.width * .5 < v.x + v.width * .5 then
		v.direction = -1
	end
	--Behaviour Code
	if plr.y < v.y and v.speedY >= 0 then
		v.speedX = settings.swimSpeed * v.direction
		v.speedY = -settings.riseSpeed
	end
	
	if v.speedY >= 1 then
		v.animationFrame = 1
		v.speedX = 0
		v:mem(0x18, FIELD_FLOAT, 0)
		v.speedY = 1
	else
		v.animationFrame = 0
	end
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
	end
	
	--Prevent Giant Blooper from turning around when it hits NPCs because they make it get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
end

--Gotta return the library table!
return sampleNPC