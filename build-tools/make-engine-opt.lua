require "build-tools/make-engine"

local plume = require "plume-data/engine/init"
local lib = require "build-tools/luaParser"

local uid = 0
local function getUID()
	uid = uid+1
	return "_temp"..uid
end


local function deepcopy(obj)
    if obj == nil then
        return nil
    end

    if type(obj) == "table" then
        local copy = {}
        for key, value in pairs(obj) do
            copy[deepcopy(key)] = deepcopy(value)
        end
        return copy
    else
        return obj
    end
end

local function apply(ast, f, ...)
	ast = f(ast, ...)
	for i, node in ipairs(ast.children) do
		local rec
		ast.children[i], rec = f(node, ...)
		if rec and ast.children[i].children then
			apply(ast.children[i], f, ...)
		end
	end
end

local function renameRun(node)
	if node.kind == "function" then
		if node.name == "plume._run_dev" then
			node.name = "plume._run"
		end
	end
	return node, true
end

local function runCommands(node)
	local toinline = false
	if node.children then
		for i, child in ipairs(node.children) do
			if child.kind == "command" then
				if child.name == "inline" then
					node.children[i] = {kind="blank", children={}}
					toinline = true
				else
					print("Unknown command '" .. node.name .. "'")
				end
			elseif toinline and child.kind == "function" then
				toinline = false
				child.toinline = true
			end
		end
	end
	return node, true
end

local function searchFunctionsToInline(node, acc, check)
	if node.kind == "function" then
		if node.toinline then
			acc[node.name] = {body=node.children, params=node.params}
			node.inlined = true
		end
	end
	return node, true
end

local function subVar(node, map)
	if node.kind == "var" then
		if map[node.name] then
			return map[node.name], false
		end
	elseif node.kind == "call" then
		local src = map[node.name]
		if src then
			node.name = src.name
			local i = 1
			while not node.name and i <= #src.children do
				if src.children[i].kind == "var" then
					node.name = src.children[i].name
				end
				i = i + 1
			end
		end
	end
	return node, true
end

local function handleReturn(node, returnVars)
	if node.kind == "return" then
		node.kind = "blank"
		if #returnVars > 0 then
			table.insert(node.children, 1, {kind="raw", value=table.concat(returnVars, ", ").." ="})
		else
			table.insert(node.children, 1, {kind="raw", value="local _ ="})
		end
	end
	return node, false
end

local function inlineRequire(node)
	if node.kind == "call" and node.name == "require" then
		local nodePath = node.children[1].children[1]
		if nodePath.kind == "string" then
			local value = nodePath.value:sub(2, -2) -- remove quotes
			local src = io.open(value..".lua")
			if src then
				local ast = lib.parse(src:read("*a"))
				return ast
			else
				print("Cannot inline lib '" .. value .. "'.")
			end
		end
	end
	return node, true
end

local function inlineCall(node, functions, check)
	if node.kind == "call" then
		if functions[node.name] then
			local f = functions[node.name]
			local body = deepcopy(f.body)

			local argsmap = {}
			local argscount = 0
			for _, child in ipairs(node.children) do
				if child.kind == "arg" then
					argscount = argscount + 1
					argsmap[f.params[argscount]] = {
						kind = "blank",
						children = child.children
					}
				end
			end

			local returnVars = {}
			if node.affected then
				for _ in node.affected:gmatch('[^,]+') do
					table.insert(returnVars, getUID())
				end
			end

			apply({children=body}, subVar, argsmap)
			apply({children=body}, handleReturn, returnVars)


			local result = {kind="blank", children={}}

			if true then
				table.insert(result.children, {kind="open", name="do", children=body})
			else -- if no variable collision
				table.insert(result.children, {kind="blank", children=body})
			end

			if #returnVars > 0 then
				table.insert(result.children, {kind="raw", value=" "..node.affected .. " = " .. table.concat(returnVars, ", ")})
			end

			return result
		end
	end
	return node, true
end

local function inline(ast)
	apply(ast, renameRun)
	apply(ast, inlineRequire)
	apply(ast, runCommands)

	local functions = {}
	apply(ast, searchFunctionsToInline, functions)
	apply(ast, inlineCall, functions)
end


local base = [[
--! inline
function _BIN_OPP_BOOL (opp)
    _STACK_PUSH(opp(right, left))
end

_BIN_OPP_BOOL (_AND)
]]

-- local ast = lib.parse(base)
-- inline(ast)
-- plume.debug.pprint(ast)
-- print(lib.export(ast))

local base = io.open('plume-data/engine/engine.lua')
local ast = lib.parse(base:read("*a"))
inline(ast)
io.open('plume-data/engine/engine-opt.lua', "w"):write(lib.export(ast))