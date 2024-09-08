require "common"

function Graph:new()
    local g = { nodes = List:new(), edges = List:new() }
    setmetatable(g, self)
    self.__index = self
    return g
end

function Graph:from(nodes, edges)
  local g = Graph:new()
  g.nodes = nodes
  g.edges = edges
  return g
end

function Graph:neighbors(n)
  return self.edges:filter(partial(edge_adjacent, n)):map(partial(edge_other, n))
end

-- temporary
function Graph:show()
  return self.nodes:show() .. "\n\n" .. self.edges:show()
end

function List:show()
  return self:join(", ")
end

function List:join(s)
  local r = ""
  for i, x in self:iter() do
    r = r .. x
    if i ~= self:length() then r = r .. s end
  end
  return r
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

  -- while r > 0 do
  while set_size(q) > 0 do
    local u = set_to_list(q):min_by(function (i) return dist[i] end)
    q[u] = false
    for _, v in self:neighbors(u):filter(s_contains(q)):iter() do
      local alt = dist[u] + 1
      if alt < dist[v] then
        dist[v] = alt
        prev[v] = u
      end
    end
  end

  return dist, prev
end

function main()
  local g = Graph:from({ 1, 2, 3, 4, 5 },
    { edge(1, 2), edge(2, 3) })
  print(g:show())
  while true do

  end
end

main()
