dofile("bumm_objects.lua")
dofile("http_srv.lua")
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

server = net.createServer(net.TCP)


function index_page(values)
  local control_elements = ""
  for element in list_iter(elements)do
    if(values[element:get_key()]) then
      element:set_value(values[element:get_key()])
    end
    control_elements = control_elements..element:get_control_str()
  end
  return string.gsub(html_str, "<!%-%-CONTROL_ELEMENTS%-%->", control_elements)
end

function on_receive(socket, data)
    srv = http_srv:new{callback_index = index_page}
    srv:handle_request(data)
    local buffer = srv:get_response()
    --if there is something to send, send it
    if buffer and buffer ~= "" then
      socket:send(buffer)
    end
end

function on_sent(socket)
    socket:close()
end

function callback(socket)
    socket:on("receive", on_receive)
    socket:on("sent", on_sent)
end

server:listen(80, callback)
