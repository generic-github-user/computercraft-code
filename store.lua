require "common"

function move_xyz(delta)
    print("following vector: " .. serialize_vector(delta))

    move_x(delta.x)
    move_y(delta.y)
    move_z(delta.z)
end

function travel(pos, target)
  -- return move_xyz(target - pos)
  if pos ~= target then
    move_xyz(target - pos)
  end
  return target
end

TurtleStorage = {}

function TurtleStorage:new(slots)
  local t = { slots = slots, type_ = "turtlestorage" }
  setmetatable(t, self)
  self.__index = self
  return t
end

info = {
  inv_peripheral = vector.new(0, 1, 0),
  -- staging = VChest:new(List:singleton(vector.new(0, 1, 1))),
  staging = vector.new(0, 1, 1),
  staging_delta = "up",
  temp_slot = 15,
  fuel_slot = 16,
  storage = VChest:new(Rect:new(vector.new(3, 1, 0), vector.new(6, 1, 2)):blocks_vec()),
  -- fuel = VChest:new(List:singleton(vector.new(-2, 1, 0)))
  fuel_pos = vector.new(-2, 1, 0),
  fuel_limit = 200,
  db_path = "./index"
}
current_pos = vector.new(0, 0, 0)

function player_items(inv_)
  return List:from(inv_.getItems())
end

-- function transfer_items(a, b)

-- end

function List:call(f)
  f(self)
  return self
end

-- function VChest:take(count, slot)
  -- turtle.select(slot)
  -- local n = 0
  -- while n < count do
  -- for _, chest in self.chests:iter()
  -- for _, i in self:slots():iter() do
  -- TODO
-- end

function VChest:rangeError(i)
  error("Index " .. i " out of range; must be between 0 and " .. self:n_slots() - 1)
end

function VChest:address(slot)
  local chest_size = 27 * 2
  if slot < 0 or slot >= self:n_slots() then VChest:rangeError(slot) end
  -- vchest addresses are 0-based
  return self.chests:get(math.floor(slot / chest_size) + 1), (slot % chest_size + 1)
end

function VChest:push(from, to, count)
  local chest_pos, slot = self:address(to)
  return pushItems(chest_pos, from, slot, count)
end

function withTempSlot(f)
  local chest = peripheral.find("minecraft:chest")
  local occupied = chest.getItemDetail(1) ~= nil
  if occupied then local tmp_count = chest.getItemDetail(1).count end

  if occupied then
    print("temp slot occupied, performing swap")
    turtle.select(info.temp_slot)
    turtle.suck(tmp_count)
  end
  local r = f()
  if occupied then
    turtle.select(info.temp_slot)
    turtle.drop(tmp_count)
  end
  return r
end

-- function dropItems(slot, count)
--   turtle.select(slot)
--   return turtle.drop(count)
-- end

-- function suckItems(slot, count)
--   turtle.select(slot)
--   return turtle.suck(count)
-- end

function pushItems(target, from, to, count)
  print("moving " .. (count or "") .. " items from slot " .. from .. " (local) to slot " .. to .. " (remote) @ " .. textutils.serialize(target))
  current_pos = travel(current_pos, target - vector.new(0, 1, 0))
  local chest = peripheral.find("minecraft:chest")

  -- local tmp_count = chest.getItemDetail(1).count
  -- local occupied = tmp_count > 0
  if to == 1 then
    return dropItems(target, from, count)
  else
    return withTempSlot(function ()
      dropItems(target, from, count)
      chest.pushItems(peripheral.getName(chest), 1, count, to) end)
  end
end

function pullItems(target, from, to, count)
  print("moving " .. (count or "") .. " items from slot " .. from .. " (remote) to slot " .. to .. " (local) @ " .. textutils.serialize(target))
  current_pos = travel(current_pos, target - vector.new(0, 1, 0))
  local chest = peripheral.find("minecraft:chest")
  if count == nil then count = chest.getItemDetail(from).count end
  if from == 1 then
    return suckItems(target, to, count)
  else
    return withTempSlot(function ()
      chest.pushItems(peripheral.getName(chest), from, count, 1)
      suckItems(target, to, count)
    end)
  end
end

function getItems(target)
  current_pos = travel(current_pos, target - vector.new(0, 1, 0))
  local chest = peripheral.find("minecraft:chest")
  return List:from(chest.list()) -- TODO: make sure sparse indices don't fuck this up
end

nonEmpty = function (item) return item ~= nil and item.count > 0 end

function dropItems(target, slot, count)
  current_pos = travel(current_pos, target - vector.new(0, 1, 0))
  turtle.select(slot)
  return turtle.drop(count)
end

function suckItems(target, slot, count)
  current_pos = travel(current_pos, target - vector.new(0, 1, 0))
  turtle.select(slot)
  return turtle.suck(count)
end

function refuel()
  local n = math.ceil(info.fuel_limit / 80) + 1
  assert(suckItems(info.fuel_pos, n, info.fuel_slot))
  assert(turtle.refuel(n))
end

function stackSize(slot)
  return turtle.getItemCount(slot) + turtle.getItemSpace(slot)
end

function store_stack(index, slot)
  print("Storing stack from slot " .. slot)
  if turtle.getFuelLevel() < info.fuel_limit then refuel() end
  -- TODO: refactor with takeWhile or some such
  local n = turtle.getItemCount(slot)
  -- local targets = List:new()
  -- for _, i in range(0, storage:n_slots() - 1):iter() do
  --   local x = index:get(i + 1)
  --   if x == nil or x.count 
  local details = turtle.getItemDetail(slot)
  while n > 0 do
    local target = index:findIndexIf(function (item)
      return item == nil or (item.name == details.name and item.count < stackSize(slot)) end)
    if not target.some then return false end
    target = unwrap(target)

    -- TODO: bleh
    local currentSize = index:get(target)
    if currentSize ~= nil then currentSize = currentSize.count
    else currentSize = 0 end

    local m = math.min(n, stackSize(slot) - currentSize)
    info.storage:push(slot, target - 1, m)
    -- if index:get(target) == nil then
    index:set(target, { name = details.name, count = currentSize + m })
    n = n - m
  end
  write_text(info.db_path, textutils.serialize(index))
  return true
end

function read_text(path)
  local f = assert(io.open(path, "r"))
  local content = f:read("*all") -- /shrug
  f:close()
  return content
end

function write_text(path, content)
  local f = assert(io.open(path, "w"))
  local r = f:write(content)
  f:close()
  return r
end

function store()
  print(textutils.serialize(info.storage))

  current_pos = travel(current_pos, info.inv_peripheral - vector.new(0, 1, 0))
  local inv = peripheral.find("inventoryManager")
  player_items(inv)
    :filter(function (i) return i.slot >= 9 and i.slot <= 36 end)
    :filter(function (i) return i.count > 0 end)
    :call(function (l) print("Transferring " .. l:length()
      .. " stacks from player inventory") end)
    :foreach(function (item, j)
      -- TODO: pre-check that target chest is empty
      print(" - slot " .. item.slot .. ": moving " .. item.name .. " (" .. item.count .. ")")
      inv.removeItemFromPlayer(info.staging_delta,
      { toSlot = j - 1, fromSlot = item.slot, count = item.count }) end)

  local index = nil
  if fs.exists(info.db_path) then
    assert(not fs.isDir(info.db_path))
    index = textutils.unserialize(read_text(info.db_path))
  else
    index = List:full(info.storage:n_slots(), nil)
  end
  
  -- TODO: grab multiple (probably 12) stacks at once
  while getItems(info.staging):any(nonEmpty) do
    pullItems(info.staging, unwrap(getItems(info.staging):findIndexIf(nonEmpty)), 1, nil)
    store_stack(index, 1)
  end
  print(getItems(info.staging):length())
  current_pos = travel(current_pos, vector.new(0, 0, 0))
end

function handle(f)
  local success, err = pcall(f)
  if not success then
    current_pos = travel(current_pos, vector.new(0, 0, 0))
  end
  print(err)
  return success, err
end

function main()
  -- pushItems(info.storage, 1, 17, 64)
  -- handle(function () info.storage:push(1, 17, 64) end)

  peripheral.find("modem", rednet.open)
  assert(rednet.isOpen())
  while true do
    if turtle.getFuelLevel() < info.fuel_limit then refuel() end
    id, message = rednet.receive()
    if message == "store" then
      local s, e = handle(store)
      if not s then break end
    end
    sleep(1)
  end
end

main()

-- tmp