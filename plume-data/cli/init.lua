--[[This file is part of Plume

Plume🪶 is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.

Plume🪶 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Plume🪶.
If not, see <https://www.gnu.org/licenses/>.
]]

local function main()
	local filename = arg[2]

	if not filename then
		print("Missing input file")
		return
	end

	local file = io.open(filename)
		if not file then
			print("Cannot read file '" .. filename .. "'.")
		end
		local code = file:read "*a"
	file:close()

	package.path = arg[1].."/?.lua;" .. package.path
	local plume = require "engine/init"

	local runtime = plume.initRuntime()
	plume.compileFile(code, filename, runtime)
	plume.finalize(runtime)
	local ret = plume.executeFile(filename)
	plume.debug.pprint(ret)
end

main()