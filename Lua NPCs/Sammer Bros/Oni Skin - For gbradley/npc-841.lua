--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local colliders = require("colliders")
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
	nofireball = true,
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
	debug = false
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=npcID,
		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=npcID,
	}
);

--Custom local definitions below
local sfx_weaponswing = Misc.resolveFile("Swing.wav")
local sfx_weaponthud = Misc.resolveFile("s3k_stomp.ogg")

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
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
		v.ai2 = 0
		v.ai3 = 0
		data.initialized = false
		return
	end
	if sampleNPCSettings.debug == true then
		data.weaponBox:Debug(true)
	end
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		--ai1 = state, ai2 = timer, ai3 = weapon jump timer, ai4 = frame timer, ai5 = wander
		if settings.slam == nil then
			settings.slam = true
		end

		v.ai5 = v.direction
		data.rndTimer = RNG.randomInt(192,256)
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
		v.ai1 = 0
		v.ai2 = 0
		v.ai3 = 0
		return
	end
	v.ai2 = v.ai2 + 1
	if v.ai1 == 1 then
		v.ai3 = v.ai3 + 1
	end
	v.ai4 = v.ai4 + 1
	local frametimer = v.ai4
	local timer = v.ai2
	local state = v.ai1
	local weapontimer = v.ai3


	--Behaviour Code
	if v.ai1 == 0 then
		v.speedX = 1 * v.ai5
		if v.ai5 == 1 then
			if v.x >= v.spawnX + 64 then
				v.ai5 = -v.ai5
				v.direction = -v.direction
			end
		elseif v.ai5 == -1 then
			if v.x <= v.spawnX - 64 then
				v.ai5 = -v.ai5
				v.direction = -v.direction
			end
		end
		if math.abs((plr.x) - (v.x + v.width/2)) <= sampleNPCSettings.idledetectboxx and math.abs((plr.y) - (v.y + v.height/2)) <= sampleNPCSettings.idledetectboxy then
			v.ai1 = 1
			v.ai3 = 0
			npcutils.faceNearestPlayer(v)
		end
	elseif v.ai1 == 1 then
		if v.ai2 % 64 == 0 then
			npcutils.faceNearestPlayer(v)
		end
		if math.abs((plr.x) - (v.x + v.width/2)) <= 80 and math.abs((plr.y) - (v.y + v.height/2)) <= 96 then
			v.speedX = 0
			v.ai1 = 2
			v.ai2 = 0
			npcutils.faceNearestPlayer(v)
		else
			v.speedX = 2 * v.direction
		end
		if math.abs((plr.x) - (v.x + v.width/2)) > 320 and math.abs((plr.y) - (v.y + v.height/2)) > 208 then
			v.ai1 = 0
			v.ai2 = 0
			v.ai3 = 0
			v.ai5 = v.direction
			v.spawnX = v.x
		end
		if v.ai3 >= data.rndTimer and math.abs((plr.x) - (v.x + v.width/2)) <= 320 and settings.slam == true then
			v.ai1 = 3
			v.ai2 = 0
			data.rndTimer = RNG.randomInt(192,256)
		end
	elseif v.ai1 == 2 then
		v.speedX = 0
		if v.ai2 == 8 then SFX.play(sfx_weaponswing) end
		if Colliders.collide(plr,data.weaponBox) and (v.ai2 >= 22) then
			plr:harm()
		end
		if v.ai2 >= 65 then
			v.ai1 = 0
			v.ai2 = 0
			npcutils.faceNearestPlayer(v)
		end
		if data.feet == nil then
			data.feet = Colliders.Box(0,0,v.width,1)
			data.lastFrameCollision = true
		end
		data.lastFrameCollision = collidesWithSolid
		if v.ai2 == 22 and v.collidesBlockBottom then
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
	elseif v.ai1 == 3 then
		if v.ai2 == 16 then SFX.play(sfx_weaponswing) end
		if Colliders.collide(plr,data.weaponBox) and (v.ai2 >= 22) then
			plr:harm()
		end
		if v.ai2 == 8 then
			v.speedY = -9
			v.speedX = 0
		end
		if data.feet == nil then
			data.feet = Colliders.Box(0,0,v.width,1)
			data.lastFrameCollision = true
		end
		data.lastFrameCollision = collidesWithSolid
		if v.ai2 > 32 and v.collidesBlockBottom then
			v.ai2 = 0
			v.ai1 = 4
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
	elseif v.ai1 == 4 then
		if v.ai2 >= 48 then
			v.ai1 = 1
			v.ai2 = 0
			v.ai3 = 0
			v.ai4 = 0
			npcutils.faceNearestPlayer(v)
		end
	end
	--Animation Code
	if v.ai1 == 0 or v.ai1 == 1 or v.ai1 == 5 then
		if v.ai4 < 8 then
			v.animationFrame = 0
		elseif v.ai4 < 16 then
			v.animationFrame = 1
		elseif v.ai4 < 16 then
			v.animationFrame = 2
		elseif v.ai4 < 16 then
			v.animationFrame = 3
		else
			v.animationFrame = 0
			v.ai4 = 0
		end
	elseif v.ai1 == 2 then
		if v.ai2 < 8 then
			v.animationFrame = 0
		elseif v.ai2 < 16 then
			v.animationFrame = 4
		elseif v.ai2 < 22 then
			v.animationFrame = 5
		elseif v.ai2 < 28 then
			v.animationFrame = 6
		else
			v.animationFrame = 7
		end
	elseif v.ai1 == 3 then
		if v.ai2 < 8 then
			v.animationFrame = 0
		elseif v.ai2 < 16 then
			v.animationFrame = 4
		elseif v.ai2 < 22 then
			v.animationFrame = 5
		elseif v.ai2 < 28 then
			v.animationFrame = 6
		else
			v.animationFrame = 7
		end
	else
		v.animationFrame = 7
	end
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
	end
	
	--Prevent Sammer Bro from turning around when he hits NPCs because they make him get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end
end

--Gotta return the library table!
return sampleNPC