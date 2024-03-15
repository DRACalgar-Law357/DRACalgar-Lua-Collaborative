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
	gfxheight = 128,
	gfxwidth = 128,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 38,
	height = 80,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 8,
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
	hitboxwidth=40,
	hitboxheight=32,
	hitboxxoffset = {
		[-1] = -32,
		[1] = 19 + 32,
	},
	hitboxyoffset = 32,
	idledetectboxx = 320,
	idledetectboxy = 272,
	shockwaveid=842,
	debug = false,
	hp = 8,
	effectExplosion1ID = 950,
	effectExplosion2ID = 952,
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

local sfx_weaponswing = Misc.resolveFile("Swing.wav")
local sfx_weaponthud = Misc.resolveFile("s3k_stomp.ogg")
local sfx_hit = Misc.resolveFile("s3k_damage.ogg")
local sfx_explode = Misc.resolveFile("s3k_stomp.ogg")
local sfx_charge = Misc.resolveFile("dbz_energy_charge.mp3")

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	data.weaponBox = Colliders.Box(v.x - (v.width * 1.2), v.y - (v.height * 1), sampleNPCSettings.hitboxwidth, sampleNPCSettings.hitboxheight)
	if v.direction == DIR_LEFT then
		data.weaponBox.x = v.x + v.width/2 - data.weaponBox.width/2 + sampleNPCSettings.hitboxxoffset[-1]
	elseif v.direction == DIR_RIGHT then
		data.weaponBox.x = v.x + v.width/2 - data.weaponBox.width/2 + sampleNPCSettings.hitboxxoffset[1]
	end
	data.weaponBox.y = v.y + v.height/2 - data.weaponBox.height/2 + sampleNPCSettings.hitboxyoffset
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end
	if sampleNPCSettings.debug == true then
		data.weaponBox:Debug(true)
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
		data.consecutive = 0
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
			v.animationFrame = math.floor(lunatime.tick() / 8) % 4
			v.speedX = 2.5 * v.direction
		end
		if data.timer >= data.rndTimer and v.dontMove == false then
			data.rndTimer = RNG.randomInt(120,180)
			data.timer = 0
			--2 Ram Attack, 3 Jump Up and then slam while causing a shockwave, 5 charge up and then slam three times two to four times of long-lasting shockwaves
			data.state = RNG.irandomEntry{2,5,3}
			if data.state == 5 then
				if data.health <= sampleNPCSettings.hp and data.health > sampleNPCSettings.hp*3/4 then
					data.consecutive = 2
				elseif data.health <= sampleNPCSettings.hp*3/4 and data.health*3/4 > sampleNPCSettings.hp*2/4 then
					data.consecutive = 3
				elseif data.health <= sampleNPCSettings.hp*2/4 and data.health > sampleNPCSettings.hp*1/4 then
					data.consecutive = 4
				else
					data.consecutive = 5
				end
			end
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
		if data.attackTimer < 8 then
			v.animationFrame = 0
		elseif data.attackTimer < 16 then
			v.animationFrame = 4
		elseif data.attackTimer < 22 then
			v.animationFrame = 5
		elseif data.attackTimer < 28 then
			v.animationFrame = 6
		else
			v.animationFrame = 7
		end
		v.speedX = 0
		if data.attackTimer == 8 then SFX.play(sfx_weaponswing) end
		if Colliders.collide(plr,data.weaponBox) and (data.attackTimer >= 22) then
			plr:harm()
		end
		if data.attackTimer >= 65 then
			data.state = 0
			data.attackTimer = 0
			npcutils.faceNearestPlayer(v)
		end
		if data.feet == nil then
			data.feet = Colliders.Box(0,0,v.width,1)
			data.lastFrameCollision = true
		end
		data.lastFrameCollision = collidesWithSolid
		if data.attackTimer == 22 and v.collidesBlockBottom then
			if data.feet == nil then
				data.feet = Colliders.Box(0,0,v.width,1)
				data.lastFrameCollision = true
			end
			data.feet.x = v.x
			data.feet.y = v.y + v.height
			local collidesWithSolid = false
			local footCollisions = Colliders.getColliding{
			
				a=	data.feet,
				b=	Block.SOLID ..
					Block.PLAYER ..
					Block.SEMISOLID .. 
					Block.SIZEABLE,
				btype = Colliders.BLOCK,
				filter= function(other)
					if (not collidesWithSolid and not other.isHidden and other:mem(0x5A, FIELD_WORD) == 0) then
						if Block.SOLID_MAP[other.id] or Block.PLAYER_MAP[other.id] then
							return true
						end
						if data.feet.y <= other.y + 8 then
							return true
						end
					end
					return false
				end
				
			}

			if #footCollisions > 0 then
				collidesWithSolid = true
				if not data.lastFrameCollision then
					local id = NPC.config[v.id].shockwaveid
					SFX.play(4)
					for i=1,2 do
						local f = NPC.spawn(id, v.x + v.width/2 - data.weaponBox.width/2 + sampleNPCSettings.hitboxxoffset[v.direction], footCollisions[1].y - 0.5 * NPC.config[id].height, v:mem(0x146, FIELD_WORD), false, true)
						Animation.spawn(1, v.x + v.width/2 - data.weaponBox.width/2 + sampleNPCSettings.hitboxxoffset[v.direction], footCollisions[1].y - 4)
						if i == 1 then
							f.speedX = -1
						else
							f.speedX = 1
						end 
					end
					Defines.earthquake = 5
					SFX.play(sfx_weaponthud)
					return
				end
			end
			data.lastFrameCollision = collidesWithSolid
		end
	elseif data.state == 2 then
		v.animationFrame = math.floor(lunatime.tick() / 4) % 4
		local ptl
		if data.timer % 10 == 0 then
			if v.direction == -1 then
				ptl = Effect.spawn(74, v.x + v.width + 8 - 16, v.y + v.height - 16)
			else
				ptl = Effect.spawn(74, v.x - 8 - 16, v.y + v.height - 16)
			end
			SFX.play(86)
		end
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
	elseif data.state == 3 then
		if data.timer < 8 then
			v.animationFrame = 0
		elseif data.timer < 16 then
			v.animationFrame = 4
		elseif data.timer < 22 then
			v.animationFrame = 5
		elseif data.timer < 28 then
			v.animationFrame = 6
		else
			v.animationFrame = 7
		end
		if data.timer == 16 then SFX.play(sfx_weaponswing) end
		if Colliders.collide(plr,data.weaponBox) and (data.timer >= 22) then
			plr:harm()
		end
		if data.timer == 8 then
			v.speedY = -9
			v.speedX = 0
		end
		if data.feet == nil then
			data.feet = Colliders.Box(0,0,v.width,1)
			data.lastFrameCollision = true
		end
		data.lastFrameCollision = collidesWithSolid
		if data.timer > 32 and v.collidesBlockBottom then
			data.timer = 0
			data.state = 6
			v.speedX = 0
			if data.feet == nil then
				data.feet = Colliders.Box(0,0,v.width,1)
				data.lastFrameCollision = true
			end
			data.feet.x = v.x
			data.feet.y = v.y + v.height
			local collidesWithSolid = false
			local footCollisions = Colliders.getColliding{
			
				a=	data.feet,
				b=	Block.SOLID ..
					Block.PLAYER ..
					Block.SEMISOLID .. 
					Block.SIZEABLE,
				btype = Colliders.BLOCK,
				filter= function(other)
					if (not collidesWithSolid and not other.isHidden and other:mem(0x5A, FIELD_WORD) == 0) then
						if Block.SOLID_MAP[other.id] or Block.PLAYER_MAP[other.id] then
							return true
						end
						if data.feet.y <= other.y + 8 then
							return true
						end
					end
					return false
				end
				
			}

			if #footCollisions > 0 then
				collidesWithSolid = true
				if not data.lastFrameCollision then
					local id = NPC.config[v.id].shockwaveid
					SFX.play(4)
					for i=1,2 do
						local f = NPC.spawn(id, v.x + v.width/2 - data.weaponBox.width/2 + sampleNPCSettings.hitboxxoffset[v.direction], footCollisions[1].y - 0.5 * NPC.config[id].height, v:mem(0x146, FIELD_WORD), false, true)
						Animation.spawn(1, v.x + v.width/2 - data.weaponBox.width/2 + sampleNPCSettings.hitboxxoffset[v.direction], footCollisions[1].y - 4)
						if i == 1 then
							f.speedX = -1
						else
							f.speedX = 1
						end 
					end
					Defines.earthquake = 5
					SFX.play(sfx_weaponthud)
					return
				end
			end
			data.lastFrameCollision = collidesWithSolid
		end
	elseif data.state == 6 then
		v.animationFrame = 7
		v.speedX = 0
		if data.timer >= 40 then data.timer = 0 data.state = 0 end
	elseif data.state == 4 then
		v.friendly = true
		if v.dontMove then
			v.animationFrame = 1
		else
			v.animationFrame = math.floor(lunatime.tick() / 9) % 4
			v.speedX = 2.5 * v.direction
		end
	elseif data.state == 5 then
		if data.timer < 6 then
			v.animationFrame = 3
		elseif data.timer < 70 then
			v.animationFrame = 4
		elseif data.timer < 74 then
			v.animationFrame = 0
		elseif data.timer < 78 then
			v.animationFrame = 4
		elseif data.timer < 82 then
			v.animationFrame = 5
		elseif data.timer < 86 then
			v.animationFrame = 6
		else
			v.animationFrame = 7
		end
		if data.timer < 70 and data.timer % 6 == 5 then
			for i=0,2 do
				local ptl = Animation.spawn(80, math.random(v.x - v.width / 2, v.x + v.width / 2), math.random(v.y - v.height / 2, v.y + v.height / 2))
				a.x=a.x-a.width/2
				a.y=a.y-a.height/2
			end
		end
		if data.timer == 74 then SFX.play(sfx_weaponswing) end
		if Colliders.collide(plr,data.weaponBox) and (data.timer >= 82) then
			plr:harm()
		end
		if data.timer >= 90 then
			data.consecutive = data.consecutive + 1
			if data.consecutive <= 0 then
				data.state = 0
				data.timer = 0
				npcutils.faceNearestPlayer(v)
			else
				data.timer = 70
			end
		end
		if data.feet == nil then
			data.feet = Colliders.Box(0,0,v.width,1)
			data.lastFrameCollision = true
		end
		data.lastFrameCollision = collidesWithSolid
		if data.timer == 86 and v.collidesBlockBottom then
			data.feet.x = v.x
			data.feet.y = v.y + v.height
			local collidesWithSolid = false
			local footCollisions = Colliders.getColliding{
				a=	data.feet,
				b=	Block.SOLID ..
					Block.PLAYER ..
					Block.SEMISOLID .. 
					Block.SIZEABLE,
				btype = Colliders.BLOCK,
				filter= function(other)
					if (not collidesWithSolid and not other.isHidden and other:mem(0x5A, FIELD_WORD) == 0) then
						if Block.SOLID_MAP[other.id] or Block.PLAYER_MAP[other.id] then
							return true
						end
						if data.feet.y <= other.y + 8 then
							return true
						end
					end
					return false
				end			
			}
	
				if #footCollisions > 0 then
					collidesWithSolid = true
					if not data.lastFrameCollision then
						local id = NPC.config[v.id].shockwaveid
						SFX.play(4)
						local f = NPC.spawn(id, v.x + v.width/2 - data.weaponBox.width/2 + sampleNPCSettings.hitboxxoffset[v.direction], footCollisions[1].y - 0.5 * NPC.config[id].height, v:mem(0x146, FIELD_WORD), false, true)
						Animation.spawn(1, v.x + v.width/2 - data.weaponBox.width/2 + sampleNPCSettings.hitboxxoffset[v.direction], footCollisions[1].y - 4)
						f.speedX = 4.5 * v.direction
						Defines.earthquake = 5
						SFX.play(sfx_weaponthud)
						return
					end
				end
				data.lastFrameCollision = collidesWithSolid
		end
		if data.timer == 1 then SFX.play(sfx_charge) end
	else
		data.timer = data.timer + 1
		--A state to kill the NPC, with some fancy effects. Credits to King DRACalgar Law for this function
		v.animationFrame = math.floor(lunatime.tick() / 5) % 4
		v.speedX = 0
		v.speedY = 0
		v.harmed = true
		v.friendly = true
		if data.timer % 24 == 0 then
			local a = Animation.spawn(sampleNPCSettings.effectExplosion1ID, math.random(v.x - v.width / 2, v.x + v.width / 2), math.random(v.y - v.height / 2, v.y + v.height / 2))
			a.x=a.x-a.width/2
			a.y=a.y-a.height/2
			SFX.play(sfx_explode)
		end
		if data.timer == 250 then
			v:kill(9)
			Animation.spawn(sampleNPCSettings.effectExplosion2ID, v.x + (v.width / 4), v.y)
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

function sampleNPC.onNPCHarm(e, v, o, c)
	local data = v.data
	if v.id ~= NPC_ID then return end
	if o == HARM_TYPE_LAVA then return end
	if v.harmed == true then
		if o == HARM_TYPE_JUMP or o == HARM_TYPE_SPINJUMP or o == HARM_TYPE_SWORD or o == HARM_TYPE_FROMBELOW or (type(c) == "NPC") then
			local data = v.data
			data.health = data.health - 1
			if data.health > 0 then
				e.cancelled = true
				data.timer = 0
				if o == HARM_TYPE_JUMP or o == HARM_TYPE_SPINJUMP then
					SFX.play(2)
				elseif o == HARM_TYPE_SWORD then
					SFX.play(Misc.resolveSoundFile("zelda-hit"))
				else
					SFX.play(9)
				end
				if Colliders.downSlash(player,v) then
					player.speedY = -6
				end
				SFX.play(sfx_hit)
				v.harmed = true
			else
				data.state = 3
				data.timer = 0
				e.cancelled = true
			end
			if o ~= HARM_TYPE_JUMP and o ~= HARM_TYPE_SPINJUMP then
				if c then
					Animation.spawn(75, c.x+c.width/2-16, c.y+c.width/2-16)
				end
			end
			if c then
				if type(c) == "NPC" and (c.id ~= 195 and c.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
					c:kill(HARM_TYPE_NPC)
				elseif c.__type == "Player" then
					--Bit of code taken from the basegame chucks
					if (c.x + 0.5 * c.width) < (v.x + v.width*0.5) then
						c.speedX = -4
					else
						c.speedX = 4
					end
				elseif type(c) == "NPC" and (NPC.HITTABLE_MAP[c.id] or c.id == 45) and c.id ~= 50 and v:mem(0x138, FIELD_WORD) == 0 then
					c:kill(HARM_TYPE_NPC)
				end
			end
		end
	else
		e.cancelled = true
	end
end

--Gotta return the library table!
return sampleNPC