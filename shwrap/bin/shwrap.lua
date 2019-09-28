package.loaded['mmgui'] = nil
local component = require("component")
local term = require("term")
local gpu = component.gpu
local gui = require("mmgui")
local thread = require("thread")
local event = require("event")

local prgName = "shwrap"
local version = "0.2" .. " (MMGUI Lib " .. gui.Version() .. ")"

local screenWidth, screenHeight = gpu.getResolution()

-- main panel
local panel

--
-- REACTORS BEGIN
--

local reactorPanel

-- reactor labels
local lblReactorPowerGen

-- cache
local reactorValueWidth
local reactorTwoValueWidth
local reactorsUpdateTimer

-- reactor grid controller - initialized by background service brgc (part of bigreactors script)
local grid_controller = require("brgc/grid_controller")


local lastEnergyProducedReactors
function updateReactorPowerGen(cur)
    if lastEnergyProducedReactors == cur then
        return false
    end
    local p = reactorPanel
    gui.setText(p, lblReactorPowerGen, string.format("%*.1f / %*.1f", reactorTwoValueWidth, reactorTwoValueWidth, cur))
end

function updateReactors()
    if reactorTwoValueWidth < 2 then
        return false
    end

    if grid_controller.isRunning() then
        local energyProducedReactors = grid_controller.getEnergyProductionRateReactors()
        updateReactorPowerGen(energyProducedReactors)
    end
end

function setupReactors()
    reactorPanel = gui.newFrame(panel, 1, 1, panel.width - 1, 8, "Reactors")

    local p = reactorPanel

    gui.newLabel(p, 2, 2, "Generated")

    lblReactorPowerGen = gui.newLabel(p, 10, 2, "")
    reactorValueWidth = p.width - 6 - 10 - 2
    reactorTwoValueWidth = (reactorValueWidth - 3 - 2) / 2

    gui.newLabel(p, p.width - 5, 2, "RF/t")

    reactorsUpdateTimer = event.timer(2, updateReactors, math.huge)
end

--
-- REACTORS END
--


-- setup main panel
function setupPanel()
    setupReactors()
end

function buttonExitCallback(guiID, id)
    local result = gui.getYesNo("", "Do you really want to exit?", "")
    if result == true then
        gui.exit()
    end
    gui.displayGui(guiID)
end

-- initial gui creation and screen setup
panel = gui.newGui(screenWidth - 36, 2, 37, screenHeight - 2, false, nil, 0x141512, 0xa0a0a0)
buttonExit = gui.newButton(panel, panel.width - 2, 0, "X", buttonExitCallback, 0x201010, 0xff2222)

setupPanel(panel)

gui.clearScreen()
gui.setTop(prgName .. " " .. version)

function guiThread()
    while true do
        gui.runGui(panel)
    end
end

-- detach thread
local detached_thread = thread.create(guiThread):detach()

-- set terminal window to dedicated screen space
term.window.width = screenWidth - 37
term.window.height = screenHeight - 2
term.window.dx = 0
term.window.dy = 1

-- we are done return to shell

