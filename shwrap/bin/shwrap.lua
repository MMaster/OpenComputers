package.loaded['mmgui'] = nil
local component = require("component")
local term = require("term")
local gpu = component.gpu
local gui = require("mmgui")

local prgName = "shwrap"
local version = "0.1" .. " (MMGUI Lib " .. gui.Version() .. ")"

local guiPanel

function buttonExitCallback(guiID, id)
  local result = gui.getYesNo("", "Do you really want to exit?", "")
  if result == true then
    term.window.width = screenWidth
    term.window.height = screenHeight
    term.window.dx = 0
    term.window.dy = 0
    gui.exit()
  end
  gui.displayGui(guiID)
end

local screenWidth, screenHeight = gpu.getResolution()

guiPanel = gui.newGui(screenWidth - 36, 2, 37, screenHeight - 2, false, nil, 0x141512, 0xa0a0a0)

buttonExit = gui.newButton(guiPanel, guiPanel.width - 1, 0, "X", buttonExitCallback, 0x201010, 0xff2222)

gui.clearScreen()
gui.setTop(prgName .. " " .. version)

function guiThread()
  while true do
      gui.runGui(guiPanel)
  end
end

local detached_thread = thread.create(guiThread):detach()

term.window.width = screenWidth - 37
term.window.height = screenHeight - 2
term.window.dx = 0
term.window.dy = 1

