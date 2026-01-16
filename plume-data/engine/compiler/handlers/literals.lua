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

return function (plume, context, nodeHandlerTable)
	-- Stack constants
	nodeHandlerTable.TRUE = function(node)
		context.registerOP(node, plume.ops.LOAD_TRUE, 0, 0)
	end

	nodeHandlerTable.FALSE = function(node)
		context.registerOP(node, plume.ops.LOAD_FALSE, 0, 0)
	end

	nodeHandlerTable.EMPTY = function(node)
		context.registerOP(node, plume.ops.LOAD_EMPTY, 0, 0)
	end

	nodeHandlerTable.COMMENT = function()end

	nodeHandlerTable.TEXT = function(node)
		local offset = context.registerConstant(node.content)
		context.registerOP(node, plume.ops.LOAD_CONSTANT, 0, offset)
	end

	nodeHandlerTable.NUMBER = function(node)
		local offset = context.registerConstant(tonumber(node.content))
		context.registerOP(node, plume.ops.LOAD_CONSTANT, 0, offset)
	end

	nodeHandlerTable.QUOTE = function(node)
		local content = (node.children[1] and node.children[1].content) or ""
		local offset = context.registerConstant(content)
		context.registerOP(node, plume.ops.LOAD_CONSTANT, 0, offset)
	end

end