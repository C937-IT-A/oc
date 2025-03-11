print("Please wait...")

local comp = require("component")
local event = require("event")

local gpu = comp.gpu or error("You're not gonna see this anyway")
local geo = comp.geolyzer or error("Geolyzer peripheral not found")

term.clear()

-- determine GPU color depth
local success = pcall(function() gpu.setDepth(8) end)
if not success then success = pcall(function() gpu.setDepth(4) end) end
if not success then error("Your system's specifications do not meet the minimum GPU requirements: 4-bit color depth") end -- terminate program if monochrome
gpu.setForeground(0xffee00)
print("Color depth verified")

local resX, resY = gpu.getResolution()
print("GPU resolution found")

local termLocX = resX; local termLocY = 1 -- location of X button that exits program. MUST be on toolbar!
local scanLocX = 1; local scanLocY = 4 -- location of scan button. should be on sidebar, must NOT be in main!
local compLocX = 1; local compLocY = 6 -- location of compare button. should be on sidebar, must NOT be in main!
local sqLocX = 1; local sqLocY = 8 -- location of button that sets status quo. should be on sidebar, must NOT be in main!

print("Button locations defined")

os.sleep(.25)
term.clear()

-- make toolbar & propagate information & buttons
gpu.setbackground(0xd6d6d6)
gpu.setForeground(0x000000)
gpu.fill(1, 1, resX, 2, " ")
gpu.set(1, 1, "GEOLOGICAL SECURITY APPLICATION")
gpu.set(1, 2, "R.B.C. CYBER; ARR @3/11/2025")
gpu.setBackground(0xff0000)
gpu.setForeground(0xffffff)
gpu.set(termLocX, termLocY, "X") -- termination button
gpu.setBackground(0xacedff)
gpu.fill(1, 3, resX, resY-2, " ") -- main area
gpu.setBackground(0x8f8f8f)
gpu.fill(1, 3, 2, resY-2, " ") -- side bar
gpu.setBackground(0x00ff0e)
gpu.set(scanLocX, scanLocY, "+") -- scan button
gpu.setBackground(0x9300ff)
gpu.set(compLocX, compLocY, "=") -- compare button
gpu.setBackground(0xf2ff00)
gpu.set(sqLocX, sqLocY, "~") -- status quo button

local lastMSGlen = 0
local function setStatus(status, clr) -- sets status message
    local prevBKG = gpu.getBackground()
    local prevFRG = gpu.getForeground()
    gpu.setBackground(0xd6d6d6)
    gpu.setForeground(clr)
    gpu.fill(resX - lastMSGlen, 2, lastMSGlen, 1, " ") -- clear last message
    gpu.set(resX - status.len(), 2, status) -- set new message
    lastMSGlen = status.len()
    gpu.setBackground(prevBKG)
    gpu.setForeground(prevFRG)
end

setStatus("READY", 0x00ff0e)

-- MAIN --
-- TODO lol