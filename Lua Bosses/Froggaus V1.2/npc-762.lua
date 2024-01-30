local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local ball = {}

local npcID = NPC_ID

local ballSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	gfxoffsety = 2,
	width = 28,
	height = 28,
	frames = 6,
	framestyle = 0,
	framespeed = 6,
	jumphurt = 1,
	nogravity = 0,
	noblockcollision = 1,
	nofireball=0,
	noiceball=1,
	npcblock=0,
	noyoshi=0,
	spinjumpsafe = false,
}

local effectID = 762
--Applies NPC settings
npcManager.setNpcSettings(ballSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=effectID,
		[HARM_TYPE_PROJECTILE_USED]=effectID,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=effectID,
		[HARM_TYPE_TAIL]=effectID,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=effectID,
	}
);

function ball.onInitAPI()
	npcManager.registerEvent(npcID, ball, "onTickNPC")
	registerEvent(ball,"onNPCKill")
end

function ball.onNPCKill(eventObj,v,reason)
    if npcID ~= v.id or (reason == HARM_TYPE_LAVA or reason == HARM_TYPE_OFFSCREEN) then return end
	SFX.play(91)
end

function ball.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data

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
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then

	end
end

return ball