local wiggler = {}

local npcManager = require("npcManager")
local wiggler = require("wigglerboss")

local npcID = NPC_ID

wiggler.registerHead(npcID, {id = npcID})

npcManager.registerHarmTypes(npcID, {HARM_TYPE_JUMP, HARM_TYPE_NPC, HARM_TYPE_SWORD, HARM_TYPE_LAVA, HARM_TYPE_SPINJUMP}, {
[HARM_TYPE_NPC]=npcID,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});
function wiggler.onInitAPI()
	registerEvent(wiggler, "onNPCHarm")
end
function wiggler.onNPCHarm(eventToken, v, killReason, culprit)
    local data = v.data._basegame
    local cfg = NPC.config[v.id]
    if v.id == npcID and killReason == HARM_TYPE_JUMP or killReason == HARM_TYPE_SPINJUMP or killReason == HARM_TYPE_NPC or killReason == HARM_TYPE_PROJECTILE then
        if v.hp > 0 then
            if v:mem(0x156, FIELD_WORD) <= 0 then
                eventToken.cancelled = true
                v.hp = v.hp - 1
                SFX.play(39)
                v:mem(0x156, FIELD_WORD,12)
                if (v.hp % cfg.angryHealth == cfg.angryHealth - 1 and cfg.hitSet == 0) or (cfg.hitSet == 1) then
                    data.turningAngry = true
                end
            else
                eventToken.cancelled = true
            end
        else

        end
    end
end
return wiggler