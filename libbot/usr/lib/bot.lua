local component = require("component")
local sides = require("sides")
local os = require("os")

local bot = {}
local x, y, z, f = 0, 0, 0, 0 -- f(acing) 0 fwd 1 right 2 back 3 left
local delta = {[0] = function(x,y,d) return (x + d), y end,
               [1] = function(x,y,d) return x, (y + d) end,
               [2] = function(x,y,d) return (x - d), y end,
               [3] = function(x,y,d) return x, (y - d) end}
-------------------------------------------------------------------------------
-- General

function bot.name()
  return component.robot.name()
end

function bot.X()
  return x
end

function bot.Y()
  return y
end

function bot.Z()
  return z
end

function bot.XYZ()
  return x, y, z
end

function bot.getFacing()
  return f
end

function bot.getRelative(fwd, right, up)
  local retX, retY, retZ = x, y, z
  if fwd ~= 0 then retX, retY = delta[f](retX, retY, fwd) end
  if right ~= 0 then retX, retY = delta[(f+1)%4](retX, retY, right) end
  if up ~= 0 then retZ = retZ + up end
  return retX, retY, retZ
end

function bot.resetPosition()
  x, y, z, f = 0, 0, 0, 0
end

function bot.level()
  if component.isAvailable("experience") then
    return component.experience.level()
  else
    return 0
  end
end

function bot.getLightColor()
  return component.robot.getLightColor()
end

function bot.setLightColor(value)
  return component.robot.setLightColor(value)
end

-------------------------------------------------------------------------------
-- World

function bot.detect()
  return component.robot.detect(sides.front)
end

function bot.detectUp()
  return component.robot.detect(sides.up)
end

function bot.detectDown()
  return component.robot.detect(sides.down)
end

-------------------------------------------------------------------------------
-- Inventory

function bot.inventorySize()
  return component.robot.inventorySize()
end


function bot.select(...)
  return component.robot.select(...)
end

function bot.count(...)
  return component.robot.count(...)
end

function bot.space(...)
  return component.robot.space(...)
end

function bot.compareTo(...)
  return component.robot.compareTo(...)
end

function bot.transferTo(...)
  return component.robot.transferTo(...)
end

-------------------------------------------------------------------------------
-- Inventory + World

function bot.compare()
  return component.robot.compare(sides.front)
end

function bot.compareUp()
  return component.robot.compare(sides.up)
end

function bot.compareDown()
  return component.robot.compare(sides.down)
end

function bot.drop(count)
  checkArg(1, count, "nil", "number")
  return component.robot.drop(sides.front, count)
end

function bot.dropUp(count)
  checkArg(1, count, "nil", "number")
  return component.robot.drop(sides.up, count)
end

function bot.dropDown(count)
  checkArg(1, count, "nil", "number")
  return component.robot.drop(sides.down, count)
end

function bot.place(side, sneaky)
  checkArg(1, side, "nil", "number")
  return component.robot.place(sides.front, side, sneaky ~= nil and sneaky ~= false)
end

function bot.placeUp(side, sneaky)
  checkArg(1, side, "nil", "number")
  return component.robot.place(sides.up, side, sneaky ~= nil and sneaky ~= false)
end

function bot.placeDown(side, sneaky)
  checkArg(1, side, "nil", "number")
  return component.robot.place(sides.down, side, sneaky ~= nil and sneaky ~= false)
end

function bot.suck(count)
  checkArg(1, count, "nil", "number")
  return component.robot.suck(sides.front, count)
end

function bot.suckUp(count)
  checkArg(1, count, "nil", "number")
  return component.robot.suck(sides.up, count)
end

function bot.suckDown(count)
  checkArg(1, count, "nil", "number")
  return component.robot.suck(sides.down, count)
end

-------------------------------------------------------------------------------
-- Tool

function bot.durability()
  return component.robot.durability()
end


function bot.swing(side, sneaky, swingSlot, drop)
  checkArg(1, side, "nil", "number")
  local ret, reason
  if swingSlot ~= nil then
    local s = bot.select()
    bot.select(swingSlot)
    ret, reason = component.robot.swing(sides.front, side, sneaky ~= nil and sneaky ~= false)
    if drop then
      drop(swingSlot)
    end
    bot.select(s)
  else
    ret, reason = component.robot.swing(sides.front, side, sneaky ~= nil and sneaky ~= false)
  end
  return ret, reason
end

function bot.swingUp(side, sneaky, swingSlot, drop)
  checkArg(1, side, "nil", "number")
  local ret, reason
  if swingSlot ~= nil then
    local s = bot.select()
    bot.select(swingSlot)
    ret, reason = component.robot.swing(sides.up, side, sneaky ~= nil and sneaky ~= false)
    if drop then
      drop(swingSlot)
    end
    bot.select(s)
  else
    ret, reason = component.robot.swing(sides.up, side, sneaky ~= nil and sneaky ~= false)
  end
  return ret, reason
end

function bot.swingDown(side, sneaky, swingSlot, drop)
  checkArg(1, side, "nil", "number")
  local ret, reason
  if swingSlot ~= nil then
    local s = bot.select()
    bot.select(swingSlot)
    ret, reason = component.robot.swing(sides.down, side, sneaky ~= nil and sneaky ~= false)
    if drop then
      drop(swingSlot)
    end
    bot.select(s)
  else
    ret, reason = component.robot.swing(sides.down, side, sneaky ~= nil and sneaky ~= false)
  end
  return ret, reason
end

function bot.use(side, sneaky, duration)
  checkArg(1, side, "nil", "number")
  checkArg(3, duration, "nil", "number")
  return component.robot.use(sides.front, side, sneaky ~= nil and sneaky ~= false, duration)
end

function bot.useUp(side, sneaky, duration)
  checkArg(1, side, "nil", "number")
  checkArg(3, duration, "nil", "number")
  return component.robot.use(sides.up, side, sneaky ~= nil and sneaky ~= false, duration)
end

function bot.useDown(side, sneaky, duration)
  checkArg(1, side, "nil", "number")
  checkArg(3, duration, "nil", "number")
  return component.robot.use(sides.down, side, sneaky ~= nil and sneaky ~= false, duration)
end

-------------------------------------------------------------------------------
-- Movement

function bot.moveToSide(side, distance, swingSlot, drop)
  local d = distance or 1

  for i = 1,d do
    local ret, reason = component.robot.move(side)
    local repeats = 0
    while (not ret) and (repeats < 10) and swingSlot do
      if (side == sides.up and d > 0)
        or (side == sides.down and d < 0) then
        bot.swingUp(nil, false, swingSlot, drop)
      elseif (side == sides.up and d < 0)
        or (side == sides.down and d > 0) then
        bot.swingDown(nil, false, swingSlot, drop)
      elseif side == sides.back then
        bot.turnAround()
        bot.swing(nil, false, swingSlot, drop)
        bot.turnAround()
      else
        bot.swing(nil, false, swingSlot, drop)
      end

      os.sleep(0.1)
      ret, reason = component.robot.move(side)
      repeats = repeats + 1
    end

    if ret then
      if side == sides.forward then
        x, y = delta[f](x, y, 1)
      elseif side == sides.back then
        x, y = delta[f](x, y, -1)
      elseif side == sides.right then
        x, y = delta[(f+1)%4](x, y, 1)
      elseif side == sides.left then
        x, y = delta[(f-1)%4](x, y, 1)
      elseif side == sides.up then
        z = z + 1
      elseif side == sides.down then
        z = z - 1
      end
    else
      return false, reason, i-1
    end
  end
  return true
end

function bot.forward(distance, swingSlot, drop)
  local d = distance or 1
  if d < 0 then
    return bot.back(-d, swingSlot, drop)
  end

  return bot.moveToSide(sides.front, d, swingSlot, drop)
end

function bot.back(distance, swingSlot, drop)
  local d = distance or 1
  if d < 0 then
    return bot.forward(-d, swingSlot, drop)
  end
  return bot.moveToSide(sides.back, d, swingSlot, drop)
end

function bot.up(distance, swingSlot, drop)
  local d = distance or 1
  if d < 0 then
    return bot.down(-d, swingSlot, drop)
  end
  return bot.moveToSide(sides.up, d, swingSlot, drop)
end

function bot.down(distance, swingSlot, drop)
  local d = distance or 1
  if d < 0 then
    return bot.up(-d, swingSlot, drop)
  end

  return bot.moveToSide(sides.down, d, swingSlot, drop)
end


function bot.turnLeft()
  if component.robot.turn(false) then
    f = (f - 1) % 4
    return true
  end
  return false
end

function bot.turnRight()
  if component.robot.turn(true) then
    f = (f + 1) % 4
    return true
  end
  return false
end

function bot.turnAround()
  local turn = math.random() < 0.5 and bot.turnLeft or bot.turnRight
  return turn() and turn()
end

function bot.turnToFace(face)
  local turn = face - f;
  -- f        0  1  2  3
  -- face  0  0 -1  2  1
  --       1  1  0 -1  2
  --       2  2  1  0 -1
  --       3 -1  2  1  0
  --
  -- turn = face - f
  -- if turn > 2 then
  --   turn = turn - 4
  -- elseif turn < -2 then
  --   turn = turn + 4
  -- end
  --

  if turn > 2 then
    turn = turn - 4
  elseif turn < -2 then
    turn = turn + 4
  end

  if turn < 0 then
    for i = 1, -turn do
      bot.turnLeft()
    end
  else
    for i = 1, turn do
      bot.turnRight()
    end
  end
end

function bot.move(fwd, right, up, up_first, swingSlot, drop)
  if up_first and up ~= 0 then
    bot.up(up, swingSlot, drop)
  end

  if fwd ~= 0 then
    bot.forward(fwd, swingSlot, drop)
  end

  if right ~= 0 then
    if right > 0 then
      bot.turnRight()
    else
      bot.turnLeft()
      right = -right
    end
    bot.forward(right, swingSlot, drop)
  end

  if not up_first and up ~= 0 then
    bot.up(up, swingSlot, drop)
  end
end

function bot.moveTo(X,Y,Z, up_first, swingSlot, drop)
  local dx, dy, dz = X - x, Y - y, Z - z

  bot.turnToFace(0)
  bot.move(dx, dy, dz, up_first, swingSlot, drop)
end

-------------------------------------------------------------------------------
-- Tank

function bot.tankCount()
  return component.robot.tankCount()
end


function bot.selectTank(tank)
  return component.robot.selectTank(tank)
end

function bot.tankLevel(...)
  return component.robot.tankLevel(...)
end

function bot.tankSpace(...)
  return component.robot.tankSpace(...)
end

function bot.compareFluidTo(...)
  return component.robot.compareFluidTo(...)
end

function bot.transferFluidTo(...)
  return component.robot.transferFluidTo(...)
end

-------------------------------------------------------------------------------
-- Tank + World

function bot.compareFluid()
  return component.robot.compareFluid(sides.front)
end

function bot.compareFluidUp()
  return component.robot.compareFluid(sides.up)
end

function bot.compareFluidDown()
  return component.robot.compareFluid(sides.down)
end

function bot.drain(count)
  checkArg(1, count, "nil", "number")
  return component.robot.drain(sides.front, count)
end

function bot.drainUp(count)
  checkArg(1, count, "nil", "number")
  return component.robot.drain(sides.up, count)
end

function bot.drainDown(count)
  checkArg(1, count, "nil", "number")
  return component.robot.drain(sides.down, count)
end

function bot.fill(count)
  checkArg(1, count, "nil", "number")
  return component.robot.fill(sides.front, count)
end

function bot.fillUp(count)
  checkArg(1, count, "nil", "number")
  return component.robot.fill(sides.up, count)
end

function bot.fillDown(count)
  checkArg(1, count, "nil", "number")
  return component.robot.fill(sides.down, count)
end

-------------------------------------------------------------------------------

return bot
-- vim: set ts=2 sw=2 sts=2 et: