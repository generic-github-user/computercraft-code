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

function deposit_items(pos)
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
            for s=1,14 do
                turtle.select(s)
                turtle.drop()
            end
            turtle.turnRight()
            if occupied_slots(14) == 0 then
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

function mine_layer(shape_, i)
    local x = shape_.x
    local y = shape_.y
    local pos = {x = 0, y = 0, z = -(i-1)}
    if turtle.getFuelLevel() < (x * y + x) * 2 * 1.5 then
        refuel(pos)
    end
    if occupied_slots(14) > 4 then
        deposit_items(pos)
    end
    for j=1,x do
        for k=1,y do
            local success, data = turtle.inspectDown()
            if success and (data.name == "minecraft:water" or data.name == "minecraft:lava") and data.state.level == 0 then
                turtle.select(16)
                assert(turtle.placeDown())
            end
            if k ~= y then
                forward(false, 1)
            end
        end

        for k=y,1,-1 do
            if turtle.detectDown() then
                turtle.select(16)
                if (not turtle.compareDown()) or turtle.getItemSpace() == 0 then
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
    -- ??
    left(false, x-1)
end

current_pos = vector.new(0, 0, 0)
shape = { x = 10, y = 10, z = 30 }
fuel_pos = { x = 0, y = -1, z = 0 }

storage_pos = { x = 0, y = -3, z = 0 }
storage_shape = { y = 5, z = 1 }
fuel_slot = 15
fuel_increment = 8
start = 5

function main()
    local z = shape.z
    for i=1,z do
        -- mine_layer(shape.x, shape.y, i)
        if i > start then
            mine_layer(shape, i)
        end
        if i ~= z then down(false, 1) end
    end
    up(false, z-1)
    deposit_items({x = 0, y = 0, z = 0})
end

main()
