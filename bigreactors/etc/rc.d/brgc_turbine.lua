--[[
Init script for Big Reactors Grid Control - Turbine Controller for OpenComputers by MMaster
Website: http://tenyx.de/brgc/
--]]
local shell = require("shell")
local service = "turbine"

function start()
    shell.execute("/usr/bin/brgcctrl service " .. service .. " start")
end

function stop()
    shell.execute("/usr/bin/brgcctrl service " .. service .. " stop")
end

function restart()
    shell.execute("/usr/bin/brgcctrl service " .. service .. " restart")
end

function status()
    shell.execute("/usr/bin/brgcctrl service " .. service .. " status")
end

