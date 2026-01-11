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

-- Optimize engine.lua to performances
-- Thanks for thenumbernine lua-parser lib.

package.path =  "build-tools/?.lua;build-tools/thenumbernine/?.lua;build-tools/thenumbernine/ext/?.lua;;build-tools/thenumbernine/parser/?.lua;;build-tools/thenumbernine/template/?.lua;" .. package.path
local Parser = require "parser"
local ast = require "parser.lua.ast"
local tolua = require 'ext.tolua'

local function printTable(t)
	print(tolua(t))
end

local functionsToInline = {}
local function applyCommands(code)
	for name in code:gmatch('%-%-! inline\n%s*function%s+([a-zA-Z_0-9]*)') do
		functionsToInline[name] = true
	end

	code = code:gsub('%-%-! to%-remove%-begin.-%-%-! to%-remove%-end', '')
	for command in code:gmatch('%-%-! ([^\n]*)') do
		if command ~= "inline" then
			print("Error: unknow command '" .. command .. "'.")
		end
	end

	return code
end

local function loadCode(path, isFile)
	local code
	if isFile then
		local f = io.open(path)
			code = f:read("a")
		f:close()
	else
		code = path
	end

	code = applyCommands(code)
	local result, msg = Parser.parse(code, isFile and path, '5.2', true)

	if not result then
		print("Cannot load " .. path .. ".")
		error(msg)
	end

	return result
end

local function inlineRequire(node)
	if node.type == "call" and node.func.name == "require" then
		local path = node.args[1].value .. ".lua"
		return ast._do(loadCode(path, true))
	end
	return node
end

local function inlineFunctions(node)
	if node.type == "call" then
		local f = functionsToInline[node.func.name]
		if f then
			local body = f.body:copy()
			local args = node.args
			local params = f.params
			for i, param in ipairs(params) do
				local arg = node.args[i] or ast._nil()
				body:traverse(function(node)
					if node.type == "var" and node.name == param.name then
						return arg:copy()
					end
					return node
				end)
			end

			return ast._block(unpack(body))
		end
	end
	return node
end

local function saveFunctionsToInline(node)
	if node.type == "function" and node.name then
		local name = node.name.name
		if functionsToInline[name] then
			functionsToInline[name] = {
				body = node,
				params = node.args
			}
			return ast._block()
		end
	end
	return node
end

local function renameRun(node)
	if node.type == "function" and node.name then
		if node.name.key and node.name.key.value == "_run_dev" then
			node.name.key.value = "_run"
		end
	end
	return node
end

require "make-engine" -- Compile base file
local tree = loadCode('plume-data/engine/engine.lua', true)
-- local tree = loadCode([[
-- --! inline
-- function TEST(x)
-- 	x.foo()
-- end

-- TEST(y)
-- ]], false)

-- printTable(tree)

tree:traverse(inlineRequire)
tree:traverse(renameRun)
tree:traverse(saveFunctionsToInline)
tree:traverse(nil, inlineFunctions)
-- print(tree:toLua())

local beautifier = require "luaBeautifier"
local f = io.open('plume-data/engine/engine-opt.lua', 'w')
	f:write(beautifier(tree))
f:close()