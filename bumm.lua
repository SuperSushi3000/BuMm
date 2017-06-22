dofile("bumm_objects.lua")
elements = {}
elements[1] = switch:new(0, 0)

file.open("/FLASH/BuMmControl.html")
file_str = file.read()
file.close()

server = net.createServer(net.TCP)

function on_receive(socket, data)
    print(data)
    --remove lattenzaun because it begins with %(escape symbol)
    data = string.gsub(data, "%%23", "")
    --parse for header with pattern GET /?key=value HTTP
    local _, _, method, path, vars = string.find(data, "([A-Z]+) (.+)?(.+) HTTP")
    if(method == nil) then
        --if failed, parse for GET /? HTTP
        _, _, method, path = string.find(data, "([A-Z]+) (.+)?.HTTP")
    end
    --if both attempts to parse failed, there is no change to the values of interest
    local values_changed = not(method == nil)
    
    local values = {}
    if(vars ~= nil)then
        for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                values[k] = v
        end
    end
    local control_elements = ""
    for _, element in pairs(elements)do
      element:set_value(vars[element:get_key()])
      control_elements = control_elements..element:get_control_str()
    end
    
    local buffer = file_str
    buffer = string.gsub(buffer, "<!%-%-CONTROL_ELEMENTS%-%->", control_elements)
   
    socket:send(buffer)
end

function on_sent(socket)
    socket:close()
end

function callback(socket)
    socket:on("receive", on_receive)
    socket:on("sent", on_sent)
end

server:listen(80, callback)
