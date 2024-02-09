--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local utils = require("npcs/npcutils")
local imagic = require("imagic")
--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
local id = NPC_ID
--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 94,
	gfxwidth = 92,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 54,
	height = 54,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 30,
	--Frameloop-related
	frames = 11,
	framestyle = 1,
	framespeed = 5, --# frames between frame change
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
	hp = 20,
	score = 6,
	chaseidletime = 60,
	chasingtime = 480,
	rolldelay = 45,
	rolltime = 360,
	hurttime = 180,
	rotationspeed = 0.045,
	effect = id,
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
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
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

--Custom local definitions below
local bosshit = Misc.resolveFile("starfybosshit.wav")
local fall = Misc.resolveFile("starfyfall.wav")
--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]

	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		v.ai1 = 0 --state timer
		v.ai2 = 0 --state 0 chase, state 1 ready to roll, state 2 roll, state 3 hurt
		v.ai3 = 0 -- 0 is armor on and 1 is armor off
		v.ai4 = config.hp --health points
		v.ai5 = 0 --move timer
		v.ai6 = 0 --allows to be hittable in armorless after more than 15 frames
		v.directionalAnimation = 0
		v.rotation2 = 0
		v.rotation3 = 0
		v.armorlesshittable = false
		v.hittable = true
		v.armoron = true
		data.initialized = true
		data.ySpeedTrack = 0
		data.rotation = ((math.pi*1.5)+((math.pi*0.5)*v.direction))%(math.pi*2)
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
		v.animationFrame = math.floor((lunatime.tick) / 8) % 3 + 8
		v.ai2 = 0
		return
	end

	if v.armoron == false then
		v.ai6 = v.ai6 + 1
		if v.ai6 > 15 then
			v.armorlesshittable = true
		end
	else
		v.ai6 = 0
		v.armorlesshittable = false
	end

	if v.ai2 == 0 then
		v.ai1 = v.ai1 + 1
		v.ai5 = v.ai5 + 1
		if v.ai5 >= config.chaseidletime then
			local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
									
			local startX = p.x + p.width / 2
			local startY = p.y + p.height / 2
			local X = v.x + v.width / 2
			local Y = v.y + v.height / 2
						
			local angle = math.atan2((Y - startY), (X - startX))
			local randomspeed = RNG.randomInt(-1, -3)
			v.speedX = randomspeed * math.cos(angle)
			v.speedY = randomspeed * math.sin(angle)
			v.ai5 = 0
		end
		
		if v.ai1 >= config.chasingtime then
			v.ai1 = 0
			v.ai2 = 1
			v.ai5 = 0
			v.speedX = 0
			v.speedY = 0
			if v.armoron == false then
				SFX.play(77)
				v.armoron = true
				v.armorlesshittable = false
			end
		end
	end

	if v.ai2 == 1 then
		v.ai1 = v.ai1 + 1
		if v.ai1 >= config.rolldelay then
			v.ai1 = 0
			v.ai2 = 2
			local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
									
			local startX = p.x + p.width / 2
			local startY = p.y + p.height / 2
			local X = v.x + v.width / 2
			local Y = v.y + v.height / 2
						
			local angle = math.atan2((Y - startY), (X - startX))
			local randomspeed = RNG.randomInt(-4, -5)
			v.speedX = (randomspeed * math.cos(angle))
			v.speedY = randomspeed * math.sin(angle)
			data.ySpeedTrack = randomspeed * math.sin(angle)
		end
		v.armoron = true
	end

	if v.ai2 == 2 then
		v.ai1 = v.ai1 + 1
		v.armoron = true

		if v.collidesBlockLeft or v.collidesBlockRight or v.collidesBlockUp or v.collidesBlockBottom then
			defines.earthquake = 10
			SFX.play(37)
		end

		if v.collidesBlockBottom or v.collidesBlockUp then
			data.ySpeedTrack = -data.ySpeedTrack
			v.speedY = data.ySpeedTrack
		end

		if v.collidesBlockLeft or v.collidesBlockRight then
			v.speedX = -v.speedX
		end
		local rotationSpeed = config.rotationSpeed

		data.rotation = (data.rotation-rotationSpeed)%(math.pi*2)

		if v.ai1 >= config.rolltime then
			v.ai1 = 0
			v.ai2 = 0
			v.speedX = 0
			v.speedY = 0
		end
		-- Interact with blocks
		data.destroyCollider = data.destroyCollider or Colliders.Box(v.x, v.y, v.width+6, v.height+6);
		if v.direction == -1 then
			data.destroyCollider.x = v.x-3
		else
			data.destroyCollider.x = v.x+3
		end
		if v.speedY < 0 then
			data.destroyCollider.y = v.y-4;
		else
			data.destroyCollider.y = v.y+4;
		end
		local tbl = Block.SOLID .. Block.PLAYER
		local list = Colliders.getColliding{
		a = data.destroyCollider,
		b = tbl,
		btype = Colliders.BLOCK,
		filter = function(other)
			if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
				return false
			end
			return true
		end
		}
		for _,b in ipairs(list) do
			if (Block.config[b.id].smashable ~= nil and Block.config[b.id].smashable == 3) then
				b:remove(true)
			else
				b:hit(true)
			end
		end
	end

	if v.ai2 == 3 then
		v.ai1 = v.ai1 + 1
		v.speedX = 0
		v.speedY = 0
		v.friendly = true
		v.hittable = false
		v.armoron = false
		v.armorlesshittable = false
		if v.ai1 == config.hurttime then
			v.ai1 = 0
			v.ai2 = 0
			SFX.play(77)
			v.armoron = true
			v.hittable = true
			v.friendly = false
			v.jumphurt = true
		end
		if v.ai1 == config.hurttime - 5 and v.ai4 <= 0 then
			local e = Effect.spawn(config.effect, v.x, v.y)
			e.speedX = 4 * -v.direction
			e.speedY = -8
			v:kill(HARM_TYPE_NPC)
			SFX.play(fall)
			
			if v.legacyBoss then
				local ball = NPC.spawn(16, v.x, v.y, v.section)
				ball.x = ball.x + ((v.width - ball.width) / 2)
				ball.y = ball.y + ((v.height - ball.height) / 2)
				ball.speedY = -6
				ball.despawnTimer = 100
				
				SFX.play(20)
			end
		end
	end
	--Animation Code
	if v.ai2 == 0 then
		if v.armoron == true then
			v.animationFrame = math.floor(v.ai1 / 6) % 3
		else
			v.animationFrame = math.floor(v.ai1 / 6) % 3 + 5
		end
	elseif v.ai2 == 1 then
		v.animationFrame = 3
	elseif v.ai2 == 2 then
		v.animationFrame = 4
	elseif v.ai2 == 3 or 4 then
		if lunatime.tick() % 8 > 4 then
			v.animationFrame = math.floor(v.ai1 / 6) % 3 + 8
		else
			v.animationFrame = -50
		end
	end
	
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = utils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
	end
	
	--Prevent Bankirosu from turning around when it hits NPCs because they make it get stuck
	if v:mem(0x120, FIELD_BOOL) then
		v:mem(0x120, FIELD_BOOL, false)
	end

end

function sampleNPC.onDrawNPC(v)
	local data = v.data
	local config = NPC.config[v.id]




	if not data.sprite then
		data.sprite = Sprite{texture = Graphics.sprites.npc[v.id].img,frames = utils.getTotalFramesByFramestyle(v)}
	end

	local priority = -45
	if config.priority then
		priority = -15
	end

	data.sprite.x = v.x+(v.width/2)
	data.sprite.y = v.y+v.height-(config.gfxheight/2)

	if v.ai2 == 2 then
		data.sprite.rotation = math.deg(data.rotation or 0)
	else
		data.sprite.rotation = 0
	end

	data.sprite.pivot = Sprite.align.CENTRE
	data.sprite.texpivot = Sprite.align.CENTRE
	if v.animationFrame >= 0 then
		data.sprite:draw{frame = v.animationFrame+1,priority = priority,sceneCoords = true}
	end
	utils.hideNPC(v)
end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end
	


	if culprit then
		if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
			culprit:kill(HARM_TYPE_NPC)
			if not v.armoron then
				SFX.play(bosshit)
				v.ai4 = v.ai4 - 4
				v.ai2 = 3
				v.ai1 = 0
				v.ai5 = 0
			else
				v.ai3 = 1
				v.ai5 = 0
				v.ai1 = 0
				v.ai2 = 0
				v.speedX = 0
				v.speedY = 0
				v.armoron = false
				SFX.play(4)
				Routine.setFrameTimer(1, (function() 
					local ptl = Animation.spawn(764, v.x + v.width/2, v.y + v.height/2)
				end), 3, false)
			end
		elseif (NPC.HITTABLE_MAP[culprit.id] or culprit.id == 45 and v:mem(0x138, FIELD_WORD) == 0) and culprit.id ~= 50 then
			culprit:kill(HARM_TYPE_NPC)
			if not v.armoron then
				SFX.play(bosshit)
				v.ai4 = v.ai4 - 4
				v.ai2 = 3
				v.ai1 = 0
				v.ai5 = 0
			else
				v.ai3 = 1
				v.ai5 = 0
				v.ai1 = 0
				v.ai2 = 0
				v.speedX = 0
				v.speedY = 0
				v.armoron = false
				SFX.play(4)
				Routine.setFrameTimer(1, (function() 
					local ptl = Animation.spawn(764, v.x + v.width/2, v.y + v.height/2)
				end), 3, false)
			end
		elseif culprit.id == 13 then
			SFX.play(9)
			v.ai4 = v.ai4 - 1
		elseif culprit.__type == "Player" then
			--Bit of code taken from the basegame chucks
			if (culprit.x + 0.5 * culprit.width) < (v.x + v.width*0.5) then
				culprit.speedX = -4
			else
				culprit.speedX = 4
			end
			if not v.armoron then
				SFX.play(bosshit)
				v.ai4 = v.ai4 - 4
				v.ai1 = 0
				v.ai5 = 0
				v.ai2 = 3
			else
				culprit:harm()
			end
		end
	end
	if reason ~= HARM_TYPE_JUMP and reason ~= HARM_TYPE_SPINJUMP then
		if culprit then
			Animation.spawn(75, culprit.x+culprit.width/2-16, culprit.y+culprit.width/2-16)
		end
	end
	if v.ai4 <= 0 then
        v.ai2 = 3
		v.ai1 = 0
		v.speedX = 0
		v.speedY = 0
		SFX.play(bosshit)
	elseif v.ai4 > 0 then
		eventObj.cancelled = true
		v:mem(0x156,FIELD_WORD,60)
	end
	
	eventObj.cancelled = true
end

--Gotta return the library table!
return sampleNPC