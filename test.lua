sv = net.createServer(net.TCP, 30)

function receiver(sck, data)
  print(data)
  sck:close()
end

function callback(conn)
    conn:on("receive", receiver)
end

if sv then
  sv:listen(80, callback)
end