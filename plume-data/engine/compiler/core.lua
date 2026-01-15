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

		require 'plume-data/engine/compiler/bytecode' (plume, context)
		require 'plume-data/engine/compiler/labels'   (plume, context)
		require 'plume-data/engine/compiler/scopes'   (plume, context)
		require 'plume-data/engine/compiler/utils'    (plume, context)

		return context
	end
end