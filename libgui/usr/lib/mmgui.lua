local versionMajor = "2"
local versionMinor = "2"

--[[
    Original by Dustpuppy
    Modified & Extended by MMaster

    Gui functions
    Needs a screen tier 2 or tier 3
    All x, y coordinates are relative to the gui, not the screen
------------------------------------------------------------------------
gui.Version()
  returns the version of the library

gui.clearScreen()
  clears the screen to background color, sets top and back line 

gui.setTop(text)
  prints a text centered on the top line

gui.setBottom(text)
  prints a text centered on the bottom line

gui.newGui(x, y, w, h, frame, text, bg, fg)
  setup a new gui 
  frame = true/false
  needs: x, y, w, h, frame

gui.displayGui(guiID)
  displays the whole gui and his widgets
  needs to be called before handling the gui
  first call of runGui will do it

gui.newLabel(guiID, x, y, text, bg, fg)
  register a new label to gui
  returns id of the label
  needs: guiID, x, y, text)

gui.newCheckbox(guiID, x, y, status)
  register a new checkbox to the gui
  returns id of the checkbox
  status can be true or false

gui.newRadio(guiID, x, y)
  registers a new radio button
  returns id of the radio button
  a gui can have only one set of radio buttons

gui.newButton(guiID, x, y, text, func, bg, fg, clickedBg, clickedFg, disabledBg, disabledFg)
  register a new button to gui
  returns id of the button
  func will be called if button is clicked with func(guiID, buttonID)
  needs: guiID, x, y, text

gui.newText(guiID, x, y, lenght, text, func)
  register a new text input to gui
  returns id of the text input
  func will be called if input is finished and enter is pressed with func(guiID, textID, text)
  needs: guiID, x, y, lenght, text

gui.newProgress(guiID, x, y, lenght, maxValue, value, func, number)
  register a new progress bar to the gui
  returns the id of the progress bar
  func will be called if value reached max value with func(guiID, progressID)
  if number is given, it displays a % value in the middle on top of the bar
  Progressbar will be paused if an text input is active
  needs: guiID, x, y, lenght, maxValue, value

gui.newVProgress(guiID, x, y, lenght, maxValue, value, func, direction)
  register a new vertical progress bar to the gui
  returns the id of the progress bar
  func will be called if value reached max value with func(guiID, progressID)
  If direction is 0 or not given, the bar runs from top to bottom.
  If direction is 1 then bar runs from bottom to top
  Progressbar will be paused if an text input is active
  needs: guiID, x, y, lenght, maxValue, value

gui.newList(guiID, x, y, width, height, tab, func, text)
  register a new selection list to the gui
  tab = table with entries
  returns the id of the list
  func will be called, if scrolling in list, or entry is selected with func(guiID, listID, selectedID, selectedText)
  needs: guiID, x, y, width, height, tab

gui.newFrame(guiID, x, y, width, height, text, bg, fg)
  register a new frame to the gui
  needs: guiID, x, y, width, height

gui.newHLine(guiID, x, y, width)
  register a new horizontal line
  
gui.getCheckboxStatus(guiID, widgetID)
  returns the status of the checkbox (true = enabled or false = disabled)

gui.getSelected(guiID, listID)
  returns the number and the text of the selected entrie in a list

gui.setMax(guiID, progressID, maxValue)
  set the maximum value of a progress bar

gui.setValue(guiID, progressID, value)
  set the value of a progress bar

gui.resetProgress(guiID, progressID)
  resets a progress bar to 0, so it can be used again

gui.setText(guiID, widgetID, text)
  sets text of an element 
  can be used on label, text inputs and lists

gui.getText(guiID, widgetID)
  returns text of an input field
  can be used on label, text inputs and lists

gui.setEnable(guiID, widgetID, state)
  enable or disable element
  state = true/false

gui.setVisible(guiID, widgetID, state)
  shows or hides an element
  state = true/false
  will also enable or disable the element. setEnable needs to be called if state is set back to true

gui.clearList(guiID, listID)
  clears a list to use it again

gui.insertList(guiID, listID, value)
  insert an entry into a list

gui.getRadio(guiID)
  resturns id of the selected radio button or -1 if none is selected

gui.runGui(guiID)
  needs to be called in a loop to run gui actions
  it's possible to setup guis and run each seperated.

gui.processEvent(guiID, isAuthorizedFunc, e, x, y, button, player)
  processes event collected somewhere else
  runGui uses it like this:

  function gui.runGui(guiID, isAuthorizedFunc)
    if displayed == false then
      displayed = true
      gui.displayGui(guiID)
    end
    local e, _, x, y, button, player = event.pull(0.1, "touch")
    if e == nil then
      return false
    end
    gui.processEvent(guiID, isAuthorizedFunc, e, x, y, button, player)
  end


gui.showError(msg1, msg2, msg3)
  displays a centered error message, with exit program as button

gui.showMsg(msg1, msg2, msg3)
  displays a message box

gui.getYesNo(msg1, msg2, msg3)
  displays a yes-No question
  returns true or false

gui.exit()
  clears the screen to black and exits the program

---------------------------------------------------------------

Example:

local component = require("component")
local gpu = component.gpu
local gui = require("gui")

local prgName = "Test"
local version = gui.Version()

function buttonCallback(guiID, id)
  local result = gui.getYesNo("", "Do you really want to exit?", "")
  if result == true then
    gui.exit()
  end
  gui.displayGui(myGui)
end

myGui = gui.newGui(2, 2, 78, 23, true)
button = gui.newButton(myGui, "center", 21, "exit", buttonCallback)

gui.clearScreen()
gui.setTop(prgName .. " " .. version)
while true do
  gui.runGui(myGui)
end

]]


local component = require("component")
local gpu = component.gpu
local event = require("event")
local ser = require("serialization")
local computer = require("computer")

local gui = {}

local colorScreenBackground = 0x000000
local colorScreenForeground = 0x7F7F7F
local colorTopLineBackground = 0x131411
local colorTopLineForeground = 0x90908A
local colorBottomLineBackground = 0x131411
local colorBottomLineForeground = 0x90908A
local colorFrameBackground = 0x272822
local colorFrameForeground = 0x75715E
local colorButtonBackground = 0x39392F
local colorButtonForeground = 0xF8F8F2
local colorButtonClickedBackground = 0x272822
local colorButtonClickedForeground = 0xFFFFFF
local colorButtonDisabledBackground = 0x131411
local colorButtonDisabledForeground = 0x888882
local colorTextBackground = 0x131411
local colorTextForeground = 0xE6DB74
local colorInputBackground = 0x131411
local colorInputForeground = 0xF8F8F2
local colorProgressBackground = 0x39392F
local colorProgressForeground = 0xA6E22E
local colorProgressNumberForeground = 0x000000
local colorListBackground = 0x131411
local colorListForeground = 0xE6DB74
local colorListActiveBackground = 0x39392F
local colorListActiveForeground = 0xF8F8F2
local colorListDisabledBackground = 0x131411
local colorListDisabledForeground = 0x90908A
local colorVProgressBackground = colorProgressBackground
local colorVProgressForeground = colorProgressForeground
local colorVSliderBackground = 0x131411
local colorVSliderForeground = 0x66D9EF
local colorChartBackground = 0x131411
local colorChartForeground = 0xF92672

local screenWidth, screenHeight = gpu.getResolution()

function gui.Version()
  return versionMajor .. "." .. versionMinor, versionMajor, versionMinor
end

function gui.checkVersion(major, minor)
  local ret = true
  if major < tonumber(versionMajor) then
    ret = false
  else
    if minor < tonumber(versionMinor) then
      ret = false
    end
  end
  return ret
end

-- displays the gui frame, if set or just clears the display area
local function _displayFrame(gui)
  gpu.setBackground(gui.bg)
  gpu.setForeground(gui.fg)
  gpu.fill(gui.x, gui.y, gui.width, gui.height, " ")
  if gui.frame == true then
    gpu.fill(gui.x, gui.y, 1, gui.height, "¦")
    gpu.fill(gui.x + gui.width - 1, gui.y, 1, gui.height, "¦")
    gpu.fill(gui.x, gui.y, gui.width, 1, "-")
    gpu.fill(gui.x, gui.y + gui.height - 1, gui.width, 1, "-")
    gpu.set(gui.x, gui.y, "+")
    gpu.set(gui.x + gui.width - 1 , gui.y, "+")
    gpu.set(gui.x, gui.y + gui.height - 1 , "+")
    gpu.set(gui.x + gui.width - 1 , gui.y + gui.height - 1, "+")
    if gui.text then
      gpu.set(gui.x + math.floor((gui.width/2)) - math.floor((string.len(gui.text)/2)), gui.y, gui.text)
    end
  end
end

-- displays a frame
local function _displayAFrame(guiID, frameID)
  gpu.setBackground(guiID.bg)
  gpu.setForeground(guiID.fg)
  gpu.fill(guiID[frameID].x, guiID[frameID].y, 1, guiID[frameID].height, "¦")
  gpu.fill(guiID[frameID].x + guiID[frameID].width - 1, guiID[frameID].y, 1, guiID[frameID].height, "¦")
  gpu.fill(guiID[frameID].x, guiID[frameID].y, guiID[frameID].width, 1, "-")
  gpu.fill(guiID[frameID].x, guiID[frameID].y + guiID[frameID].height - 1, guiID[frameID].width, 1, "-")
  gpu.set(guiID[frameID].x, guiID[frameID].y, "+")
  gpu.set(guiID[frameID].x + guiID[frameID].width - 1 , guiID[frameID].y, "+")
  gpu.set(guiID[frameID].x, guiID[frameID].y + guiID[frameID].height - 1 , "+")
  gpu.set(guiID[frameID].x + guiID[frameID].width - 1 , guiID[frameID].y + guiID[frameID].height - 1, "+")
  if guiID[frameID].text then
    gpu.set(guiID[frameID].x + math.floor((guiID[frameID].width/2)) - math.floor((string.len(guiID[frameID].text)/2)+1), guiID[frameID].y, " " .. guiID[frameID].text .. " ")
  end
end

--display a horizontal line
local function _displayHLine(guiID, lineID)
  gpu.setBackground(guiID.bg)
  gpu.setForeground(guiID.fg)
  gpu.fill(guiID[lineID].x, guiID[lineID].y, guiID[lineID].width, 1, "-")
end

-- displays a checkbox
local function _displayCheckbox(guiID, checkboxID)
  if guiID[checkboxID].visible == true then
    gpu.setBackground(guiID.bg)
    gpu.setForeground(guiID.fg)
    local x = 0
    x =guiID.x + guiID[checkboxID].x
    if guiID[checkboxID].status == true then
      gpu.set(x, guiID[checkboxID].y, "[v]")
    else
      gpu.set(x, guiID[checkboxID].y, "[ ]")
    end
  end
end

-- displays a radio button
local function _displayRadio(guiID, radioID)
  if guiID[radioID].visible == true then
    gpu.setBackground(guiID.bg)
    gpu.setForeground(guiID.fg)
    local x = 0
    x =guiID.x + guiID[radioID].x
    if guiID[radioID].status == true then
      gpu.set(x, guiID[radioID].y, "(x)")
    else
      gpu.set(x, guiID[radioID].y, "( )")
    end
  end
end

-- displays a label
local function _displayLabel(guiID, labelID)
  if guiID[labelID].visible == true then
    gpu.setBackground(guiID[labelID].bg)
    gpu.setForeground(guiID[labelID].fg)
    local x = 0
    if guiID[labelID].x == "center" then
      x = guiID.x + math.floor((guiID.width / 2)) - math.floor((string.len(guiID[labelID].text)) / 2)
    else
      x =guiID.x + guiID[labelID].x
    end
    gpu.set(x, guiID[labelID].y, guiID[labelID].text)
  end
end

-- displays a button
local function _displayButton(guiID, buttonID)
  if guiID[buttonID].visible == true then
    if guiID[buttonID].active == true then
      if guiID[buttonID].clickBg then
        gpu.setBackground(guiID[buttonID].clickBg)
      else
        gpu.setBackground(colorButtonClickedBackground)
      end
      if guiID[buttonID].clickFg then
        gpu.setForeground(guiID[buttonID].clickFg)
      else
	      gpu.setForeground(colorButtonClickedForeground)
      end
    elseif guiID[buttonID].enabled == false then
			if guiID[buttonID].disabledBg then
				gpu.setBackground(guiID[buttonID].disabledBg)
			else
        gpu.setBackground(colorButtonDisabledBackground)
			end
			if guiID[buttonID].disabledFg then
				gpu.setForeground(guiID[buttonID].disabledFg)
			else
        gpu.setForeground(colorButtonDisabledForeground)
			end
    else
			if guiID[buttonID].bg then
				gpu.setBackground(guiID[buttonID].bg)
			else
        gpu.setBackground(colorButtonBackground)
			end
			if guiID[buttonID].fg then
				gpu.setForeground(guiID[buttonID].fg)
			else
        gpu.setForeground(colorButtonForeground)
			end
    end
    local x = 0
    if guiID[buttonID].x == "center" then
      x = guiID.x + math.floor((guiID.width / 2)) - math.floor((guiID[buttonID].lenght / 2))
    else
      x = guiID.x + guiID[buttonID].x
    end
    gpu.fill(x, guiID[buttonID].y, guiID[buttonID].lenght, 1, " ")
    gpu.set(x, guiID[buttonID].y, guiID[buttonID].text)
  end
end

-- displays a text
local function _displayText(guiID, textID)
  if guiID[textID].visible == true then
    gpu.setBackground(colorTextBackground)
    gpu.setForeground(colorTextForeground)
    local x = 0
    if guiID[textID].x == "center" then
      x = guiID.x + math.floor((guiID.width / 2)) - math.floor((guiID[textID].lenght) / 2)
    else
      x = guiID.x + guiID[textID].x
    end
    gpu.fill(x, guiID[textID].y , guiID[textID].lenght, 1, " ")
    gpu.set(x, guiID[textID].y, string.sub(guiID[textID].text, 1, guiID[textID].lenght))
  end
end

-- displays a vertical slider
local function _displayVslider(guiID, sliderID)
  if guiID[sliderID].visible == true then
    gpu.setBackground(colorVSliderBackground)
    gpu.setForeground(colorVSliderForeground)
    local x = 0
    x = guiID.x + guiID[sliderID].x
    gpu.fill(x, guiID[sliderID].y , guiID[sliderID].lenght + 2, 1, " ")
    gpu.setBackground(colorButtonBackground)
    gpu.setForeground(colorButtonForeground)
    gpu.set(x, guiID[sliderID].y, "-")
    gpu.set(x + guiID[sliderID].lenght + 1, guiID[sliderID].y, "+")
  end
end

-- displays a progress bar
local function _displayProgress(guiID, progressID)
  if guiID[progressID].visible == true then
    gpu.setBackground(colorProgressForeground)
    gpu.setForeground(colorProgressBackground)
    local x = 0

    local proz = math.floor(100 / guiID[progressID].max * guiID[progressID].value)
    if proz > 100 then
      proz = 100
      if guiID[progressID].finished == false and guiID[progressID].func then
        guiID[progressID].func(guiID, progressID)
      end
      guiID[progressID].finished = true
    end

    local length = guiID[progressID].lenght
    if guiID[progressID].displayNumber == true then
        length = length - 4
    end
    if guiID[progressID].x == "center" then
      x = guiID.x + math.floor((guiID.width / 2)) - math.floor(length / 2)
    else
      x = guiID.x + guiID[progressID].x
    end
    local pos = math.floor(length / 100 * proz)
    gpu.fill(x, guiID[progressID].y , pos, 1, " ")
    gpu.setBackground(colorProgressBackground)
    gpu.setForeground(colorProgressForeground)
    gpu.fill(x + pos, guiID[progressID].y, length - pos, 1, " ")
    gpu.setBackground(guiID.bg)
    gpu.setForeground(guiID.fg)
    if guiID[progressID].displayNumber == true then
      -- gpu.fill(x, guiID[progressID].y - 1, guiID[progressID].lenght, 1, " ")
      gpu.set(x + guiID[progressID].lenght - #("" .. proz) - 1, guiID[progressID].y, proz .. "%")
    end
  end
end

-- displays a vertical progress bar
local function _displayVProgress(guiID, progressID)
  if guiID[progressID].visible == true then
    local x = 0
    if guiID[progressID].x == "center" then
      x = guiID.x + math.floor((guiID.width / 2)) - math.floor((guiID[progressID].lenght) / 2)
    else
      x = guiID.x + guiID[progressID].x
    end
    local proz = math.floor(100 / guiID[progressID].max * guiID[progressID].value)
    if proz > 100 then
      proz = 100
      if guiID[progressID].finished == false and guiID[progressID].func then
	guiID[progressID].func(guiID, progressID)
      end
      guiID[progressID].finished = true
    end
    local pos = math.floor(guiID[progressID].lenght / 100 * proz)
    for i = 1, guiID[progressID].width do
      if guiID[progressID].direction == 0 then
	gpu.setBackground(colorProgressForeground)
	gpu.setForeground(colorProgressBackground)
	gpu.fill(x+i-1, guiID[progressID].y , 1, pos, " ")
	gpu.setBackground(colorProgressBackground)
	gpu.setForeground(colorProgressForeground)
	gpu.fill(x+i-1, guiID[progressID].y + pos, 1, guiID[progressID].lenght - pos, " ")
      end
      if guiID[progressID].direction == 1 then
	gpu.setBackground(colorProgressBackground)
	gpu.setForeground(colorProgressForeground)
	gpu.fill(x+i-1, guiID[progressID].y, 1, guiID[progressID].lenght, " ")
	gpu.setBackground(colorProgressForeground)
	gpu.setForeground(colorProgressBackground)
	gpu.fill(x+i-1, guiID[progressID].y + guiID[progressID].lenght - pos , 1, pos, " ")
      end
    end
  end
end

-- display list
local function _displayList(guiID, listID)
  if guiID[listID].visible == true then
    if guiID[listID].enabled == true then
      gpu.setBackground(colorListBackground)
      gpu.setForeground(colorListForeground)
    else
      gpu.setBackground(colorListDisabledBackground)
      gpu.setForeground(colorListDisabledForeground)
    end
    gpu.fill(guiID[listID].x, guiID[listID].y, guiID[listID].width, guiID[listID].height, " ")
    gpu.fill(guiID[listID].x, guiID[listID].y, guiID[listID].width, 1, "-")
    if guiID[listID].text then
      gpu.set( guiID[listID].x + (guiID[listID].width/2) - (string.len(guiID[listID].text)/2), guiID[listID].y, "¦" .. guiID[listID].text .. "?")
    end
    if guiID[listID].active + guiID[listID].height - 3 > #guiID[listID].entries then
      l = #guiID[listID].entries
    else
      l = guiID[listID].active + guiID[listID].height - 3
    end
    gpu.fill(guiID[listID].x, guiID[listID].y +guiID[listID].height - 1, guiID[listID].width, 1, "-")
    gpu.set(guiID[listID].x, guiID[listID].y + guiID[listID].height - 1, "[<]")
    gpu.set(guiID[listID].x + guiID[listID].width - 3, guiID[listID].y + guiID[listID].height - 1, "[>]")
    for v = guiID[listID].active, l  do
      if v == guiID[listID].selected then
	gpu.setBackground(colorListActiveBackground)
	gpu.setForeground(colorListActiveForeground)
      else
	if guiID[listID].enabled == true then
	  gpu.setBackground(colorListBackground)
	  gpu.setForeground(colorListForeground)
	else
	  gpu.setBackground(colorListDisabledBackground)
	  gpu.setForeground(colorListDisabledForeground)
	end
      end
      gpu.fill(guiID[listID].x, guiID[listID].y + v - guiID[listID].active + 1, guiID[listID].width, 1 , " ")
      gpu.set(guiID[listID].x + 1, guiID[listID].y + v - guiID[listID].active + 1, guiID[listID].entries[v] )
    end
  end
end

-- displays a chart
local function _displayChart(guiID, chartID)
  if guiID[chartID].visible == true then
    gpu.setBackground(colorChartBackground)
    gpu.setForeground(colorChartForeground)
    for x = 1, #guiID[chartID].data do
	local proz = math.floor(100 / guiID[chartID].max * guiID[chartID].data[x])
	local dotPos = guiID[chartID].height - math.floor( guiID[chartID].height / guiID[chartID].max * guiID[chartID].data[x])
	for y = 1, guiID[chartID].height do
	  if dotPos == y then
	    gpu.setBackground(colorChartForeground)
	  else
	    gpu.setBackground(colorChartBackground)
	  end
	  gpu.set(x + guiID[chartID].x, y + guiID[chartID].y, " ")
	  
	end
    end
  end
end

-- display the gui and all widgets
function gui.displayGui(guiID)
  _displayFrame(guiID)
  
  for i = 1, #guiID do
    if guiID[i].type == "label" then
      _displayLabel(guiID, i)
    elseif guiID[i].type == "button" then
      _displayButton(guiID, i)
    elseif guiID[i].type == "text" then
      _displayText(guiID, i)
    elseif guiID[i].type == "progress" then
      _displayProgress(guiID, i)
    elseif guiID[i].type == "vprogress" then
      _displayVProgress(guiID, i)
    elseif guiID[i].type == "list" then
      _displayList(guiID, i)
    elseif guiID[i].type == "frame" then
      _displayAFrame(guiID, i)
    elseif guiID[i].type == "hline" then
      _displayHLine(guiID, i)
    elseif guiID[i].type == "checkbox" then
      _displayCheckbox(guiID, i)
    elseif guiID[i].type == "radio" then
      _displayRadio(guiID, i)
    elseif guiID[i].type == "vslider" then
      _displayVslider(guiID, i)
    elseif guiID[i].type == "chart" then
      _displayChart(guiID, i)
    end
  end
end


function gui.exit()
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, screenWidth, screenHeight, " ")
  os.exit()
end

function gui.clearScreen()
  gpu.setBackground(colorScreenBackground)
  gpu.setForeground(colorScreenForeground)
  gpu.fill(1, 1, screenWidth, screenHeight, " ")

  gpu.setBackground(colorTopLineBackground)
  gpu.setForeground(colorTopLineForeground)
  gpu.fill(1, 1, screenWidth, 1, " ")
  
  gpu.setBackground(colorBottomLineBackground)
  gpu.setForeground(colorBottomLineForeground)
  gpu.fill(1, screenHeight, screenWidth, 1, " ")
end

function gui.setTop(text)
  gpu.setBackground(colorTopLineBackground)
  gpu.setForeground(colorTopLineForeground)
  gpu.set( (screenWidth / 2) - (string.len(text) / 2), 1, text)
end

function gui.setBottom(text)
  gpu.setBackground(colorBottomLineBackground)
  gpu.setForeground(colorBottomLineForeground)
  gpu.set( (screenWidth / 2) - (string.len(text) / 2), screenHeight, text)
end

-- need to be called first to setup a new dialog
function gui.newGui(x, y, w, h, frame, text, bg, fg)
  local tmpTable = {}
  if x == "center" then
    tmpTable["x"] = math.floor((screenWidth / 2) - (w / 2))
  else
    tmpTable["x"] = x
  end
  if y == "center" then
    tmpTable["y"] = math.floor((screenHeight / 2) - (h / 2))
  else
    tmpTable["y"] = y
  end
  tmpTable["bg"] = bg or colorFrameBackground
  tmpTable["fg"] = fg or colorFrameForeground
  tmpTable["width"] = w
  tmpTable["height"] = h
  tmpTable["frame"] = frame
  if text then
    tmpTable["text"] = "¦" .. text .. "?"
  end
  return tmpTable
end

-- checkbox
function gui.newCheckbox(guiID, x, y, status)
  local tmpTable = {}
  tmpTable["type"] = "checkbox"
  tmpTable["status"] = status or false
  tmpTable["y"] = y + guiID.y
  tmpTable["visible"] = true
  tmpTable["enabled"] = true
  tmpTable["x"] = x
  table.insert(guiID, tmpTable)
  return #guiID
end

-- radio button
function gui.newRadio(guiID, x, y)
  local tmpTable = {}
  tmpTable["type"] = "radio"
  tmpTable["status"] = false
  tmpTable["y"] = y + guiID.y
  tmpTable["visible"] = true
  tmpTable["enabled"] = true
  tmpTable["x"] = x
  table.insert(guiID, tmpTable)
  return #guiID
end

-- label
function gui.newLabel(guiID, x, y, text, bg, fg)
  local tmpTable = {}
  tmpTable["type"] = "label"
  tmpTable["y"] = y + guiID.y
  tmpTable["text"] = text
  tmpTable["lenght"] = string.len(text)
  tmpTable["bg"] = bg or guiID.bg
  tmpTable["fg"] = fg or guiID.fg
  tmpTable["visible"] = true
  tmpTable["x"] = x
  table.insert(guiID, tmpTable)
  return #guiID
end

-- button
function gui.newButton(guiID, x, y, text, func, bg, fg, clickBg, clickFg, disabledBg, disabledFg)
  local tmpTable = {}
  tmpTable["type"] = "button"
  tmpTable["y"] = y + guiID.y
  tmpTable["text"] = text
  tmpTable["lenght"] = string.len(tmpTable.text)
  tmpTable["visible"] = true
  tmpTable["enabled"] = true
  tmpTable["active"] = false
  tmpTable["bg"] = bg
  tmpTable["fg"] = fg
  tmpTable["clickBg"] = clickBg
  tmpTable["clickFg"] = clickFg
  tmpTable["disabledBg"] = disabledBg
  tmpTable["disabledFg"] = disabledFg
  tmpTable["func"] = func
  tmpTable["x"] = x
  table.insert(guiID, tmpTable)
  return #guiID
end

-- text input field
function gui.newText(guiID, x, y, lenght, text, func)
  local tmpTable = {}
  tmpTable["type"] = "text"
  tmpTable["x"] = x
  tmpTable["y"] = y + guiID.y
  tmpTable["text"] = text
  tmpTable["lenght"] = lenght
  tmpTable["visible"] = true
  tmpTable["enabled"] = true
  tmpTable["func"] = func
  table.insert(guiID, tmpTable)
  return #guiID
end

-- progressbar
function gui.newProgress(guiID, x, y, lenght, maxValue, value, func, number)
  local tmpTable = {}
  tmpTable["type"] = "progress"
  tmpTable["x"] = x
  tmpTable["y"] = y + guiID.y
  tmpTable["lenght"] = lenght
  tmpTable["visible"] = true
  tmpTable["enabled"] = true
  tmpTable["max"] = maxValue
  tmpTable["value"] = value
  tmpTable["func"] = func
  tmpTable["finished"] = false
  tmpTable["displayNumber"] = number
  table.insert(guiID, tmpTable)
  return #guiID
end

-- vertical progress
function gui.newVProgress(guiID, x, y, lenght, width, maxValue, value, func, direction)
  local tmpTable = {}
  tmpTable["type"] = "vprogress"
  tmpTable["x"] = x
  tmpTable["y"] = y + guiID.y
  tmpTable["lenght"] = lenght
  tmpTable["width"] = width
  tmpTable["visible"] = true
  tmpTable["enabled"] = true
  tmpTable["max"] = maxValue
  tmpTable["value"] = value
  tmpTable["func"] = func
  tmpTable["direction"] = direction or 0
  tmpTable["finished"] = false
  table.insert(guiID, tmpTable)
  return #guiID
end

-- vertical slider
function gui.newVSlider(guiID, x, y, lenght, minValue, maxValue, value, func)
  local tmpTable = {}
  tmpTable["type"] = "vslider"
  tmpTable["x"] = x
  tmpTable["y"] = y + guiID.y
  tmpTable["lenght"] = lenght
  tmpTable["visible"] = true
  tmpTable["enabled"] = true
  tmpTable["min"] = minValue
  tmpTable["max"] = maxValue
  tmpTable["value"] = value
  tmpTable["func"] = func
  table.insert(guiID, tmpTable)
  return #guiID
end

-- list
function gui.newList(guiID, x, y, width, height, tab, func, text)
  local tmpTable = {}
  tmpTable["type"] = "list"
  tmpTable["x"] = x + guiID.x
  tmpTable["y"] = y + guiID.y
  tmpTable["width"] = width
  tmpTable["height"] = height
  tmpTable["visible"] = true
  tmpTable["enabled"] = true
  tmpTable["func"] = func
  tmpTable["selected"] = 1
  tmpTable["active"] = 1
  tmpTable["entries"] = tab
  tmpTable["text"] = text
  table.insert(guiID, tmpTable)
  return #guiID
end

--frame
function gui.newFrame(guiID, x, y, width, height, text, bg, fg)
  local tmpTable = {}
  tmpTable["type"] = "frame"
  tmpTable["x"] = x + guiID.x
  tmpTable["y"] = y + guiID.y
  tmpTable["bg"] = bg or colorFrameBackground
  tmpTable["fg"] = fg or colorFrameForeground
  tmpTable["width"] = width
  tmpTable["height"] = height
  tmpTable["visible"] = true
  tmpTable["enabled"] = true
  tmpTable["text"] = text
  table.insert(guiID, tmpTable)
  return #guiID
end

-- hline
function gui.newHLine(guiID, x, y, width)
  local tmpTable = {}
  tmpTable["type"] = "hline"
  tmpTable["x"] = x + guiID.x
  tmpTable["y"] = y + guiID.y
  tmpTable["width"] = width
  tmpTable["visible"] = true
  tmpTable["enabled"] = true
  table.insert(guiID, tmpTable)
  return #guiID
end

-- chart
function gui.newChart(guiID, x, y, minValue, maxValue, data, lenght, height, bg, fg)
  local tmpTable = {}
  tmpTable["type"] = "chart"
  tmpTable["y"] = y + guiID.y
  tmpTable["lenght"] = lenght
  tmpTable["height"] = height
  tmpTable["bg"] = bg or guiID.bg
  tmpTable["fg"] = fg or guiID.fg
  tmpTable["visible"] = true
  tmpTable["x"] = x + guiID.x
  tmpTable["data"] = data
  tmpTable["min"] = minValue
  tmpTable["max"] = maxValue
  table.insert(guiID, tmpTable)
  return #guiID
end

function gui.getSelected(guiID, listID)
  return guiID[listID].selected, guiID[listID].entries[guiID[listID].selected]
end

function gui.setSelected(guiID, listID, selection)
  if selection<= #guiID[listID] then
    guiID[listID].selected = selection
    _displayList(guiID, listID)
  end
end

function gui.setMax(guiID, widgetID, maxValue)
  guiID[widgetID].max = maxValue
  _displayProgress(guiID, widgetID)
end

function gui.setChartData(guiID, chartID, data)
  guiID[chartID].data = data
  _displayChart(guiID, chartID)
end

function gui.setValue(guiID, widgetID, value)
  guiID[widgetID].value = value
  if guiID[widgetID].type == "progress" then
    _displayProgress(guiID, widgetID)
  end
  if guiID[widgetID].type == "vprogress" then
    _displayVProgress(guiID, widgetID)
  end
end

function gui.resetProgress(guiID, progressID)
  guiID[progressID].finished = false
  _displayProgress(guiID, progressID)
end

-- sets the text of a widget
function gui.setText(guiID, widgetID, text)
  guiID[widgetID].text = text
  if guiID[widgetID].type == "text" then
    _displayText(guiID, widgetID)
  end
  if guiID[widgetID].type == "label" then
    _displayLabel(guiID, widgetID)
  end
--  gui.displayGui(guiID)
end

function gui.getText(guiID, widgetID)
  return guiID[widgetID].text
end

function gui.getCheckboxStatus(guiID, widgetID)
  return guiID[widgetID].status
end

function gui.setEnable(guiID, widgetID, state)
  guiID[widgetID].enabled = state
  gui.displayGui(guiID)
end

function gui.setVisible(guiID, widgetID, state)
  if state == false then
    guiID[widgetID].visible = state
    guiID[widgetID].enabled = state
  elseif state == true then
    guiID[widgetID].visible = state
  end
  gui.displayGui(guiID)
end

function gui.setBackground(guiID, widgetID, color)
  guiID[widgetID].bg = color
  if guiID[widgetID].type == "label" then
    _displayLabel(guiID, widgetID)
  end
end
function gui.setForeground(guiID, widgetID, color)
  guiID[widgetID].fg = color
  if guiID[widgetID].type == "label" then
    _displayLabel(guiID, widgetID)
  end
end

function gui.clearList(guiID, listID)
  guiID[listID].entries = {}
end

function gui.insertList(guiID, listID, value)
  table.insert(guiID[listID].entries, value)
  _displayList(guiID, listID)
end

function gui.getRadio(guiID)
  for i = 1, #guiID do
    if guiID[i].type == "radio" then
      if guiID[i].status == true then
	return i
      end
    end
  end
  return -1
end

function gui.setRadio(guiID, radioID)
  for i = 1, #guiID do
    if guiID[i].type == "radio" then
      guiID[i].status = false 
    end
  end
  guiID[radioID].status = true
  return -1
end

local function runInput(guiID, textID)
  local inputText = guiID[textID].text
  gpu.setBackground(colorInputBackground)
  gpu.setForeground(colorInputForeground)
  
  local x = 0
  if guiID[textID].x == "center" then
    x = guiID.x + math.floor((guiID.width / 2)) - math.floor((guiID[textID].lenght) / 2)
  else
    x =guiID.x + guiID[textID].x
  end

  local loopRunning = true
  while loopRunning == true do
    gpu.fill(x, guiID[textID].y, guiID[textID].lenght, 1, " ")
    tmpStr = inputText
    if string.len(tmpStr) + 1 > guiID[textID].lenght then
      tmpStr = string.sub(tmpStr, string.len(tmpStr) - guiID[textID].lenght + 2, string.len(tmpStr))
    end
    gpu.set(x, guiID[textID].y, tmpStr .. "_")
    local e, _, character, code = event.pullMultiple(0.1, "key_down", "touch")
    if e == "key_down" then
      if character == 8 then	-- backspace
	inputText = string.sub(inputText, 1, string.len(inputText) - 1)
      elseif character == 13 then 	-- return
	guiID[textID].text = inputText
	if guiID[textID].func then
	  guiID[textID].func(guiID, textID, inputText)
	end
	loopRunning = false
      elseif character > 31 and character < 128 then
	inputText = inputText .. string.char(character)
      end
    elseif e == "touch" then
      if character < x or character > (x + guiID[textID].lenght) or guiID[textID].y ~= code then
	guiID[textID].text = inputText
	_displayText(guiID, textID)
	if guiID[textID].func then
	  guiID[textID].func(guiID, textID, inputText)
	end
	loopRunning = false
	computer.pushSignal("touch", _, character, code)
      end
    end
  end
end

local displayed = false

function gui.log(logname, message)
  file=io.open(logname,"a")
  file:write(os.date("[%c] ") .. message .. "\n")
  file:close()
end

local showErrGui = false

function errGuiOK()
  showErrGui = false
end

function gui.runGui(guiID, isAuthorizedFunc)
  if displayed == false then
    displayed = true
    gui.displayGui(guiID)
  end
  local e, _, x, y, button, player = event.pull(0.1, "touch")
  if e == nil then
    return false
  end
  gui.processEvent(guiID, isAuthorizedFunc, e, x, y, button, player)
end

function gui.processEvent(guiID, isAuthorizedFunc, e, x, y, button, player)
  if e == nil or e ~= "touch" then
    return false
  end
  local ix = 0
  if isAuthorizedFunc and not isAuthorizedFunc(guiID, player) then
    gui.log("touches.log", "Not authorized: " .. player)

    local errGui = gui.newGui(2, "center", screenWidth - 2, 8, true, "ERROR", 0xFF0000, 0xFFFF00)
    local errMsgLabel = gui.newLabel(errGui, "center", 3, player)    
    local errMsgLabel2 = gui.newLabel(errGui, "center", 4, "not authorized!")
    local errButton = gui.newButton(errGui, "center", 6, "OK", errGuiOK)
    showErrGui = true

    gui.displayGui(errGui)
    local cnt = 200

    while showErrGui do
      gui.runGui(errGui)
      cnt = cnt - 1
      if cnt <= 0 then
	showErrGui = false
      end
    end

    showErrGui = false
    gui.displayGui(guiID)
    return false
  end

  for i = 1, #guiID do
    if guiID[i].type == "button" then
      if guiID[i].x == "center" then
	ix = guiID.x + math.floor((guiID.width / 2)) - math.floor((guiID[i].lenght / 2))
      else
	ix = guiID.x + guiID[i].x
      end
      if x >= ix and x < (ix + guiID[i].lenght) and guiID[i].y == y then
	if guiID[i].func and guiID[i].enabled == true then
	  guiID[i].active = true
	  gui.displayGui(guiID)
	  os.sleep(0.05)
	  guiID[i].active = false
	  guiID[i].usedBy = player
	  gui.displayGui(guiID)
	  guiID[i].func(guiID, i)
	end
      end
    elseif guiID[i].type == "checkbox" then
      ix = guiID.x + guiID[i].x + 1
      if x == ix and guiID[i].y == y then
	if guiID[i].enabled == true then
	  if guiID[i].status == true then
	    guiID[i].status = false
	  else
	    guiID[i].status = true
	  end
	  _displayCheckbox(guiID, i)
	end
      end
    elseif guiID[i].type == "radio" then
      ix = guiID.x + guiID[i].x + 1
      if x == ix and guiID[i].y == y then
	if guiID[i].enabled == true then
	  for c = 1, #guiID do
	    if guiID[c].type == "radio" then
	      guiID[c].status = false
	      _displayRadio(guiID, c)
	    end
	  end
	  guiID[i].status = true
	  _displayRadio(guiID, i)
	end
      end
    elseif guiID[i].type == "text" then
      if guiID[i].x == "center" then
	ix = guiID.x + math.floor((guiID.width / 2)) - math.floor((guiID[i].lenght / 2))
      else
	ix = guiID.x + guiID[i].x
      end
      if x >= ix and x < (ix + guiID[i].lenght) and guiID[i].y == y then
	if guiID[i].enabled == true then
	  runInput(guiID, i)
	end
      end
    elseif guiID[i].type == "list" and guiID[i].enabled == true then
      if x == guiID[i].x +1 and y == guiID[i].y + guiID[i].height - 1 then
	guiID[i].active = guiID[i].active - guiID[i].height + 2
	if guiID[i].active < 1 then
	  guiID[i].active = 1
	end
	gpu.setBackground(colorListActiveBackground)
	gpu.setForeground(colorListActiveForeground)
	gpu.set(guiID[i].x, guiID[i].y + guiID[i].height - 1, "[<]")
	guiID[i].selected = guiID[i].active
--	_displayList(guiID, i)

	if guiID[i].func then
	  gpu.setBackground(colorButtonClickedBackground)
	  gpu.setForeground(colorButtonClickedForeground)
	  gpu.set(guiID[i].x, guiID[i].y + guiID[i].height - 1, "[<]")
	  os.sleep(0.05)
	  gpu.setBackground(colorListBackground)
	  gpu.setForeground(colorListForeground)
	  guiID[i].usedBy = player
	  gpu.set(guiID[i].x, guiID[i].y + guiID[i].height - 1, "[<]")
	  guiID[i].func(guiID, i, guiID[i].selected, guiID[i].entries[guiID[i].selected])
	end
      end
      if x == guiID[i].x + guiID[i].width - 2 and y == guiID[i].y + guiID[i].height - 1 then
	if guiID[i].active + guiID[i].height - 2 < #guiID[i].entries then
	  guiID[i].active = guiID[i].active + guiID[i].height - 2
	  guiID[i].selected = guiID[i].active
	end
	gpu.setBackground(colorListActiveBackground)
	gpu.setForeground(colorListActiveForeground)
	gpu.set(guiID[i].x + guiID[i].width - 3, guiID[i].y + guiID[i].height - 1, "[>]")
--	_displayList(guiID, i)
	
	if guiID[i].func then
	  gpu.setBackground(colorButtonClickedBackground)
	  gpu.setForeground(colorButtonClickedForeground)
	  gpu.set(guiID[i].x + guiID[i].width - 3, guiID[i].y + guiID[i].height - 1, "[>]")
	  os.sleep(0.05)
	  gpu.setBackground(colorListBackground)
	  gpu.setForeground(colorListForeground)
	  guiID[i].usedBy = player
	  gpu.set(guiID[i].x + guiID[i].width - 3, guiID[i].y + guiID[i].height - 1, "[>]")
	  guiID[i].func(guiID, i, guiID[i].selected, guiID[i].entries[guiID[i].selected])
	end
      end
      if x > guiID[i].x - 1 and x < guiID[i].x + guiID[i].width and y > guiID[i].y and y < guiID[i].y + guiID[i].height - 1 then
	if guiID[i].active + y - guiID[i].y - 1 <= #guiID[i].entries then
	  guiID[i].selected = guiID[i].active + y - guiID[i].y - 1
--	  _displayList(guiID, i)
	  
	  if guiID[i].func then
            guiID[i].usedBy = player
	    guiID[i].func(guiID, i, guiID[i].selected, guiID[i].entries[guiID[i].selected])
	  end
	end
      end
	  _displayList(guiID, i)
    elseif guiID[i].type == "chart" and guiID[i].enabled == true then
      _displayChart(guiID, i)
    end
  end
  
--  gui.displayGui(guiID)
end

errorGui = gui.newGui("center", "center", screenWidth / 3 * 2, 10, true, "ERROR", 0xFF0000, 0xFFFF00)
errorMsgLabel1 = gui.newLabel(errorGui, "center", 3, "")
errorMsgLabel2 = gui.newLabel(errorGui, "center", 4, "")
errorMsgLabel3 = gui.newLabel(errorGui, "center", 5, "")
errorButton = gui.newButton(errorGui, "center", 8, "exit", gui.exit)

function gui.showError(msg1, msg2, msg3)
  gui.setText(errorGui, errorMsgLabel1, msg1 or "")
  gui.setText(errorGui, errorMsgLabel2, msg2 or "")
  gui.setText(errorGui, errorMsgLabel3, msg3 or "")
  gui.displayGui(errorGui)
  while true do
    gui.runGui(errorGui)
  end
end


local msgRunning = true
function msgCallback()
  msgRunning = false
end

msgGui = gui.newGui("center", "center", 40, 10, true, "Info")
msgLabel1 = gui.newLabel(msgGui, "center", 3, "")
msgLabel2 = gui.newLabel(msgGui, "center", 4, "")
msgLabel3 = gui.newLabel(msgGui, "center", 5, "")
msgButton = gui.newButton(msgGui, "center", 8, "ok", msgCallback)

function gui.showMsg(msg1, msg2, msg3)
  gui.setText(msgGui, msgLabel1, msg1 or "")
  gui.setText(msgGui, msgLabel2, msg2 or "")
  gui.setText(msgGui, msgLabel3, msg3 or "")
  msgRunning = true
  gui.displayGui(msgGui)
  while msgRunning == true do
    gui.runGui(msgGui)
  end
end


local yesNoRunning = true
local yesNoValue = false

local function yesNoCallbackYes()
  yesNoRunning = false
  yesNoValue = true
end
local function yesNoCallbackNo()
  yesNoRunning = false
  yesNoValue = false
end

yesNoGui = gui.newGui("center", "center", screenWidth / 3 * 2, 8, true, "Question")
yesNoMsgLabel1 = gui.newLabel(yesNoGui, "center", 2, "")
yesNoMsgLabel2 = gui.newLabel(yesNoGui, "center", 3, "")
yesNoMsgLabel3 = gui.newLabel(yesNoGui, "center", 4, "")
yesNoYesButton = gui.newButton(yesNoGui, 3, 6, "yes", yesNoCallbackYes)
yesNoNoButton = gui.newButton(yesNoGui, screenWidth / 3 * 2 - 4, 6, "no", yesNoCallbackNo)


function gui.getYesNo(msg1, msg2, msg3)
  yesNoRunning = true
  gui.setText(yesNoGui, yesNoMsgLabel1, msg1 or "")
  gui.setText(yesNoGui, yesNoMsgLabel2, msg2 or "")
  gui.setText(yesNoGui, yesNoMsgLabel3, msg3 or "")
  gui.displayGui(yesNoGui)
  while yesNoRunning == true do
    gui.runGui(yesNoGui)
  end
  return yesNoValue
end




-- File handling

function gui.splitString(str, sep)
        local sep, fields = sep or ":", {}
        local pattern = string.format("([^%s]+)", sep)
        str:gsub(pattern, function(c) fields[#fields+1] = c end)
        return fields
end




local function convert( chars, dist, inv )
  return string.char( ( string.byte( chars ) - 32 + ( inv and -dist or dist ) ) % 95 + 32 )
end

function gui.string2key(str)
  tmpTable = {}
  for i = 1, string.len(str) do
    tmpTable[i] = string.byte(str,i)
  end
  while #tmpTable < 5 do
    table.insert(tmpTable,100)
  end
  return tmpTable
end


function gui.crypt(str,inv,k)
  if not k then
    k = {1,2,3,4,5}
  end
  while #k < 5 do
    table.insert(k,100)
  end
  local enc= "";
  for i=1,#str do
    if(#str-k[#k] >= i or not inv)then
      for inc=0,3 do
	if(i%4 == inc)then
	  enc = enc .. convert(string.sub(str,i,i),k[inc+1],inv);
	  break;
	end
      end
    end
  end
  if(not inv)then
    for i=1,k[#k] do
      enc = enc .. string.char(math.random(32,126));
    end
  end
  return enc;
end

--// exportstring( string )
--// returns a "Lua" portable version of the string
local function exportstring( s )
	s = string.format( "%q",s )
	-- to replace
	s = string.gsub( s,"\\\n","\\n" )
	s = string.gsub( s,"\r","\\r" )
	s = string.gsub( s,string.char(26),"\"..string.char(26)..\"" )
	return s
end
--// The Save Function
function gui.saveTable(tbl,filename )
	local charS,charE = "   ","\n"
	local file,err
	-- create a pseudo file that writes to a string and return the string
	if not filename then
		file =  { write = function( self,newstr ) self.str = self.str..newstr end, str = "" }
		charS,charE = "",""
	-- write table to tmpfile
	elseif filename == true or filename == 1 then
		charS,charE,file = "","",io.tmpfile()
	-- write table to file
	-- use io.open here rather than io.output, since in windows when clicking on a file opened with io.output will create an error
	else
		file,err = io.open( filename, "w" )
		if err then 
		  print ("Gui-lib: Error saving table " .. filename .." -> " .. err)
		  return _,err 
		end
	end
	-- initiate variables for save procedure
	local tables,lookup = { tbl },{ [tbl] = 1 }
	file:write( "return {"..charE )
	for idx,t in ipairs( tables ) do
		if filename and filename ~= true and filename ~= 1 then
			file:write( "-- Table: {"..idx.."}"..charE )
		end
		file:write( "{"..charE )
		local thandled = {}
		for i,v in ipairs( t ) do
			thandled[i] = true
			-- escape functions and userdata
			if type( v ) ~= "userdata" then
				-- only handle value
				if type( v ) == "table" then
					if not lookup[v] then
						table.insert( tables, v )
						lookup[v] = #tables
					end
					file:write( charS.."{"..lookup[v].."},"..charE )
				elseif type( v ) == "function" then
					file:write( charS.."loadstring("..exportstring(string.dump( v )).."),"..charE )
				else
					local value =  ( type( v ) == "string" and exportstring( v ) ) or tostring( v )
					file:write(  charS..value..","..charE )
				end
			end
		end
		for i,v in pairs( t ) do
			-- escape functions and userdata
			if (not thandled[i]) and type( v ) ~= "userdata" then
				-- handle index
				if type( i ) == "table" then
					if not lookup[i] then
						table.insert( tables,i )
						lookup[i] = #tables
					end
					file:write( charS.."[{"..lookup[i].."}]=" )
				else
					local index = ( type( i ) == "string" and "["..exportstring( i ).."]" ) or string.format( "[%d]",i )
					file:write( charS..index.."=" )
				end
				-- handle value
				if type( v ) == "table" then
					if not lookup[v] then
						table.insert( tables,v )
						lookup[v] = #tables
					end
					file:write( "{"..lookup[v].."},"..charE )
				elseif type( v ) == "function" then
					file:write( "loadstring("..exportstring(string.dump( v )).."),"..charE )
				else
					local value =  ( type( v ) == "string" and exportstring( v ) ) or tostring( v )
					file:write( value..","..charE )
				end
			end
		end
		file:write( "},"..charE )
	end
	file:write( "}" )
	-- Return Values
	-- return stringtable from string
	if not filename then
		-- set marker for stringtable
		return file.str.."--|"
	-- return stringttable from file
	elseif filename == true or filename == 1 then
		file:seek ( "set" )
		-- no need to close file, it gets closed and removed automatically
		-- set marker for stringtable
		return file:read( "*a" ).."--|"
	-- close file and return 1
	else
		file:close()
		return 1
	end
end
 
--// The Load Function
function gui.loadTable( sfile )
	local tables, err, _

	-- catch marker for stringtable
	if string.sub( sfile,-3,-1 ) == "--|" then
		tables,err = loadstring( sfile )
	else
		tables,err = loadfile( sfile )
	end
	if err then 
	  print("Gui-lib: Error loading table " ..sfile .. " -> " ..err)
	  return _,err
	end
	tables = tables()
	for idx = 1,#tables do
		local tolinkv,tolinki = {},{}
		for i,v in pairs( tables[idx] ) do
			if type( v ) == "table" and tables[v[1]] then
				table.insert( tolinkv,{ i,tables[v[1]] } )
			end
			if type( i ) == "table" and tables[i[1]] then
				table.insert( tolinki,{ i,tables[i[1]] } )
			end
		end
		-- link values, first due to possible changes of indices
		for _,v in ipairs( tolinkv ) do
			tables[idx][v[1]] = v[2]
		end
		-- link indices
		for _,v in ipairs( tolinki ) do
			tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
		end
	end
	return tables[1]
end

function gui.sepString(str)
  tmpTable = {}
  for i = 1, string.len(str) do
    tmpTable[i] = string.char(string.byte(str,i))
  end
  return tmpTable
end






return gui
