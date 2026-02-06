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
		LOAD_LOCAL LOAD_STATIC LOAD_REF
		STORE_LOCAL STORE_STATIC STORE_VOID

		TABLE_NEW
		TABLE_SET TABLE_INDEX TABLE_REGISTER_SELF
		TABLE_SET_META
		TABLE_SET_ACC
		TABLE_EXPAND

		CALL_INDEX_REGISTER_SELF

		TAG_META_KEY TAG_KEY
		
		ENTER_SCOPE LEAVE_SCOPE
		BEGIN_ACC CONCAT_TABLE CONCAT_TEXT CONCAT_CALL CHECK_IS_TEXT

		JUMP_IF JUMP_IF_NOT JUMP_IF_NOT_EMPTY JUMP_FOR JUMP
		JUMP_IF_PEEK JUMP_IF_NOT_PEEK

		GET_ITER FOR_ITER

		OP_ADD OP_MUL OP_SUB OP_DIV OP_NEG OP_MOD OP_POW
		OP_LT OP_EQ
		OP_AND OP_NOT OP_OR
		
		DUPLICATE SWITCH

		RETURN RETURN_FILE

		END
]]
	local function makeNames(names)
		local t = {}
		plume.ops_count = 1
		for name in names:gmatch("%S+") do
			t[name] = plume.ops_count
			plume.ops_count = plume.ops_count + 1
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
		for _, child in ipairs(node.children or {}) do
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

	function plume.ast.markType(node)
		local waitOneValue = node.parent and (node.parent.name == "ELSE" or node.parent.name == "ELSEIF")

		if node.parent and (
			   node.name == "FOR"
			or node.name == "WHILE"
			or node.name == "IF"
			or node.name == "ELSE"
			or node.name == "ELSEIF"
			or (node.name == "BODY" and (
				   node.parent.name == "FOR"
				or node.parent.name == "WHILE"
				or node.parent.name == "IF"
				or node.parent.name == "ELSE"
				or node.parent.name == "ELSEIF"
			)))	 then
			node.type = node.parent.type
		else
			node.type = "EMPTY"
		end



		for _, child in ipairs(node.children or {}) do
			child.parent = node
			local childType = plume.ast.markType(child)

			-- workaround for the case where child is an information,
			-- not a proper child
			local avoid = child.name == "IDENTIFIER" and (
			    	node.name ~= "EVAL"
					and node.name ~= "LIST_ITEM"
			)

			if not avoid then
				if node.type == "EMPTY" then
					if childType == "TEXT"
					and (child.name ~= "FOR" and child.name ~= "WHILE") then
						node.type = "VALUE"
					else
						node.type = childType
					end
				elseif node.type == "VALUE"
				and (childType == "TEXT" or childType == "VALUE") then
					if waitOneValue then
						waitOneValue = false
					else
						node.type = "TEXT"
					end
				elseif node.type == "TEXT" and childType == "VALUE" then
					node.type = "TEXT"
				elseif childType ~= "EMPTY" and node.type ~= childType then
					plume.error.mixedBlockError(child, node.type, childType)
				end
			end
		end

		-- For / While cannot produce VALUE
		if node.name == "FOR" or node.name == "WHILE" then
			if node.type == "VALUE" then
				node.type = "TEXT"
			end
		end

		-- primitive types
		if node.name == "LIST_ITEM"
		or node.name == "HASH_ITEM"
		or node.name == "EXPAND" then
			return "TABLE"
		elseif node.name == "TEXT"
			or node.name == "EVAL"
			or node.name == "BLOCK"
			or node.name == "NUMBER" 
			or node.name == "IDENTIFIER"
			or node.name == "QUOTE"
			then
			return "TEXT"
		elseif node.name == "FOR"
			or node.name == "WHILE"
			or node.name == "IF"
			or node.name == "ELSE"
			or node.name == "ELSEIF"
			or node.name == "BODY" then
			return node.type
		elseif node.name == "MACRO" then
			if plume.ast.get(node, "IDENTIFIER") then
				return "EMPTY"
			else
				return "VALUE"
			end
		elseif node.name == "ADD"
			or node.name == "SUB"
			or node.name == "MUL"
			or node.name == "DIV"
			or node.name == "POW"
			or node.name == "MOD"
			or node.name == "EQ"
			or node.name == "NEQ"
			or node.name == "LT"
			or node.name == "GT"
			or node.name == "LTE"
			or node.name == "GTE"

		    or node.name == "AND"
		    or node.name == "NOT"
		    or node.name == "OR"

		    or node.name == "FALSE"
		    or node.name == "TRUE"

		    or node.name == "DO" then
			return "VALUE"
		else
			return "EMPTY"
		end
	end

	function plume.checkIdentifier(identifier)
		for kw in ('if then elseif else while for do macro let set const static param use'):gmatch('%S+') do
			if identifier == kw then
				return false
			end
		end
		return true
	end

	function plume.ast.labelMacro(ast)
		plume.ast.browse(ast, function(node)
			if node.name == "HASH_ITEM" and node.children[1].name == "IDENTIFIER"  then
				local value = node.children[2]
				if value.name == "BODY" and #value.children == 1 and value.children[1].name == "MACRO" then
					value.children[1].label = node.children[1].content
				end
			end
		end)
	end

	local function formatDir(s)
        local result = s:gsub('\\', '/')
        if result ~= "" and not result:match('/$') then
            result = result .. "/"
        end
        return result
    end
    local function formatDirFromFilename(s)
        local result = formatDir(s:gsub('/[^/]+$', ''))
        if result ~= "" and not result:match('/$') then
            result = result .. "/"
        end
        return result
    end

    local pathTemplates = {
        "%base%%path%.%ext%",
        "%base%%path%/init.%ext%",
    }
    
    function plume.getFilenameFromPath(path, lua, runtime, firstFilename, lastFilename)
        path = path:gsub('\\', '/')
        
        local root
        if path:match('^%.+/') or path == "." then
            root = formatDirFromFilename(lastFilename)
        else
            root = formatDirFromFilename(firstFilename)
        end

        local ext
        if lua then
            ext = "lua"
        else
            ext = "plume"
        end

        local basedirs = {}
        local env = runtime.env.PLUME_PATH
        if env then
            for dir in env:gmatch('[^;]+') do
                dir = formatDir(dir)
                table.insert(basedirs, dir)
            end
        end
        table.insert(basedirs, root)
        table.insert(basedirs, "")

        local searchPaths = {}
        for _, base in ipairs(basedirs) do
            for _, template in ipairs(pathTemplates) do
                template = template:gsub('%%base%%', base)
                template = template:gsub('%%path%%', path)
                template = template:gsub('%%ext%%', ext)

                table.insert(searchPaths, template)
            end
        end

        for _, search in ipairs(searchPaths) do
            local f = io.open(search)
            if f then
                f:close()
                return search
            end
        end
        
        return nil, searchPaths
    end
end