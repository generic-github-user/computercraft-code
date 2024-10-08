require "common"
require "vchest"

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
  -- storage = VChest:new(Rect:new(vector.new(3, 1, 0), vector.new(6, 1, 2)):blocks_vec()),
  storage = VChest:new(Rect:new(vector.new(2, 1, 0), vector.new(16, 1, 4)):blocks_vec()),
  -- fuel = VChest:new(List:singleton(vector.new(-2, 1, 0)))
  fuel_pos = vector.new(-2, 1, 0),
  fuel_limit = 400,
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

function withTempSlot(target, f)
  local chest = peripheral.find("minecraft:chest")
  local occupied = chest.getItemDetail(1) ~= nil
  if occupied then local tmp_count = chest.getItemDetail(1).count end

  if occupied then
    print("temp slot occupied, performing swap")
    suckItems(target, info.temp_slot, tmp_count)
    -- turtle.select(info.temp_slot)
    -- turtle.suck(tmp_count)
  end
  local r = f()
  if occupied then
    dropItems(target, info.temp_slot, tmp_count)
    -- turtle.select(info.temp_slot)
    -- turtle.drop(tmp_count)
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

function refuel()
  local n = math.ceil(info.fuel_limit / 80) + 1
  assert(suckItems(info.fuel_pos, info.fuel_slot, n))
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
  print(textutils.serialize(details))
  while n > 0 do
    local target = index:findIndexIf(function (item)
      return item == nil or (item.name == details.name and item.nbt == details.nbt and item.count < stackSize(slot)) end)
    if not target.some then return false end
    target = unwrap(target)
    print("found open slot: " .. target)

    -- TODO: bleh
    local currentSize = index:get(target)
    if currentSize ~= nil then currentSize = currentSize.count
    else currentSize = 0 end

    local m = math.min(n, stackSize(slot) - currentSize)
    info.storage:push(slot, target - 1, m)
    -- if index:get(target) == nil then
    index:set(target, { name = details.name, nbt = details.nbt, count = currentSize + m })
    n = n - m
    save_index()
  end
  return true
end

function save_index()
  return write_text(info.db_path, index:serialize())
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

function List:serialize()
  return textutils.serialize(self)
end

function List:deserialize(text)
  local data = textutils.unserialize(text)
  return List:from(data.data, data.size)
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
  
  -- TODO: grab multiple (probably 12) stacks at once
  while getItems(info.staging):any(nonEmpty) do
    while getItems(info.staging):any(nonEmpty) and not range(1, 12):all(isOccupied) do
      pullItems(info.staging, unwrap(getItems(info.staging):findIndexIf(nonEmpty)), 1, nil, nil)
    end
    for _, i in range(1, 12):filter(isOccupied):iter() do
      store_stack(index, i)
    end
  end
  print(getItems(info.staging):length())
  current_pos = travel(current_pos, vector.new(0, 0, 0))
  return true
end

function List:unique()
  local s = {}
  local l = List:new()
  for _, i in self:iter() do
    if not s[i] then l:append(i) end
    s[i] = true
  end
  return l
end

function getattr(name)
  return (function (x) return x[name] end)
end

function nonNil(x)
  return x ~= nil
end

function disambiguate(name)
  -- local matches = index:map(function (item) return item.name end)
  local names = index:filter(nonNil):map(getattr("name"))
  local real_name
  if names:contains(name) then
    real_name = name
  else
    local matches = names
      :unique()
      :filter(function (item) return string_contains(item, name) end)
    if matches:length() > 1 then
      error("{" .. name .. "} is ambiguous; the following items all match: " .. matches:show())
    end
    -- if matches:length() > 1 then error("") end
    real_name = matches:head()
  end
  print(index:filter(nonNil):length())
  print(real_name)
  return real_name
end

-- TODO: clean this up.....
function fetch(name, count)
  print("Getting " .. count .. "x " .. name .. "...")
  assert(count >= 0)
  local real_name = disambiguate(name)
  if count > count_item(real_name) then
    error("insufficient capacity -- requested " .. count .. " items, only " .. count_item(real_name) .. " present in storage")
  end

  while count > 0 do
    while count > 0 and not range(1, 12):all(isOccupied) do
      local slot = unwrap(index:findIndexIf(function (item) return item ~= nil and item.name == real_name end))
      local item = index:get(slot)
      local n = math.min(item.count, count)
      -- info.storage:pull(slot - 1, unwrap(range(1, 12):findIf(isEmpty)), n)
      info.storage:pull(slot - 1, 1, n)

      if n == item.count then index:set(slot, nil)
      else index:set(slot, { name = item.name, nbt = item.nbt, count = item.count - n }) end
      save_index()

      count = count - n
    end
    range(1, 12):filter(isOccupied):foreach(function (i) dropItems(info.staging, i, nil) end)
  end

  local contents = getItems(info.staging)
  current_pos = travel(current_pos, info.inv_peripheral - vector.new(0, 1, 0))
  local inv = peripheral.find("inventoryManager")
  for slot, item in contents:iter() do -- TODO
    if item ~= nil then inv.addItemToPlayer(info.staging_delta, { slot = slot, count = item.count }) end
  end
  current_pos = travel(current_pos, vector.new(0, 0, 0))
  return true
end

function count_item(name)
  return index:filter(function (item) return item ~= nil and item.name == name end):map(getattr("count")):sum()
end

function count(name)
  local s, name_ = pcall(disambiguate, name)
  if not s then error(name_) end -- ???
  return count_item(name_)
end

function handle(f, ...)
  local success, err = pcall(f, ...)
  if not success then
    save_index()
    current_pos = travel(current_pos, vector.new(0, 0, 0))
  end
  print(err)
  return success, err
end

function main()
  index = nil
  if fs.exists(info.db_path) then
    assert(not fs.isDir(info.db_path))
    index = List:deserialize(read_text(info.db_path))
  else
    print("rebuilding index...")
    -- index = List:full(info.storage:n_slots(), nil)
    index = range(0, info.storage:n_slots() - 1):map(function (i) return info.storage:getSlot(i) end) -- ?
  end

  -- pushItems(info.storage, 1, 17, 64)
  -- handle(function () info.storage:push(1, 17, 64) end)

  peripheral.find("modem", rednet.open)
  assert(rednet.isOpen())
  while true do
    if turtle.getFuelLevel() < info.fuel_limit then refuel() end
    id, message = rednet.receive()
    local request = textutils.unserialize(message)
    local s, r
    if request.name == "store" then
      s, r = handle(store)
    elseif request.name == "get" then
      s, r = handle(function () return fetch(request.args.name, request.args.count) end)
    elseif request.name == "count" then
      -- s, r = handle(function () return count(request.args.name) end)
      s, r = handle(count, request.args.name)
    else
      error("command not recognized")
    end
    local response = { type_ = "response" }
    if s then
      response.content = "operation completed successfully: \n" .. dump(r)
    else
      response.content = "operation failed: \n" .. dump(r)
      -- break
    end
    local rtext = textutils.serialize(response)
    print(rtext)
    rednet.broadcast(rtext)
    sleep(1)
  end
end

main()

-- tmp
-- TODO: add more safety checks