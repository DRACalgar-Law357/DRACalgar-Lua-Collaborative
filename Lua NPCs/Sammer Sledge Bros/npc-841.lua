--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
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
	width = 48,
	height = 60,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 24,
	--Frameloop-related
	frames = 5,
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
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	luahandlesspeed = true,
	staticdirection = true,

	--Define custom properties below
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
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		--ai1 = state, ai2 = timer, ai3 = weapon jump timer, ai4 = frame timer, ai5 = wander
		if settings.jumpblock == nil then
			settings.jumpblock = true
		end
		if settings.slam == nil then
			settings.slam = true
		end

		v.ai5 = v.direction
		data.rndTimer = RNG.randomInt(192,256)
		data.sledgeReady = false
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
	--frametimer = v.ai4
	--timer = v.ai2
	--state = v.ai1
	--weapontimer = v.ai3
	--wander = v.ai5
	--Sledge Bro Stomp (Code by Murphmario)
	if v.speedY > 1 then
		data.sledgeReady = true
	end
	
	if data.sledgeReady and v.collidesBlockBottom then
		for k, p in ipairs(Player.get()) do --Section copypasted from the Sledge Bros. code
			if p:isGroundTouching() and not playerStun.isStunned(k) and v:mem(0x146, FIELD_WORD) == player.section then
				playerStun.stunPlayer(k, 60)
			end
		end
		data.sledgeReady = false
		SFX.play(sampleNPCSettings.sfx_jumpthud)
		Defines.earthquake = 6
	end


	--Behaviour Code
	if v.ai1 == 0 then
		v.speedX = 1 * v.ai5
		if v.ai5 == 1 then
			if v.x >= v.spawnX + 96 then
				v.ai5 = -v.ai5
				v.direction = -v.direction
			end
		elseif v.ai5 == -1 then
			if v.x <= v.spawnX - 96 then
				v.ai5 = -v.ai5
				v.direction = -v.direction
			end
		end
		if math.abs((plr.x) - (v.x + v.width/2)) <= sampleNPCSettings.idledetectboxx and math.abs((plr.y) - (v.y + v.height/2)) <= sampleNPCSettings.idledetectboxy then
			v.ai1 = 1
			v.ai3 = 0
			npcutils.faceNearestPlayer(v)
		end
		--Code by Core / KateBulka
		local count = 0
			
		if v.direction == -1 then
			count = #Block.getIntersecting(v.x - 32, v.y, v.x, v.y + v.height + 1)
		else
			count = #Block.getIntersecting(v.x + v.width, v.y, (v.x + v.width) + 32, v.y + v.height + 1)
		end
		if count == 0 and settings.jumpblock == true then
			v.ai2 = 0
			v.ai1 = 5
			v.speedX = 0
		end	
	elseif v.ai1 == 1 then
		if v.ai2 % 64 == 0 then
			npcutils.faceNearestPlayer(v)
		end
		if ((v.direction == -1 and v.collidesBlockLeft) or (v.direction == 1 and v.collidesBlockRight)) and v.collidesBlockBottom then
			v.speedY = -7.5
		end
		if math.abs((plr.x) - (v.x + v.width/2)) <= 56 and math.abs((plr.y) - (v.y + v.height/2)) <= 128 then
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
			npcutils.faceNearestPlayer(v)
		end
		--Code by Core / KateBulka
		local count = 0
			
		if v.direction == -1 then
			count = #Block.getIntersecting(v.x - 32, v.y, v.x, v.y + v.height + 1)
		else
			count = #Block.getIntersecting(v.x + v.width, v.y, (v.x + v.width) + 32, v.y + v.height + 1)
		end
		if count == 0 and settings.jumpblock == true then
			v.ai2 = 0
			v.ai1 = 5
			v.speedX = 0
		end	
	elseif v.ai1 == 2 then
		v.speedX = 0
		if v.ai2 == 26 then SFX.play(sampleNPCSettings.sfx_weaponswing) end
		if Colliders.collide(plr,data.weaponBox) and (v.ai2 >= 32 and v.ai2 < 40) then
			plr:harm()
		end
		if sampleNPCSettings.debug == true and (v.ai2 >= 32 and v.ai2 < 40) then
			data.weaponBox:Debug(true)
		end
		if v.ai2 == 38 and v.collideBlockBottom then
			Defines.earthquake = 5
			SFX.play(sampleNPCSettings.sfx_weaponthud)
		end
		if v.ai2 >= 65 then
			v.ai1 = 0
			v.ai2 = 0
			npcutils.faceNearestPlayer(v)
		end
	elseif v.ai1 == 3 then
		if v.ai2 == 32 then SFX.play(sampleNPCSettings.sfx_weaponswing) end
		if Colliders.collide(plr,data.weaponBox) and (v.ai2 >= 32 and v.ai2 < 40) then
			plr:harm()
		end
		if v.ai2 < 16 then v.speedX = 0 end
		if v.ai2 == 16 then
			v.speedY = -9
			v.speedX = 1 * v.direction
		end
		if v.ai2 > 32 and v.collidesBlockBottom then
			v.ai2 = 0
			v.ai1 = 4
			v.speedX = 0
			Defines.earthquake = 5
			SFX.play(sampleNPCSettings.sfx_weaponthud)
		end
	elseif v.ai1 == 4 then
		if v.ai2 >= 48 then
			v.ai1 = 1
			v.ai2 = 0
			v.ai3 = 0
			v.ai4 = 0
			npcutils.faceNearestPlayer(v)
		end
	elseif v.ai1 == 5 then
		if v.ai2 == 32 then
			local closest = 3.5
			
			for i = 1, 4 do
				if v.direction == -1 then
					if #Block.getIntersecting(v.x - (32 * i), v.y, v.x, v.y + v.height + 1) ~= 0 then
						closest = i / 1.5
						break
					end
				else
					if #Block.getIntersecting(v.x + v.width, v.y, v.x + v.width + (32 * i), v.y + v.height + 1) ~= 0 then
						closest = i / 1.5
						break
					end		
				end
			end
			
			v.speedX = closest * v.direction
			v.speedY = -7.5
			v.y = v.y - 1
		elseif v.ai2 > 32 then
			if v.collidesBlockBottom then
				if math.abs((player.x + player.width/2) - (v.x + v.width/2)) <= 240 and math.abs((player.y + player.height/2) - (v.y + v.height/2)) <= 208 then
					v.ai1 = 1
					v.ai3 = 0
					npcutils.faceNearestPlayer(v)
				else
					v.ai1 = 0
					v.ai2 = 0
					v.spawnX = v.x
					v.ai5 = v.direction
				end
			end
		end
	end
	--Animation Code
	if v.ai1 == 0 or v.ai1 == 1 or v.ai1 == 5 then
		if v.ai4 < 8 then
			v.animationFrame = 0
		elseif v.ai4 < 16 then
			v.animationFrame = 1
		else
			v.animationFrame = 0
			v.ai4 = 0
		end
	elseif v.ai1 == 2 then
		if v.ai2 < 32 then
			v.animationFrame = 2
		elseif v.ai2 < 38 then
			v.animationFrame = 3
		else
			v.animationFrame = 4
		end
	elseif v.ai1 == 3 then
		if v.ai2 < 32 then
			v.animationFrame = 2
		elseif v.ai2 < 38 then
			v.animationFrame = 3
		else
			v.animationFrame = 4
		end
	else
		v.animationFrame = 4
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