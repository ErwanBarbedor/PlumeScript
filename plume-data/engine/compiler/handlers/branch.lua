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
	nodeHandlerTable.IF = function(node)
		local condition = plume.ast.get(node, "CONDITION")
		local body      = plume.ast.get(node, "BODY")
		local _elseif   = plume.ast.getAll(node, "ELSEIF")
		local _else     = plume.ast.get(node, "ELSE")
		local uid = context.getUID()

		
		local specialValueMode = (
			node.parent.type == "VALUE"
			and node.type ~= "EMPTY"
		)

		local _else_body
		if specialValueMode then
			-- Special case: if inside a VALUE block,
			-- create an ELSE branch to emit LOAD_EMPTY
			if not _else then
				_else_body = {type="EMPTY"}
			end
		end

		local branchs = {body, condition}
		for _, child in ipairs(_elseif) do
			local condition = plume.ast.get(child, "CONDITION")
			local body      = plume.ast.get(child, "BODY")

			table.insert(branchs, body)
			table.insert(branchs, condition)
		end

		if _else then
			local body = plume.ast.get(_else, "BODY")
			table.insert(branchs, body)
		elseif _else_body then
			table.insert(branchs, _else_body)
		end

		local finalBranch = #branchs+1
		for i=1, #branchs, 2 do
			local body = branchs[i]
			local condition = branchs[i+1]
			context.registerLabel(node, "branch_"..i.."_"..uid)
			if condition then
				context.childrenHandler(condition)
				context.registerGoto(node, "branch_"..(i+2).."_"..uid, "JUMP_IF_NOT")
			end
			if body.type == "TEXT" then
				context.scope(context.accBlock())(body)
			else
				context.scope()(body)
			end
			if specialValueMode and body.type == "EMPTY" then
				context.registerOP(node, plume.ops.LOAD_EMPTY)
			end

			context.registerGoto(node, "branch_"..finalBranch.."_"..uid)
		end

		context.registerLabel(node, "branch_"..finalBranch.."_"..uid)

	end
end