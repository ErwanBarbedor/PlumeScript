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
	--- Handle structure like
	--- @wing(argList)
	--- 	... // body
	--- end
	--- Where the (optional) argList and body contribute together
	--- to the "real" argList used when calling wing.
	--- If body is a table, it is just joined to argList.
	--- If it's a value, it is added as a single list item.
	nodeHandlerTable.BLOCK_CALL = function(node)
		local argList = plume.ast.get(node, "CALL")
		local body    = plume.ast.get(node, "BODY")

		-- Body has it's own scope
		context.scope(function()
			if argList then
				context.childrenHandler(argList)
			end

			if body.type == "TABLE" then
				context.childrenHandler(body)
			else
				context.accBlock()(body)
			end
		end)(body)
	end

	--- Handle evaluation node: computations, calls and indexes  
	--- All values must be put on stack in reverse order, then all call/index in order  
	--- `$wing.nib()[5]` -> `load 5; load nib; load wing; index; call; index`
	nodeHandlerTable.EVAL = function(node)
		-- Push all index/call info in reverse order.
		for i=#node.children, 2, -1 do
			local child = node.children[i]

			-- `$wing(arg1, arg2)`
			if child.name == "CALL" then
				context.accTableInit(node)
				context.childrenHandler(child) -- child.children are the args
			
			-- `@wing ... end`
			elseif child.name == "BLOCK_CALL" then
				context.accTableInit(node)
				context.nodeHandler(child) -- = nodeHandlerTable.BLOCK_CALL(child)
			
			-- `$wing[1]`
			elseif child.name == "INDEX" then
				-- Always one child, that contain the index value/computation
				context.nodeHandler(child.children[1]) 
			
			-- `$wing.nib`
			elseif child.name == "DIRECT_INDEX" then 
				local index = plume.ast.get(child, "IDENTIFIER")
				local name = index.content
				local offset = context.registerConstant(name)
				context.registerOP(index, plume.ops.LOAD_CONSTANT, 0, offset)
			end
		end

		context.nodeHandler(node.children[1]) -- Load the "root" value

		-- Push all index and call opcodes in order
		for i=2, #node.children do
			local child = node.children[i]
			if child.name == "CALL" or child.name == "BLOCK_CALL" then
				context.registerOP(node, plume.ops.CONCAT_CALL)
			elseif child.name == "INDEX" or child.name == "DIRECT_INDEX" then
				local nextChild = node.children[i+1]
				local nextChildIsCall = nextChild and (nextChild.name == "CALL" or nextChild.name == "BLOCK_CALL")
				-- When call a table field, add the table in argument list as the value for the key `self`
				-- Ex: `$wing.nib()` is treated like `$wing.nib(self: $wing)`
				if nextChildIsCall then
					context.registerOP(child, plume.ops.CALL_INDEX_REGISTER_SELF, 0, 0)
				end
				context.registerOP(child, plume.ops.TABLE_INDEX)
			end
		end

		-- In inside a TEXT block, check the type of value returned by eval
		if context.checkIfCanConcat() then
			context.registerOP(node, plume.ops.CHECK_IS_TEXT)
		end
	end


	--- Same logic for most of operators
	--- `a OPP b` is treated as `load a;load b; do OPP`
	--- `OPP a` as load `a;do OPP`
	local opNames = "ADD SUB MUL DIV MOD LT EQ NOT NEG POW"
	for opName in opNames:gmatch("%S+") do
		nodeHandlerTable[opName] = function(node)
			context.nodeHandler(node.children[1])
			if node.children[2] then--only binary
				context.nodeHandler(node.children[2])
			end
			context.registerOP(node, plume.ops["OP_" .. opName])
		end
	end

	---------------------------------------------------------
	--- NEQ, GT, LTE and GTE are emulated from EQ, LT and NOT
	---------------------------------------------------------

	--- x NEQ y := NOT x EQ y
	nodeHandlerTable.NEQ = function(node)
		nodeHandlerTable.EQ(node)
		context.registerOP(node, plume.ops.OP_NOT)
	end

	--- x GT y := y LT x
	nodeHandlerTable.GT = function(node)
		context.nodeHandler(node.children[2])
		if node.children[2] then
			context.nodeHandler(node.children[1])
		end
		context.registerOP(node, plume.ops.OP_LT)
	end

	--- x LTE y := NOT x GT y
	nodeHandlerTable.LTE = function(node)
		nodeHandlerTable.GT(node)
		context.registerOP(node, plume.ops.OP_NOT)
	end

	--- x GTE y := NOT x LT y
	nodeHandlerTable.GTE = function(node)
		nodeHandlerTable.LT(node)
		context.registerOP(node, plume.ops.OP_NOT)
	end

	------------------------------------------------
	--- OR and AND are lazy.
	--- Second membre is evaluated only when needed
	------------------------------------------------
	nodeHandlerTable.OR = function(node)
		local uid = context.getUID()
		context.nodeHandler(node.children[1])
		context.registerGoto(node, "or_end_"..uid, "JUMP_IF_PEEK") -- If first membre is true, skip the second
		context.nodeHandler(node.children[2])
		context.registerOP(node, plume.ops["OP_OR"])
		context.registerLabel(node, "or_end_"..uid)
	end

	nodeHandlerTable.AND = function(node)
		local uid = context.getUID()
		context.nodeHandler(node.children[1])
		context.registerGoto(node, "and_end_"..uid, "JUMP_IF_NOT_PEEK") -- If first membre is false, skip the second
		context.nodeHandler(node.children[2])
		context.registerOP(node, plume.ops["OP_AND"])
		context.registerLabel(node, "and_end_"..uid)
	end

	--- Wrapper for computations
	nodeHandlerTable.EXPR = context.childrenHandler
end