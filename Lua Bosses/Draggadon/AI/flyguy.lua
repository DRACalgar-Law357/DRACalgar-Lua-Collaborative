--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local redirector = require("redirector")

--***************************************************************************************************************
--onDraw code taken from boingboingsplat's Albatoss code.
--Credit to the basegame scuttlebug.lua script, some code was used from that for the "Swoop and Leave" behaviour.
--***************************************************************************************************************

local guys = {}
local npcIDs = {}

local rad, sin, cos, pi = math.rad, math.sin, math.cos, math.pi
local death = Misc.resolveSoundFile("enemyDie")

local STATE_NORMAL = 0
local STATE_HIT = 1

--Register events
function guys.register(id)
	npcManager.registerEvent(id, guys, "onTickNPC")
	npcManager.registerEvent(id, guys, "onDrawNPC")
	npcIDs[id] = true
end

function guys.onInitAPI()
    registerEvent(guys, "onNPCHarm")
end

function guys.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.state = STATE_NORMAL
		data.timer = 0
		data.left = true
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_NORMAL
		data.timer = data.timer or 0
		data.left = data.left or true
	end
	
	--If on Yoshi's tongue release the item
	if v:mem(0x138, FIELD_WORD) == 5 then
		if v.ai1 > 0 then
			local n = NPC.spawn(v.ai1, v.x - config.gfxwidth * -0.05, v.y - config.gfxheight * -0.3)
			n.direction = v.direction
				if NPC.config[n.id].iscoin then
					n.ai1 = 1
					n.speedX = 0
				end
			v.ai1 = 0
		end
	end

	if v.ai5 > 0 then
		data.state = STATE_HIT
	end

	--If grabbed then turn it into a rolling shy guy, more intended for MrDoubleA's playable.
	if v:mem(0x12C, FIELD_WORD) > 0 or (v:mem(0x138, FIELD_WORD) > 0 and (v:mem(0x138, FIELD_WORD) ~= 4 and v:mem(0x138, FIELD_WORD) ~= 5)) then
		data.timer = 0
		v:transform(751)
		v.ai2 = config.colour
		if v.direction == DIR_LEFT then
			v.ai1 = config.leftRollFrame
		else
			v.ai1 = config.rightRollFrame
		end
	end
	if data.state == STATE_NORMAL then
		if settings.list == nil then settings.list = 0 end
		if settings.list == 0 then
			--Hover around in place
			data.timer = data.timer + 1
			if data.timer >= 256 then
				v.direction = -v.direction
				data.timer = 0
			end
			v.speedX = 0.6 * v.direction
			v.speedY = math.sin(lunatime.tick()/config.sineSpeed)*config.sineAmplitude
		elseif settings.list == 1 then
			if v.ai2 == 0 then
				if v:mem(0x124, FIELD_BOOL) then
				
					if data.timer <= 0 then
						--Set position to begin in, above the section and left or right depending on the initial direction
						v.y = Section(v:mem(0x146, FIELD_WORD)).boundary.top - 64
						if v.direction == DIR_RIGHT then
							v.x = v.spawnX + Section(v:mem(0x146, FIELD_WORD)).boundary.top - 64 - v.spawnY
							data.left = false
						else
							v.x = v.spawnX + 128 - Section(v:mem(0x146, FIELD_WORD)).boundary.top - 64 + v.spawnY
						end
					end
					
					--Set variables for the player and the camera
					local p = Player.getNearest(v.x, v.y)
					local cam = Camera(p.idx)
					if v.section == p.section then
						local sec = Section(p.section)
					end		
					
					--If the spawn position of the NPCs is onscreen
					if (data.timer <= 0) and (((v.spawnX >= cam.x) and (v.spawnX + v.width <= (cam.x + cam.width)))) then
						if v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0 then
							data.timer = 1
							v.y = v.spawnY
						else
							data.timer = 1
							v:mem(0x124, FIELD_BOOL,true)
							v:mem(0x12A, FIELD_WORD, 180) -- set the NPC to act as if it is onscreen as it will be dopping from offscreen
						end
					end
					
					--Make the NPC begin moving down to its spawn position
					if data.timer > 0 then
						if v.y < v.spawnY then 
							v.speedY = 4
							v.speedX = 4 * v.direction
						else
							v.speedY = 0
							v.speedX = 0
							data.timer = 0
							v.ai2 = 1
						end
					end
					
				end
				--Make the NPC hover up and down for a bit
			elseif v.ai2 == 1 then
				data.timer = data.timer + 1
				v.speedY = math.sin(-data.timer/config.sineSpeed)*config.sineAmplitude / 3.5
				if data.timer >= 128 then
					v.ai2 = 2
					v.speedY = 0
					data.timer = 0
				end
				--Have the NPC spin in a circle
			elseif v.ai2 == 2 then
				data.w = 2 * pi/65
				data.timer = data.timer + 1
				if data.left then
					v.speedX = 50 * -data.w * cos(data.w*data.timer)
				else
					v.speedX = 50 * data.w * cos(data.w*data.timer)
				end
				v.speedY = 50 * -data.w * sin(data.w*data.timer)
				if data.timer >= 64 then
					v.ai2 = 3
					data.timer = 0
				end
			else
				--Fly off
				data.timer = data.timer + 1
				if data.timer == 32 then SFX.play("shyGuyLaugh.wav") end
				v.speedY = -4
				if v:mem(0x12A, FIELD_WORD) <= 90 then v:kill(HARM_TYPE_OFFSCREEN) end
			end
		else
			for _,bgo in ipairs(BGO.getIntersecting(v.x+(v.width/2)-0.5,v.y+(v.height/2),v.x+(v.width/2)+0.5,v.y+(v.height/2)+0.5)) do
				if redirector.VECTORS[bgo.id] then -- If this is a redirector and has a speed associated with it
					local redirectorSpeed = redirector.VECTORS[bgo.id] * settings.moveSpeed -- Get the redirector's speed and make it match the speed in the NPC's settings		
					-- Now, just put that speed from earlier onto the NPC
					v.speedX = redirectorSpeed.x
					v.speedY = redirectorSpeed.y
				elseif bgo.id == redirector.TERMINUS then -- If this BGO is one of the crosses
					-- Simply make the NPC stop moving
					v.speedX = 0
					v.speedY = 0
				end
			end
		end
	else
		if data.timer < 5.9 then
			data.timer = data.timer + 0.1
		end
		v.speedX = 0.5 * v.direction
		if v.ai5 <= 0 then
			v.speedY = -data.timer
		else
			v.speedY = -data.timer * 3
		end
		if v:mem(0x12A, FIELD_WORD) <= 90 then v:kill(HARM_TYPE_OFFSCREEN) end
	end
end

--When harmed, make the NPC do various things, such as transforming into a rolling shy guy or playing a sound effect.
function guys.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if not npcIDs[v.id] then return end
	local config = NPC.config[v.id]
	
	--Spawn its payload
	if v.ai1 > 0 then
		local n = NPC.spawn(v.ai1, v.x - config.gfxwidth * -0.05, v.y - config.gfxheight * -0.3)
		n.direction = v.direction
		if NPC.config[n.id].iscoin then
			n.ai1 = 1
			n.speedX = 0
		end
	end
	
	if reason == HARM_TYPE_JUMP then	
		SFX.play(death)
	elseif reason == HARM_TYPE_NPC or reason == HARM_TYPE_TAIL then
		if reason == HARM_TYPE_TAIL then SFX.play(9) end
		if culprit then
			if culprit.isValid and type(culprit) == "NPC" and culprit.id == 195 or culprit.id == 50 then
				return
			else
				if type(culprit) == "Player" or (type(culprit) == "NPC" and NPC.HITTABLE_MAP[culprit.id] or culprit.id == 45 or culprit.id == 13 and v:mem(0x138, FIELD_WORD) == 0 and data.state == STATE_NORMAL) then -- Make the Fly Guy fly off
					if type(culprit) == "NPC" then
						culprit:kill()
					end
					if v.ai1 > 0 then
						eventObj.cancelled = true
						data.state = STATE_HIT
						v.ai1 = 0
						data.timer = 3
					end
				end
			end
		else
			if v.ai1 > 0 then
				eventObj.cancelled = true
				data.state = STATE_HIT
				v.ai1 = 0
				data.timer = 3
			end
		end
	else
	return
	end
end

function guys.onDrawNPC(v)
  if v:mem(0x12A, FIELD_WORD) <= 0 then return end
  
  --If empty container, don't draw anything
  if v.ai1 <= 0 then return end
  
  --Draw the sprite of the contained NPC
  local id = v.ai1;
	if(id > 0) then
		local i = Graphics.sprites.npc[id].img;
		local cfg = NPC.config[id];
		local h = cfg.gfxheight;
		local w = cfg.gfxwidth;
		if(h == 0) then
			h = cfg.height;
		end
		if(w == 0) then
			w = cfg.width;
		end
    
    --If we're facing right, flip the texture
    if v.direction == 1 then
      w = -w;
    end
		
		local x,y = v.x + 0 * v.direction + v.width * 0.5, v.y + 0 + v.height;
    
		x = x - w*0.5;
		y = y - h*0.3;
		
		Graphics.drawBox{
							x = x, y = y, 
							textureCoords = {0,0,1,0,1,h/i.height,0,h/i.height}, 
							width = w, height = h, 
							texture = i, 
							priority=-50, sceneCoords=true
						}
	end
  
end

return guys