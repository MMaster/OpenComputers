local event = require("event")
local libGUI = require("libGUI")
local reactor_ctrl = require("brgc/reactor_ctrl")
local turbine_ctrl = require("brgc/turbine_ctrl")

local reactor_info_small = require("brgc/gui/reactor_info_small")
local turbine_info_small = require("brgc/gui/turbine_info_small")

local reactor_info_big = require("brgc/gui/reactor_info_big")
local turbine_info_big = require("brgc/gui/turbine_info_big")

local controller_info_big = require("brgc/gui/controller_info_big")

local tabframe = libGUI.newFrame("tabframe")
local list_r = libGUI.newFrame("list")
local list_t = libGUI.newFrame("list")
local list_c = libGUI.newFrame("list")
local grid_view = controller_info_big()

--

local function update_list()
	local reactors = {}
	local turbines = {}

	for _, reactor in pairs(reactor_ctrl.mReactors or {}) do
		table.insert(reactors, reactor)
	end
	for _, turbine in pairs(turbine_ctrl.mTurbines or {}) do
		table.insert(turbines, turbine)
	end

	table.sort(reactors, function(a,b) return a:getAddress() < b:getAddress() end)
	table.sort(turbines, function(a,b) return a:getAddress() < b:getAddress() end)

--	if #list_r.mChildren ~= #reactors then
		while #list_r.mChildren > 0 do
			list_r:removeChild(list_r.mChildren[1])
		end

		for _, reactor in pairs(reactors) do
			local rframe = reactor_info_small(reactor)
			function rframe:onTouch() tabframe:setFrameActive(reactor_info_big(reactor)) end
			list_r:addChild(rframe)
		end
--	end

--	if #list_t.mChildren ~= #turbines then
		while #list_t.mChildren > 0 do
			list_t:removeChild(list_t.mChildren[1])
		end

		for _, turbine in pairs(turbines) do
			local tframe = turbine_info_small(turbine)
			function tframe:onTouch() tabframe:setFrameActive(turbine_info_big(turbine)) end
			list_t:addChild(tframe)
		end
--	end

--	if #list_c.mChildren ~= #reactors+#turbines then
		while #list_c.mChildren > 0 do
			list_c:removeChild(list_c.mChildren[1])
		end

		list_c:addChild(libGUI.newFrame("label", "Reactors", "center"))
		for _, reactor in pairs(reactors) do
			local rframe = reactor_info_small(reactor)
			function rframe:onTouch() tabframe:setFrameActive(reactor_info_big(reactor)) end
			list_c:addChild(rframe)
		end
		list_c:addChild(libGUI.newFrame("label", "Turbines", "center"))
		for _, turbine in pairs(turbines) do
			local tframe = turbine_info_small(turbine)
			function tframe:onTouch() tabframe:setFrameActive(turbine_info_big(turbine)) end
			list_c:addChild(tframe)
		end
--	end

--	tabframe:onDraw()
end

local function update_list_callback()
	xpcall(update_list, function(...)
		libGUI.exit()
		io.stderr:write("[BRGCGUI] " .. debug.traceback( ... ) .. "\n")
	end)
	tabframe:onDraw(false)
end


local function onTerminate()
	event.ignore("brgc_reactor_added", update_list_callback)
	event.ignore("brgc_turbine_added", update_list_callback)
	event.ignore("libGUI_terminate", onTerminate)
end

--

libGUI.init()
libGUI.setRootFrame(tabframe)
libGUI.setOptimalResolutionByTier(0.5, 1)

update_list()

tabframe:addItem("Grid", nil, grid_view)
tabframe:addItem("Combined", nil, list_c)
if libGUI.getResolution() > 60 then
	tabframe:addItem("Reactors", nil, list_r)
	tabframe:addItem("Turbines", nil, list_t)
end
tabframe:addItem("Exit", libGUI.exit, nil)

tabframe:activateItem("Combined")

event.listen("brgc_reactor_added", update_list_callback)
event.listen("brgc_turbine_added", update_list_callback)
event.listen("libGUI_terminate", onTerminate)

libGUI.setRedrawInterval(1)
libGUI.runOrFork()