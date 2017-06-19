gpio.mode(0, gpio.OUTPUT)
gpio.write(0, gpio.LOW)
gpio.mode(1, gpio.OUTPUT)
pwm.setup(1, 100, 0)
pwm.start(1)

--RGB LED, 5=green, 6=red, 7=blue
gpio.mode(5, gpio.OUTPUT)
pwm.setup(5, 100, 0)
pwm.start(5)
gpio.mode(6, gpio.OUTPUT)
pwm.setup(6, 100, 512)
pwm.start(6)
gpio.mode(7, gpio.OUTPUT)
pwm.setup(7, 100, 512)
pwm.start(7)

pin1_value = 0
rgb_value = "#FFFFFF"

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

    local pin0_checked = ""
    
    if(values.pin0 == "on")then
        gpio.write(0, gpio.HIGH)
        pin0_checked = " checked=\"checked\""--nice to read, isn't it?
    elseif(values_changed) then
        gpio.write(0, gpio.LOW)
    end

  
    if(values.pin1)then
        pin1_value = values.pin1
        pwm.setduty(1, pin1_value)
    end

    if(values.rgb)then
        rgb_value = "#"..values.rgb
        local color = tonumber(values.rgb, 16)
        --set red pwm duty cycle
        print(1023-bit.lshift(bit.band(color, 0xFF0000),2))
        --pwm.setduty(6, )
        --set green pwm duty cycle
        --pwm.setduty(5, 1023-bit.lshift(bit.band(color, 0x00FF00),2))
        --set blue pwm duty cycle
        --pwm.setduty(7, 1023-bit.lshift(bit.band(color, 0x0000FF),2))
    end

    local buffer = file_str
    buffer = string.gsub(buffer, "<!%-%-VAR/pin0_checked%-%->", pin0_checked)
    buffer = string.gsub(buffer, "<!%-%-VAR/pin1_value%-%->", pin1_value)
    buffer = string.gsub(buffer, "<!%-%-VAR/rgb_value%-%->", rgb_value)
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
