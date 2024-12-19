local proxy = ...
local fs = require('filesystem')
local config = require('../config.lua')
fs.mount(proxy, config["mount"])
-- mounts disk

local cmdFile = fs.open("/bin/" .. config["cname"] .. ".lua", "w")
cmdFile:write("local fs = require(\"filesystem\")\nif fs.exists(\"" .. config["mount"] .. "\") then\n\trequire(\"" .. config["mount"] .. "/run.lua\")\nelse\n\tprint(\"Could not find required mount at  .. " .. config["mount"] .. ".\")\nend")
cmdFile:close()
-- creates binary command