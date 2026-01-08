require "build-tools/make-engine"

local plume = require "plume-data/engine/init"
local lib = require "build-tools/luaParser"

local function checkToInline(name)
	return name:match('^[_A-Z]+$')
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

local function searchFunctionsToInline(node, acc)
	if node.kind == "function" then
		if checkToInline(node.name) then
			acc[node.name] = {body=node.children, params=node.params, affected=node.affected, isLocal = node.isLocal}
		end
	end
	return node, true
end

local function subVar(node, map)
	if node.kind == "var" then
		if map[node.name] then
			return map[node.name]
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

local function inlineCall(node, functions)
	if node.kind == "call" then
		if checkToInline(node.name) and functions[node.name] then
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

			apply({children=body}, subVar, argsmap)

			if not f.affected then
				return {kind="open", name="do", children=body}
			end
		end
	end
	return node, true
end

local function inline(ast)
	apply(ast, renameRun)
	apply(ast, inlineRequire)

	local functions = {}
	apply(ast, searchFunctionsToInline, functions)
	apply(ast, inlineCall, functions)
end

local base = io.open('plume-data/engine/engine.lua')

local ast = lib.parse(base:read("*a"))
inline(ast)
io.open('plume-data/engine/engine-opt.lua', "w"):write(lib.export(ast))