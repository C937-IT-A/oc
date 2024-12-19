local config = require("../../config.lua")
local fs = require("filesystem")
local serial = require("serialization")

local function initinp()
    print("Please select a mode from the following: scan, check, set or type help for a description of modes.\n > ")
    local i1 = string.lower(io.read("*l"))

    if i1 == "help" then
        print("...scan | creates a new geoscan\n..check | checks for discrepancies between latest geoscan and status-quo\n....set | sets latest geoscan as status-quo")
        initinp()
    elseif i1 == "scan" then
        --TODO
    elseif i1 == "check" then
        local currentX = 1
        local currentZ = 1
        local lS = fs.open(config["libraryPath"] .. "/latestScan.data", "r") -- gets file for latestScan, opens with read permission
        local sQ = fs.open(config["libraryPath"] .. "/statusQuo.data", "r") -- gets file for statusQuo, opens with read permission

        if fs.exists(config["libraryPath"] .. "/discrepancies.data") then
            fs.remove(config["libraryPath"] .. "/discrepancies.data")
        end
        local dsc = fs.open(config["libraryPath"] .. "/discrepancies.data", "a") -- gets file for discrepancy notation, opens with append permission
        local dscLocal = {}
        
        for i in io.lines(config["libraryPath"] .. "/latestScan.data") do
            local lineLS = lS:read("*l")
            local lineSQ = sQ:read("*l")
            local newLine = {}
            for v in #serial.unserialize(lineLS) do -- NOTE: doesn't work if lineLS and lineSQ are tables with different number of indices.
                                                    -- be sure to clear those two files when column size is changed
                newline[v] = serial.unserialize(lineSQ)[v] - serial.unserialize(lineLS)[v]
            end
            if serial.serialize(newLine) ~= "{" .. string.rep("0.0", #serial.unserialize(lineLS)) .. "}" then
                dsc:write(serial.serialize(newLine) .. "\n")
                table.insert(dscLocal, serial.serialize(newLine))
            else
                dsc:write("nil\n")
                table.insert(dscLocal, 0)
            end
        end
        for i in dscLocal do
            if dscLocal[i] ~= 0 then
                print("DISCREPANCY | " .. serial.serialize(dscLocal[i]) .. "X" .. currentX .. " Z" .. currentZ)
            end
            currentX += 1
            if currentX > config["X"] then
                currentX = 1
                currentZ += 1
            end
        end
        dscLocal = nil
    elseif i1 == "set" then
        if fs.exists(config["libraryPath"] .. "/statusQuo.data") and fs.exists(config["libraryPath"] .. "/latestScan.data") then
            local lS = fs.open(config["libraryPath"] .. "/latestScan.data", "r") -- gets file for latestScan, opens with read permission
            local sQ = fs.open(config["libraryPath"] .. "/statusQuo.data", "w") -- gets file for statusQuo, opens with write permission - CLEARS CURRENT SQ!

            sQ:write(lS:read("*a")) -- NOTE: might cause RAM allocation issues - depending on
                                    -- scan file size, this could be a HUGE request. would
                                    -- prefer to iterate over a loop for the lines of lS,
                                    -- appending to sQ by iter. definite TODO.
        else
            error("Unable to find one or both of two needed files (statusQuo, latestScan data files).\nTry creating them manually with commands edit " .. config["libraryPath"] .. "/statusQuo.data and edit " .. config["libraryPath"] .. "/latestScan.data.\nBe sure to save, even if the files are empty.")
        end
    end
end