require "common"

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

-- function Fill()

Union = {}

function Union:new(pos, parts)
    local u = { pos = pos, parts = parts }
    setmetatable(u, self)
    self.__index = self
    return u
end

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

function Dict:get(k) return self.data[dump(k)] end
function Dict:set(k, v)
    self.data[dump(k)] = v
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
