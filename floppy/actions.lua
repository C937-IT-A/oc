local fs = require("filesystem")

print("Open (O) or Uninstall (U)")
local inp = io.read("*l").lower().sub(1,1)
if inp == "o" then
    os.execute("/geolib/exec.lua")
elseif inp == "u" then
    fs.umount("/geolib") -- possible breakpoint
    print("Uninstallation protocol complete. Removal of GEO floppy permissible.")
    fs.remove("manGeo.lua") -- possible breakpoint
end