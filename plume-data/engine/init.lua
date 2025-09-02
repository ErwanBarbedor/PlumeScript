--[[
Plume🪶 0.54
Copyright (C) 2024-2025 Erwan Barbedor

Check https://github.com/ErwanBarbedor/PlumeScript
for documentation, tutorials, or to report issues.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
]]

local plume = {}

require 'plume-data/engine/debug_tools' (plume)

require 'plume-data/engine/utils'     (plume)
require 'plume-data/engine/objects'   (plume)
require 'plume-data/engine/std'       (plume)
require 'plume-data/engine/parser'    (plume)
require 'plume-data/engine/compiler'  (plume)
require 'plume-data/engine/engine'    (plume)
require 'plume-data/engine/finalizer' (plume)

function plume.execute(code, filename, runtime)
	if not runtime then
		runtime = plume.initRuntime()
	end

	plume.compileFile(code, filename, runtime)
	plume.finalize(runtime)
	local success, result, ip = plume.run(runtime)

	if success then
		return result
	else
		error("Error at instruction " .. ip .. ": " .. result)
	end
end

function plume.executeFile(filename)
	local f = io.open(filename)
		if not f then
			error("The file '" .. filename .. "' don't exist or isn't readable.")
		end

		local code = f:read("*a")
	f:close()

	return plume.execute(code, filename)
end

plume.hook = nil -- A function call at each step of the vm

return plume