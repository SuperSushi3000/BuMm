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
  --print(tb.index)
  --print(tb.pin)
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






  
