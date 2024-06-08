local npcManager = require("npcManager")
local playerStun = require("playerstun")
local npcutils = require("npcs/npcutils")
local temperaturesync = require("temperaturesynced")
local frostee = {}

--***************************************************************************************************
--                                                                                                  *
--              Based on Monty Mole codes                                                           *
--                                                                                                  *
--***************************************************************************************************
local npcID = NPC_ID;

local frosteeData = {}

frosteeData.config = npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 32,
	gfxoffsety = 0,
	gfxheight = 32, 
	width = 24, 
	height = 24, 
	frames = 2,
	framespeed = 8,
	framestyle = 1,
	luahandlesspeed=true,
    freezeDelay = 36,
    freezeCooldown = 60,
    iscold = true,
    nohurt = true,
	--blocknpc = -1
	--lua only
	--death stuff
})

npcManager.registerHarmTypes(npcID, {HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_TAIL, HARM_TYPE_HELD, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=10,
[HARM_TYPE_FROMBELOW]=10,
[HARM_TYPE_NPC]=10,
[HARM_TYPE_TAIL]=10,
[HARM_TYPE_HELD]=10,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

function frostee.onInitAPI()
	npcManager.registerEvent(npcID, frostee, "onTickNPC")
	npcManager.registerEvent(npcID, frostee, "onStartNPC")
	npcManager.registerEvent(npcID, frostee, "onTickEndNPC")
	registerEvent(frostee, "onDraw")
end

local function getDistance(k,p)
	return k.x - p.x, k.x < p.x
end

local function setDir(dir, v)
	if (dir and v.data._basegame.direction == 1) or (v.data._basegame.direction == -1 and not dir) then return end
	if dir then
		v.data._basegame.direction = 1
	else
		v.data._basegame.direction = -1
	end
end

local function chasePlayers(v)
	if player2 then
		local p1, dir1 = getDistance(v, player)
		local p2, dir2 = getDistance(v, player2)
		if p1 > p2 then
			setDir(dir2, v)
		else
			setDir(dir1, v)
		end
	else
		local p1, dir1 = getDistance(v, player)
		setDir(dir1, v)
	end
end

--******************************************
--                                         *
--              Frostee                    *
--                                         *
--******************************************

function frostee.onStartNPC(v)
	local data = v.data._basegame
	data.timer = 0
	data.direction = v.direction
    data.cooldown = 0
end

function frostee.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height/2)
	v.collisionGroup = "FrankEnemy"
    Misc.groupsCollide["FrankBoss"]["FrankEnemy"] = false
    Misc.groupsCollide["FrankProjectile"]["FrankEnemy"] = false
	if data.state == nil then
		data.timer = 0
		data.direction = -1
        data.cooldown = 0
	end
	if not (v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x132, FIELD_WORD) > 0 or v:mem(0x134, FIELD_WORD) > 0) then --chase
		chasePlayers(v)
		v.speedX = math.clamp(v.speedX + 0.075 * data.direction, -4*NPC.config[v.id].speed, 4*NPC.config[v.id].speed)
		data.timer = data.timer - 1
        data.cooldown = data.cooldown - 1
		if data.timer <= 0 and v.collidesBlockBottom then
			data.timer = RNG.randomInt(40, 70)
		end
	else
		local pN = v:mem(0x12C, FIELD_WORD)
		if pN == 0 then
			pN = v:mem(0x132, FIELD_WORD)
		end
		if pN ~= 0 then
			data.direction = Player(pN).direction
		end
	end
    if Colliders.collide(plr, v) and not v.friendly and not Defines.cheat_donthurtme then
        for k, p in ipairs(Player.get()) do --Section copypasted from the Sledge Bros. code
            if not playerStun.isStunned(k) and v:mem(0x146, FIELD_WORD) == plr.section and v.data._basegame.cooldown <= 0 then
                playerStun.stunPlayer(k, NPC.config[v.id].freezeDelay)
                SFX.play(59)
                v.data._basegame.cooldown = NPC.config[v.id].freezeCooldown
            end
        end
    end
	if temperaturesync.state == 1 then
		v:kill(HARM_TYPE_NPC)
	end
end

function frostee.onTickEndNPC(v)	
	local data = v.data._basegame
	local frames = NPC.config[v.id].frames
	
	if data.timer == nil then
		data.timer = 0
		data.direction = v.direction
        data.cooldown = 0
	end
	
	v.animationFrame = math.floor(lunatime.tick() / NPC.config[npcID].framespeed) % frames
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = NPC.config[v.id].frames
		});
	end
end

return frostee