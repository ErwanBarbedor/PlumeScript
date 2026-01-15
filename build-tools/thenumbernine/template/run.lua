local template = require 'template'

local run = function(code, env, ...)
	if not env then
		if getfenv then
			env = getfenv(1)
		else
			-- TODO can't use _ENV ... we need _ENV of the caller ...
			env = _G
		end
	end
	return load(template(code, env))(...)
end

return run
