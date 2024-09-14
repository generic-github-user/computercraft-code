require "common"

function move_xyz(delta)
    print("following vector: " .. serialize_vector(delta))

    move_x(delta.x)
    move_y(delta.y)
    move_z(delta.z)
end

function travel(pos, target)
  return move_xyz(target - pos)
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
  staging = VChest:new(List:singleton(vector.new(0, 1, 1))),
  staging_delta = "south",
  storage = VChest:new(Rect(vector.new(3, 1, 0), vector.new(6, 1, 2)):blocks()),
  fuel = VChest:new(List:singleton(vector.new(-2, 1, 0)))
}
current_pos = vector.new(0, 0, 0)

function player_items(inv_)
  return List:from(inv_.getItems())
end

function transfer_items(a, b)

end

function store()
  local inv = peripheral.find("inventoryManager")
  print(textutils.serialize(info.storage))

  player_items(inv)
    :filter(function (i) return i.slot >= 9 and i.slot <= 36 end)
    :filter(function (i) return i.count > 0 end)
    :foreach(function (item, j)
      removeItemFromPlayer(info.staging_delta,
      { toSlot = j, fromSlot = item.slot, count = item.count }) end)
end

store()
