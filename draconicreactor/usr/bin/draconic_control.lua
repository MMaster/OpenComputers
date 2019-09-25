--[[
Draconic Control v1.3 for OpenComputers by XyFreak
Website: http://tenyx.de/draconic_control/
--]]

local draconic_control = require("draconic_control");
local event = require("event");
local shell = require("shell");

local args = shell.parse(...);
if #args == 0 then
	io.write("Usage: draconic_control <start|stop|shutdown>");
elseif args[1] == "start" then
	if draconic_control.isRunning() then
		io.write("Draconic control service already running.");
	else
		draconic_control.loadConfig();
		draconic_control.start();
		io.write("Draconic control service started.");
	end
elseif args[1] == "stop" then
	if not draconic_control.isRunning() then
		io.write("Draconic control service not running.");
	else
		draconic_control.stop();
		io.write("Draconic control service stopped.");
	end
elseif args[1] == "status" then
	if draconic_control.isRunning() then
		io.write("Draconic Control is running.");
	else
		io.write("Draconic Control is not running.");
	end
elseif args[1] == "shutdown" then
	draconic_control.shutdown();
elseif args[1] == "runOnce" then
	draconic_control.timer();
else
	io.stderr:write("Unknown command: " .. args[1]);
end