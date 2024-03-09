local wiggler = {}

local npcManager = require("npcManager")
local wiggler = require("billggler")

local npcID = NPC_ID

wiggler.registerHead(npcID, {id = npcID, speed=1, gfxheight=52, trailID = npcID + 1})

npcManager.registerHarmTypes(npcID, {HARM_TYPE_JUMP, HARM_TYPE_NPC, HARM_TYPE_SWORD, HARM_TYPE_LAVA, HARM_TYPE_SPINJUMP}, {
[HARM_TYPE_NPC]=npcID,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

return wiggler