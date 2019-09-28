package.loaded['mmgui'] = nil
local component = require("component")
local term = require("term")
local gpu = component.gpu
local gui = require("mmgui")

local prgName = "shwrap"
local version = "0.1" .. " (MMGUI Lib " .. gui.Version() .. ")"

function buttonExitCallback(guiID, id)
  local result = gui.getYesNo("", "Do you really want to exit?", "")
  if result == true then
    gui.exit()
  end
  gui.displayGui(myGui)
end

local screenWidth, screenHeight = gpu.getResolution()

guiPanel = gui.newGui(screenWidth - 36, 2, 37, screenHeight - 1, false, nil, 0x141512, 0xa0a0a0)

buttonExit = gui.newButton(guiPanel, guiPanel.width - 1, 0, "X", buttonExitCallback, 0x201010, 0xff2222)

gui.clearScreen()
gui.setTop(prgName .. " " .. version)

while true do
  gui.runGui(guiPanel)
end
