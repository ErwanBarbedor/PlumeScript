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

return function (plume, context)
	--- @param key string
	--- @return any last element of context[key]
	function context.getLast(key)
		return context[key][#context[key]]
	end

	local uid = 0
	--- Return each time an unique number
	--- Used to name labels
	---@return number
	function context.getUID()
		uid = uid+1
		return uid
	end

	-- All lua std function are stored as static variables
	function context.loadSTD()
		local keys = {}
		for key, f in pairs(plume.std) do
			table.insert(keys, key)
		end
		table.sort(keys)

		for _, key in ipairs(keys) do
			context.registerVariable(key, true, false, false, plume.std[key])
		end
	end

	function context.registerOP(node, op, arg1, arg2)
		assert(op) -- Guard against opcode typo
		local current = context.getLast("chunks").instructions
		table.insert(current, {op, arg1, arg2, mapsto=node})
	end

	--- Return the last scope of context.scopes
    --- @return table
    function context.getCurrentScope()  
        return context.scopes[#context.scopes]  
    end  
end