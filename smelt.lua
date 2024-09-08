Graph = {}

function Graph:new()
    local g = { nodes = List:new(), edges = List:new() }
    setmetatable(g, self)
    self.__index = self
    return g
end

function Graph:from(nodes, edges)
  local g = Graph:new()
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

function List:from(xs)
  local l = List:new()
  for _, x in ipairs(xs) do
    l:append(x)
  end
  return l
end

function List:show()
  return self:join(", ")
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

function partial(f, x)
  return function (y) return f(x, y) end
end

-- borrowed from https ://stackoverflow.com/a/27028488
function dump(o)
   if type(o) == 'table' then
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

function main()
  local g = Graph:from({ 1, 2, 3, 4, 5 },
    { edge(1, 2), edge(2, 3), edge(3, 4), edge(4, 5), edge(3, 5) })
  print(g)
  print(g:show())
  print(g:neighbors(2):show())
  local dist, prev = g:dijkstra(3)
  print(dump(dist))
  print(dump(prev))
  print(g:shortest_path(1, 4):show())
  
  -- while true do

  -- end
end

main()
