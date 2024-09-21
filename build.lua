require "common"
require "set"

Shape = {}

function Shape:new(shape, material)
    local s = { shape = shape, material = material, type_ = "shape" }
    setmetatable(s, self)
    self.__index = self
    return s
end

function Shape:blocks()
    local blocks = Dict:new()
    for _, pos in self.shape:blocks_vec():iter() do
        -- blocks[pos] = self.material
        blocks:set(pos, self.material)
    end
    return blocks
end

function vec_max(a, b)
    return vector.new(math.max(a.x, b.x), math.max(a.y, b.y), math.max(a.z, b.z))
end

function vec_min(a, b)
    return vector.new(math.min(a.x, b.x), math.min(a.y, b.y), math.min(a.z, b.z))
end

-- function Fill()

Union = {}

function Union:new(pos, parts)
    local u = { pos = pos, parts = parts }
    setmetatable(u, self)
    self.__index = self
    return u
end

function structure_z(s)
    local zs = s:keys():map(function (p) return p.z end)
    return Range:new(zs:min(), zs:max())
end

function placeable_above(state, structure, pos)
    local below = state:get(pos - vector.new(0, 0, 1))
    local block = structure:get(pos)
    return block.direction == nil or block.direction == "z" or
        (block.direction == "-z" and not below) or (block.direction == "+z" and below) or
        (block.half == "top" and not below) or (block.half == "bottom" and below)
end

function plan_route(structure)
    local zs = structure_z(structure)
    local state = Dict:new()
    local prev = vector.new(0, 0, 0)
    local route = List:new()
    for i=zs.a, zs.b do
        local layer = structure:keys():filter(function (p) return p.z == i end)
        local top, side = layer:partitionP(function (p) return place)

function Item(name, data)
    if not string_contains(name, "minecraft:") then name = "minecraft:" .. name end
    if data == nil then data = {} end
    data.name = name
    return data
end

Dict = {}

function Dict:new()
    local d = { data = {}, size = 0, type_ = "dict" }
    setmetatable(d, self)
    -- d.__index = 
    -- TODO
    self.__index = self
    -- self.__index = function (table, k) return table.data[dump(k)] end
    -- self.__newindex = function (table, k, v)
    --     table.data[dump(k)] = v
    --     table.size = table.size + 1
    -- end
    return d
end

function Dict:get(k) return self.data[dump(k)][2] end
function Dict:set(k, v)
    self.data[dump(k)] = {k, v}
    self.size = self.size + 1
    return self
end

function Dict:show()
    local r = ""
    for k, v in pairs(self.data) do
        r = r .. dump(k) .. " = " .. dump(v) .. "\n"
    end
    return r
end

function Dict:contains(k)
    return self:get(k) ~= nil
end

function Dict:keys()
    local l = List:new()
    for k, v in pairs(self.data) do
        l:append(v[1])
    end
    return l
end

function Dict:merge(a, b)
    local c = Dict:new()
    for _, k in a:keys():iter() do c:set(k, a:get(k)) end
    for _, k in b:keys():iter() do c:set(k, b:get(k)) end
    return c
end

function build(structure)
    -- print(textutils.serialize(structure:blocks()))
    print(structure:blocks():show())
    print(structure:blocks().size)
    -- print(structure:blocks().type_)
end

function main()
    return build(Shape:new(Rect:new(vector.new(0, 2, 0), vector.new(2, 3, 1)), Item("stone")))
end

main()
