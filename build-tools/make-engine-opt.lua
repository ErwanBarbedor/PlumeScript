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

local _ret = 0
local function geturet()
	_ret = _ret + 1
	return "_ret".._ret
end
local _labend = 0
local function getulabend()
	_labend = _labend + 1
	return "_inline_end".._labend
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

			local labend = getulabend()
			local rets = {}
			body:traverse(function(node)
				if node.type == "return" then
					for i=1, #node.exprs do
						if #rets<i then
							table.insert(rets, ast._var(geturet()))
						end
					end
					return ast._block(
						ast._assign(rets, node.exprs),
						ast._goto(labend)
					)
				end
				return node
			end)

			local init
			if #rets>0 then
				init = ast._local(rets)
			end

			body:traverse(nil, inlineFunctions)

			local parent = ast._block
			for _, elem in ipairs(body) do
				if elem.type == "local" then
					parent = ast._do
					break
				end
			end
			
			local result = parent(unpack(body))
			if init then
				result = ast._block(init, result)
			end
			if #rets>0 then
				result = ast._block(result, ast._label(labend))
			end

			local insertPoint, assignPoint
			if node.parent.type == "assign" then
				assignPoint = node.parent
				if node.parent.parent.type == "local" then
					insertPoint = node.parent.parent
				else
					insertPoint = node.parent
				end
			else
				return result
			end

			if insertPoint then
				insertPoint.insertBefore = result

				if assignPoint and #rets>0 then
					assignPoint.exprs = rets
					return
				else
					return ast._nil()
				end
			end


		end
	end
	return node
end

local function applyInsertBefore(node)
	if node.insertBefore then
		local before = node.insertBefore
		node.insertBefore = nil
		return ast._block(before, node)
	end
	return node
end

local function applyInsertExprs(node)
	if node.insertExprs then
		local exprs = node.insertExprs
		node.insertExprs = nil
		node.exprs = exprs
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

local debug = true

require "make-engine" -- Compile base file
local tree

if debug then
	tree = loadCode([[
--! inline
function double()
	return x, y
end]], false)

else
	tree = loadCode('plume-data/engine/engine.lua', true)
end

-- printTable(tree)

tree:traverse(inlineRequire)
tree:traverse(renameRun)
tree:traverse(saveFunctionsToInline)
tree:traverse(nil, inlineFunctions)
tree:traverse(nil, applyInsertBefore)
tree:traverse(nil, applyInsertExprs)

local beautifier = require "luaBeautifier"
local finalCode = beautifier(tree)
if debug then
	print(finalCode)
else
	local f = io.open('plume-data/engine/engine-opt.lua', 'w')
		f:write(finalCode)
	f:close()
end