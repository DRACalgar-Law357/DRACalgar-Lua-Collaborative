local blockmanager = require("blockmanager")
local temperaturesync = require("temperaturesynced")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	bumpable = true,
})

temperaturesync.registertemperatureSwitch(blockID)

return block