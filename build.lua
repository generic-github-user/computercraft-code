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

-- TODO
function has_vertical_variants(name)
    return string_contains(name, "_log") or string_contains(name, "piston")
end

function placeable_above(state, structure, pos)
    local below = state:contains(pos - vector.new(0, 0, 1))
    local block = structure:get(pos)
    -- TODO: check this...
    return (block.direction == nil
        or block.direction == "z"
        or (block.direction == "-z" and not below)
        or (block.direction == "+z" and below)
        or (cardinal_directions:contains(block.direction) and not has_vertical_variants(block.name))) and
        (block.half == nil or (block.half == "top" and not below) or (block.half == "bottom" and below))
end

function valid_targets(state, structure, pos)
    local block = structure:get(pos)
    local xs = List:from({pos - vector.new(1, 0, 0), pos + vector.new(1, 0, 0)})
    local ys = List:from({pos - vector.new(0, 1, 0), pos + vector.new(0, 1, 0)})
    local deltas = {
        "-x" = vector.new(-1, 0, 0),
        "+x" = vector.new(1, 0, 0),
        "-y" = vector.new(0, -1, 0),
        "+y" = vector.new(0, 1, 0)
    }
    local candidates
    if block.half == "bottom" then
        if block.direction == nil then candidates = List:concat_n(List:from({xs, ys}))
        elseif block.direction == "x" then candidates = xs
        elseif block.direction == "y" then candidates = ys
        else
            local offset
            -- if block.direction == "+x" then b = end TODO
            for k, v in pairs(deltas) do
                if block.direction == k then offset = v end
            end
            if state:contains(pos - offset) or state:contains(pos - vector.new(0, 0, 1)) then
                offset = -offset
            end
            candidates = List:singleton(pos + offset)
        end
    else
        candidates = List:empty()
    end
    return candidates:filter(function (pos) return not state:contains(pos) end)
end

function plan_route(structure)
    local zs = structure_z(structure)
    -- local state = Dict:new()
    local state = Set:new()
    local prev = vector.new(0, 0, 0)
    local route = List:new()
    for i=zs.a, zs.b do
        local layer = structure:keys():filter(function (p) return p.z == i end)
        local top, side = layer:partitionP(function (p) return placeable_above(state, structure, p) end)
        top, side = Set:from(top), Set:from(side)
        while side:size() > 0 do
            local block = side:to_list():min_by(function (b) return (b - prev):length() end)
            local targets = valid_targets(state, structure, block)
            print("targets: " .. targets:show())
            if targets:length() == 0 then
                error("could not find suitable route for structure")
            else
                -- TODO
                route:append(block)
                state:insert(block)
                side:remove(block)
                prev = block
            end
        end
        while top:size() > 0 do
            local block = top:to_list():min_by(function (b) return (b - prev):length() end)
            route:append(block)
            state:insert(block)
            side:remove(block)
            prev = block
        end
    end
    return route
end

function material_batch(structure, route, k)
    local function count_stacks(item_counts)
        local n = 0
        for k, v in pairs(item_counts) do
            n = n + math.ceil(v / 64) -- TODO
        end
        return n
    end

    local items = {}
    -- while count_stacks(items) <= 15 do
    local route_blocks = route:map(structure:get)
    for i=k, route_blocks:length() do
        local b = route_blocks:get(i).name
        if items[b] == nil then items[b] = 1
        else items[b] = items[b] + 1 end
        if count_stacks(items) > 15 then
            items[b] = items[b] - 1
            return items
        end
    end
    return items
end

function build(structure)
    -- print(textutils.serialize(structure:blocks()))
    print(structure:blocks():show())
    print(structure:blocks().size)
    -- print(structure:blocks().type_)

    local route = plan_route(structure)
    print("route: " .. route:show())

    local function getSlot(block)
        return range(1, 15):findIf(function (i) return turtle.getItemDetail(i).name == block.name end)
    end

    local function turnTo(pos1, pos2)
        local d = pos2 - pos1
        if d == vector.new(0, 1, 0) then return 0
        elseif d == vector.new(1, 0, 0) then return 1
        elseif d == vector.new(0, -1, 0) then return 2
        elseif d == vector.new(-1, 0, 0) then return 3
        end
    end

    local state = Set:new()
    -- local directions = List:from({"+y", "+x", "-y", "-x"})
    for i, pos in route:iter() do
        local block = structure:get(pos)
        local slot = getSlot(block)
        if not slot.some then
            for k, v in pairs(material_batch(structure, route, i)) do
                info.storage:fetch(k, v, 1)
            end
            slot = getSlot(block)
        end
        turtle.select(unwrap(slot))
        if placeable_above(state, structure, pos) then
            travel(state, pos + vector.new(0, 0, 1), "build")
            if cardinal_directions:contains(block.direction) then
                local r = unwrap(cardinal_directions:index(block.direction)) - 1
                turnRight(r)
                turtle.placeDown()
                turnLeft(r)
            else
                turtle.placeDown()
            end
        else
            -- TODO: use closest target position
            travel(state, valid_targets(state, structure, pos):head(), "build")
            local r = turnTo(current_pos, pos)
            turnRight(r)
            turtle.place()
            turnLeft(r)
        end
        state:insert(pos)
    end
    travel(state, vector.new(0, 0, 0), "storage")
end

function travel(pos, region)
    local delta = pos - current_pos

    -- TODO

    current_pos = pos
    current_region = region
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

function main()
    current_pos = vector.new(0, 0, 0)
    current_region = "storage"
    return build(Shape:new(Rect:new(vector.new(0, 2, 0), vector.new(2, 3, 1)), Item("stone")))
end

cardinal_directions = List:from({"+y", "+x", "-y", "-x"})
main()
