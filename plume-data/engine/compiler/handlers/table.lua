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
	nodeHandlerTable.LIST_ITEM = context.accBlock()

	nodeHandlerTable.HASH_ITEM = function(node)
		local identifier = plume.ast.get(node, "IDENTIFIER").content
		local body = plume.ast.get(node, "BODY")
		local meta = plume.ast.get(node, "META")

		local offset = context.registerConstant(identifier)

		context.accBlock()(body)
		context.registerOP(node, plume.ops.LOAD_CONSTANT, 0, offset)

		if meta then
			context.registerOP(node, plume.ops.TABLE_SET_ACC, 0, 1)
		else
			context.registerOP(node, plume.ops.TABLE_SET_ACC, 0, 0)
		end
	end

	nodeHandlerTable.EXPAND = function(node)
		table.insert(context.concats, false)
		context.childrenHandler(node)
		table.remove(context.concats)
		context.registerOP(node, plume.ops.TABLE_EXPAND, 0, 0)
	end
end