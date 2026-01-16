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
	function plume.compileFile(code, filename, chunk)
		local context = plume.newCompilationContext(chunk)

		-- Cache system disabled
		-- if not plume.copyExecutableChunckFromCache(filename, chunk) then
			context.loadSTD()

			local ast = plume.parse(code, filename)
			context.nodeHandler(ast)
			plume.finalize(chunk)

			-- plume.saveExecutableChunckToCache(filename, chunk)
		-- end

		return true
	end

	function plume.newCompilationContext(chunk)
		local context = {}

		context.static    = {}
		context.scopes    = {}
		context.concats   = {}
		context.roots     = {}
		context.loops     = {}
		context.chunks    = {chunk}
		context.chunk     = chunk
		context.constants = chunk.constants

		require 'plume-data/engine/compiler/labels'    (plume, context)
		require 'plume-data/engine/compiler/scopes'    (plume, context)
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