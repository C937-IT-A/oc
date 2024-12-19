-- called by bin command
local components = require("component")
local gpu = components.gpu

if not pcall(function()
    gpu.setDepth(8)
end) then
    pcall(function()
        gpu.setDepth(4)
    end)
end -- attempts to set maximum color depth

if gpu.getDepth() > 1 then
    require("../operation_modes/windowed.lua")
else
    print("GPU is set to monochrome.\nWindowed mode cannot run in monochrome. Continue in DOS? (Y/N)\n > ")
    if string.lower(io.read("*l")):sub(1,1) == "y" then
        require("term").clear()
        require("../operation_modes/DOS.lua")
    else
        print("Try upgrading your graphics card.")
    end
end