--[[
Plume🪶 0.69
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
require 'plume-data/engine/std/vm'        (plume)
require 'plume-data/engine/std/lua'       (plume)
require 'plume-data/engine/std'           (plume)
require 'plume-data/engine/parser'        (plume)
require 'plume-data/engine/compiler/core' (plume)
require 'plume-data/engine/engine'        (plume)
require 'plume-data/engine/engine-opt'    (plume)
require 'plume-data/engine/finalizer'     (plume)
require 'plume-data/engine/pec'           (plume)

function plume.run(runtime, chunk)
	if plume.runDevFlag then
		return plume._run_dev(runtime, chunk)
	else
		return plume._run(runtime, chunk)
	end
end

function plume.execute(code, filename, chunk, runtime)
	local success, result, ip
	success, result = pcall(plume.compileFile, code, filename, chunk, runtime)

	if success then
		success, result, ip = plume.run(runtime, chunk)
	else
		return false, result
	end

	if success then
		return true, result
	else
		if not secondary then
			result = plume.error.makeRuntimeError(runtime, ip, result)
		end
		return false, result
	end
end

function plume.executeFile(filename, runtime)
	local runtime = runtime or plume.obj.runtime()
	local chunk   = plume.obj.macro(filename, runtime)

	local f = io.open(filename)
		if not f then
			error("The file '" .. filename .. "' don't exist or isn't readable.")
		end

		local code = f:read("*a")
	f:close()

	return plume.execute(code, filename, chunk, runtime)
end

plume.hook = nil -- A function call at each step of the vm

return plume