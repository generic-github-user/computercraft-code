function right(dig, n)
    turtle.turnRight()
    forward(dig, n)
    turtle.turnLeft()
end

function left(dig, n)
    turtle.turnLeft()
    forward(dig, n)
    turtle.turnRight()
end

function move_n(f, g)
  return (function (dig, i)
      for j=1,i do
        if dig then g() end
        assert(f())
      end
      return true
  end)
end

function turnRight(n)
    for i=1,n do turtle.turnRight() end
end

up = move_n(turtle.up, turtle.digUp)
down = move_n(turtle.down, turtle.digDown)
forward = move_n(turtle.forward, turtle.dig)
-- back = move_n(turtle.back)
function back(dig, n)
    -- if not dig then
    if dig then
        turnRight(2)
        forward(dig, n)
        turnRight(2)
    else
        for i=1,n do turtle.back() end
    end
    -- current_pos = current_pos + vec(0, -1, 0)
end

function axis_movement(f, g)
    return (function (n)
        if n < 0 then
            f(false, -n)
        elseif n > 0 then
            g(false, n)
        end
    end)
end

move_x = axis_movement(left, right)
move_y = axis_movement(back, forward)
move_z = axis_movement(down, up)

function placeLeft()
    turtle.turnLeft()
    turtle.place()
    turtle.turnRight()
end

function placeRight()
    turtle.turnRight()
    turtle.place()
    turtle.turnLeft()
end

function placeBack()
    turnRight(2)
    turtle.place()
    turnRight(2)
end

-- TODO: orientation-based API
function mkLeft(f)
    return (function ()
        turtle.turnLeft()
        local r = f()
        turtle.turnRight()
        return r
    end)
end

function mkRight(f)
    return (function ()
        turtle.turnRight()
        local r = f()
        turtle.turnLeft()
        return r
    end)
end

function mkBack(f)
    return (function ()
        turnRight(2)
        local r = f()
        turnRight(2)
        return r
    end)
end

placeLeft = mkLeft(turtle.place)
placeRight = mkRight(turtle.place)
placeBack = mkBack(turtle.place)
inspectLeft = mkLeft(turtle.inspect)
inspectRight = mkRight(turtle.inspect)
inspectBack = mkBack(turtle.inspect)

function Some(x)
    return { some = true, value = x }
end

function None()
    return { some = false, value = nil }
end

function unwrap(x)
    assert(x.some)
    return x.value
end

List = {}

function List:new()
    local l = { size = 0, data = {} }
    setmetatable(l, self)
    self.__index = self
    return l
end

function List:append(x)
    self.data[self.size+1] = x
    self.size = self.size + 1
    return self
end

function List:findIf(f)
    for i=1,self.size do
        if f(self.data[i]) then
            -- return Some(i)
            return Some(self.data[i])
        end
    end
    return None()
end

function List:map(f)
    local l = List:new()
    for i=1, self.size do
        l:append(f(self.data[i]))
    end
    return l
end

function List:all(f)
    for i=1, self.size do
        if not f(self.data[i]) then
            return false
        end
    end
    return true
end

function List:any(f)
    for i=1, self.size do
        if f(self.data[i]) then
            return true
        end
    end
    return false
end


function range(a, b)
    local l = List:new()
    for i=a, b do
        l:append(i)
    end
    return l
end

-- print(range(5, 9).findIf(function (i) return i > 7 end))
print(unwrap(range(5, 9):findIf(function (i) return i > 7 end)))

function isOccupied(i)
    return turtle.getItemCount(i) > 0
end

function findSlot(a, b)
    return unwrap(range(a, b):findIf(isOccupied))
end

-- function refresh(i, height, f)
    -- back(false, i+6-1)
    -- turtle.turnLeft()
    -- assert(up(false, height))
-- 
    -- f()
    -- 
    -- assert(down(false, height))
    -- forward(false, i+6-1)
    -- turtle.turnRight()
-- end

function occupied_slots(k)
    local n = 0
    for i=1,k do
        if turtle.getItemCount(i) > 0 then n = n + 1 end
    end
    return n
end

function serialize_vector(v)
    return "<" .. v.x .. ", " .. v.y .. ", " .. v.z .. ">"
end

function travel_to(pos, target)
    local delta = target - pos
    print("following vector: " .. serialize_vector(delta) .. " (" .. serialize_vector(pos) .. " -> " .. serialize_vector(target) .. ")")

    move_x(delta.x)
    move_y(delta.y)
    move_z(delta.z)
    current_pos = target
end

function travel_from(pos, target)
    local delta = target - pos
    print("following vector: " .. serialize_vector(delta) .. " (" .. serialize_vector(pos) .. " -> " .. serialize_vector(target) .. ")")

    move_z(delta.z)
    move_x(delta.x)
    move_y(delta.y)
    current_pos = target
end

function vec(v)
    return vector.new(v.x, v.y, v.z)
end

function refuel(pos)
    print("almost out of fuel, refuelling")
    local p1 = vec(pos)
    local p2 = vec(fuel_pos)
    travel_from(p1, p2)
    turtle.turnLeft()

    local slot = turtle.getSelectedSlot()
    turtle.select(fuel_slot)
    assert(turtle.suck(fuel_increment))
    turtle.refuel(fuel_increment)
    turtle.select(slot)

    turtle.turnRight()
    travel_to(p2, p1)
end

function deposit_items(pos, slots)
    print("storing inventory contents in chest array")
    -- local p1 = vec(pos)
    -- local p2 = vec(
    local success = false
    current_pos = vec(pos)
    for yi=1,storage_shape.y do
        for zi=1,storage_shape.z do
            travel_from(current_pos, vec(storage_pos) + vector.new(0, -(yi-1), zi-1))
            turtle.turnLeft()
            assert(turtle.detect())
            -- TODO: higher-level handling of inventory slot selection/deselection
            for s=1,slots do
                turtle.select(s)
                turtle.drop()
            end
            turtle.turnRight()
            if occupied_slots(storage_slots) == 0 then
                success = true
                -- break
                goto next
            end
        end
    end
    ::next::
    turtle.select(1)
    assert(success)
    travel_to(current_pos, vec(pos)) -- ?
end

function isLiquid(success, data)
    return success and (data.name == "minecraft:water" or data.name == "minecraft:lava")
end

function is_nonsolid(success, data)
    return (not success) or isLiquid(success, data)
end

function mine_layer(shape_, i)
    local x = shape_.x
    local y = shape_.y
    -- local pos = {x = 0, y = 0, z = -(i + (mode - 2))}
    local pos = { x = 0, y = 0, z = -(i - 1) }
    print("current position: " .. textutils.serialize(pos))
    print("fuel status: " .. turtle.getFuelLevel() .. " / " .. turtle.getFuelLimit())
    if turtle.getFuelLevel() < (x * y + x) * 2 * 1.5 then
        refuel(pos)
    end
    if occupied_slots(storage_slots) > 4 then
        deposit_items(pos, storage_slots)
    end

    local fillIfEmpty = function ()
        -- if is_nonsolid(unpack(turtle.inspect())) then
        local s, d = turtle.inspect()
        if is_nonsolid(s, d) then
            turtle.select(findSlot(fuel_slot + 1, 16))
            assert(turtle.place())
        end
    end

    local fillEdges = function ()
        down(true, 1)
        for i=0,3 do
            turtle.select(1)
            local limit = ({y, x})[i % 2 + 1]
            for n=1,limit do
                mkLeft(fillIfEmpty)()
                if n ~= limit then forward(true, 1) end
            end
            turtle.turnRight()
        end
        up(true, 1)
    end

    local shouldPickup = function (inspector)
        -- local success, data = turtle.inspect()
        local success, data = inspector()
        return (success and (data.name == "minecraft:stone" or data.name == "minecraft:cobblestone") and
                range(fuel_slot + 1, 16):map(turtle.getItemSpace):any(
                    function (i) return i ~= 0 end))
    end

    if mode == 1 then
        fillEdges()

        for j=1,x do
            for k=1,y do
                local success, data = turtle.inspectDown()
                if (success
                        and (data.name == "minecraft:water" or data.name == "minecraft:lava")
                        and data.state.level == 0) then
                    turtle.select(fuel_slot + 1)
                    assert(turtle.placeDown())
                end
                if k ~= y then
                    forward(false, 1)
                end
            end

            for k=y,1,-1 do
                if turtle.detectDown() then
                    -- turtle.select(fuel_slot + 1)
                    -- if (not turtle.compareDown()) or turtle.getItemSpace() == 0 then
                    local s, d = turtle.inspect()
                    -- if (not (success and (data.name == "minecraft:stone" or data.name == "minecraft:cobblestone"))) or 
                    -- TODO: bug
                    if shouldPickup(turtle.inspectDown) then
                        turtle.select(fuel_slot + 1)
                    else
                        turtle.select(1)
                    end
                    turtle.digDown()
                end
                if k ~= 1 then
                    back(false, 1)
                end
            end

            if j ~= x then
                right(false, 1)
            end
        end
    elseif mode == 2 then
        for j=1,x do
            for k=1,y do
                if j == 1 then mkLeft(fillIfEmpty)() end
                if j == x then mkRight(fillIfEmpty)() end
                if k == 1 then mkBack(fillIfEmpty)() end
                if k == y then fillIfEmpty() end

                -- TODO
                if k ~= y then
                    local s, d = turtle.inspect()
                    if isLiquid(s, d) and d.state.level == 0 then
                        -- turtle.select(fuel_slot + 1)
                        turtle.select(findSlot(fuel_slot + 1, 16))
                        turtle.place()
                    end
                end

                if shouldPickup(turtle.inspect) then
                    turtle.select(fuel_slot + 1)
                else
                    turtle.select(1)
                end

                if k ~= y then
                    forward(true, 1)
                    -- if j % 2 == 1 then
                        -- forward(true, 1)
                    -- else
                        -- TODO
                        -- back(true, 1)
                    -- end
                end
            end
            if j ~= x then
                if j % 2 == 1 then turtle.turnRight() else turtle.turnLeft() end
                turtle.select(1)
                forward(true, 1)
                if j % 2 == 1 then turtle.turnRight() else turtle.turnLeft() end
            end
        end
        if x % 2 == 0 then turnRight(2) else back(true, y-1) end
    end
    -- ??
    left(false, x-1)
end

current_pos = vector.new(0, 0, 0)
shape = { x = 5, y = 5, z = 3 }
fuel_pos = { x = 0, y = -1, z = 0 }

storage_pos = { x = 0, y = -3, z = 0 }
storage_shape = { y = 5, z = 1 }
fuel_slot = 13
fuel_increment = 8
storage_slots = 12
start = 0
mode = 1

function main()
    local z = shape.z
    for i=1,z do
        print("mining layer " .. i)
        -- mine_layer(shape.x, shape.y, i)
        if mode == 2 then
            down(true, 1)
        end
        if i > start then
            mine_layer(shape, i)
        end
        if mode == 1 then
            if i ~= z then down(false, 1) end
        end
    end
    up(false, z - 1)
    deposit_items({x = 0, y = 0, z = 0}, 16)
end

main()

-- TODO: handle mobs/entities
