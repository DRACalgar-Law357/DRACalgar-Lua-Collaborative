local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local star = {}

local npcID = NPC_ID

local config = {
	id = npcID,
	gfxheight = 12,
    gfxwidth = 16,
	width = 16,
	height = 12,
    frames = 1,
    framestyle = 1,
	framespeed = 4, 
    nofireball=0,
	nogravity=1,
	noblockcollision = 1,
	linkshieldable = true,
	noshieldfireeffect = true,
	noiceball = true,
	nowaterphysics = true,
	jumphurt = true,
	npcblock = false,
	spinjumpsafe = false,
	noyoshi = true,
	ishot = true,
	lightradius = 100,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.orange,
}

npcManager.setNpcSettings(config)

npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=899,
		[HARM_TYPE_PROJECTILE_USED]=899,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=899,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=899,
	}
);

function star.onInitAPI()
	npcManager.registerEvent(npcID, star, "onTickEndNPC")
end

function star.onTickEndNPC(v)
		--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
    v.ai1 = v.ai1 + 1
    if v.ai1 < 10 then
        v.animationFrame = 0
    elseif v.ai1 < 20 then
        v.animationFrame = 0
    else
        v.animationFrame = 0
    end

    if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = config.frames
		});
	end
end

return star;
