local args = {...}

peripheral.find("modem", rednet.open)
assert(rednet.isOpen())
-- rednet.broadcast("store")

local message = {}
if args[1] == "store" then
    message = { type_ = "request", name = "store" }
elseif args[1] == "get" then
    message = {
        type_ = "request",
        name = "get",
        args = { name = args[2], count = tonumber(args[3]) } }
elseif args[1] == "count" then
    message = {
        type_ = "request",
        name = "count",
        args = { name = args[2] } }
end

rednet.broadcast(textutils.serialize(message))

local id, msg, msg_
repeat
    id, msg_ = rednet.receive()
    msg = textutils.unserialize(msg_)
until msg.type_ == "response"
print(msg.content)