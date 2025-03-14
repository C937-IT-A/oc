local fs = require("filesystem")

print("Open (O) or Uninstall (U)")
local inp = string.sub(1, 1, string.lower(io.read("*l")))
if inp == "o" then
    os.execute("/geolib/exec.lua")
elseif inp == "u" then
    fs.umount("/geolib") -- possible breakpoint; idk how to mount
    print("Uninstallation protocol complete. Removal of GEO floppy permissible.")
    fs.remove("manGeo.lua") -- possible breakpoint; can a file remove itself?
end
