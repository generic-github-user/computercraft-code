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

-- TODO
function safeBack(n)
    for i=1,n do
        local r = turtle.back()
        if not r then
            back(true, 1)
        end
    end
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

function List:iter()
    return ipairs(self.data)
end

function List:to_set()
    local r = {}
    for _, x in self:iter() do
        r[x] = true
    end
    return r
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
