--[[
    Giant Fireball sprite ripped by A.J. Nitro

    This NPC uses most of the code from MDA's Background Bullet Bill AI
]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local ai = require("draggadonBackgroundBulletAI")


local bulletBills = {}
local npcID = NPC_ID

local deathEffectID = (755)
local smokeEffectID = (755)

local bulletBillsSettings = table.join({
	id = npcID,
	gfxheight = 64,
	gfxwidth = 64,
	width = 64,
	height = 64,
	gfxoffsety = 0,
	smokeEffectID = smokeEffectID,
	
	hitboxDepth = 20,
	disappearDepth = -20,

	fadeColor = Color.orange,
	fadeDistance = 15,

	enterRotation = 360,

	destroyWhenNormal = false,
	jumphurt = true,
	destroyWhenRedirected = false,
	isStrong = true,
},ai.bulletSettings)

npcManager.setNpcSettings(bulletBillsSettings)
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP]            = deathEffectID,
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_SPINJUMP]        = 10,
	}
)


ai.registerBullet(npcID)


return bulletBills