peripheral.find("modem", rednet.open)
assert(rednet.isOpen())
rednet.broadcast("store")
