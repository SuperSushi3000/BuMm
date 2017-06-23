--BuMm base element object prototype 

function list_iter (t)
  local i = 0
  local n = table.getn(t)
  return function ()
    i = i + 1
    if i <= n then 
      return t[i] 
    end
  end
end

element = {}
element.pins = {}

function element:new(tb)
  new_element_object = tb.derived or {}
  new_element_object.name = tb.name
  new_element_object.pins = tb.pins
  for pin in list_iter(new_element_object.pins) do
    gpio.mode(pin, gpio.OUTPUT)
    gpio.write(pin, gpio.LOW)
  end
  setmetatable(new_element_object, self)
  self.__index = self
  return new_element_object
end

function element:set_value(value)
  self.value = value
end

function element:get_control_str()
  print("error: function must be overloaded")
  return nil
end

function element:get_key()
  return self.name
end

--Switch object prototype, derived from element
switch = element:new{name="switch", pins={0}}

function switch:new(tb)
  print("Adding Switch with index:"..tb.index..", switching Pin:"..tb.pin.."\n")
  new_switch_object = element:new{name="switch/"..tb.index, pins={tb.pin}}
  setmetatable(new_switch_object, self)
  self.__index = self
  return new_switch_object
end

function switch:set_value(value)
  if(value == "on")then
    self.value = true
    gpio.write(self.pins[1], gpio.HIGH)
  else
    self.value = false
    gpio.write(self.pins[1], gpio.LOW)
  end
end

function switch:get_control_str()
  if self.value then
    temp = " checked=\"checked\""--nice to read, isn't it?
  else
    temp = ""
  end
  return[[<label>
                <input type="checkbox" name="]]..self.name..[["]]..temp..[[onchange="form.submit()">
                ]]..self.name..[[<br>
          </label>]].."\n"
end

--fader object prototype, derived from element
fader = element:new{name="fader", pins={0}}

function fader:new(tb)
  print("Adding Fader with index:"..tb.index..", PWM-ing Pin:"..tb.pin.."\n")
  new_fader_object = element:new{name="fader/"..tb.index, pins={tb.pin}}
  new_fader_object.value = 0
  pwm.setup(tb.pin, 100, 0)
  pwm.start(tb.pin)
  setmetatable(new_fader_object, self)
  self.__index = self
  return new_fader_object
end

function fader:set_value(value)
  --print("fader:set_value")
  if(value)then
    self.value = value
    pwm.setduty(self.pins[1], self.value)
  end
end

function fader:get_control_str()
  return[[<label>
                <input type="range" min="0" max="1023" name="]]..self.name..[[" value="]]..self.value..[[" onchange="form.submit()">
                ]]..self.name..[[<br>
          </label>]].."\n"
end


--rgb object prototype, derived from element
rgb = element:new{name="rgb", pins={0, 1, 2}}

function rgb:new(tb)
  print("Adding RGB LED with index:"..tb.index..",\nred: Pin "..tb.pins.r..",\ngreen: Pin "..tb.pins.g..",\nblue: Pin "..tb.pins.b.."\n")
  new_rgb_object = element:new{name="rgb/"..tb.index, pins={tb.pins.r, tb.pins.g, tb.pins.b}}
  new_rgb_object.value = "#000000"
  pwm.setup(tb.pins.r, 100, 0)
  pwm.start(tb.pins.r)
  pwm.setup(tb.pins.g, 100, 0)
  pwm.start(tb.pins.g)
  pwm.setup(tb.pins.b, 100, 0)
  pwm.start(tb.pins.b)
  setmetatable(new_rgb_object, self)
  self.__index = self
  return new_rgb_object
end

function rgb:set_value(value)
  --print("fader:set_value")
  if(value)then
    self.value = value
    local color = tonumber(string.gsub(value,"#",""),16)
    --set red pwm duty cycle
    pwm.setduty(self.pins[1], 1023-bit.rshift(bit.band(color, 0xFF0000),14))
    --set green pwm duty cycle
    pwm.setduty(self.pins[2], 1023-bit.rshift(bit.band(color, 0x00FF00),6))
    --set blue pwm duty cycle
    pwm.setduty(self.pins[3], 1023-bit.lshift(bit.band(color, 0x0000FF),2))
  end
end

function rgb:get_control_str()
  return[[<label>
                <input type="color" name="]]..self.name..[[" value="]]..self.value..[[" onchange="form.submit()">
                ]]..self.name..[[<br>
          </label>]].."\n"
end






  
