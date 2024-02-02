--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local phantoServantsAI = require("phantosservants")
local npcID = NPC_ID
--local textplus = require("textplus");    --for debugging
--local effectMap = {basic=1,aggro=1,furious=1}



--Create the library table
local phanto = {}

--Defines NPC config for our NPC. You can remove superfluous definitions.
local settings = {
	id = npcID,
	aggroLevel = 2,
	chaseDuration = 420
}

phantoServantsAI.register(settings)

--Gotta return the library table!
return phanto