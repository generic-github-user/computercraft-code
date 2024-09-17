require "common"

function move_xyz(delta)
    print("following vector: " .. serialize_vector(delta))

    move_x(delta.x)
    move_y(delta.y)
    move_z(delta.z)
end

function travel(pos, target)
  -- return move_xyz(target - pos)
  move_xyz(target - pos)
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
  fuel = vector.new(-2, 1, 0),
  fuel_limit = 200
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

function VChest:address(slot)
  return self.chests:get(math.floor(slot / (27 * 2)) + 1)
end

function VChest:push(from, to, count)
  local chest_pos, slot = self:address(to)
  return pushItems(chest_pos, from, slot, count)
end

function withTempSlot(f)
  if occupied then
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

function pushItems(target, from, to, count)
  current_pos = travel(current_pos, target - vector.new(0, 1, 0))
  local chest = peripheral.find("minecraft:chest")

  local tmp_count = chest.getItemDetail(1).count
  local occupied = tmp_count > 0
  return withTempSlot(function ()
    turtle.select(from)
    turtle.drop(count)
    chest.pushItems(chest, 1, to, count) end)
end

function suckItems(target, count, slot)
  current_pos = travel(current_pos, target - vector.new(0, 1, 0))
  turtle.select(slot)
  return turtle.suck(count)
end

function refuel()
  local n = math.ceil(info.fuel_limit / 80) + 1
  assert(suckItems(info.fuel_pos, n, info.fuel_slot))
  assert(turtle.refuel(n))
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
end

function main()
  -- pushItems(info.storage, 1, 17, 64)
  info.storage:push(1, 17, 64)

  peripheral.find("modem", rednet.open)
  assert(rednet.isOpen())
  while true do
    id, message = rednet.receive()
    if turtle.getFuelLevel() < info.fuel_limit then refuel() end
    if message == "store" then store() end
    sleep(1)
  end
end

main()
