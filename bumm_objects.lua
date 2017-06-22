--BuMm base element object prototype 
element = {}
element.pins = {}

function element:new(name, pins, derived)
  new_element_object = derived or {}
  new_element_object.name = name
  new_element_object.pins = pins
  for pin in pins do
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
  return "var/"..self.name
end

--Switch object prototype, derived from element
switch = element:new({index=0},"switch",0)

function switch:new(index, pin, derived)
  new_switch_object = derived or element:new("switch/"..index,{pin})
  setmetatable(new_switch_object, self)
  self.__index = self
  return new_switch_object
end

function switch:set_value(value)
  self.value = value
  if value then
    gpio.write(self.pins[1], gpio.HIGH)
  else
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
                ]]..self.name..[[
          </label>]]
end






  
