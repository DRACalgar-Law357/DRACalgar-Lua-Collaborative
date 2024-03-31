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

local defaultProjectileID = (npcID + 1)

local bulletBillsSettings = table.join({
	id = npcID,
	defaultProjectileID = defaultProjectileID,

	projectileSpeedX = 7,
	projectileSpeedY = 0,
	activeNPCLimit = 1,
},ai.blasterSettings)

npcManager.setNpcSettings(bulletBillsSettings)
npcManager.registerHarmTypes(npcID,ai.blasterHarmTypes,ai.blasterHarmEffects)


ai.registerBlaster(npcID)


return bulletBills