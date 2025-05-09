print("Please wait...")

local needsRestart = false
local comparing = false
local exitCode = "1"

-- fundamentals
local comp = require("component")
local event = require("event")
local fs = require("filesystem")
local serial = require("serialization")
local term = require("term")

-- componentry
local gpu = comp.gpu or error("You're not gonna see this anyway")
local geo = comp.geolyzer or error("Geolyzer peripheral not found")
local CC = comp.computer or error("Surely not...")

term.clear()

-- determine GPU color depth
local success = pcall(function() gpu.setDepth(8) end)
if not success then success = pcall(function() gpu.setDepth(4) end) end
if not success then error("Your system's specifications do not meet the minimum GPU requirements: 4-bit color depth") end -- terminate program if monochrome
gpu.setForeground(0xffff00)
print("Color depth verified")

if gpu.getDepth() ~= gpu.maxDepth() then
    print("Your GPU's color depth is not at its maximum. Set this option? (Y/N)")
    local choice = io.read("*l").lower()[0]
    if choice == "y" then
        gpu.setDepth(gpu.maxDepth())
    end
end

-- determine GPU resolution for rendering calculations
if gpu.getResolution() ~= gpu.maxResolution() then
    print("Your GPU's resolution is not at its maximum. Set this option? (Y/N)")
    local choice = io.read("*l").lower()[0]
    if choice == "y" then
        gpu.setResolution(gpu.maxResolution())
    end
end
local resX, resY = gpu.getResolution()
print("GPU resolution found")

-- determine button locations to compare against click locations
local termLocX = resX; local termLocY = 1 -- location of X button that exits program. MUST be on toolbar!
local scanLocX = 1; local scanLocY = 4 -- location of scan button. should be on sidebar, must NOT be in main!
local compLocX = 1; local compLocY = 6 -- location of compare button. should be on sidebar, must NOT be in main!
local sqLocX = 1; local sqLocY = 8 -- location of button that sets status quo. should be on sidebar, must NOT be in main!
print("Button locations defined")

local holo -- optional!
if comp.isAvailable("hologram") then holo = comp.hologram else holo = nil end
local holoResX, holoResY
if holo then print("Hologram found") else print("Optional hologram not found") end
if holo then holoResX, holoResY = holo.getScale(); holo.clear() end
-- if holo then holo.setPaletteColor(0, 0xff0000); holo.setPaletteColor(1, 0x00ff00); holo.setPaletteColor(2, 0x0000ff) end

os.sleep(.25)
term.clear()

-- make toolbar & propagate information & buttons
gpu.setBackground(0xacedff)
gpu.fill(1, 1, resX, resY, " ") -- main area
local function propagateInformation()
    gpu.setBackground(0xd6d6d6)
    gpu.setForeground(0x000000)
    gpu.fill(1, 1, resX, 2, " ") -- toolbar
    gpu.set(1, 1, "GEOLOGICAL SECURITY APPLICATION") -- title
    gpu.set(1, 2, "R.B.C. CYBER; ARR @3/11/2025") -- cc info
    gpu.setBackground(0xff0000)
    gpu.setForeground(0xffffff)
    gpu.set(termLocX, termLocY, "X") -- termination button
    gpu.setBackground(0x8f8f8f)
    gpu.fill(1, 3, 2, resY-2, " ") -- side bar
    gpu.setBackground(0x00ff0e)
    gpu.set(scanLocX, scanLocY, "+") -- scan button
    gpu.setBackground(0x9300ff)
    gpu.set(compLocX, compLocY, "=") -- compare button
    gpu.setBackground(0xf2ff00)
    gpu.set(sqLocX, sqLocY, "~") -- status quo button
end
local function depropagateInformation()
    gpu.setBackground(0xacedff)
    gpu.fill(1, 3, resX, resY, " ") -- main area
end
propagateInformation()
local lastMSGlen = 0
local function setStatus(status, clr) -- sets status message
    local prevBKG = gpu.getBackground()
    local prevFRG = gpu.getForeground()
    gpu.setBackground(0xd6d6d6)
    gpu.setForeground(clr)
    gpu.fill(resX - lastMSGlen, 2, resX, 1, " ") -- clear last message
    gpu.set(resX - string.len(status), 2, status) -- set new message
    lastMSGlen = string.len(status)
    gpu.setBackground(prevBKG)
    gpu.setForeground(prevFRG)
end

setStatus("READY", 0x00ff00)

-- MAIN --

repeat
    local _, _, x, y = event.pull("touch") -- possible breakpoint; is this how you get clicks?
    if x == termLocX and y == termLocY then
        -- closed program
        depropagateInformation()
        gpu.setBackground(0x000000)
        gpu.setForeground(0xffffff)
        CC.beep(800, .25);CC.beep(600, .25);CC.beep(400, .25)
        term.clear()
        if holo then holo.clear() end
        print("Exited GEOSEC with code 0; successful user-initiated shutdown.")
        return
    elseif x == scanLocX and y == scanLocY then
        -- requested scan
        local success = pcall(function() --uncomment me when i'm working right!
            if holo then holo.clear() end
            depropagateInformation()
            setStatus("WORKING", 0xf2ff00)
            CC.beep(400, 1)
            local width = tonumber(io.open("settings/scanW.cf"):read("*a"));io.flush() -- possible breakpoints; can i read directly from an io.open or does it need to be localized?
            local depth = tonumber(io.open("settings/scanD.cf"):read("*a"));io.flush()
            local height = tonumber(io.open("settings/scanH.cf"):read("*a"));io.flush()
            local offX = tonumber(io.open("settings/scanX.cf"):read("*a")) - 1;io.flush()
            local offY = tonumber(io.open("settings/scanY.cf"):read("*a"));io.flush()
            local offZ = tonumber(io.open("settings/scanZ.cf"):read("*a")) - 1;io.flush()

            local lSF = io.open("/geoinfo/lastScan.bdat", "w")

            local currX = 1
            local currZ = 1

            repeat -- possible breakpoint; RAM allocation. might require a whole-ass server... actually that seems reasonable. scalability issues but whaddeva!
                local columnData = geo.scan(offX + currX, offZ + currZ, offY, 1, 1, height)
                for i,v in pairs(columnData) do
                    if string.sub(tostring(v), 3, 3) == "0" then -- truncate scanned information to one decimal place for storage or whole number if no decimal portion
                        columnData[i] = tonumber(string.sub(tostring(v), 1, 1))
                    else
                        columnData[i] = tonumber(string.sub(tostring(v), 1, 3))
                    end
                    if columnData[i] == 0 then
                        columnData[i] = math.abs(columnData[i]) -- replace all instances of -0.0 with 0.0 for storage
                    end
                end
                for i=#columnData,height + 1,-1 do
                    table.remove(columnData, i)
                end
                lSF:write(serial.serialize(columnData) .. "\n")
                gpu.setBackground(0xf2ff00)
                gpu.set(currX, currZ + 2, " ")
                if currX >= width then
                    if currZ < depth then
                        currZ = currZ + 1
                        currX = 1
                    else
                        break
                    end
                else
                    currX = currX + 1
                end
            until nil
            io.flush()
            setStatus("READY; PRESS ENTER", 0xf2ff00)
            CC.beep(700, .75)
            coroutine.resume(coroutine.create(function() -- definite breakpoint
                io.read("*l")
                propagateInformation()
                setStatus("READY", 0x00ff00)
            end))
        end)
        if not success then setStatus("ERROR; SHUT DOWN", 0xFF0000);needsRestart = true end
    elseif x == compLocX and y == compLocY then
        -- requested compare
        --local success = pcall(function() --uncomment me when i'm working right!
            if holo then holo.clear() end
            depropagateInformation()
            setStatus("WORKING", 0xf2ff00)
            CC.beep(400, 1)
            if not fs.exists("/geoinfo/lastScan.bdat") then
                setStatus("ERROR; SHUT DOWN", 0xFF0000)
                exitCode = "2"
                needsRestart = true
                break
            end
            if not fs.exists("/geoinfo/statusQuo.bdat") then
                setStatus("ERROR; SHUT DOWN", 0xFF0000)
                exitCode = "2"
                needsRestart = true
                break
            end
            if not fs.exists("/geoinfo/discrep.bdat") then
                setStatus("ERROR; SHUT DOWN", 0xFF0000)
                exitCode = "2"
                needsRestart = true
                break
            end
            local lastScan = io.open("/geoinfo/lastScan.bdat") --last scan made, read
            local statusQuo --scan considered the normal state, read
            local discrep --stores mathematical difference between the two files, append
            local sQlS;local lSlS
            local lineLen = string.len(lastScan:read("*l")) --unit length of one line used for fs:seek parameter.
            lastScan:close()
            local currX = 1;local currY = 1
            local printX = 1; local printY = 3
            local baseX = printX;local baseY = printY
            local width = tonumber(io.open("settings/scanW.cf"):read("*a"));io.flush() -- possible breakpoints; can i read directly from an io.open or does it need to be localized?
            local depth = tonumber(io.open("settings/scanD.cf"):read("*a"));io.flush()
            
            for line in lastScan:lines() do -- possible breakpoint; RAM allocation. might require a whole-ass server... actually that seems reasonable. scalability issues but whaddeva!
                lastScan = io.open("/geoinfo/lastScan.bdat")
                fs:seek("set", (lineLen * line))
                lSlS = serial.unserialize(io.read("*l"))
                lastScan:close()
                statusQuo = io.open("/geoinfo/statusQuo.bdat")
                fs:seek("set", (lineLen * line))
                sQlS = serial.unserialize(io.read("*l"))
                statusQuo:close()
                local diff = {}
                local flag = false
                for i,v in pairs(lSlS) do
                    local lDiff = sQlS[i] - v
                    if lDiff > 0 then
                        flag = "lR"
                    elseif lDiff < 0 then
                        if flag ~= "lR" then
                            flag = "hR"
                        end
                    end
                    table.insert(diff, lDiff)
                    if v <= 0 and lDiff ~= 0 then flag = "AIR" end
                end
                if flag then
                    -- discrepancy in current column
                    if flag == "lR" then
                        -- new column contains blocks with less breakforce than previous but not air
                        gpu.setBackground(0xFFFF00)
                        gpu.set(printX, printY, "?")
                    elseif flag == "hR" then
                        -- new column contains blocks with more breakforce than previous
                        gpu.setBackground(0x0000FF)
                        gpu.set(printX, printY, " ")
                    elseif flag == "AIR" then
                        -- new column contains air that was not previously there
                        gpu.setBackground(0xFF0000)
                        gpu.set(printX, printY, "!")
                    end
                else
                    -- no discrepancy in current column
                    gpu.setBackground(0xFFFFFF)
                    gpu.set(printX, printY, " ")
                end
                -- problems \/
                discrep = io.open("/geoinfo/discrep.bdat", "w")
                discrep:write(serial.serialize(diff) .. "\n")
                io.flush()
                discrep:close()
                --so... okay.
                --the discrep file stores column data in (X by Y in i) format. first line
                --is X1Y1i1, second is X2Y1i2, and so on incrementing X until width is reached,
                --at which point X resets to 1 and Y increments by 1. if Y has reached depth,
                --the loop breaks as the compare is finished.
                if currX >= width then
                    if currY < depth then
                        currY = currY + 1 -- increment Y
                        currX = 1 -- reset X
                        printX = baseX
                        printY = printY + 1
                    else
                        break -- all columns accounted for; break loop
                    end
                else
                    currX = currX + 1 -- increment X
                    printX = printX + 1
                end
            end
            io.flush()
            setStatus("COMPARING", 0xf2ff00)
            comparing = true
            CC.beep(700, .75)
            coroutine.resume(coroutine.create(function() -- possible breakpoint
                io.read("*l")
                propagateInformation()
                comparing = false
                setStatus("READY", 0x00ff00)
            end))
        --end)
        --if not success then setStatus("ERROR; SHUT DOWN", 0xFF0000);needsRestart = true end
    elseif x == sqLocX and y == sqLocY then
        -- requested set SQ
        local success = pcall(function() --uncomment me when i'm working right!
            propagateInformation()
            setStatus("WORKING", 0xf2ff00)
            CC.beep(400, 1)
            gpu.setForeground(0xffffff)
            if fs.exists("/geoinfo/lastScan.bdat") then
                gpu.set(3, 3, "Found lastScan.bdat")
            else
                setStatus("ERROR; SHUT DOWN", 0xFF0000)
                exitCode = "2"
                needsRestart = true
                break
            end
            if fs.exists("/geoinfo/statusQuo.bdat") then
                gpu.set(3, 4, "Found statusQuo.bdat")
            else
                setStatus("ERROR; SHUT DOWN", 0xFF0000)
                exitCode = "2"
                needsRestart = true
                break
            end
            gpu.set(3, 5, "Copying...")
            fs.copy("/geoinfo/lastScan.bdat", "/geoinfo/statusQuo.bdat")
            gpu.set(5, 6, "lastScan.bdat >> statusQuo.bdat")
            local fsize = tostring(fs.size("/geoinfo/lastScan.bdat") / 1000)
            io.open("/geoinfo/lastScan.bdat", "w");io.flush() -- clears lastScan.bdat
            gpu.set(5, 7, "lastScan.bdat cleared: saved " .. fsize .. " KB")
            setStatus("READY", 0x00ff0e)
            CC.beep(700, .75)
        end)
        if not success then setStatus("ERROR; SHUT DOWN", 0xFF0000);needsRestart = true end
    elseif comparing then
        io.flush()
        local discrep = io.open("/geoinfo/discrep.bdat")
        local liq = string.len(io.read("*l"))
        fs:seek("set", (liq * x * (y - 2)))
        liq = io.read("*l")
        gpu.setForeground(0xffffff)
        for i,v in pairs(serial.unserialize(liq)) do -- values are stored from the bottom up
            if v > 0 then -- discrep; softer
                gpu.setBackground(0xff0000)
                if v >= 10 then
                    gpu.set(2, resY - i, ">")
                else
                    gpu.set(2, resY - i, tostring(v[0]))
                end
                if holo then
                    holo.clear()
                    for ZZ=v do
                        if ZZ > 48 then
                            holo.set(2, holoResY - i, ZZ - 48, 0)
                        else
                            holo.set(1, holoResY - i, ZZ, 0)
                        end
                    end
                end
            elseif v == 0 then -- no discrep
                gpu.setBackground(0x00ff00)
                gpu.set(2, resY - i, " ")
                if holo then
                    holo.clear()
                    holo.set(1, holoResY - i, 1, 1)
                end
            else -- discrep; harder
                gpu.setBackground(0x0000ff)
                if v <= -10 then
                    gpu.set(2, resY - i, ">")
                else
                    gpu.set(2, resY - i, tostring(-v[0]))
                end
                if holo then
                    holo.clear()
                    for ZZ=v do
                        if ZZ > 48 then
                            holo.set(2, holoResY - i, ZZ - 48, 0)
                        else
                            holo.set(1, holoResY - i, ZZ, 0)
                        end
                    end
                end
            end
        end
    end
until needsRestart
io.flush()
repeat
    CC.beep(1000, .5)
    os.sleep(.5)
    CC.beep(1200, .5)
    os.sleep(.5)
until nil
