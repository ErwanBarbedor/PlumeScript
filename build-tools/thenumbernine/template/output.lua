local table = require 'ext.table'
local class = require 'ext.class'

local DefaultOutput = class()
function DefaultOutput:init()
	self.strs = table()
end
function DefaultOutput:__call(str)
	self.strs:insert(str)
end
function DefaultOutput:done()
	return self.strs:concat()
end

return DefaultOutput
