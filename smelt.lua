function furnace_index(i)
  return vec.new(i % width, 1, (i // width) * 2 + 1)
end

width = 10
height = 2
pos = {
  inputs = {},
  fuel = {},
  outputs = {}
}
fuel_limit = math.ceil(width * height * 3 * 1.5)

function distribute_inputs()

end

function move_xyz(delta)
    print("following vector: " .. serialize_vector(delta))

    move_x(delta.x)
    move_y(delta.y)
    move_z(delta.z)
end

function travel()

function main()
  local g = Graph:from({ 1, 2, 3, 4, 5 },
    { edge(1, 2), edge(2, 3), edge(3, 4), edge(4, 5), edge(3, 5) },
    false)
  print(g)
  print(g:show())
  print(g:neighbors(2):show())
  local dist, prev = g:dijkstra(3)
  print(dump(dist))
  print(dump(prev))
  print(g:shortest_path(1, 4):show())
  print(Rect(vec.new(1, 2, 3), vec.new(4, 5, 6)) == Rect(vec.new(1, 2, 3), vec.new(4, 5, 6)))
  
  -- while true do
    -- distribute_inputs()
  -- end
end

main()
