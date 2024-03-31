--[[

	Written by MrDoubleA
	Please give credit!

    Banzai bill blaster sprites by Sednaiur
	Background banzai bill sprites by Squishy Rex

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local ai = require("bulletBills_backgroundAI")


local bulletBills = {}
local npcID = NPC_ID

local projectileID = (npcID + 1)

local bulletBillsSettings = table.join({
	id = npcID,
	projectileID = projectileID,
},ai.blasterSettings)

npcManager.setNpcSettings(bulletBillsSettings)
npcManager.registerHarmTypes(npcID,{},{})

ai.registerBlaster(npcID)

return bulletBills