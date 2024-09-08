function travel_to(pos, target)
    local delta = target - pos
    print("following vector: " .. serialize_vector(delta) .. " (" .. serialize_vector(pos) .. " -> " .. serialize_vector(target) .. ")")

    move_y(delta.y)
    move_x(delta.x)
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

function refuel(pos, fuel_limit)
    print("almost out of fuel, refuelling -- " .. fuel_limit .. " units")
    local p1 = vec(pos)
    local p2 = vec(fuel_pos)
    travel_from(p1, p2)
    turtle.turnLeft()

    display_fuel()
    local slot = turtle.getSelectedSlot()
    turtle.select(fuel_slot)
    local n = math.ceil(fuel_limit / 80) + 1
    assert(turtle.suck(n))
    assert(turtle.refuel(n))
    turtle.select(slot)
    display_fuel()

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

function waterlogged(success, data)
    return success and data.state ~= nil and data.state.waterlogged
end

function isLiquid(success, data)
    return success and (data.name == "minecraft:water" or data.name == "minecraft:lava")
        -- or (data.state ~= nil and data.state.waterlogged))
end

function is_nonsolid(success, data)
    return (not success) or isLiquid(success, data)
end

function display_fuel()
    print("fuel status: " .. turtle.getFuelLevel() .. " / " .. turtle.getFuelLimit())
end

function retry(f)
    repeat
        local r = f()
        if r then break end
        sleep(1)
    until false
    return true
end

function mine_layer(shape_, i)
    local x = shape_.x
    local y = shape_.y
    -- local pos = {x = 0, y = 0, z = -(i + (mode - 2))}
    print("current position: " .. textutils.serialize(pos))
    display_fuel()

    local fillIfEmpty = function ()
        -- if is_nonsolid(unpack(turtle.inspect())) then
        local s, d = turtle.inspect()
        if waterlogged(s, d) then
            turtle.dig()
        end
        -- turtle.dig()

        local s, d = turtle.inspect()
        if is_nonsolid(s, d) then
            turtle.select(findSlot(fuel_slot + 1, 16))
            assert(retry(turtle.place))
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
            local pos = { x = (j - 1), y = 0, z = -(i - 1) }
            local fuel_limit = (x * y + x) * 2 * 1.5
            if turtle.getFuelLevel() < fuel_limit then
                refuel(pos, fuel_limit)
            end
            if occupied_slots(storage_slots) > 4 then
                deposit_items(pos, storage_slots)
            end

            for k=1,y do
                local success, data = turtle.inspectDown()
                if waterlogged(success, data) then
                    turtle.digDown()
                end
                
                local success, data = turtle.inspectDown()
                if (success
                        and (data.name == "minecraft:water" or data.name == "minecraft:lava")
                        and data.state.level == 0) then
                    -- turtle.select(fuel_slot + 1)
                    turtle.select(findSlot(fuel_slot + 1, 16))
                    assert(retry(turtle.placeDown))
                end
                if k ~= y then
                    forward(true, 1)
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
                    safeBack(1)
                end
            end

            if j ~= x then
                right(true, 1)
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
                        retry(turtle.place)
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
shape = { x = 30, y = 30, z = 90 }
fuel_pos = { x = 0, y = -1, z = 0 }

storage_pos = { x = 0, y = -3, z = 0 }
storage_shape = { y = 10, z = 3 }
fuel_slot = 13
fuel_increment = 8
storage_slots = 12
start = 3
mode = 1

function main()
    -- pre-checks
    assert(range(1, storage_slots):all(function (i)
        local data = turtle.getItemDetail(i)
        return data == nil
    end))
    assert(range(fuel_slot+1, 16):all(function (i)
        local data = turtle.getItemDetail(i)
        return data ~= nil and data.name == "minecraft:cobblestone" and data.count == 64
    end))

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
-- TODO: add starting material assertions
-- TODO: more assertions (including most/all movements)
-- TODO: virtual chests that stripe together multiple physical storage units
