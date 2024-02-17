local npc = {}
local npcManager = require("npcManager")
local effectconfig = require("game/effectconfig")
local id = NPC_ID

npcManager.setNpcSettings{
	id = id,
	gfxheight = 96,
	gfxwidth = 96,
	width = 60,
	height = 66,
	frames = 4,
	framestyle = 1,
	framespeed = 2, 
	speed = 1,

	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	jumphurt = true, 
	spinjumpsafe = true, 
	nogravity = true,
	noblockcollision = true,
}

local idle = Misc.resolveSoundFile("Zinger_DKC2")
local death = Misc.resolveSoundFile("Zinger_die")
local turn = Misc.resolveSoundFile("Zinger_turn")	
local playSound = false
local idleSoundObj
function effectconfig.onTick.TICK_ZINGER(v)
    if v.timer == v.lifetime-1 then
        v.speedX = math.abs(v.speedX)*-v.direction
    end

    v.animationFrame = math.min(v.frames-1,math.floor((v.lifetime-v.timer)/v.framespeed))
end
function npc.onTick()
    if playSound then
        -- Create the looping sound effect for all of the NPC's
        if idleSoundObj == nil then
			idleSoundObj = SFX.play{sound = idle,loops = 0}
        end
    elseif idleSoundObj ~= nil then -- If the sound is still playing but there's no NPC's, stop it
        idleSoundObj:stop()
        idleSoundObj = nil
    end
    
    -- Clear playSound for the next tick
    playSound = false
end
function npc.onTickEndNPC(v)
	data = v.data
	if data.noise == nil then
		data.noise = true
	end
	if not v.friendly and NPC.config[v.id].strong then
        for _,p in ipairs(NPC.getIntersecting(v.x - 5, v.y - 5, v.x + v.width + 5, v.y + v.height + 5)) do
		--If the intersecting NPC is being held or has been thrown.
            if p:mem(0x12A, FIELD_WORD) > 0 and p:mem(0x138, FIELD_WORD) == 0 and (not p.isHidden) and (not p.friendly) then
                if p:mem(0x12C, FIELD_WORD) > 0 or p:mem(0x132, FIELD_WORD) > 0 then
				--List of IDs which do not cause any sound.
				local noSoundNPCs = {22, 26, 31, 32, 35, 49, 154, 155, 156, 157, 171, 191, 193, 238, 278, 279, 433, 434, 451, 452, 453, 454, 457}
                  local isNoSoundNPC = false
                  for _,id in ipairs(noSoundNPCs) do
                        if p.id == id then
                            isNoSoundNPC = true
                            break
                        end                        
                    end
					--Play the death sound if not one of the NPCs listed in noSoundNPCs.
                    if not isNoSoundNPC then
                        p:harm(HARM_TYPE_HELD)
                        SFX.play(death)
                    end
                end
            end
        end
    end
	if (v.x + v.width > camera.x and v.x < camera.x + 800 and v.y + v.height > camera.y and v.y < camera.y + 600) then
		playSound = true
		data.noise = true
	else
		data.noise = false
	end
end

function npc.onPostNPCHarm(v, r, c)
	if v.id ~= id then return end

	local config = NPC.config[id]
	
	--Only play if the NPC is killed but not by offscreen or if another NPC dies.
	if reason == HARM_TYPE_OFFSCREEN then return end

	SFX.play(death)
end

function npc.onInitAPI()
	local config = NPC.config[id]
	
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
	npcManager.registerEvent(id, npc, 'onTickNPC')
	npcManager.registerHarmTypes(id,
		{
			HARM_TYPE_HELD,
		}, 
		{
			[HARM_TYPE_HELD]=801,
		}
	);
	
	registerEvent(npc, 'onPostNPCHarm')
end


return npc