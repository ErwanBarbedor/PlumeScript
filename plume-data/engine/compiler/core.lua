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
	--- Compile a sourcefile into an executable bytecode
	--- @param code string The sourcecode
	--- @param filename string Unique name associated with the source code
	--- @param chunk chunk The table to store all sourcecode informations
	--- (bytecode, static table, parameters names and number...)
	--- @return nil (instructions are writted directly into the chunk)
	function plume.compileFile(code, filename, chunk, runtime)
		local context = plume.newCompilationContext(chunk, runtime)

			-- A compilation is already running. Save the partial result
			if #runtime.instructions > 0 then
				context.savedInstructions = runtime.instructions
				runtime.instructions = {}
			end

		-- Cache system disabled
		-- if not plume.copyExecutableChunckFromCache(filename, chunk) then
			-- Add std function to the chunck static table
			context.loadSTD() 
			-- Make the ast from source code
			local ast = plume.parse(code, filename) 
			-- Call, for each ast node, a function to emit bytecode
			context.nodeHandler(ast) 
			-- Save file offset
			chunk.offset = (runtime.bytecode and #runtime.bytecode or 0) + 1
			-- Encode OP, compute goto offsets
			plume.finalize(runtime) 
			-- plume.saveExecutableChunckToCache(filename, chunk)
		-- end

			-- Restore instructions
			if context.savedInstructions then
				runtime.instructions = context.savedInstructions
				context.savedInstructions = nil
			end

		return true
	end

	--- @param chunk chunk
	--- @return nil
	function plume.newCompilationContext(chunk, runtime)
		local context = {}

		context.chunk = chunk
		context.runtime = runtime

		context.static    = {}
		context.constants = runtime.constants
		
		context.scopes    = {}
		context.concats   = {}
		context.roots     = {}
		context.loops     = {}
		context.macros    = {}
		

		require 'plume-data/engine/compiler/labels'    (plume, context)
		require 'plume-data/engine/compiler/wrappers'  (plume, context)
		require 'plume-data/engine/compiler/utils'     (plume, context)
		require 'plume-data/engine/compiler/variables' (plume, context)

		context.nodeHandlerTable = {}
		require 'plume-data/engine/compiler/handlers/core'       (plume, context, context.nodeHandlerTable)

		require 'plume-data/engine/compiler/handlers/alu'        (plume, context, context.nodeHandlerTable)
		require 'plume-data/engine/compiler/handlers/branch'     (plume, context, context.nodeHandlerTable)
		require 'plume-data/engine/compiler/handlers/directives' (plume, context, context.nodeHandlerTable)
		require 'plume-data/engine/compiler/handlers/literals'   (plume, context, context.nodeHandlerTable)
		require 'plume-data/engine/compiler/handlers/loops'      (plume, context, context.nodeHandlerTable)
		require 'plume-data/engine/compiler/handlers/macro'      (plume, context, context.nodeHandlerTable)
		require 'plume-data/engine/compiler/handlers/scopes'     (plume, context, context.nodeHandlerTable)
		require 'plume-data/engine/compiler/handlers/table'      (plume, context, context.nodeHandlerTable)
		require 'plume-data/engine/compiler/handlers/variables'  (plume, context, context.nodeHandlerTable)

		return context
	end
end