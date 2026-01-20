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
	--- Nothing special to notice: while is translated with 2 label,
	--- one before the check and one at the body end
	nodeHandlerTable.WHILE = function(node)
		local condition = plume.ast.get(node, "CONDITION")
		local body      = plume.ast.get(node, "BODY")
		local uid = context.getUID()

		context.registerLabel(node, "while_begin_"..uid)
		context.childrenHandler(condition)
		context.registerGoto(node, "while_end_"..uid, "JUMP_IF_NOT")

		table.insert(context.loops, {begin_label="while_begin_"..uid, end_label="while_end_"..uid}) -- Informations used by break/continue
		context.scope()(body)
		table.remove(context.loops)

		context.registerGoto(node, "while_begin_"..uid)
		context.registerLabel(node, "while_end_"..uid)
	end

	--- For create two scopes: one that lives the iterator,
	--- and another recreated at each iteration.
	nodeHandlerTable.FOR = function(node)
		local varlist = plume.ast.get(node, "VARLIST")
		local iterator   = plume.ast.get(node, "ITERATOR")
		local body       = plume.ast.get(node, "BODY")
		local uid = context.getUID()

		local next = context.registerConstant("next")
		local iter = context.registerConstant("iter")
		
		context.toggleConcatOff() -- Prevent iterator to be converted to string
		context.childrenHandler(iterator) -- Evaluate the iterator expression
		context.toggleConcatPop()

		context.registerOP(node, plume.ops.GET_ITER) -- Get the iterator (meta method iter or default iterator)

		-------------------------------------------------------
		-- why don't use the wrapper context.scope()?
		context.registerOP(nil, plume.ops.ENTER_SCOPE, 0, 3) -- iterator, state and flag
		table.insert(context.scopes, {}) 
		-------------------------------------------------------

			context.registerOP(node, plume.ops.STORE_LOCAL, 0, 1) -- Save the iterator
			context.registerOP(node, plume.ops.STORE_LOCAL, 0, 2) -- Save the state
			context.registerOP(node, plume.ops.STORE_LOCAL, 0, 3) -- Save the flag

			context.registerLabel(node, "for_begin_"..uid)
			context.registerGoto(node, "for_end_"..uid, "FOR_ITER", 1) -- Call iterator to get next(s) value(s)

			context.scope(function(body)
				context.affectation(node, varlist, -- Store returned value(s) into var(s)
					nil,   -- body
					true,  -- isLet
					false, -- isConst
					false, -- isStatic
					false, -- isParam
					false, -- isFrom 
					nil,   -- compound
					true   -- isBodyStacked
				)
				
				table.insert(context.loops, {begin_label="for_loop_end_"..uid, end_label="for_end_"..uid}) -- Informations used by break/continue
				context.childrenHandler(body)
				table.remove(context.loops)
				context.registerLabel(node, "for_loop_end_"..uid)
			end, 1)(body)

			context.registerGoto (node, "for_begin_"..uid)
			context.registerLabel(node, "for_end_"..uid)
		
		-------------------------------------------------------
		-- why don't use the wrapper context.scope()?
		table.remove(context.scopes)
		context.registerOP(node, plume.ops.LEAVE_SCOPE)
		-------------------------------------------------------	
	end

	-----------------------------------------------------------	
	--- BREAK/CONTINUE are just goto to the last loop end/begin
	-----------------------------------------------------------	
	nodeHandlerTable.CONTINUE = function(node)
		local loop = context.getLast'loops'
		if not loop or not loop.begin_label then
			plume.error.cannotUseContinueOutsideLoop(node)
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