-- runs on insertion
local fs = require("filesystem")
local proxy = ...
fs.mount(proxy, "/geolib") -- mounts this floppy to root as geolib

fs.copy("actions.lua", "/bin/manGeo.lua") -- possible breakpoint; just test it