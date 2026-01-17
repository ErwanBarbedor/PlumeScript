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
	nodeHandlerTable.LEAVE = function(node)
		context.registerGoto(node, "macro_end")
	end

	nodeHandlerTable.FILE = context.file(function(node)
		local lets = #plume.ast.getAll(node, "LET")
		context.registerOP(node, plume.ops.ENTER_SCOPE, 0, lets)
		table.insert(context.scopes, {})
		context.accBlock()(node, "macro_end")
		table.remove(context.scopes)
		-- LEAVE_SCOPE handled by RETURN
	end)

	nodeHandlerTable.DO = function(node)
		context.accBlock(function(node)
			context.childrenHandler(node)
		end)(node)
		context.registerOP(node, plume.ops.STORE_VOID)
	end
end