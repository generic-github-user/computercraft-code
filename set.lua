-- from Claude 3.5 Sonnet

#include "common"

local Set = {}
Set.__index = Set

function Set.new()
    local instance = {
        elements = {}
    }
    return setmetatable(instance, Set)
end

function Set:size()
    local count = 0
    for _ in pairs(self.elements) do
        count = count + 1
    end
    return count
end

function Set:insert(element)
    -- self.elements[element] = true
    self.elements[dump(element)] = element
end

function Set:remove(element)
    self.elements[dump(element)] = nil
end

function Set:contains(element)
    -- return self.elements[element] == true
    return self.elements[element] ~= nil
end

-- Optional: Add a method to print the set
function Set:print()
    local elements = {}
    for e in pairs(self.elements) do
        table.insert(elements, tostring(e))
    end
    print("{" .. table.concat(elements, ", ") .. "}")
end

----

function Set:from(l)
    local s = Set:new()
    for _, x in l:iter() do s:insert(x) end
    return s
end

function Set:to_list()
    local l = List:new()
    for k, v in pairs(self.elements) do l:append(v) end
    return l
end

----

return Set