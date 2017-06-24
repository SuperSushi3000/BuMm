dofile("bumm_objects.lua")

--Load elements from JSON file
file.open("/FLASH/config.json")
file_str = file.read()
file.close()

local json_table = sjson.decode(file_str)

elements = {}
--add switches
for switch_ in list_iter(json_table.switches) do
  table.insert(elements, switch:new{index = switch_.index, pin = tonumber(switch_.pin)})
end
--add faders
for fader_ in list_iter(json_table.faders) do
  table.insert(elements, fader:new{index = fader_.index, pin = tonumber(fader_.pin)})
end
--add rgbs
for rgb_ in list_iter(json_table.rgbs) do
  table.insert(elements, rgb:new{index = rgb_.index,
                                 pins = 
                                 {r=tonumber(rgb_.pin_r), 
                                  g=tonumber(rgb_.pin_g), 
                                  b=tonumber(rgb_.pin_b)}})
end

--Load HTML page representing GUI 
file.open("/FLASH/BuMmControl.html")
html_str = file.read()
file.close()

--Load style sheet
file.open("/FLASH/bumm.css")
local style_str = file.read()
file.close()

--put style sheet into html string
html_str = string.gsub(html_str, "<!%-%-STYLESHEET%-%->", style_str)

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
    
    local buffer = html_str
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
