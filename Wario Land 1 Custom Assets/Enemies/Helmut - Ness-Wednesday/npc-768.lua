local npcManager = require("npcManager")
local Helmut = require("Helmut")

local HelmutNPC = {}

local npcID = NPC_ID

local HelmutNPCSettings = {
	id = npcID,
	gfxheight = 60,
	gfxwidth = 32,
	width = 32,
	height = 24,
	gfxoffsetx = 0,
	gfxoffsety = 18,
	frames = 2,
	framestyle = 1,
	framespeed = 8,
	speed = 1,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
	
	seaSlider=false, --While in any forced state, should the Helmut move horizontally?
	sturdy = false, --Should Mario be able to kill the Helmut by touching its underside?
	TipTop = 19, --How tall is the spike hitbox?
}

npcManager.setNpcSettings(HelmutNPCSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
	}
);

Helmut.register(npcID)

return HelmutNPC