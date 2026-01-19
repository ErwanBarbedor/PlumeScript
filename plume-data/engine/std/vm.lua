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

return function (plume)
	plume.stdVM = {}
	local function addLuaStdFunction(name, positionalParamCount)
		plume.stdVM[name] = {
			type = "luaStdFunction",
			name = name,
			opcode = plume.ops_count,
			positionalParamCount = positionalParamCount or 0
		}
		
		local opName = "STD_" .. name:upper()
		plume.ops[opName] = plume.ops_count
		plume.ops_names = plume.ops_names .. " " .. opName
		plume.ops_count = plume.ops_count + 1

	end

	addLuaStdFunction("len", 1)
	addLuaStdFunction("type", 1)
end