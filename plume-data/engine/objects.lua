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

return function(plume)
	require "table.new"
	
	plume.obj = {}
	plume.obj.empty = {type = "empty"}

	--- lua fonction take 1 parameter: the plume table of all given arguments
	function plume.obj.luaFunction (name, f)
		return {
			type = "luaFunction",
			callable = f,
			name = name -- optionnal
		}
	end

	function plume.obj.table (listSlots, hashSlots)
		local t
		t = {
			type = "table", --type
			table = table.new(listSlots, hashSlots),
			keys = table.new(hashSlots, 0),
			meta = {-- meta table
				iter = plume.obj.luaFunction("iter", function(args)
					local iterator = plume.obj.table(1, 1)
					iterator.table[1] = 0
					iterator.table.next = plume.obj.luaFunction("next", function()
						iterator.table[1] = iterator.table[1]+1
						local value = t.table[iterator.table[1]]
						if value then
							return value
						else
							return plume.obj.empty
						end
					end)
					return iterator
				end)
			} 
		}
		return t
	end

end