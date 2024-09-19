local args = {...}

peripheral.find("modem", rednet.open)
assert(rednet.isOpen())
-- rednet.broadcast("store")

local message = {}
if args[1] == "store" then message = { name = "store" }
elseif args[1] == "get" then
    message = {
        name = "get",
        args = { name = args[2], count = tonumber(args[3]) } }
end

rednet.broadcast(textutils.serialize(message))