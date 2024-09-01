function right(dig, n)
    turtle.turnRight()
    -- if dig then turtle.dig() end
    forward(dig, n)
    turtle.turnLeft()
end

function left(dig, n)
    turtle.turnLeft()
    -- if dig then turtle.dig() end
    forward(dig, n)
    -- turtle.turnLeft() ?
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

-- function move_dig(f, g)
    -- return (function (i)
        -- g()
        -- f()
    -- end)
-- end

up = move_n(turtle.up, turtle.digUp)
down = move_n(turtle.down, turtle.digDown)
forward = move_n(turtle.forward, turtle.dig)
-- back = move_n(turtle.back)
function back(dig, n)
    turnRight(2)
    forward(dig, n)
    turnRight(2)
end

-- digUp = move_dig(turtle

-- left_n = move_n(function () return left(true) end)
-- right_n = move_n(function () return right(true) end)

width = 12
immediate_replant = false
refslot = 15
dist = 10

function refresh(i, height, f)
    turtle.turnLeft()
    -- for j=1,i+6-1 do turtle.forward() end
    forward(true, i+dist-1)
    assert(up(false, height))

    f()
    
    assert(down(false, height))
    -- for j=1, i+6-1 do turtle.back() end
    back(true, i+dist-1)
    turtle.turnRight()
end

function refuel()
    turtle.select(16)
    assert(turtle.suck(8))
    turtle.refuel(8)
    turtle.select(1)
end

function replenish_saplings()
    local slot = turtle.getSelectedSlot()
    turtle.select(9)
    -- local n = turtle.getItemSpace()
    local n = (math.ceil(width * 2 * (2 / 3)) + 1) - turtle.getItemCount()
    assert(turtle.suck(n))
    turtle.select(slot)
end

function deposit_items()
    local slot = turtle.getSelectedSlot()
    for i=1,8 do
        turtle.select(i)
        if turtle.getItemCount() > 0 then
            assert(turtle.compareTo(refslot))
            turtle.drop()
        end
    end
    turtle.select(slot)
end

function attempt_harvest(depth)
    local success, data = turtle.inspect()
    turtle.select(1)
    print(data.name)
    -- assert(success)
    if not success then
        print("no tree here, skipping")
    end

    if success and data.name == "minecraft:spruce_log" then
        print("found tree section, chopping")
        height = 0
        turtle.dig()
        assert(turtle.forward())
        repeat
            turtle.digUp()
            turtle.up()
            height = height + 1
        until not turtle.detectUp()
        for j=1,height do
            -- handle leaves from newly grown trees
            turtle.digDown()
            turtle.down()
        end
        if depth == 0 then
          attempt_harvest(1)
        end
        turtle.back()
    end
end

function replant()
    turtle.select(9)
    -- assert(turtle.inspect ...)
    for i=1,width do
        if i % 3 ~= 0 then
            print("replanting slice " .. i)
            if turtle.getItemCount() < width * (2 / 3) then
                refresh(i, 2, replenish_saplings)
            end
            if not turtle.detect() then
                -- should be enough to handle race condition
                forward(true, 1)
                -- TODO: clean this up...
                turtle.dig()
                turtle.place()
                back(true, 1)
                -- turtle.back()
                turtle.place()
            end
        end
        right(true, 1)
    end
end

function occupied_slots(k)
    local n = 0
    for i=1,k do
        if turtle.getItemCount(i) > 0 then n = n + 1 end
    end
    return n
end

function full_harvest()
    for i=1,width do
        print("processing slice " .. i)
        print("fuel status: " .. turtle.getFuelLevel() .. " / " .. turtle.getFuelLimit())

        if turtle.getFuelLevel() < 50 * 2 * 2 * 1.5 then
            refresh(i, 1, refuel)
        end
        if occupied_slots(8) > 4 then
            refresh(i, 0, deposit_items)
        end

        if i % 3 ~= 0 then
            attempt_harvest(0)

            -- drop sticks and saplings into water stream
            local slot = turtle.getSelectedSlot()
            for i=1,8 do
                turtle.select(i)
                if turtle.getItemCount() > 0 and not turtle.compareTo(refslot) then
                    turtle.dropDown()
                end
            end
            turtle.select(slot)
        end

        right(true, 1)
    end
    print("harvest cycle complete")

    -- turtle.turnLeft()
    -- assert(forward(width))
    -- turtle.turnRight()
    left(true, width)

    replant()
    left(true, width)
end

function main()
    repeat
        assert(turtle.getItemCount(refslot) ~= 0)
        full_harvest()
        sleep(30)
    until false
end

main()

-- todo: virtual fence, block breaking pre-checks
