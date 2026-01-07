require "build-tools/make-engine"

local plume = require "plume-data/engine/init"
local lib = require "build-tools/luaParser"

local function apply(ast, f)
	for i, node in ipairs(ast.children) do
		ast.children[i] = f(node)
		if ast.children[i].children then
			apply(ast.children[i], f)
		end
	end
end

local function inline_require(node)
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
	return node
end

local function inline(ast)
	apply(ast, inline_require)
end

local base = io.open('plume-data/engine/engine.lua')

local ast = lib.parse(base:read("*a"))
inline(ast)
io.open('plume-data/engine/engine-opt.lua', "w"):write(lib.export(ast))