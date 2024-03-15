--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
local colliders = require("colliders")
local playerStun = require("playerstun")
--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 112,
	gfxwidth = 120,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 48,
	height = 72,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 6,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	staticdirection = true,
	luahandlespeed = true,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
	hp = 60,
	hitboxwidth=78,
	hitboxheight=90,
	hitboxxoffset = {
		[-1] = -16,
		[1] = 15,
	},
	hitboxyoffset = -14,
	idledetectboxx = 320,
	idledetectboxy = 272,
	debug = false,
	sfx_weaponswing = Misc.resolveFile("Swing.wav"),
	sfx_weaponthud = 37,
	sfx_jumpthud = 37
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below

local spawnOffsetHammer = {}
spawnOffsetHammer[-1] = (20)
spawnOffsetHammer[1] = (78)

local spawnOffsetSlam = {}
spawnOffsetSlam[-1] = (-30)
spawnOffsetSlam[1] = (58)




--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		v.harmed = false
		data.health = sampleNPCSettings.hp
		data.harmframe = 0
		data.harmtimer = 75
		data.turnTimer = 0
		if v.friendly == false then
			data.state = 0
		else
			data.state = 4
		end
		data.timer = 0
		data.attackTimer = 0
		data.rndTimer = RNG.randomInt(120,180)
		data.cooldown = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then

	end
	if (v.collidesBlockLeft or v.collidesBlockRight) then
		v.direction = -v.direction
	end
	if data.state ~= 1 then
		data.timer = data.timer + 1
		if data.cooldown > 0 then
			data.cooldown = data.cooldown - 1
		end
	else
		data.attackTimer = data.attackTimer + 1
	end
    if data.state == 0 then
		data.turnTimer = data.turnTimer + 1
		if v.dontMove then
			v.animationFrame = 1
		else
			v.animationFrame = math.floor(lunatime.tick() / 9) % 4
			v.speedX = 2.5 * v.direction
		end
		if data.timer >= data.rndTimer and v.dontMove == false then
			data.rndTimer = RNG.randomInt(120,180)
			data.timer = 0
			data.state = 2
			npcutils.faceNearestPlayer(v)
		end
		if data.turnTimer % 65 == 0 then
			npcutils.faceNearestPlayer(v)
		end
		if player.x + player.width/2 >= v.x - 40 and player.x + player.width/2 <= v.x + v.width + 40 and player.y + player.height/2 <= v.y + v.height * 1.05 and player.y + player.height/2 >= v.y - 24 and data.cooldown <= 0 then
			data.state = 1
			data.cooldown = 25
			v.speedX = 0
			npcutils.faceNearestPlayer(v)
		end
	elseif data.state == 1 then
		if data.attackTimer >= 30 then
			v.animationFrame = 5
		else
			v.animationFrame = 4
		end
		v.speedX = 0
		if data.attackTimer == 30 and not data.hammer then
			data.hammer = NPC.spawn(sampleNPCSettings.hammerID, v.x - 20 + spawnOffsetHammer[v.direction], v.y + sampleNPCSettings.hammerOffsetY, player.section, false, false)
			data.hammer.layerName = "Spawned NPCs"
			data.hammer.data.parent = v
			data.hammer.data.owner = v
			SFX.play(37)
			Defines.earthquake = 7
		end
		if data.attackTimer >= 65 then
			if data.hammer then
				data.hammer:kill(9)
				data.hammer = nil
			end
			data.attackTimer = 0
			data.state = 0
			npcutils.faceNearestPlayer(v)
		end
	elseif data.state == 2 then
		v.animationFrame = math.floor(lunatime.tick() / 5) % 4
		if data.timer < 30 then
			npcutils.faceNearestPlayer(v)
			v.speedX = 0
		else
			v.speedX = 5 * v.direction
		end
		if data.timer >= 100 then
			data.timer = 0
			data.state = 0
			v.speedX = 0
			npcutils.faceNearestPlayer(v)
		end
	elseif data.state == 4 then
		v.friendly = true
		if v.dontMove then
			v.animationFrame = 1
		else
			v.animationFrame = math.floor(lunatime.tick() / 9) % 4
			v.speedX = 2.5 * v.direction
		end
	else
		data.timer = data.timer + 1
		--A state to kill the NPC, with some fancy effects. Credits to King DRACalgar Law for this function
		v.animationFrame = math.floor(lunatime.tick() / 5) % 4
		v.speedX = 0
		v.speedY = 0
		v.harmed = true
		v.friendly = true
		if data.timer % 24 == 0 then
			Animation.spawn(899, math.random(v.x - v.width / 2, v.x + v.width / 2), math.random(v.y - v.height / 2, v.y + v.height / 2))
			SFX.play("Explosion 2.wav")
		end
		if data.timer == 270 then
			v:kill(9)
			Animation.spawn(901, v.x + (v.width / 4), v.y)
		end
	end
	if data.state ~= 4 then
		if v.harmed then
			v.friendly = true
			data.harmtimer = data.harmtimer - 1
			data.harmframe = data.harmframe + 1
			if data.harmframe == 6 then
				data.harmframe = 0
			end
			if data.harmframe >= 3 then
				v.animationFrame = -50
			end
			if data.harmtimer == 0 then
				data.harmtimer = 75
				data.harmframe = 0
				v.harmed = false
			end
		else
			v.friendly = false
		end
	else
		v.friendly = true
	end
	if data.hammer then
		if data.hammer.isValid then
			data.hammer.x = v.x - (v.width / 8) + spawnOffsetSlam[v.direction]
			data.hammer.y = v.y - (v.height / 3) + sampleNPCSettings.hammerY
		else
			data.hammer = nil
		end
	end
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
	end

end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end
	if reason ~= HARM_TYPE_LAVA then
		if not v.harmed then
			if reason == HARM_TYPE_JUMP or killReason == HARM_TYPE_SPINJUMP or killReason == HARM_TYPE_FROMBELOW then
				SFX.play(39)
				v.harmed = true
				data.health = data.health - 5
			elseif reason == HARM_TYPE_SWORD then
				if v:mem(0x156, FIELD_WORD) <= 0 then
					data.health = data.health - 5
					SFX.play(89)
					v:mem(0x156, FIELD_WORD,20)
				end
				if Colliders.downSlash(player,v) then
					player.speedY = -6
				end
			elseif reason == HARM_TYPE_NPC then
				if culprit then
					if type(culprit) == "NPC" then
						if culprit.id == 13  then
							SFX.play(9)
							data.health = data.health - 1
						else
							SFX.play(39)
							data.health = data.health - 5
							v.harmed = true
						end
					else
						SFX.play(39)
						data.health = data.health - 5
						v.harmed = true
					end
				else
					SFX.play(39)
					data.health = data.health - 5
					v.harmed = true
				end
			elseif reason == HARM_TYPE_LAVA and v ~= nil then
				v:kill(HARM_TYPE_OFFSCREEN)
			elseif v:mem(0x12, FIELD_WORD) == 2 then
				v:kill(HARM_TYPE_OFFSCREEN)
			end
			if culprit then
				if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
					culprit:kill(HARM_TYPE_NPC)
				elseif culprit.__type == "Player" then
					--Bit of code taken from the basegame chucks
					if (culprit.x + 0.5 * culprit.width) < (v.x + v.width*0.5) then
						culprit.speedX = -4
					else
						culprit.speedX = 4
					end
				elseif type(culprit) == "NPC" and (NPC.HITTABLE_MAP[culprit.id] or culprit.id == 45) and culprit.id ~= 50 and v:mem(0x138, FIELD_WORD) == 0 then
					culprit:kill(HARM_TYPE_NPC)
				end
			end
			if data.health <= 0 then
				data.state = 3
				data.timer = 0
				if data.hammer then
					data.hammer:kill(9)
					data.hammer = nil
				end
			elseif data.health > 0 then
				eventObj.cancelled = true
				v:mem(0x156,FIELD_WORD,60)
			end
		end
	else
		v:kill(HARM_TYPE_LAVA)
	end
	
	eventObj.cancelled = true
end

--Gotta return the library table!
return sampleNPC