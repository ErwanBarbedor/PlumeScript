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
	--- `- item`
	nodeHandlerTable.LIST_ITEM = context.accBlock()

	--- `key: value` and `meta key: value`
	nodeHandlerTable.HASH_ITEM = function(node)
		local identifier = plume.ast.get(node, "IDENTIFIER")
		local eval       = plume.ast.get(node, "EVAL")
		local body       = plume.ast.get(node, "BODY")
		local meta       = plume.ast.get(node, "META")
		local ref        = plume.ast.get(node, "REF")

		if eval then
			context.nodeHandler(eval) 
		end

		context.accBlock()(body)

		if identifier then
			local offset = context.registerConstant(identifier.content)
			context.registerOP(node, plume.ops.LOAD_CONSTANT, 0, offset)

			if ref then
				if not context.registerVariable(identifier.content, nil, nil, nil, nil, nil, true) then
					
				end
			end
		else
			context.registerOP(node, plume.ops.SWITCH, 0, 0)
		end

		if meta then
			context.registerOP(node, plume.ops.TAG_META_KEY, 0, 0)
		else
			context.registerOP(node, plume.ops.TAG_KEY, 0, 0)
		end
	end

	--- `...table`
	nodeHandlerTable.EXPAND = function(node)
		context.toggleConcatOff()
		context.childrenHandler(node)
		context.toggleConcatPop()
		context.registerOP(node, plume.ops.TABLE_EXPAND, 0, 0)
	end
end