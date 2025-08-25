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
	plume.obj.empty = {}

	function plume.obj.macro (offset, name)
		return {
			"macro", -- type
			offset,  -- location
			0,       -- number of positionnal parameters
			0,       -- number of nameds parameters
			{},      -- named parameters offsets
			name
		}
	end

	--- lua fonction take 1 parameters: the plume table of all given arguments
	function plume.obj.luaFunction (name, f)
		return {
			"luaFunction", -- type
			f,  -- function
			name -- optionnal
		}
	end

	function plume.obj.table (listSlots, hashSlots)
		return {
			"table", --type
			table.new(listSlots, hashSlots), -- lua table
			table.new(hashSlots, 0) -- key order
		}
	end

end