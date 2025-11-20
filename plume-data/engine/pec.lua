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
	function plume.newPlumeExecutableChunk(isFile, state)
		state = state or {}
		local pec = {
			type                 = "macro",
			isFile               = isFile,
			name                 = name,
			instructions         = {},
			linkedInstructions   = {},
			bytecode             = {},
			static               = {},
			mapping              = {},
			positionalParamCount = 0,
			namedParamCount      = 0,
			namedParamOffset     = {},
			localsCount          = 0,
			variadicOffset       = 0, -- 0 for non variadic
			state                = state
		}

		if state[1] then
			pec.constants = state[1].constants
			pec.callstack = state[1].callstack
		else
			pec.constants = {}
			pec.callstack = {}
		end

		if not state[pec] then
			table.insert(state, pec)
		end
		state[pec] = true
		return pec
	end
end