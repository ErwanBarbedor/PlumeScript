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
	nodeHandlerTable.EVAL = function(node)
		-- Push all index/call info in reverse order
		for i=#node.children, 2, -1 do
			local child = node.children[i]

			if child.name == "CALL" then
				context.accTableInit(node)
				context.childrenHandler(child)
			elseif child.name == "BLOCK_CALL" then
				context.accTableInit(node)
				context.nodeHandler(child)
			elseif child.name == "INDEX" then
				context.childrenHandler(child)
			elseif child.name == "DIRECT_INDEX" then
				local index = plume.ast.get(child, "IDENTIFIER")
				local name = index.content
				local offset = context.registerConstant(name)
				context.registerOP(index, plume.ops.LOAD_CONSTANT, 0, offset)
			end
		end

		-- Load eval value
		context.nodeHandler(node.children[1])

		-- Push all index/call op in order
		for i=2, #node.children do
			local child = node.children[i]
			if child.name == "CALL" or child.name == "BLOCK_CALL" then
				context.registerOP(node, plume.ops.ACC_CALL, 0, 0)
			elseif child.name == "INDEX" or child.name == "DIRECT_INDEX" then
				if node.children[i+1] and (node.children[i+1].name == "CALL" or node.children[i+1].name == "BLOCK_CALL") then
					context.registerOP(child, plume.ops.TABLE_INDEX_ACC_SELF, 0, 0)
				else
					context.registerOP(child, plume.ops.TABLE_INDEX, 0, 0)
				end
			end
		end

		if context.concats[#context.concats] then
			context.registerOP(node, plume.ops.ACC_CHECK_TEXT, 0, 0)
		end
	end

	local oppNames = "ADD SUB MUL DIV MOD LT EQ NOT NEG POW"

	for oppName in oppNames:gmatch("%S+") do
		nodeHandlerTable[oppName] = function(node)
			context.nodeHandler(node.children[1])
			if node.children[2] then--only binary
				context.nodeHandler(node.children[2])
			end
			context.registerOP(node, plume.ops["OPP_" .. oppName], 0, 0)
		end
	end

	nodeHandlerTable.NEQ = function(node)
		nodeHandlerTable.EQ(node)
		context.registerOP(node, plume.ops.OPP_NOT, 0, 0)
	end

	nodeHandlerTable.GT = function(node)
		-- reverse the order of operands
		context.nodeHandler(node.children[2])
		if node.children[2] then
			context.nodeHandler(node.children[1])
		end
		context.registerOP(node, plume.ops.OPP_LT, 0, 0)
	end

	nodeHandlerTable.LTE = function(node)
		nodeHandlerTable.GT(node)
		context.registerOP(node, plume.ops.OPP_NOT, 0, 0)
	end

	nodeHandlerTable.GTE = function(node)
		nodeHandlerTable.LT(node)
		context.registerOP(node, plume.ops.OPP_NOT, 0, 0)
	end

	nodeHandlerTable.OR = function(node)
		local uid = context.getUID()
		context.nodeHandler(node.children[1])
		context.registerGoto(node, "or_end_"..uid, "JUMP_IF_PEEK")
		context.nodeHandler(node.children[2])
		context.registerOP(node, plume.ops["OPP_OR"], 0, 0)
		context.registerLabel(node, "or_end_"..uid)
	end

	nodeHandlerTable.AND = function(node)
		local uid = context.getUID()
		context.nodeHandler(node.children[1])
		context.registerGoto(node, "and_end_"..uid, "JUMP_IF_NOT_PEEK")
		context.nodeHandler(node.children[2])
		context.registerOP(node, plume.ops["OPP_AND"], 0, 0)
		context.registerLabel(node, "and_end_"..uid)
	end

	nodeHandlerTable.EXPR = context.childrenHandler
end