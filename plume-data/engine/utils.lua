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

return function (plume)
	-- OPP
	plume.ops_names = [[
		LOAD_CONSTANT LOAD_TRUE LOAD_FALSE LOAD_EMPTY
		LOAD_LOCAL LOAD_LEXICAL LOAD_STATIC 
		STORE_LOCAL STORE_LEXICAL STORE_STATIC

		TABLE_NEW TABLE_ADD TABLE_SET TABLE_SET_ACC TABLE_INDEX
		
		ENTER_SCOPE LEAVE_SCOPE
		ENTER_FILE  LEAVE_FILE
		BEGIN_ACC ACC_TABLE ACC_TEXT ACC_EMPTY ACC_CALL RETURN

		JUMP_IF JUMP_IF_NOT JUMP_IF_NOT_EMPTY JUMP

		OPP_ADD OPP_MUL OPP_SUB OPP_DIV OPP_NEG OPP_MOD OPP_POW
		OPP_GTE OPP_LTE OPP_GT OPP_LT OPP_EQ OPP_NEQ
		OPP_AND OPP_NOT OPP_OR
		
		END
]]
	local function makeNames(names)
		local t = {}
		local count = 1
		for name in names:gmatch("%S+") do
			t[name] = count
			count = count + 1
		end
		return t
	end

	plume.ops = makeNames(plume.ops_names)

	-- AST
	plume.ast = {}
	function plume.ast.browse(node, f, mindeep, maxdeep, parents)
		if mindeep then
			mindeep = mindeep - 1
		end
		if maxdeep then
			maxdeep = maxdeep - 1
			if maxdeep < -1 then
				return
			end
		end

		parents = parents or {}

		if not mindeep or mindeep <= 0 then
			local value = f(node, parents)
			if value == "STOP" then
				return value
			end
		end

		table.insert(parents, node)
		for _, child in ipairs(node.childs or {}) do
			local value = plume.ast.browse(child, f, mindeep, maxdeep, parents)
			if value == "STOP" then
				return value
			end
		end
		table.remove(parents)
	end

	function plume.ast.set(node, key, value, mindeep, maxdeep)
		plume.ast.browse(node, function(node) node[key] = value end, mindeep, maxdeep)
	end

	-- return the first child with given name
	function plume.ast.get(node, name, mindeep, maxdeep)
		mindeep = mindeep or 1
		maxdeep = maxdeep or 1
		local result
		plume.ast.browse(node, function(node)
			if node.name==name then
				result = node
				return "STOP"
			end
		end, mindeep, maxdeep)

		return result
	end

	function plume.ast.getAll(node, name, mindeep, maxdeep)
		mindeep = mindeep or 1
		maxdeep = maxdeep or 1
		local result = {}
		plume.ast.browse(node, function(node)
			if node.name==name then
				table.insert(result, node)
			end
		end, mindeep, maxdeep)

		return result
	end
end