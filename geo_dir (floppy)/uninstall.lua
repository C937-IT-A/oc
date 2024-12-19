local fs = require('filesystem')
local config = require('../config.lua')
fs.unmount(config["mount"])
fs.remove("/bin/" .. config["cname"] .. ".lua")
print("Uninstalled!")
-- unmounts disk and removes binary command