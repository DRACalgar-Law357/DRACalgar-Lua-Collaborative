--[[

	Written by MrDoubleA
	Please give credit!

    Banzai bill blaster sprites by Sednaiur
	Background banzai bill sprites by Squishy Rex

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local ai = require("bulletBills_ai")


local bulletBills = {}
local npcID = NPC_ID

local deathEffectID = (npcID - 1)

local bulletBillsSettings = table.join({
	id = npcID,
	deathEffectID = deathEffectID,
},ai.bulletSettings)

npcManager.setNpcSettings(bulletBillsSettings)
npcManager.registerHarmTypes(npcID,ai.bulletHarmTypes,ai.bulletHarmEffects)


ai.registerBullet(npcID)


return bulletBills