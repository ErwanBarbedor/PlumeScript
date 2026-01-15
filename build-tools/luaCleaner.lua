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

-- These adjustments should only have a minor impact on performance, since luajit would have done it itself.
-- But it makes the code look nicer.

local ast = require "parser.lua.ast"

local function isEmpty(node)
	for _, child in ipairs(node) do
		if child.type ~= "block" or not isEmpty(child) then
			return false
		end
	end
	return true
end

local function hasLocals(node)
	for _, child in ipairs(node) do
		if child.type== "local" then
			return true
		end
	end
	return false
end

return {
	removeUselessDo = function(node)
		if node.type == "do" then
			if isEmpty(node) then
				return ast._block()
			elseif not hasLocals(node) then
				return ast._block(unpack(node))
			end
		end
		return node
	end
}