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
	--- For a given node, call the appropriate handler to generate bytecode
	--- @param node node The node to process
	--- @return nil (Bytecode is directly added to chunk.instructions)
	function context.nodeHandler(node)
		local handler = nodeHandlerTable[node.name]
		if not handler then
			error("NYI tokenhandler " .. node.name) -- Guard against typo errors in parser
		end
		handler(node)
	end

	--- Handle all node children.
	--- Usefull to process structure body.
	--- Don't fail if node hasn't children.
	--- @param node node
	--- @return nil
	function context.childrenHandler(node)
		for _, child in ipairs(node.children or {}) do
			context.nodeHandler(child)
		end
	end
end