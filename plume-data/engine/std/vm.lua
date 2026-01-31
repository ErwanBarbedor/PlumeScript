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
	local function registerLuaStdFunction(name, minArgs, maxArgs)
		if not minArgs then
			minArgs = 0
		end
		if not maxArgs then
			maxArgs = minArgs
		end

		plume.stdVM[name] = {
			type = "luaStdFunction",
			name = name,
			opcode = plume.ops_count,
			minArgs = minArgs,
			maxArgs = maxArgs
		}
		
		local opName = "STD_" .. name:upper()
		plume.ops[opName] = plume.ops_count
		plume.ops_names = plume.ops_names .. " " .. opName
		plume.ops_count = plume.ops_count + 1

	end

	registerLuaStdFunction("len", 1)
	registerLuaStdFunction("type", 1)
	registerLuaStdFunction("seq", 1, 3)
	registerLuaStdFunction("items", 1)
	registerLuaStdFunction("enumerate", 1)
	registerLuaStdFunction("import", 1)
end