-- builds based on voxel array
--
-- CUSTOMIZE
local dome_size_ex, dome_size_ey, dome_size_ez = 18, 18, 9
local resume_from_layer = 0

local dont_place = false
-- END OF CUSTOMIZE

local component = require("component")
local sides = require("sides")
local io = require("io")
local math = require("math")
local os = require("os")
local computer = require("computer")

package.loaded.bot = nil
local bot = require("bot")
local db = component.database -- primary database component
local me = component.upgrade_me
local minx, miny, minz = 0, 0, 0
local maxx, maxy, maxz = 0, 0, 0
local blueprint = {}
local delta = { [1] = function() return 0, -1, -1 end,
                [2] = function() return 1, 0, -1 end,
                [3] = function() return 0, 1, -1 end }

local itemGroups = { [1] = { name = "stone",  slot_min =  1, slot_max =  2, db_entry = 2 },
                     [2] = { name = "glass",  slot_min =  3, slot_max =  4, db_entry = 3 },
                     [3] = { name = "dirt",   slot_min =  5, slot_max =  5, db_entry = 1 },
                     [4] = { name = "light",  slot_min =  6, slot_max =  6, db_entry = 4 } }
                      
function refillFromME(idx)
  if not me then return end
  local dbSlot = itemGroups[idx].db_entry
  bot.select(itemGroups[idx].slot_min)

  local ret, reason = me.requestItems(db.address, dbSlot, 64)

  if ret > 0 then
    return true
  end
  return false, reason
end

function dropToME(slot)
  local s = bot.select()
  bot.select(slot)
  if not me then 
    bot.dropDown(64)
  else
    me.sendItems(64)
  end
  bot.select(s)
end

function itemCount(idx)
  local cnt = 0
  for i = itemGroups[idx].slot_min, itemGroups[idx].slot_max do
    cnt = cnt + bot.count(i)
  end
  return cnt
end

function selectItem(idx)
  local selected = bot.select()
  if selected >= itemGroups[idx].slot_min 
    and selected <= itemGroups[idx].slot_max 
    and bot.count() > 0 then
    return true
  end

  while true do
    for i = itemGroups[idx].slot_min, itemGroups[idx].slot_max do
      if bot.count(i) > 0 then
        bot.select(i)
        return true
      end
    end
    local refilled = false
    -- item not found
    if me then refilled = refillFromME(idx) end

    if not refilled then
      log("Need more " .. itemGroups[idx].name .. " material in slots " .. itemGroups[idx].slot_min .. " - " .. itemGroups[idx].slot_max .. ".")
      log("Press return to continue.")
      io.read()
    end
  end
  return false
end

function log(...)
  io.write(..., "\n")
  print(...)
end

local function isInEllipsoidEX(xdivex2, ydivey2, zdivez2)
  return (xdivex2 + ydivey2 + zdivez2 <= 1)
end

function isInEllipsoid(x, y, z, ex, ey, ez)
  return ((x/ex)^2 + (y/ey)^2 + (z/ez)^2 <= 1)
end

function resetBlueprint()
  minx, maxx = 0, 0
  miny, maxy = 0, 0
  minz, maxz = 0, 0
  blueprint = {}
end

function getBPV(x,y,z)
  return blueprint[x][y][z]
end

function setBPV(x,y,z,v)
  blueprint[x][y][z] = v
end

function CircleFillerFn(radius)
  return function (x,y,z) 
    local r = radius + 0.25
    local xdivex2, ydivey2, zdivez2 = (x/r)^2, (y/r)^2, 0
    if isInEllipsoidEX(xdivex2, ydivey2, zdivez2) then
      if (not isInEllipsoidEX(((x + 1)/r)^2, ydivey2, zdivez2))
        or (not isInEllipsoidEX(((x - 1)/r)^2, ydivey2, zdivez2))
        or (not isInEllipsoidEX(xdivex2, ((y + 1)/r)^2, zdivez2))
        or (not isInEllipsoidEX(xdivex2, ((y - 1)/r)^2, zdivez2)) then
        return 1
      end
    end
    return 0
  end
end

function TexturedDomeFillerFn(eX, eY, eZ)
  return function (x,y,z)
    local ex, ey, ez = eX + 0.25, eY + 0.25, eZ + 0.25
    local xdivex2, ydivey2, zdivez2 = (x/ex)^2, (y/ey)^2, (z/ez)^2

    if isInEllipsoidEX(xdivex2, ydivey2, zdivez2) then

      if (z == -1) then
        if (x == 0) and (y == 0) then
          return 0
        end
        return 1
      end

      if (not isInEllipsoidEX(((x + 1)/ex)^2, ydivey2, zdivez2))
        or (not isInEllipsoidEX(((x - 1)/ex)^2, ydivey2, zdivez2))
        or (not isInEllipsoidEX(xdivex2, ((y + 1)/ey)^2, zdivez2))
        or (not isInEllipsoidEX(xdivex2, ((y - 1)/ey)^2, zdivez2))
        or (not isInEllipsoidEX(xdivex2, ydivey2, ((z + 1)/ez)^2))
        or (not isInEllipsoidEX(xdivex2, ydivey2, ((z - 1)/ez)^2)) then
        
        if (z == math.ceil(ez / 2)) or (z == 0) then
          return 1
        end

        local ev = math.floor( ( (x / (ex*0.25))^2 + 
                                 (y / (ey*0.25))^2 ) * 100)
        if (ev == 100) -- circle
          or ( (ev > 100) -- outside of circle
            and ( (math.abs(y) == math.ceil(ey * 0.33))
               or (math.abs(x) == math.ceil(ex * 0.33))
               or (x == 0) 
               or (y == 0) ) ) then
          return 1
        end

        return 2
      end
    end
    return 0
  end
end

function initBlueprint(minX, maxX, minY, maxY, minZ, maxZ, fn)
  for z in minZ, maxZ do
    initBlueprintLayer(minX, maxX, minY, maxY, z, fn)
  end
end

function initBlueprintLayer(minX,maxX,minY,maxY,Z,fn)
  minx, maxx, miny, maxy, minz, maxz = minX, maxX, minY, maxY, minZ, maxZ
  
  for x = minx, maxx do
    blueprint[x] = {}
    for y = miny, maxy do
      blueprint[x][y] = {}
      blueprint[x][y][Z] = fn(x,y,Z)
    end
  end
end

function printCircle(r)
  bot.resetPosition()
  resetBlueprint()
  initBlueprint(-r-1, r+1, -r-1, r+1, 0, 0, CircleFillerFn(r))
  
  bot.up(1, 16, dropToME)
  bot.forward(r, 16, dropToME)
  bot.turnRight()

  local found = false
  repeat
    found = false

    if not dont_place then
      while not bot.placeDown() do
        log("Cannot place down block. Fix the issue and press return.");
        io.read()
      end
    end

    setBPV(bot.X(), bot.Y(), bot.Z()-1, 0)

    for i = 1,3 do
      local dx, dy, dz = delta[i]()
      local bx, by, bz = bot.getRelative(dx, dy, dz)

      if getBPV(bx, by, bz) == 1 then
        bot.move(dx, dy, 0, false, 16, dropToME)
        found = true
        break
      end
    end
  until not found
  log("Done printing circle. Returning to center...")
  bot.turnToFace(2) -- turn to face opposite of our start faceing
  bot.move(bot.X(), bot.Y(), -1) -- move back to start pos
  bot.turnAround() -- turn around to our start orientation
  log("Ready for next task.")
end


function findFarAroundBot()
  local found = false
  local sx, sy, sz = 0, 0, 0
  local s_w = -10.0
  -- find farthest point from center (1 block around bot)
  for i = 1,3 do
    local dx, dy, dz = delta[i]()
    local bx, by, bz = bot.getRelative(dx, dy, dz)
    local bv = getBPV(bx, by, bz)
    if (bv > 0) then
      local w = bx^2 + by^2
      if w > s_w then
        sx, sy, sz = dx, dy, dz
        s_w = w
        found = true
      end
      os.sleep(0)
    end
  end
  return found, sx, sy, sz
end

function findAnyOnLayer(ex, ey)
  local x,y,z = bot.XYZ()
  z = z - 1
  local sr2 = 10000000000
  local sx, sy = 0, 0
  local f = false
  local r2 = 0

  -- try to find any unfinished block on layer
  for ix = -ex, ex do
    for iy = -ey, ey do
      if getBPV(ix, iy, z) > 0 then
        r2 = (ix-x)^2 + (iy-y)^2
        if r2 < sr2 then
          -- found
          sr2, sx, sy = r2, ix, iy
          f = true
        end
      end
    end
    os.sleep(0)
  end
  
  return f, sx, sy, z + 1
end

function tryPlaceUp()
  if dont_place then
    return
  end

  if bot.detectUp() then
    if bot.compareUp() then return end
    bot.swingUp(nil, false, 16, dropToME)
  end

  local repeats = 0
  local ret, reason = bot.placeUp()
  while (not ret) and (repeats < 30) do
    bot.swingUp(nil, false, 16, dropToME)
    ret, reason = bot.placeUp()
    repeats = repeats + 1
  end
  if (not ret) then
    log("Cannot place up block. Fix the issue and press return.");
    io.read()
  end
end

function tryPlaceDown()
  if dont_place then
    return
  end

  if bot.detectDown() then
    if bot.compareDown() then return end
    bot.swingDown(nil, false, 16, dropToME)
  end

  local repeats = 0
  local ret, reason = bot.placeDown()
  while (not ret) and (repeats < 30) do
    bot.swingDown(nil, false, 16, dropToME)
    ret, reason = bot.placeDown()
    repeats = repeats + 1
  end
  if (not ret) then
    log("Cannot place down block. Fix the issue and press return.");
    io.read()
  end
end

function goRechargeAndReturn()
  local f = bot.getFacing()
  local x, y, z = bot.XYZ()
  bot.moveTo(0, 0, 0, false, 16, dropToME)
  while computer.energy() < computer.maxEnergy() * 0.99 do
    os.sleep(5)
  end
  bot.moveTo(x, y, z, true, 16, dropToME)
  bot.turnToFace(f)
end

function printDome(ex,ey,ez)
  bot.resetPosition()
--  resetBlueprint()
--  initBlueprint(-ex-1, ex+1, -ey-1, ey+1, -1, ez+1, TexturedDomeFillerFn(ex,ey,ez))
  
  selectItem(1) -- select stone

  -- check ME upgrade
  if me == nil then
    log("Cannot find me upgrade component. Insert it if you can.")
    log("Press return to continue")
    io.read()
    me = component.upgrade_me
  end

  if me then
    if not me.isLinked() then
      log("ME upgrade is not linked. Link it if you can.")
      log("Press return to continue")
      io.read()
      if not me.isLinked() then me = nil end
    end
    if not db then
      log("DB upgrade not found. Insert it or ME will be disabled.")
      log("Press return to continue")
      io.read()
      db = component.database
      if not db then 
        me = nil 
        log("DB upgrade not found. ME disabled.")
      end
    end
  end

  if me and db then
    log("ME and DB upgrades succesfully discovered.")
  end

  if resume_from_layer == 0 then
    bot.forward(ex, 16, dropToME)
    bot.turnRight()

    bot.down(1, 16, dropToME)   -- ground
  else
    bot.up(resume_from_layer - 1, 16, dropToME)
  end

  for layer = resume_from_layer, ez + 1 do
    resetBlueprint()
    initBlueprintLayer(-ex-1, ex+1, -ey-1, ey+1, -1 + layer, TexturedDomeFillerFn(ex,ey,ez))
    log("Building layer:", layer)
    bot.up(1, 16, dropToME)
  
    while true do
      local x,y,z = bot.X(), bot.Y(), bot.Z()-1

      if computer.energy() < computer.maxEnergy() / 3 then
        -- need to recharge
        log("Need recharge. Returning to start pos.")
        goRechargeAndReturn()
      end

      -- select item and place block
      local bv = getBPV(x, y, z)
      if bv > 0 then
        selectItem(bv)

        setBPV(x, y, z, 0)
        -- if we got to center
        -- don't fill it so we have way in/out
        if not (x == 0 and y == 0) then
          tryPlaceDown()
        end
      end
  
      -- find next unfinished block
      local found, sx, sy = findFarAroundBot() -- around bot
      if found then
        -- move there (relative)
        bot.move(sx, sy, 0, false, 16, dropToME)
      else
        log("Nothing around me. Looking for next area..")
        found, sx, sy = findAnyOnLayer(ex, ey) -- anywhere (closest to bot)
        if found then
          -- move above found block (absolute)
          bot.moveTo(sx, sy, z+1, false, 16, dropToME)
        else
          -- not found: layer done
          log("Nothing else found on this layer")
          break
        end
      end
    end

    log("Layer done.")
  end

  log("Returning to center...")
  bot.turnToFace(2) -- turn to face opposite of our start faceing
  bot.move(bot.X(), bot.Y(), 0) -- move back to start pos
  selectItem(2)
  log("Filling last block...")
  bot.down(2)
  tryPlaceUp()
  log("Done printing dome.")
  bot.turnAround() -- turn around to our start orientation
  bot.down(bot.Z())
  log("Ready for next task.")
end

printDome(dome_size_ex, dome_size_ey, dome_size_ez)

-- vim: set ts=2 sw=2 sts=2 et:
--