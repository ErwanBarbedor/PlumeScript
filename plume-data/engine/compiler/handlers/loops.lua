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
	nodeHandlerTable.WHILE = function(node)
		local condition = plume.ast.get(node, "CONDITION")
		local body      = plume.ast.get(node, "BODY")
		local uid = context.getUID()

		context.registerLabel(node, "while_begin_"..uid)
		context.childrenHandler(condition)
		context.registerGoto(node, "while_end_"..uid, "JUMP_IF_NOT")

		table.insert(context.loops, {begin_label="while_begin_"..uid, end_label="while_end_"..uid})
		context.scope()(body)
		table.remove(context.loops)

		context.registerGoto(node, "while_begin_"..uid)
		context.registerLabel(node, "while_end_"..uid)
	end

	nodeHandlerTable.FOR = function(node)
		local varlist = plume.ast.get(node, "VARLIST")
		local iterator   = plume.ast.get(node, "ITERATOR")
		local body       = plume.ast.get(node, "BODY")
		local uid = context.getUID()

		local next = context.registerConstant("next")
		local iter = context.registerConstant("iter")

		table.insert(context.concats, false)
		context.childrenHandler(iterator)
		table.remove(context.concats)

		context.registerOP(node, plume.ops.GET_ITER, 0, 0)
		context.registerOP(nil, plume.ops.ENTER_SCOPE, 0, 1)
		table.insert(context.scopes, {})

			context.registerOP(nil, plume.ops.STORE_LOCAL, 0, 1)

			context.registerLabel(nil, "for_begin_"..uid)
			context.registerOP(nil, plume.ops.LOAD_LOCAL, 0, 1)
			context.registerGoto(nil, "for_end_"..uid, "FOR_ITER", 1)

			context.scope(function(body)
				context.affectation(node, varlist,
					nil,   -- body
					true,  -- isLet
					false, -- isConst
					false, -- isStatic
					false, -- isParam
					false, -- isFrom 
					nil,   -- compound
					true   -- isBodyStacked
				)
				
				table.insert(context.loops, {begin_label="for_loop_end_"..uid, end_label="for_end_"..uid})
				context.childrenHandler(body)
				table.remove(context.loops)
				context.registerLabel(nil, "for_loop_end_"..uid)
			end, 1)(body)

			context.registerGoto (nil, "for_begin_"..uid)
			context.registerLabel(nil, "for_end_"..uid)

		table.remove(context.scopes)
		context.registerOP(node, plume.ops.LEAVE_SCOPE, 0, 0)	
	end

	nodeHandlerTable.CONTINUE = function(node)
		local loop = context.getLast'loops'
		if not loop or not loop.begin_label then
			plume.error.cannotUseBreakOutsideLoop(node)
		end
		context.registerGoto (node, loop.begin_label)
	end

	nodeHandlerTable.BREAK = function(node)
		local loop = context.getLast'loops'
		if not loop or not loop.end_label then
			plume.error.cannotUseBreakOutsideLoop(node)
		end
		context.registerGoto (node, loop.end_label)
	end
end