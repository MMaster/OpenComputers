package.loaded['mmgui'] = nil
local component = require("component")
local term = require("term")
local gpu = component.gpu
local gui = require("mmgui")
local thread = require("thread")
local stringutils = require("stringutils")

local prgName = "shwrap"
local version = "0.3" .. " (MMGUI Lib " .. gui.Version() .. ") by MMaster"

local screenWidth, screenHeight = gpu.getResolution()

local srep = string.rep
-- pad the left side
lpad =
    function (s, l, c)
        local res = srep(c or ' ', l - #s) .. s

        return res, res ~= s
    end

-- pad the right side
rpad =
    function (s, l, c)
        local res = s .. srep(c or ' ', l - #s)

        return res, res ~= s
    end

-- main panel
local panel

--
-- REACTORS BEGIN
--

-- cache
local reactorValueWidth = 17
local reactorTwoValueWidth = 7
local reactorUpdateTime = 3.0
local reactorUpdateWait = 1.0

-- reactor grid controller - initialized by background service brgc (part of bigreactors script)
local grid_controller = require("brgc/grid_controller")

local lastValues = {}

function updateLblValueFloat(lbl, cur)
    if lastValues[lbl] ~= nil and lastValues[lbl] == cur then
        return false
    end

    gui.setText(panel, lbl, lpad(stringutils.formatNumber(cur, "", 2), reactorValueWidth, ' '))
    lastValues[lbl] = cur
end

function updateReactors()
    if reactorTwoValueWidth < 2 then
        return false
    end

    if grid_controller.isRunning() then
		local energyStoredMax = grid_controller.getMaxEnergyStored()
		local energyStoredCurrent = grid_controller.getEnergyStored()
		local energyProducedReactors = grid_controller.getEnergyProductionRateReactors()
		local energyProducedTurbines = grid_controller.getEnergyProductionRateTurbines()
		local energyProducedTotal = grid_controller.getEnergyProductionRate()
		local energyProductionReactorsMax = grid_controller.getEnergyProductionRateReactorsMax()
		local energyProductionTurbinesMax = grid_controller.getEnergyProductionRateTurbinesMax()
		local energyProductionTotalMax = energyProductionReactorsMax + energyProductionTurbinesMax
		local energyProductionTotalOpt = grid_controller.getOptEnergyProduction()
		local energyProductionReactorOpt = energyProductionTotalOpt - energyProductionTurbinesMax

        updateLblValueFloat(lblReactorGen,      energyProducedReactors)
        updateLblValueFloat(lblReactorGenOpt,   energyProductionReactorOpt)
        updateLblValueFloat(lblReactorGenMax,   energyProductionReactorsMax)

        gui.setMax(panel, pbReactorOutput, energyProductionReactorsMax)
        gui.setValue(panel, pbReactorOutput, energyProducedReactors)

        updateLblValueFloat(lblReactorNeed,     grid_controller.getEnergyExtractionRate())
        updateLblValueFloat(lblReactorNeedAvg,  grid_controller.getEnergyExtractionRateWeighted())

        updateLblValueFloat(lblReactorStored,   energyStoredCurrent)
        updateLblValueFloat(lblReactorStoredMax,energyStoredMax)

        gui.setMax(panel, pbReactorStored, energyStoredMax)
        gui.setValue(panel, pbReactorStored, energyStoredCurrent)
    else
        updateReactorGen(0)
    end
end

local colorLabelFg = 0x90908A
local colorValueFg = 0x66D9EF

function setupLabelsValue(x, y, w, h, name, unit)
    gui.newLabel(panel, x + 1, y, name, nil, colorLabelFg)
    local lblValue = gui.newLabel(panel, x + 12 + (4-#unit), y, "", nil, colorValueFg)
    gui.newLabel(panel, x + w - #unit - 1, y, unit, nil, colorValueFg)
    return lblValue
end

function setupReactors()
    local x, y, w, h = 2, 1, panel.width - 3, 13
    reactorPanel = gui.newFrame(panel, x - 1, y - 1, w + 2, h + 2, "Reactors")

    reactorValueWidth = w - 6 - 11
    reactorTwoValueWidth = (reactorValueWidth - 3) // 2

    lblReactorGenOpt =     setupLabelsValue(x, y + 1, w, h, "Opt Output", "RF/t")
    lblReactorGen =        setupLabelsValue(x, y + 2, w, h, "Cur Output", "RF/t")
    lblReactorGenMax =     setupLabelsValue(x, y + 3, w, h, "Max Output", "RF/t")
    pbReactorOutput = gui.newProgress(panel, x + 1, y + 4, w - 2, 100.0, 0.0, nil, true)

    lblReactorNeed =       setupLabelsValue(x, y + 6, w, h, "Cur Need",   "RF/t")
    lblReactorNeedAvg =    setupLabelsValue(x, y + 7, w, h, "Avg Need",   "RF/t")

    lblReactorStored =     setupLabelsValue(x, y + 9, w, h, "Cur Stored", "RF")
    lblReactorStoredMax =  setupLabelsValue(x, y +10, w, h, "Max Stored", "RF")
    pbReactorStored = gui.newProgress(panel, x + 1, y + 11, w - 2, 100.0, 0.0, nil, true)
end

--
-- REACTORS END
--

-- tick every 0.1s or on event
function guiTick()
    reactorUpdateWait = reactorUpdateWait - 0.1
    if reactorUpdateWait < 0 then
        updateReactors()
        reactorUpdateWait = reactorUpdateTime
    end
end

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

function guiThread()
    -- initial gui creation and screen setup
    panel = gui.newGui(screenWidth - 36, 2, 37, screenHeight - 2, false, nil, 0x141512, 0xa0a0a0)
    buttonExit = gui.newButton(panel, panel.width - 2, -1, "X", buttonExitCallback, 0x201010, 0xff2222)

    setupPanel()

    gui.clearScreen()
    gui.setTop(prgName .. " " .. version)

    while true do
        guiTick()
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

