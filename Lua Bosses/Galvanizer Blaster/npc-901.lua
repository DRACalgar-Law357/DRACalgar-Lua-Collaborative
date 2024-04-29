--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local afterimages = require("afterimages")
afterimages.useShader = false
local freeze = require("freezeHighlight")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 112,
	gfxwidth = 128,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 11,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
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
	luahandlesspeed = true,
	grabside=false,
	grabtop=false,



	hp = 12
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
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

local STATE_IDLE = 0
local STATE_HORIZONTAL_SHOT = 1
local STATE_STOMP = 2
local STATE_RAM = 3
local STATE_JUMP = 4
local STATE_RELEASE = 5
local STATE_DONERAM = 6
local STATE_LASER = 7
local STATE_SPIN = 8
local STATE_AOE = 9
local STATE_LIGHTNING = 10
local STATE_SHOCK = 11
local STATE_BARRAGE = 12
local STATE_KILLED = 13
local STATE_INTRO = 14
local STATE_SHIELDING = 15
local STATE_LANDED = 16
local STATE_STUN = 17
local STATE_LOB = 18
local STATE_KAMIKAZE = 19

local spawnOffset = {}
spawnOffset[-1] = (-16)
spawnOffset[1] = (86)



local function getDistance(k,p)
	return k.x < p.x
end



local function isDespawned(v)
	return v.despawnTimer <= 0
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
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local dir1 = getDistance(v, plr)
	setDir(dir1, v)
end



--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCHarm")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then

		return
	end
	
	local data = v.data
	local config = NPC.config[v.id]
	--Despawn
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_INTRO
		data.timer = 0
		data.rndTime = RNG.randomInt(140,224)
		data.isSwooping = false
		v.harmed = false
		data.hp = sampleNPCSettings.hp
		v.harmframe = 0
		v.harmtimer = 60
		data.consecutive = 0
		data.shielding = false
		data.guaranteeShield = false
		data.vertY = 1
		data.AOETimer = 0
		data.stomped = false
		data.stateLimit = 0
		data.kamikaze = false
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		v.spawnX = v.x
		v.spawnY = v.y
	end
	
	data.timer = data.timer + 1
	
	--Thing that takes Galvanizer Blaster back to its original position
	data.dirVectr = vector.v2(
	(v.spawnX + 32) - (v.x + v.width * 0.5),
	(v.spawnY + 48) - (v.y + v.height * 0.5)
	):normalize() * 5

	

	if data.state == STATE_INTRO then
		v.friendly = true
		v.animationFrame = 2
		Defines.earthquake = 2
		if math.abs(v.spawnX - v.x) <= 8 and math.abs(v.spawnY - v.y) <= 64 then
			v.x = v.spawnX
			v.y = v.spawnY
			v.speedX = 0
			v.speedY = 0
			--When enough time has passed, go into an attack phase
			if data.timer >= 120 then
				data.timer = 0
				data.state = STATE_SHIELDING
			end
			npcutils.faceNearestPlayer(v)
		else
			v.speedX = data.dirVectr.x
			v.speedY = data.dirVectr.y
		end
	elseif data.state == STATE_IDLE then
		if data.timer >= 0 then
			if not data.guaranteeShield then
				v.friendly = false
			else
				v.friendly = true
			end
			--If still not back in place, move it there. Otherwise have it sit still and let the player attack it
			v.animationFrame = 2
			if math.abs(v.spawnX - v.x) <= 8 and math.abs(v.spawnY - v.y) <= 64 then
				v.x = v.spawnX
				v.y = v.spawnY
				v.speedX = 0
				v.speedY = 0
				--When enough time has passed, go into an attack phase
				if data.timer >= 64 then
					v.friendly = false
					if not data.guaranteeShield then
						if data.hp <= sampleNPCSettings.hp * 3/3 and data.hp > sampleNPCSettings.hp * 2/3 then
							if data.stateLimit == STATE_HORIZONTAL_SHOT then
								data.state = RNG.irandomEntry{STATE_STOMP,STATE_JUMP}
							elseif data.stateLimit == STATE_STOMP then
								data.state = RNG.irandomEntry{STATE_HORIZONTAL_SHOT,STATE_JUMP}
							elseif data.stateLimit == STATE_JUMP then
								data.state = RNG.irandomEntry{STATE_HORIZONTAL_SHOT,STATE_STOMP}
							else
								data.state = RNG.irandomEntry{STATE_HORIZONTAL_SHOT,STATE_STOMP,STATE_JUMP}
							end
						elseif data.hp <= sampleNPCSettings.hp * 2/3 and data.hp > sampleNPCSettings.hp * 1/3 then
							if data.stateLimit == STATE_AOE then
								data.state = RNG.irandomEntry{STATE_SPIN,STATE_LASER}
							elseif data.stateLimit == STATE_LASER then
								data.state = RNG.irandomEntry{STATE_SPIN,STATE_AOE}
							elseif data.stateLimit == STATE_SPIN then
								data.state = RNG.irandomEntry{STATE_LASER,STATE_AOE}
							else
								data.state = RNG.irandomEntry{STATE_SPIN,STATE_LASER,STATE_AOE}
							end
						elseif data.hp <= sampleNPCSettings.hp * 1/3 and data.hp > sampleNPCSettings.hp * 0/3 then
							if data.stateLimit == STATE_LIGHTNING then
								data.state = RNG.irandomEntry{STATE_SHOCK,STATE_BARRAGE}
							elseif data.stateLimit == STATE_SHOCK then
								data.state = RNG.irandomEntry{STATE_LIGHTNING,STATE_BARRAGE}
							elseif data.stateLimit == STATE_BARRAGE then
								data.state = RNG.irandomEntry{STATE_LIGHTNING,STATE_SHOCK}
							else
								data.state = RNG.irandomEntry{STATE_SHOCK,STATE_LIGHTNING,STATE_BARRAGE}
							end
						end
						data.stateLimit = data.state
					else
						data.state = STATE_SHIELDING
						data.guaranteeShield = false
					end
					data.timer = 0
				end
				npcutils.faceNearestPlayer(v)
			else
				v.speedX = data.dirVectr.x
				v.speedY = data.dirVectr.y
			end
		else
			v.animationFrame = 0
			v.speedX = 0
			v.speedY = 0
			v.friendly = true
			if data.timer % 20 == 0 then
				Animation.spawn(950, math.random(v.x - v.width / 2, v.x + v.width / 2), math.random(v.y - v.height / 2, v.y + v.height / 2))
				SFX.play("s3k_explode.ogg")
			end
		end
	elseif data.state == STATE_HORIZONTAL_SHOT then
		v.animationFrame = 1
		--When enough time has passed, go into an attack phase
		if data.timer >= 100 then
			data.timer = 0
		elseif data.timer == 1 then
			if data.consecutive < 3 then
				data.consecutive = data.consecutive + 1
				for i = 1,3 do
					local n = NPC.spawn(802, v.x - 20 + spawnOffset[-1], v.y + v.height/3)
					n.direction = v.direction
					n.speedX = RNG.random(-11,-1)
					n.speedY = -RNG.random(4,8)
				end
				for i = 1,3 do
					local n = NPC.spawn(802, v.x - 20 + spawnOffset[1], v.y + v.height/3)
					n.direction = v.direction
					n.speedX = RNG.random(11,1)
					n.speedY = -RNG.random(4,8)
				end
				Animation.spawn(10, v.x - 20 + spawnOffset[1], v.x + v.height/3)
				Animation.spawn(10, v.x - 20 + spawnOffset[-1], v.y + v.height/3)
				SFX.play("Ka-Zap.wav")
			else
			end
		end
		if data.consecutive >= 3 then
			--Once there, go back into its idle phase
			v.speedX = data.dirVectr.x
			v.speedY = data.dirVectr.y
			if math.abs(v.spawnX - v.x) <= 8 and math.abs(v.spawnY - v.y) <= 64 then
				data.state = STATE_IDLE
				data.timer = 0
				data.consecutive = 0
			end
		else
			v.speedX = math.sin(-data.timer/16)*6 / 4
			v.speedY = math.sin(-data.timer/12)*6 / 2
		end
	elseif data.state == STATE_STOMP then
		if data.timer <= 48 then
			--initially go to the top of the screen
			v.x = v.x - 3.5 * v.direction
			v.y = v.y - 4
		elseif data.timer > 48 and data.timer <= data.rndTime then
			--Hover up and down and track the player
			chasePlayers(v)
			v.speedX = math.clamp(v.speedX + 0.2 * v.data._basegame.direction, -6.5, 6.5)
			v.speedY = math.sin(-data.timer/12)*6 / 3.5
		elseif data.timer > data.rndTime and data.timer <= data.rndTime + 10 then
			--Slight delay before attacking, to alert the player
			v.speedX = 0
			v.speedY = 0
			data.currentYPos = v.y
		else
			if data.timer >= data.rndTime + 10 then
				--Swoop to the player
				v.speedY = 9.5
				local locatePlayer = vector.v2(Player.getNearest(v.x + v.width/2, v.y + v.height).x + 0.5 * Player.getNearest(v.x + v.width/2, v.y + v.height).width - (v.x + 0.5 * v.width))
				v.speedX = locatePlayer.x / 75
				if v.collidesBlockBottom then
					data.state = STATE_RAM
					data.timer = 0
					Defines.earthquake = 6
					SFX.play("s3k_shootbig.ogg")
				end
			end
		end
		--Animation stuff
		if data.timer <= data.rndTime + 9 or (data.timer > data.rndTime + 10) then
			v.animationFrame = 0
		else
			v.animationFrame = 2
		end
	elseif data.state == STATE_LIGHTNING then
		local ptl = Animation.spawn(949, math.random(v.x - 20, v.x - 20 + v.width), math.random(v.y - 20, v.y - 20 + v.height))
		if data.timer <= 48 then
			--initially go to the top of the screen
			v.x = v.x - 3.5 * v.direction
			v.y = v.y - 4
		elseif data.timer > 48 and data.timer <= 360 then
			--Hover up and down and track the player
			chasePlayers(v)
			v.speedX = math.clamp(v.speedX + 0.2 * v.data._basegame.direction, -6.5, 6.5)
			v.speedY = math.sin(-data.timer/12)*6 / 3.5
			if data.timer % 96 == 0 then
				SFX.play("Zap-Zap.wav")
				local n = NPC.spawn(361, v.x + v.width/3, v.y + v.height/2)
				n.speedX = RNG.random(-1,1)
			end
		elseif data.timer > 360 and data.timer <= 360 + 10 then
			--Slight delay before attacking, to alert the player
			v.speedX = 0
			v.speedY = 0
			data.currentYPos = v.y
		else
			if data.timer >= 360 + 10 then
				--Swoop to the player
				v.speedY = 9.5
				v.speedX = 0
				if v.collidesBlockBottom then
					data.state = STATE_LANDED
					data.timer = 0
					Defines.earthquake = 6
					SFX.play("Machine Hit.wav")
					local n = NPC.spawn(852, v.x + v.width/3, v.y + v.height/2.5)
				end
			end
		end
		--Animation stuff
		if data.timer <= data.rndTime + 9 or (data.timer > data.rndTime + 10) then
			v.animationFrame = 0
		else
			v.animationFrame = 2
		end
	elseif data.state == STATE_LANDED then
		if data.timer >= 90 then
			data.timer = 0
			data.state = STATE_IDLE
		else
			v.speedY = -2.5
			v.animationFrame = 1
		end
	elseif data.state == STATE_SHOCK then
		v.animationFrame = math.floor(lunatime.tick() / 4) % 5
		if math.abs(v.spawnX - v.x) <= 8 and math.abs(v.spawnY - v.y) <= 210 then
			v.x = v.spawnX
			v.y = v.spawnY
			v.speedX = 0
			v.speedY = 0
			--When enough time has passed, go into an attack phase
			if data.timer == 60 then
				SFX.play("MM1-ElecZap.ogg")
				local n = NPC.spawn(754, v.x + v.width/3, v.y + v.height/3)
			elseif data.timer >= 120 then
				data.timer = 0
				data.state = STATE_IDLE
			end
			npcutils.faceNearestPlayer(v)
		else
			v.speedX = data.dirVectr.x
			v.speedY = data.dirVectr.y
		end
		if data.timer == 1 then
			SFX.play("Thunder.ogg")
		end
		if data.timer % 6 == 0 then
			local ptl = Animation.spawn(949, v.x + v.width/3, v.y + v.height/2)
			ptl.speedX = RNG.random(-6,6)
			ptl.speedY = RNG.random(-6,6)
		end
	elseif data.state == STATE_RAM then
		if v.direction == -1 then
			v.animationFrame = 5
		else
			v.animationFrame = 6
		end
		if data.timer <= 30 then
			v.dontMove = true
			v.speedY = 0
		else
			v.dontMove = false
			if data.timer % 32 == 0 then
				SFX.play("LightningJump.wav")
				local n = NPC.spawn(801, v.x + v.width / 3, v.y)
				n.speedY = -7
				Animation.spawn(10, v.x + v.width / 3, v.y)
			end
			v.speedX = math.clamp(v.speedX + (.1 * v.direction), -7, 7)
			if v.collidesBlockLeft or v.collidesBlockRight then
				data.timer = 0
				Defines.earthquake = 3
				SFX.play("s3K_stomp.ogg")
				data.state = STATE_DONERAM
			end
		end
	elseif data.state == STATE_JUMP then
		v.speedY = v.speedY + 0.3
		if v.speedY > 9 then
			v.speedY = v.speedY - 0.3
		end
		if data.timer >= 0 and data.timer < 5 then
			v.animationFrame = 4
		elseif data.timer >= 5 and data.timer < 10 then
			v.animationFrame = 3
		elseif data.timer >= 10 and data.timer < 15 then
			v.animationFrame = 2
		elseif data.timer >= 15 and data.timer < 20 then
			v.animationFrame = 1
		else
			v.animationFrame = 0
		end
		if v.collidesBlockBottom then
			SFX.play("Mech Stomp.wav")
			if data.consecutive < 4 then
				data.timer = 0
				data.consecutive = data.consecutive + 1
				npcutils.faceNearestPlayer(v)
				v.speedY = -12.5
				v.speedX = 4.5 * v.direction
				local n1 = NPC.spawn(803, v.x + v.width / 3, v.y)
				local n2 = NPC.spawn(803, v.x + v.width / 3, v.y)
				n1.speedX = 2
				n2.speedX = -2
				n1.speedY = -7.5
				n2.speedY = -7.5
			else
				data.timer = 0
				data.consecutive = 0
				v.speedY = 0
				if data.barrier then
					data.state = STATE_RELEASE
				else
					data.state = STATE_IDLE
				end
			end
		end
	elseif data.state == STATE_RELEASE then
		v.animationFrame = 1
		local ptl = Animation.spawn(949, math.random(v.x - 20, v.x - 20 + v.width), math.random(v.y - 20, v.y - 20 + v.height))
		if math.abs(v.spawnX - v.x) <= 8 and math.abs(v.spawnY - v.y) <= 64 then
			v.x = v.spawnX
			v.y = v.spawnY
			v.speedX = 0
			v.speedY = 0
			--When enough time has passed, go into an attack phase
			if data.timer >= 64 then
				data.state = STATE_IDLE
				data.timer = 0
				if data.barrier then
					if data.barrier.isValid then
						local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
							
						local startX = p.x + p.width / 2
						local startY = p.y + p.height / 2
						local X = v.x + v.width / 2
						local Y = v.y + v.height / 2
						
						local angle = math.atan2((Y - startY), (X - startX))
						data.barrier.speedX = -7 * math.cos(angle)
						data.barrier.speedY = -7 * math.sin(angle)
						data.barrier = nil
						SFX.play("Electrical 2.wav")
					end
				end
				for i = 1,6 do
					local n = NPC.spawn(801, v.x + v.width/3, v.y)
					n.direction = v.direction
					n.speedX = RNG.random(4,-4)
					n.speedY = RNG.random(-1,6)
				end
			end
			npcutils.faceNearestPlayer(v)
		else
			v.speedX = data.dirVectr.x
			v.speedY = data.dirVectr.y
		end
		if data.timer == 1 then
			SFX.play("Electrical 3.wav")
		end
	elseif data.state == STATE_BARRAGE then
		if data.timer == 50 or 100 or 150 or 200 or 250 then
			if data.timer == 50 then
				local n = NPC.spawn(804, v.x - 20 + spawnOffset[-1], v.y + v.height/3)
				n.direction = v.direction
				n.speedY = -3
			elseif data.timer == 100 then
				local n = NPC.spawn(804, v.x - 20 + spawnOffset[-1], v.y + v.height/3)
				n.direction = v.direction
				n.speedX = -3
			elseif data.timer == 150 then
				local n = NPC.spawn(804, v.x - 20 + spawnOffset[-1], v.y + v.height/3)
				n.direction = v.direction
				n.speedY = 3
			end
			if data.timer == 50 then
				local n = NPC.spawn(804, v.x - 20 + spawnOffset[1], v.y + v.height/3)
				n.direction = v.direction
				n.speedY = -3
			elseif data.timer == 100 then
				local n = NPC.spawn(804, v.x - 20 + spawnOffset[1], v.y + v.height/3)
				n.direction = v.direction
				n.speedX = 3
			elseif data.timer == 150 then
				local n = NPC.spawn(804, v.x - 20 + spawnOffset[1], v.y + v.height/3)
				n.direction = v.direction
				n.speedY = 3
			end
		end
		if data.timer % 50 == 0 and data.timer < 190 then
			Animation.spawn(10, v.x - 20 + spawnOffset[1], v.x + v.height/3)
			Animation.spawn(10, v.x - 20 + spawnOffset[-1], v.y + v.height/3)
			SFX.play("s3k_shoot.ogg")
		end
		if data.timer >= 0 and data.timer < 50 then
			v.animationFrame = 0
		elseif data.timer >= 50 and data.timer < 100 then
			v.animationFrame = 2
		elseif data.timer >= 100 and data.timer < 150 then
			v.animationFrame = 4
		else
			v.animationFrame = math.floor(lunatime.tick() / 2) % 3
		end
		if data.timer == 360 then
			SFX.play("Small Explosion.wav")
			v.nogravity = false
			local n = NPC.spawn(805, v.x + v.width/3, v.y - v.height/3)
			n.speedY = -11
			n.speedX = RNG.random(-4,4)
		end
		if data.timer >= 260 and data.timer < 370 then
			local ptl = Animation.spawn(950, v.x + v.width/3, v.y - v.height/2 - 20)
			ptl.speedX = RNG.random(-6,6)
			ptl.speedY = RNG.random(-6,-6)
		end
		if data.timer >= 370 then
			if not v.collidesBlockBottom then
				v.speedY = v.speedY + 0.1
			else
				v.speedY = 0
			end
		end
		if data.timer >= 550 then
			data.timer = 0
			if data.barrier then
				data.state = STATE_RELEASE
			else
				data.state = STATE_IDLE
			end
		end
	elseif data.state == STATE_DONERAM then
		v.speedX = 0
		v.animationFrame = math.floor(lunatime.tick() / 8) % 2
		if data.timer % 32 == 0 and data.timer <= 130 then
			SFX.play("ElecPulse.wav")
			local n = NPC.spawn(804, v.x + v.width / 3, v.y)
			n.speedY = -7
			Animation.spawn(10, v.x + v.width / 3, v.y)
		end
		if data.timer >= 240 then
			data.timer = 0
			data.state = STATE_IDLE
		end
	elseif data.state == STATE_LASER then
		v.animationFrame = 2
		if data.timer == 1 then
			triggerEvent("platformsappear")
			SFX.play("thwung.wav")
		end
		if data.timer <= 48 then
			--initially go to the top of the screen
			v.x = v.x - 3.5 * v.direction
			v.y = v.y - 4
		elseif data.timer > 48 and data.timer <= 320 then
			--Hover up and down and track the player
			chasePlayers(v)
			v.speedX = math.clamp(v.speedX + 0.2 * v.data._basegame.direction, -6.5, 6.5)
			v.speedY = math.sin(-data.timer/12)*6 / 3.5
			if data.timer > 90 then
				if data.timer >= 290 then
					

				elseif data.timer == 135 then

	

					SFX.play("Zapping Through.wav")
				elseif data.timer > 135 then
					local shoot = 	NPC.spawn(764, v.x + v.width/3, v.y + v.height/2)
					shoot.direction = v.direction
				elseif data.timer == 95 then
					SFX.play("SpiderElecBall.wav")
				end
			end
		else
			--Once there, go back into its idle phase
			v.speedX = data.dirVectr.x
			v.speedY = data.dirVectr.y
			if math.abs(v.spawnX - v.x) <= 8 and math.abs(v.spawnY - v.y) <= 64 then
				data.state = STATE_IDLE
				data.timer = 0
				triggerEvent("platformsdisappear")
			end
		end
	elseif data.state == STATE_SPIN then
		local ptl = Animation.spawn(949, math.random(v.x - 20, v.x - 20 + v.width), math.random(v.y - 20, v.y - 20 + v.height))
		if data.timer == 30 then
			Routine.setFrameTimer(1, (function() 
				local laserR = NPC.spawn(999, v.x + v.width - 16, v.y)
				local laserL = NPC.spawn(999, v.x, v.y)
				laserR.direction = 1
				laserL.direction = -1
			end), 8, false)
			SFX.play("Gedol Laser.wav")
			data.vertY = -1
		elseif data.timer >= 80 then
			v.speedX = 3 * v.direction
			if data.timer % 10 == 0 then
				SFX.play("spin.ogg")
			end
			if data.timer == 80 then
				v.speedY = 3
			end
			if v.collidesBlockBottom then
				v.speedY = -6
			elseif v.collidesBlockUp then
				v.speedY = 6
			end
			if v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockRight or v.collidesBlockUp then
				SFX.play("s3K_stomp.ogg")
			end
			if data.timer >= 450 then
				if data.barrier then
					data.state = STATE_RELEASE
				else
					data.state = STATE_IDLE
				end
				data.timer = 0
			end
		end
		v.animationFrame = math.floor(lunatime.tick() / 8) % 3 + 7
	elseif data.state == STATE_AOE then
		if data.timer <= 30 then
			v.animationFrame = 1
		end
		if data.timer == 10 then
			Routine.setFrameTimer(1, (function() 
				local laserR = NPC.spawn(999, v.x + v.width - 16, v.y)
				local laserL = NPC.spawn(999, v.x, v.y)
				laserR.direction = 1
				laserL.direction = -1

			end), 8, false)
			SFX.play("Gedol Laser.wav")
		end
		if data.timer > 30 and data.timer < 480 then
			data.AOETimer = data.AOETimer + 1
			if data.AOETimer == 1 then
				--Bit of code here by Murphmario
				local bombxspeed = vector.v2(Player.getNearest(v.x + v.width/2, v.y + v.height).x + 0.5 * Player.getNearest(v.x + v.width/2, v.y + v.height).width - (v.x + 0.5 * v.width))
				v.speedX = bombxspeed.x / 45
			end
			if data.AOETimer < 45 then
				if v.direction == -1 then
					v.animationFrame = 5
				else
					v.animationFrame = 6
				end
			end
			if data.AOETimer >= 45 then
				v.speedX = 0
				if not data.stomped then
					v.speedY = 7
				elseif data.stomped and data.AOETimer < 110 then
					v.speedY = -4
				end
				if not data.stomped then
					v.animationFrame = 1
				else
					v.animationFrame = 3
				end
				if v.collidesBlockBottom and not data.stomped then
					SFX.play("s3k_shootbig.ogg")
					Defines.earthquake = 4
					data.stomped = true
					data.AOETimer = 45
				end
				if data.AOETimer >= 110 and data.stomped then
					data.AOETimer = 0
					v.speedY = 0
					data.stomped = false
				end
			end
		end
		if data.timer >= 480 then
			data.timer = 0
			data.AOETimer = 0
			data.stomped = false
			data.state = STATE_IDLE
		end
	elseif data.state == STATE_KILLED then
		--A state to kill the NPC, with some fancy effects.
		data.timer = data.timer + 1
		v.animationFrame = 10
		v.speedX = 0
		v.speedY = 0
		v.harmed = true
		v.friendly = true
		if data.timer % 6 == 0 then
			Animation.spawn(950, math.random(v.x - v.width / 2, v.x + v.width / 2), math.random(v.y - v.height / 2, v.y + v.height / 2))
			SFX.play("s3k_explode.ogg")
		end
		if data.timer == 360 then
			v:kill(HARM_TYPE_OFFSCREEN)
			Animation.spawn(950, v.x + (v.width / 4), v.y)
		end
	elseif data.state == STATE_SHIELDING then
		data.timer = data.timer + 1
		v.animationFrame = 1
		local ptl = Animation.spawn(949, math.random(v.x - 20, v.x - 20 + v.width), math.random(v.y - 20 , v.y - 20 + v.height))
		if math.abs(v.spawnX - v.x) <= 8 and math.abs(v.spawnY - v.y) <= 64 then
			v.x = v.spawnX
			v.y = v.spawnY
			v.speedX = 0
			v.speedY = 0
			--When enough time has passed, go into an attack phase
			if data.timer >= 64 then
				data.timer = 0
				data.state = STATE_IDLE
				if not data.barrier then
					data.barrier = NPC.spawn(949, v.x - (v.width / 3), v.y - (v.height / 4), player.section, false, false)
					data.barrier.layerName = "Spawned NPCs"
					data.barrier.data.parent = v
					data.barrier.data.owner = v
					SFX.play("LightningShield.wav")
				end
			end
			npcutils.faceNearestPlayer(v)
		else
			v.speedX = data.dirVectr.x
			v.speedY = data.dirVectr.y
		end
	elseif data.state == STATE_STUN then
		v.speedY = -2
		v.harmed = true
		v.nohurt = true
		v.friendly = true
		v.animationFrame = 3
		if data.timer >= 100 then
			data.timer = 0
			v.speedY = 0
			data.state = STATE_LOB
			v.friendly = false
		end
	elseif data.state == STATE_LOB then
		v.animationFrame = math.floor(lunatime.tick() / 4) % 3 + 7
		if data.timer % 10 == 0 then
			SFX.play("spin.ogg")
		end
		if math.abs(v.spawnX - v.x) <= 8 and math.abs(v.spawnY - v.y) <= 210 then
			v.x = v.spawnX
			v.y = v.spawnY
			v.speedX = 0
			v.speedY = 0
			--When enough time has passed, go into an attack phase
			if data.timer >= 330 then
				data.timer = 0
				data.state = STATE_KAMIKAZE
			end
			if data.timer % 3 == 0 then
				SFX.play("yaku elec.wav")
				for i = 1,1 do
					local n = NPC.spawn(803, v.x + v.width / 3, v.y - v.height / 2)
					n.direction = v.direction
					n.speedX = RNG.random(-7.5,7.5)
					n.speedY = -RNG.random(9,14.5)
				end
			end
			npcutils.faceNearestPlayer(v)
		else
			v.speedX = data.dirVectr.x
			v.speedY = data.dirVectr.y
		end
		if data.timer % 6 == 0 then
			local ptl = Animation.spawn(949, v.x + v.width/3, v.y)
			ptl.speedX = RNG.random(-10,10)
			ptl.speedY = RNG.random(-10,10)
		end
	elseif data.state == STATE_KAMIKAZE then
		local ptl = Animation.spawn(949, math.random(v.x - 20, v.x - 20 + v.width), math.random(v.y - 20, v.y - 20 + v.height))
		if data.timer <= 48 then
			--initially go to the top of the screen
			v.x = v.x - 3.5 * v.direction
			v.y = v.y - 0
		elseif data.timer > 48 and data.timer <= 360 then
			--Hover up and down and track the player
			chasePlayers(v)
			v.speedX = math.clamp(v.speedX + 1 * v.data._basegame.direction, -10, 10)
			v.speedY = math.sin(-data.timer/12)*9 / 2
		elseif data.timer > 360 and data.timer <= 360 + 1 then
			--Slight delay before attacking, to alert the player
			v.speedX = 0
			v.speedY = 0
			data.currentYPos = v.y
		else
			if data.timer >= 360 + 1 then
				--Swoop to the player
				v.speedY = v.speedY + 1
				v.speedX = 0
				if v.collidesBlockBottom then
					data.state = STATE_KILLED
					data.timer = 0
					Defines.earthquake = 9
					for i = 1,20 do
						local n = NPC.spawn(803, v.x + v.width / 3, v.y)
						n.direction = v.direction
						n.speedX = RNG.random(-5.5,5.5)
						n.speedY = -RNG.random(10,14.5)
					end
					for i = 1,40 do
						local ptl = Animation.spawn(950, math.random(v.x - v.width / 2, v.x + v.width / 2), math.random(v.y - v.height / 2, v.y + v.height / 2))
						ptl.speedX = RNG.random(-10,10)
						ptl.speedY = RNG.random(-10,10)
					end
					SFX.play("Small Explosion.wav")
				end
			end
		end
		--Animation stuff
		if data.timer <= 360 + 9 or (data.timer > 360 + 10) then
			v.animationFrame = 0
		else
			v.animationFrame = 2
		end
	end
	

		

	if v.harmed then
		v.harmtimer = v.harmtimer - 1
		v.harmframe = v.harmframe + 1
		v.nohurt = true
		v.friendly = true
		if v.harmframe == 6 then
			v.harmframe = 0
		end
		if v.harmframe >= 3 then
			v.animationFrame = -50
		end
		if v.harmtimer == 0 then
			v.harmtimer = 60
			v.harmframe = 0
			v.harmed = false
			v.nohurt = false
		end
	else
		if data.state ~= STATE_STUN and STATE_INTRO then
			v.friendly = false
		end
	end

	if data.barrier then
		if data.barrier.isValid then
			data.barrier.x = v.x - (v.width / 8)
			data.barrier.y = v.y - (v.height / 3)
		else
			data.barrier = nil
		end
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
	
	if not v.harmed or data.kamikaze == true then
		if not data.barrier then
			SFX.play("s3k_damage.ogg")
			v.harmed = true
			data.hp = data.hp - 1
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
				culprit.speedY = -6
			end
		end
		if data.hp <= 0 then
			data.state = STATE_STUN
			if data.barrier then
				data.barrier:kill()
				data.barrier = nil
			end
			freeze.set(30)
			data.kamikaze = true
			for _,n in ipairs(NPC.get()) do
				if n.id == 801 or n.id == 802 or n.id == 803 or n.id == 852 or n.id == 851 or n.id == 804 or n.id == 999 or n.id == 754 or n.id == 361 or n.id == 362 or n.id == 805 then
					if n.x + n.width > camera.x and n.x < camera.x + camera.width and n.y + n.height > camera.y and n.y < camera.y + camera.height then
						n:kill(HARM_TYPE_OFFSCREEN)
					end
				end
			end
			SFX.play("enker-absorb.wav")
			data.timer = 0
		elseif data.hp > 0 then
			eventObj.cancelled = true
			v:mem(0x156,FIELD_WORD,60)
		end
		if data.hp == sampleNPCSettings.hp * 2/3 or data.hp == sampleNPCSettings.hp * 1/3 then
			if not data.guaranteeShield then
				data.guaranteeShield = true
			end
			SFX.play(7)
			v.friendly = true
			local n = NPC.spawn(9, v.x + v.width / 3, v.y)
			n.dontMove = true
			n.speedY = -5
			freeze.set(15)
			data.timer = -90
			data.state = STATE_IDLE
			for _,n in ipairs(NPC.get()) do
				if n.id == 801 or n.id == 802 or n.id == 803 or n.id == 852 or n.id == 851 or n.id == 804 or n.id == 999 or n.id == 754 or n.id == 361 or n.id == 362 or n.id == 805 then
					if n.x + n.width > camera.x and n.x < camera.x + camera.width and n.y + n.height > camera.y and n.y < camera.y + camera.height then
						n:kill(HARM_TYPE_OFFSCREEN)
					end
				end
			end
		end
	end
	
	eventObj.cancelled = true
end

function sampleNPC.onDrawNPC(v)
	local data = v.data
	local config = NPC.config[v.id]


	if not isDespawned(v) then
		local gfxw = NPC.config[v.id].gfxwidth
		local gfxh = NPC.config[v.id].gfxheight
		if gfxw == 0 then gfxw = v.width end
		if gfxh == 0 then gfxh = v.height end
		local frames = Graphics.sprites.npc[v.id].img.height / gfxh
		local framestyle = NPC.config[v.id].framestyle
		local frame = v.animationFrame
		local framesPerSection = frames
		local p = priority or -46
		Graphics.drawBox{
			texture = Graphics.sprites.npc[v.id].img,
			x = v.x + (v.width / 2), y = v.y + v.height-(config.gfxheight / 2),
			sourceX = 0, sourceY = v.animationFrame * config.gfxheight,
			sourceWidth = config.gfxwidth, sourceHeight = config.gfxheight,
			priority = -45, rotation = data.rotation,
			centered = true, sceneCoords = true,
		}
		afterimages.addAfterImage{
			x = v.x + 0.5 * v.width - 0.5 * gfxw + NPC.config[v.id].gfxoffsetx,
			y = v.y + 1.5 * v.height - 1.5 * gfxh + NPC.config[v.id].gfxoffsety,
			texture = Graphics.sprites.npc[v.id].img,
			lifetime = 16,
			width = gfxw,
			height = gfxh,
			texOffsetX = 0,
			texOffsetY = frame / frames,
			animWhilePaused = false,
			color = Color(0.4,0.4,0.4),
			useShader = false
		}
	end

	npcutils.hideNPC(v)
end

--Gotta return the library table!
return sampleNPC