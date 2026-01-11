-- add line numbers to code output
local string = require 'ext.string'
local function showcode(code)
	local lines = string.split(string.trim(code),'\n')
	local max = tostring(#lines)
	return lines:map(function(l,i)
		local num = tostring(i)
		return num..':'..(' '):rep(#max - #num)..l
	end):concat'\n'
end
return showcode
