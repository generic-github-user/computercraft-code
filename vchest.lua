function pushItems(target, from, to, count, expect)
    print("moving " .. (count or "") .. " items from slot " .. from .. " (local) to slot " .. to .. " (remote) @ " .. textutils.serialize(target))
    current_pos = travel(current_pos, target - vector.new(0, 1, 0))
    local chest = peripheral.find("minecraft:chest")
  
    -- local tmp_count = chest.getItemDetail(1).count
    -- local occupied = tmp_count > 0
    assert(expect == nil or item_eq(chest.getItemDetail(to), expect))
    if to == 1 then
      return dropItems(target, from, count)
    else
      return withTempSlot(target, function ()
        dropItems(target, from, count)
        assert(chest.pushItems(peripheral.getName(chest), 1, count, to) == count)
      end)
    end
end

function pullItems(target, from, to, count, expect)
    print("moving " .. (count or "") .. " items from slot " .. from .. " (remote) to slot " .. to .. " (local) @ " .. textutils.serialize(target))
    current_pos = travel(current_pos, target - vector.new(0, 1, 0))
    local chest = peripheral.find("minecraft:chest")
    if count == nil then count = chest.getItemDetail(from).count end
    print("expecting: " .. textutils.serialize(expect))
    -- print("found: " .. textutils.serialize(chest.getItemDetail(from)))
    assert(expect == nil or item_eq(chest.getItemDetail(from), expect))
    if from == 1 then
        return suckItems(target, to, count)
    else
        return withTempSlot(target, function ()
        assert(chest.pushItems(peripheral.getName(chest), from, count, 1) == count)
        suckItems(target, to, count)
        end)
    end
end

-- item_eq = 
function item_eq(a, b)
    return (a == nil and b == nil) or (a.name == b.name and a.count == b.count and a.nbt == b.nbt)
end

function getSlot(target, i)
    current_pos = travel(current_pos, target - vector.new(0, 1, 0))
    local chest = peripheral.find("minecraft:chest")
    return chest.getItemDetail(i)
end

function getItems(target)
    current_pos = travel(current_pos, target - vector.new(0, 1, 0))
    local chest = peripheral.find("minecraft:chest")
    return List:from(chest.list(), 27) -- TODO: make sure sparse indices don't fuck this up
end

nonEmpty = function (item) return item ~= nil and item.count > 0 end
isEmpty = function (i) return turtle.getItemCount(i) == 0 end

function dropItems(target, slot, count)
    if count == nil then count = turtle.getItemCount(slot) end
    current_pos = travel(current_pos, target - vector.new(0, 1, 0))
    turtle.select(slot)
    return turtle.drop(count)
end

function suckItems(target, slot, count)
    -- if count == nil then count = turtle.getItemCount(slot) end
    current_pos = travel(current_pos, target - vector.new(0, 1, 0))
    turtle.select(slot)
    return turtle.suck(count)
end

function VChest:rangeError(i)
  error("Index " .. i .. " out of range; must be between 0 and " .. self:n_slots() - 1)
end

function VChest:address(slot)
  local chest_size = 27 * 2
  if slot < 0 or slot >= self:n_slots() then self:rangeError(slot) end
  -- vchest addresses are 0-based
  return self.chests:get(math.floor(slot / chest_size) + 1), (slot % chest_size + 1)
end

function VChest:getSlot(i)
  local chest_pos, slot = self:address(i)
  return getSlot(chest_pos, slot)
end

function VChest:pull(from, to, count)
  print("pull: " .. from .. " " .. to .. " " .. count)
  local chest_pos, slot = self:address(from)
  return pullItems(chest_pos, slot, to, count, index:get(from + 1))
end

function VChest:push(from, to, count)
  local chest_pos, slot = self:address(to)
  return pushItems(chest_pos, from, slot, count, index:get(to + 1))
end