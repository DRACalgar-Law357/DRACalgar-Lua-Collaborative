local blockManager = require("blockManager")

local area = {}
local blockID = BLOCK_ID

local areaSettings = {
	id = blockID,

	sizable = true,
	passthrough = true,
}

blockManager.setBlockSettings(areaSettings)

return area