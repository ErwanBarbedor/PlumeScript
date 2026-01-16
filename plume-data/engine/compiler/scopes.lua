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

return function (plume, context)
	function context.accTableInit()
		context.registerOP(nil, plume.ops.BEGIN_ACC, 0, 0)
		context.registerOP(nil, plume.ops.TABLE_NEW, 0, 0)
	end

	function context.accTable(node)
		for _, child in ipairs(node.children) do
			if child.name == "LIST_ITEM"
			or child.name == "HASH_ITEM" then
				context.nodeHandler(child)
			else
				error("Internal Error: MixedBlockError")
			end
		end
	end

	function context.getCurrentScope()
		return context.scopes[#context.scopes]
	end

	function context.accBlock(f)
		f = f or context.childrenHandler
		return function (node, label)
			if node.type == "TEXT" then
				table.insert(context.concats, true)
				context.registerOP(node, plume.ops.BEGIN_ACC, 0, 0)
				f(node)
				if label then
					context.registerLabel(node, label)
				end
				context.registerOP(nil, plume.ops.ACC_TEXT, 0, 0)
			else
				table.insert(context.concats, false)
				-- More or less a TEXT block with 1 element
				if node.type == "VALUE" then
					f(node)
					if label then
						context.registerLabel(node, label)
					end
				-- Handled by block in most cases
				elseif node.type == "TABLE" then
					context.accTableInit()
					f(node)
					if label then
						context.registerLabel(node, label)
					end
					context.registerOP(nil, plume.ops.ACC_TABLE, 0, 0)
				elseif node.type == "EMPTY" then
					-- Exactly same behavior as BEGIN_ACC (nothing) ACC_TEXT
					f(node)
					if label then
						context.registerLabel(node, label)
					end
					context.registerOP(nil, plume.ops.LOAD_EMPTY, 0, 0)
				end
			end
			table.remove(context.concats)
		end		
	end

	function context.scope(f, internVar)
		f = f or context.childrenHandler
		return function (node)
			local lets = #plume.ast.getAll(node, "LET") + (internVar or 0)
			if lets>0 or forced then
				context.registerOP(node, plume.ops.ENTER_SCOPE, 0, lets)
				table.insert(context.scopes, {})
				f(node)
				table.remove(context.scopes)
				context.registerOP(nil, plume.ops.LEAVE_SCOPE, 0, 0)
			else
				f(node)
			end
		end		
	end

	function context.file(f)
		f = f or context.childrenHandler
		return function (node)
			table.insert(context.roots, #context.scopes+1)
			f(node)
			table.remove(context.roots)
		end		
	end
end