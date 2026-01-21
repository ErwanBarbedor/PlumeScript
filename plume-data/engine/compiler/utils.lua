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
	--- Return each time a unique number
	--- Used to name labels
	---@return number
	function context.getUID()
		uid = uid+1
		return uid
	end

	--- Load all std function and store them as static variable
	--- Don't check for registerVariable returning "nil" (mean: variable already exists)
	--- But loadSTD is called first.
	--- @return nil
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

	--- Register an opcode in the current chunk
	--- @param node node The source node to link the op with
	--- @param op number opcode constant, should be plume.op.SOMETHING
	--- @param arg1 number|nil First argument to give to the opcode. Default to 0.
	--- @param arg2 number|nil Second argument to give to the opcode. Default to 0.
	function context.registerOP(node, op, arg1, arg2)
		assert(op) -- Guard against opcode typo
		local current = context.runtime.instructions
		table.insert(current, {op, arg1 or 0, arg2 or 0, mapsto=node})
	end

	--- Return the last scope of context.scopes
    --- @return table
    function context.getCurrentScope()  
        return context.scopes[#context.scopes]  
    end

    --- Utils to set/check if the current block is a TEXT one
    function context.toggleConcatOn()
    	table.insert(context.concats, true)
    end
    function context.toggleConcatOff()
    	table.insert(context.concats, false)
    end
    function context.toggleConcatPop()
    	table.remove(context.concats)
    end
    function context.checkIfCanConcat()
    	return context.getLast"concats"
    end
end