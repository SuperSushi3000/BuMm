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

server = net.createServer(net.TCP)

function on_receive(socket, data)
    print(data)
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
        pin0_checked = "checked=\"checked\""--nice to read, isn't it?
    elseif(values_changed) then
        gpio.write(0, gpio.LOW)
    end

  
    if(values.pin1)then
        print(values.pin1)
        pin1_value = values.pin1
        pwm.setduty(1, pin1_value)
    end

    if(values.rgb)then
        print("pommes")
        print(values.rgb)
        rgb_value = values.rgb
        --TODO: set PWM channels
    end

    local buffer = ""
    buffer = [[
        <h1>BuMm-Control</h1>
        <form>
            <h2>BuMmS</h2>
            (Bjoern und Maltes multifunktionale Steckdose)<br>
            <label>
                <input type="checkbox" name="pin0"]]..pin0_checked..[[ onchange="form.submit()">
                Pin 0
            </label>
            <h2>BuMmeL</h2>
            (Bjoern und Maltes multifunktionale, elektronische Lampe)<br>
            <label>
                <input type="range" name="pin1" min="0" max="1023" value="]]..pin1_value..[[" onchange="form.submit()">
                Pin 1
            </label>
            <label>
                <input type="color" name="rgb" pattern="^#([A-Fa-f0-9]{6})$" required value="]]..rgb_value..[[" onchange="form.submit()">
                Pin 5, 6, 7
        </form>
    ]]
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
