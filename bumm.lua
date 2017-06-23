dofile("bumm_objects.lua")
elements = {}
elements[1] = switch:new{index = 1, pin = 0}
elements[2] = switch:new{index = 2, pin = 1}
elements[3] = fader:new{index = 1, pin = 2}
elements[4] = rgb:new{index = 1, pins={r=6, g=5, b=7}}
 
file.open("/FLASH/BuMmControl.html")
file_str = file.read()
file.close()

server = net.createServer(net.TCP)

function on_receive(socket, data)
    print(data)
    --substitute html character codes by their appropriate characters
    data = string.gsub(data, "%%23", "#")
    data = string.gsub(data, "%%2F", "/")
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
        --print(vars)
        for k, v in string.gmatch(vars, "(%w+/%d+)=(#?%w+)&*") do
                values[k] = v
                print(k..": "..v..", ")
        end
    end
    
    local control_elements = ""
    for element in list_iter(elements)do
      if(vars ~= nil) then
        --print(values[element:get_key()])
        element:set_value(values[element:get_key()])
      end
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
