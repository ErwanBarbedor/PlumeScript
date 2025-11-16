--[[
Plume🪶 0.62
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
require 'plume-data/engine/error'         (plume)
require 'plume-data/engine/errorMessages' (plume)
require 'plume-data/engine/utils'         (plume)
require 'plume-data/engine/objects'       (plume)
require 'plume-data/engine/std'           (plume)
require 'plume-data/engine/parser'        (plume)
require 'plume-data/engine/compiler'      (plume)
require 'plume-data/engine/engine'        (plume)
require 'plume-data/engine/finalizer'     (plume)
require 'plume-data/engine/pec'           (plume)
require 'plume-data/engine/env'           (plume)

function plume.execute(code, filename, chunk)
	local success, result, ip
	local errorSource = chunk
	success, result = pcall(plume.compileFile, code, filename, chunk)
	
	if success then
		success, result = pcall(plume.finalize, chunk)
	end

	if success then
		success, result, ip, errorSource = plume.run(chunk)
	else
		return false, result
	end

	if success then
		return true, result
	else
		return false, plume.error.makeRuntimeError(errorSource, ip, result)
	end
end

function plume.executeFile(filename, state)
	local chunk = plume.newPlumeExecutableChunk(true, state)
	chunk.name = filename

	local f = io.open(filename)
		if not f then
			error("The file '" .. filename .. "' don't exist or isn't readable.")
		end

		local code = f:read("*a")
	f:close()

	return plume.execute(code, filename, chunk)
end

plume.hook = nil -- A function call at each step of the vm

return plume