local autoScroll = require("autoscroll")

local autoscrollState = 0
local cam = Camera.get()[1]

-- Run code on level start
function onStart()
    --Your code here
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
function onTick()
    --Your code here
    if player.deathTimer > 0 or player.forcedState == 2 then return end
    if player:mem(0x148, FIELD_WORD) > 0 
    and player:mem(0x14C, FIELD_WORD) > 0 then
        player:kill()
    end
    if autoscrollState == 1 and cam.y > -140600 and player.section == 3 then
        autoScroll.scrollToBox(-140000,-140608,-139200,-140032,0.7,3)
        Text.print("Moving up", 110,168)
    end
    Text.print(autoscrollState,110,152)
end

-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(n)
    if n == "autoscrollbegin" then
		autoscrollState = 1
	end
end
