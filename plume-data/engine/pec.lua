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
	plume.cache = {}

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
			constants            = {},
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

	function plume.copyExecutableChunckFromCache(filename, chunk)
		local source = plume.cache[filename]
		if not source then
			return
		end

		chunk.instructions         = source.instructions
		chunk.linkedInstructions   = source.linkedInstructions
		chunk.bytecode             = source.bytecode
		chunk.static               = source.static
		chunk.constants            = source.constants
		chunk.mapping              = source.mapping
		chunk.positionalParamCount = source.positionalParamCount
		chunk.namedParamOffset     = source.namedParamOffset
		chunk.localsCount          = source.localsCount
		chunk.variadicOffset       = source.variadicOffset

		return true
	end

	function plume.saveExecutableChunckToCache(filename, chunk)
		plume.cache[filename] = {
			instructions         = chunk.instructions,
			linkedInstructions   = chunk.linkedInstructions,
			bytecode             = chunk.bytecode,
			static               = chunk.static, -- Source of errors
			constants            = chunk.constants,
			mapping              = chunk.mapping,
			positionalParamCount = chunk.positionalParamCount,
			namedParamOffset     = chunk.namedParamOffset,
			localsCount          = chunk.localsCount,
			variadicOffset       = chunk.variadicOffset
		}
	end
end