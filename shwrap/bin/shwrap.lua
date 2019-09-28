local component = require("component")
local gpu = component.gpu
local gui = require("mmgui")

local prgName = "shwrap"
local version = "0.1" .. "(MMGUI Lib " .. gui.Version() .. ")"

function exitButtonCallback(guiID, id)
  local result = gui.getYesNo("", "Do you really want to exit?", "")
  if result == true then
    gui.exit()
  end
  gui.displayGui(myGui)
end

local screenWidth, screenHeight = gpu.getResolution()

guiPanel = gui.newGui(screenWidth - 37, 2, 37, screenHeight - 1, false)

exitButton = gui.newButton(guiStatus, "right", 1, "X", exitButtonCallback, 0x201010)

gui.clearScreen()

gui.setTop(prgName .. " " .. version)

while true do
  gui.runGui(guiPanel)
end
