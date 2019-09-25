--[[
Init script for Draconic Control for OpenComputers by XyFreak
Website: http://tenyx.de/draconic_control/
--]]

local draconic_control = require("draconic_control");

function start()
	if draconic_control.isRunning() then
		io.stderr:write("Draconic control service already running.");
	else
		draconic_control.loadConfig();
		draconic_control.start();
	end
end

function stop()
	if not draconic_control.isRunning() then
		io.stderr:write("Draconic control service not running.");
	else
		draconic_control.stop();
	end
end

function restart()
	if draconic_control.isRunning() then
		draconic_control.stop();
	end
	draconic_control.loadConfig();
	draconic_control.start();
end

function status()
	if draconic_control.isRunning() then
		io.write("Draconic Control is running.");
	else
		io.write("Draconic Control is not running.");
	end
end