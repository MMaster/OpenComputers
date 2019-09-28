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
local reactorValueWidth = 17
local reactorTwoValueWidth = 6
local reactorsUpdateTimer

-- reactor grid controller - initialized by background service brgc (part of bigreactors script)
local grid_controller = require("brgc/grid_controller")


local lastEnergyProducedReactors = -1
function updateReactorPowerGen(cur)
    if lastEnergyProducedReactors == cur then
        return false
    end
    gui.setText(panel, lblReactorPowerGen, string.format("%*.1f / %*.1f", reactorTwoValueWidth, reactorTwoValueWidth, cur))
    lastEnergyProducedReactors = cur
end

function updateReactors()
    if reactorTwoValueWidth < 2 then
        return false
    end

    if grid_controller.isRunning() then
        local energyProducedReactors = grid_controller.getEnergyProductionRateReactors()
        updateReactorPowerGen(energyProducedReactors)
    else
        updateReactorPowerGen(0)
    end
end

function setupReactors()
    local x, y, w, h = 2, 1, panel.width - 3, 8
    reactorPanel = gui.newFrame(panel, x - 1, y - 1, w + 2, h + 2, "Reactors")

    -- line #1
    local lineY = y + 1
    gui.newLabel(panel, x + 1, lineY, "Generated")

    lblReactorPowerGen = gui.newLabel(panel, x + 10, lineY, "")
    reactorValueWidth = w - 6 - 10 - 2
    reactorTwoValueWidth = (reactorValueWidth - 3 - 2) / 2

    gui.newLabel(panel, x + w - 5, lineY, "RF/t")

    -- line #2
    lineY = y + 2

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
        event.cancel(reactorsUpdateTimer)
        gui.exit()
    end
    gui.displayGui(guiID)
end

function guiThread()
    -- initial gui creation and screen setup
    panel = gui.newGui(screenWidth - 36, 2, 37, screenHeight - 2, false, nil, 0x141512, 0xa0a0a0)
    buttonExit = gui.newButton(panel, panel.width - 2, -1, "X", buttonExitCallback, 0x201010, 0xff2222)

    setupPanel()

    gui.clearScreen()
    gui.setTop(prgName .. " " .. version)

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

