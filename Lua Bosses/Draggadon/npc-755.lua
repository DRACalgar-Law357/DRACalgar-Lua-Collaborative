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
local smokeEffectID = (npcID)

local bulletBillsSettings = table.join({
	id = npcID,
	defaultProjectileID = defaultProjectileID,
	smokeEffectID = smokeEffectID,

	gfxwidth = 128,
	gfxheight = 128,
	width = 128,
	height = 128,

	projectileSpeedX = 7,
	projectileSpeedY = 0,
},ai.blasterSettings)

npcManager.setNpcSettings(bulletBillsSettings)
npcManager.registerHarmTypes(npcID,ai.blasterHarmTypes,ai.blasterHarmEffects)


ai.registerBlaster(npcID)


return bulletBills