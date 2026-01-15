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

local function removeUselessDo(node)
	if node.type == "do" then
		if isEmpty(node) then
			return ast._block()
		elseif not hasLocals(node) then
			return ast._block(unpack(node)):traverse(removeUselessDo)
		end
	end
	return node
end


local function constantFolding(node)
	if node.type == "or" then
		if node[1].type == "nil" or node[1].type == "false" then
			return node[2]
		end
		if node[2].type == "nil" or node[2].type == "false" then
			return node[1]
		end
	elseif node.type == "eq" then
		if node[1].type == "number" and node[2].type == "number" then
			if node[1].value == node[2].value then
				return ast._true()
			else
				return ast._false()
			end
		end
	elseif node.type == "add" then
		if node[1].type == "number" and node[1].value == "0" then
			return node[2]
		end
		if node[2].type == "number" and node[2].value == "0" then
			return node[1]
		end
	elseif node.type == "par" and node.expr.type == "number" then
		return node.expr
	end
	return node
end

local function removeUselessGoto(tree)
	local count = {}
	tree:traverse(function(node)
		for pos, child in ipairs(node) do
			if child.type == "goto" then
				if count[child.name] then
					count[child.name] = count[child.name] + 1 
				else
					count[child.name] = 1 
				end
				if node[pos+1] and node[pos+1].type == "label" and node[pos+1].name == child.name then
					child.adj = true
					node[pos+1].adj = true
				end
			end
		end
		return node
	end)
	
	tree:traverse(function(node)
		if node.type == "label" or node.type == "goto" then
			if count[node.name] then
				local unic = count[node.name] == 1
				if node.adj and (unic or node.type == "goto") then
					return ast._block()
				end
			end
		end
		return node
	end)
	return node
end

return {
	removeUselessDo = removeUselessDo,
	removeUselessGoto = removeUselessGoto,
	constantFolding = constantFolding
}