vec = vector

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
    local l = { size = 0, data = {}, type_ = "list" }
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

function List:findIndexIf(f)
  for i=1, self:length() do
    if f(self.data[i]) then return Some(i) end
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

-- function invert(f)

-- List:none = invert(List:any)

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


Graph = {}

function Graph:new(directed)
    local g = { nodes = List:new(), edges = List:new(), directed = directed, type_ = "graph" }
    setmetatable(g, self)
    self.__index = self
    return g
end

function Graph:from(nodes, edges, directed)
  local g = Graph:new(directed)
  g.nodes = List:from(nodes)
  g.edges = List:from(edges)
  return g
end

function Graph:neighbors(n)
  return self.edges:filter(partial(edge_adjacent, n)):map(partial(edge_other, n))
end

-- temporary
function Graph:show()
  return self.nodes:show() .. "\n\n" .. self.edges:show()
end

function List:from(xs, n)
  -- TODO
  if n == nil then
    local l = List:new()
    for _, x in ipairs(xs) do
      l:append(x)
    end
    return l
  else
    local l = List:full(n, nil)
    for i=1, n do l:set(i, xs[i]) end
    return l
  end
end

function List:show()
  return "[" .. self:join(", ") .. "]"
end

function List:filter(f)
  local l = List:new()
  for _, x in self:iter() do
    if f(x) then l:append(x) end
  end
  return l
end

function List:min_by(f)
  local r = nil
  local v = 0
  for _, x in self:iter() do
    if r == nil or f(x) < v then
      r = x
      v = f(x)
    end
  end
  return r
end

function List:reverse()
  local l = List:new()
  for i=self:length(),1,-1 do
    l:append(self.data[i])
  end
  return l
end

function List:full(n, x)
  local l = List:new()
  for i=1, n do l:append(x) end
  return l
end

function partial(f, x)
  return function (y) return f(x, y) end
end

-- borrowed from https ://stackoverflow.com/a/27028488
function dump(o)
    if type(o) == 'table' then
      if o.type_ == "list" then
         return o:show()
      end
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ', '
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function List:join(s)
  local r = ""
  for i, x in self:iter() do
    r = r .. dump(x)
    if i ~= self:length() then r = r .. s end
  end
  return r
end

function List:length()
  return self.size
end

function edge(a, b)
  return { a = a, b = b }
end

function edge_adjacent(x, e)
  return e.a == x or e.b == x
end

function edge_other(x, e)
  if e.a == x then return e.b
  elseif e.b == x then return e.a
  else error() end
end

function set_size(s)
  local n = 0
  for k, v in pairs(s) do
    if v then n = n + 1 end
  end
  return n
end

function set_to_list(s)
  local l = List:new()
  for k, v in pairs(s) do
    if v then l:append(k) end
  end
  return l
end

function s_contains(s)
  return function (x) return s[x] end
end

function Graph:dijkstra(n)
  assert(not self.directed)

  local dist = {}
  local prev = {}
  -- local r = self.nodes:length()
  local q = self.nodes:to_set()

  for _, v in self.nodes:iter() do
    dist[v] = 100000
    prev[v] = nil
  end
  dist[n] = 0

  -- while r > 0 do
  while set_size(q) > 0 do
    local u = set_to_list(q):min_by(function (i) return dist[i] end)
    q[u] = false
    for _, v in self:neighbors(u):filter(s_contains(q)):iter() do
      local alt = dist[u] + 1
      if alt < dist[v] then
        -- print("new distance -- " .. )
        dist[v] = alt
        prev[v] = u
      end
    end
  end

  return dist, prev
end

function recover_path(prev, a, b)
  local path = List:new()
  while prev[b] ~= nil do
    path:append(b)
    b = prev[b]
  end
  path:append(a)
  return path:reverse()
end

function Graph:shortest_path(a, b)
  local d, p = self:dijkstra(a)
  return recover_path(p, a, b)
end

VirtualChest = {}

function VirtualChest:new(shape)
  assert(shape.dim.x == 1 or shape.dim.y == 1)
  local c = { shape = shape }
  setmetatable(c, self)
  self.__index = self
  return c
end

function VirtualChest:n_slots()
    return self.shape.dim.x * self.shape.dim.y * self.shape.dim.z * 27 * 2
end

VChest = {}

function VChest:new(chests)
    assert(chests:length() ~= 0)
    local c = { chests = chests }
    setmetatable(c, self)
    self.__index = self
    return c
end

function VChest:n_slots()
    return self.chests:length() * 27 * 2
end

function derive_eq(properties)
  return function (a, b)
    return properties:all(function (i) return a[i] == b[i] end)
  end
end

Rect = {}

function Rect:new(pos, dims)
  local r = { pos = pos, dims = dims, type_ = "rect" }
  setmetatable(r, self)
  self.__index = self
  self.__eq = derive_eq(List:from({ "pos", "dims" }))
  return r
end

function Rect:normalize()
  local r = Rect:new(self.pos, self.dims)
  for _, a in List:from({"x", "y", "z"}):iter() do
    if r.dims[a] < 0 then
      r.pos[a] = r.pos[a] + r.dims[a] + 1
      r.dims[a] = -r.dims[a]
    end
  end
  return r
end

function Rect:bounds()
  return self.pos, vec.new(self.pos.x + self.dims.x - 1, self.pos.y + self.dims.y - 1, self.pos.z + self.dims.z - 1)
end

function Rect:bound_ranges()
  local a, b = self:bounds()
  return Range:new(a.x, b.x), Range:new(a.y, b.y), Range:new(a.z, b.z)
end

-- function Rect:intersect(a, b)
  -- local a_bounds = a.bound_ranges()
  -- local b_bounds = b.bound_ranges()
  -- return Rect:from_bounds(Range:intersection)
-- end

function Rect:blocks()
    local xs, ys, zs = self:bound_ranges()
    return List:product(List:from({xs:to_list(), ys:to_list(), zs:to_list()})):map(
        function (v) return { x = v:get(1), y = v:get(2), z = v:get(3) } end
    )
end

function Rect:blocks_vec()
    return self:blocks():map(function (b) return vector.new(b.x, b.y, b.z) end)
end

Range = {}

function Range:new(a, b)
  local r = {a = a, b = b}
  setmetatable(r, self)
  self.__index = self
  return r
end

function Range:to_list()
    return range(self.a, self.b)
end

-- function Range:intersection(a, b)

function List:foreach(f)
  for i, x in self:iter() do
    f(x, i)
  end
end

function List:get(i)
    return self.data[i]
end

function List:set(i, x)
  self.data[i] = x
end

function List:head()
    return self:get(1)
end

function List:tail()
    local r = List:new()
    for i = 2, self:length() do r:append(self:get(i)) end
    return r
end

function List:extend(xs)
  -- TODO
  -- return xs:foreach(partial(self:append, self))
  return xs:foreach(function (x) return self:append(x) end)
end

function List:concat_n(xs)
  local l = List:new()
  xs:foreach(function (x) return l:extend(x) end)
  return l
end

function List:singleton(x)
    return List:from({x})
end

function List:empty()
    return List:from({})
end

function List:slice(a, b)
    return range(a, b):map(function (i) return self:get(i) end)
end

function List:take(n)
  return self:slice(1, math.min(n, self:length()))
end

function cons(x, xs)
    local l = List:singleton(x)
    l:extend(xs)
    return l
end

function List:product(xs)
    if xs:length() == 0 then
        -- return xs:map(List:singleton)
        return List:singleton(List:empty())
    else
        return List:concat_n(xs:head():map(
                function (a) return List:product(xs:tail()):map(
                    function (b) return cons(a, b) end) end))
    end
end

function table_size(t)
  return List:from(pairs(t)):length()
end

print(List:product(List:from({List:from({1, 2, 3}), List:from({6, 7, 8})})):show())
-- print(Rect:new(vec.new(0, 0, 0), vec.new(2, 3, 4)):blocks():show())

-- function table_product(t)
-- end
