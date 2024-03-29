local freeze = {}

--[[ Rudimentary example:
local freeze = require("freezeHighlight")

function onPostNPCKill()
    freeze.set(10)
end
]]

function freeze.onInitAPI()
    registerEvent(freeze, "onTick")
    registerEvent(freeze, "onTickEnd", "onTickEnd", true)
    registerEvent(freeze, "onDraw")
end

local freezeTimer = 0
local glowTimer = 0

local fields = {"x", "y", "speedX", "speedY", "direction", "frame"}
local mem = {{0x11C, FIELD_WORD}}
local storage = {
	x=0,
	y=0,
    speedX=0,
    speedY=0,
    direction = 0,
    frame = 0,
}

local storageMem = {
    [0x11C] = 0
}

function freeze.set(f, ignoreGlow)
    freezeTimer = f or 0

    if not ignoreGlow then
        Defines.earthquake = Defines.earthquake + 3
        glowTimer = 8
    end

    for k,v in ipairs(fields) do
        storage[v] = player[v]
    end

    for k,v in ipairs(mem) do
        storageMem[v[1]] = player:mem(v[1], v[2])
    end

    if f > 0 then
        Defines.levelFreeze = true
    end
end

function freeze.get()
    return freezeTimer > 0, freezeTimer
end

function freeze.onTickEnd()
    if glowTimer > 0 then
        glowTimer = glowTimer - 1
        if glowTimer >= 4 then
            Defines.earthquake = math.max(3, Defines.earthquake)
        end
    end

    if freezeTimer == 0 then return end

    if freezeTimer > 0 then
        freezeTimer = freezeTimer - 1
        Defines.levelFreeze = freezeTimer > 0
    end

    if Defines.levelFreeze then
        for k,v in ipairs(fields) do
            player[v] = storage[v]
        end

        for k,v in ipairs(mem) do
            player:mem(v[1], v[2], storageMem[v[1]])
        end
    end
end

function freeze.onTick()
    if freezeTimer == 0 then return end

    if Defines.levelFreeze then
        player.keys.left = false
        player.keys.right = false
    end
end

function freeze.onDraw()
    if glowTimer == 0 then return end

    Graphics.drawScreen{priority = 0, color = Color.white .. (glowTimer * 0.05)}
end

return freeze