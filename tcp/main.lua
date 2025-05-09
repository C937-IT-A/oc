local componentry = require("component")
local modem = componentry.modem or error("Brother.")
local gpu = componentry.gpu or error("Brother 2: Electric Boogaloo")

local term = require("term")
local comp = require("computer")

local port = 650
modem.open(port)

local resX, resY = gpu.getResolution()

term.clear()

gpu.setBackground(0xAAAAFF)
gpu.fill(0, 0, resX, resY, " ")
gpu.setBackground(0xffffff)
gpu.fill(0, 0, resX, 1, " ")

gpu.setForeground(0x000000)
gpu.set(0,0,"TCP v1")

local authorized_clients = {"address one", "address two"}
local auth_cli_names = {"shithead 1", "shithead 2"}

coroutine.resume(coroutine.create(function()
    repeat
        local _, _, from, Tport, _, message = require("event").pull("modem_message")
        if Tport == port then
            if message == "TCP_SYN" then
                if table.find(authorized_clients, from) then modem.send(from, port, "TCP_SYN_ACK") end
            end
        end
    until nil
end))

gpu.setBackground(0x808080)
gpu.setForeground(0xFF0000)
gpu.set(resX-1, 0, "X")

local function updateStatus()
    local oBCol = gpu.getBackground()
    local oFCol  = gpu.getForeground()
    gpu.setForeground(0x000000)
    gpu.setBackground(0xFFFF00)
    gpu.set(resX,0,"+")
    gpu.setBackground(0xFF0000)
    local connected = 0
    coroutine.resume(corTO)
    for i,v in pairs(authorized_clients) do
        modem.send(v, port, "TCP_SYN")
        local _, _, from, Tport, _, message = require("event").pull("modem_message")
        if v == from and Tport == port and message == "TCP_SYN_ACK" then
            -- connect acknowledged
            connected = connected + 1
        end
    end
    if connected == 0 then
        gpu.set(resX,0,"X")
        gpu.setForeground(oFCol)
        gpu.setBackground(oBCol)
        return
    end
    gpu.setBackground(0x00FF00)
    gpu.set(resX,0,tostring(connected))
    gpu.setForeground(oFCol)
    gpu.setBackground(oBCol)
end

updateStatus()

coroutine.resume(coroutine.create(function()
    repeat
        local _,x,y = require("event").pull("touch")
        if x == resX and y == 0 then
            updateStatus()
        elseif x == resX - 1 and y == 0 then
            for i,v in pairs(authorized_clients) do
                modem.send(v, port, "TCP_FIN")
                term.clear()
                error("User exit") -- possible breakpoint; may terminate coroutine and not main thread
            end
        end
    until nil
end))

repeat
    local _, _, from, Tport, _, message = require("event").pull("modem_message")
    if port == Tport then
        if table.find(authorized_clients, from) then
            if message = "TCP_FIN" then
                -- modem.send(from, port, "TCP_FIN_ACK") -- could be useful in a mutual-close situation
                updateStatus()
            elseif string.sub(message,0,7) == "TCP_UMSG" then
                message = string.sub(message, 8, -1)
                -- handle messages
            end
        end
    end
until nil