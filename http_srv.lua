

--Class for handling HTTP requests and generating response headers
http_srv = {}

function http_srv:new(tb)
  new_http_srv_object = {}
  new_http_srv_object.index_page = tb.callback_index
  setmetatable(new_http_srv_object, self)
  self.__index = self
  return new_http_srv_object
end

function http_srv:get_values_from_string()
  self.values={}
  --replace http character codes by their appropriate characters
  self.vars_str = string.gsub(self.vars_str,"%%2F", "/")
  self.vars_str = string.gsub(self.vars_str,"%%23", "#")
  for k, v in string.gmatch(self.vars_str, "([%w/]+)=(#?%w+)&*") do
    self.values[k] = v
    print(k..": "..v..", ")
  end
end

function http_srv:handle_request(request_str)
  print(request_str)
  _, _, self.method, sub_str, _ = string.find(request_str, "([A-Z]+) (.+) (HTTP/%d.%d)") 
  if self.method=="GET" then
    _, _, self.path = string.find(sub_str, "(.+)%?")
    if self.path then --there is a ? and therefore, there are variables
      _, _, self.vars_str = string.find(sub_str, "%?(.+)")
      self:get_values_from_string()
    else
       self.path = sub_str
    end
    if self.path == "/" then --send index page
      self.content_str = self.index_page(self.values)
    else --send file
      if not (string.find(self.path, "./") or string.find(self.path, "/FLASH")) then
        self.path = "/FLASH"..self.path
      end
      file.open(self.path)
      self.content_str = file.read()
      file.close()
    end
  end--method=="GET"
  
  if self.method == "POST" then
    _, _, self.vars_str = string.find(request_str, "\r\n\r\n(.+)")
    self:get_values_from_string()
    self.content_str = self.index_page(self.values)
  end--method=="POST"
    
end

function http_srv:get_response()
--TODO:build HTTP response header
  return self.content_str
end
