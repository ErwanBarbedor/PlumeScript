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

local Parser = require "parser"
local ast = require "parser.lua.ast"

local function printTable(t)
	print(tolua(t))
end


local recAnchor = {
	"add", "sub", "mul", "div", "mod", "concat", "pow",
	"eq", "ne", "lt", "le", "gt", "ge",
	"and", "or", "not", "index", "return"
}
for _, k in ipairs(recAnchor) do
	recAnchor[k] = true
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


local function findAnchor(node)
	local insertPoint, assignPoint
	if node.parent then
		if node.parent.type == "assign" then
			assignPoint = node.parent
			if node.parent.parent and node.parent.parent.type == "local" then
				insertPoint = node.parent.parent
			else
				insertPoint = node.parent
			end
		elseif node.parent.type == "if" then
			if node == node.parent.cond then
				insertPoint = node.parent
			else
				insertPoint = node
			end
		-- missing case where min or max should be replaced
		elseif node.parent.type == "foreq" then
			insertPoint = node
		-- Break lazy if-else strategy
		elseif node.parent.type == "elseif" then
			if node == node.parent.cond then
				insertPoint = node.parent.parent
			else
				insertPoint = node
			end
		elseif recAnchor[node.parent.type] then
			return findAnchor(node.parent)
		elseif node.parent.type == "block" or node.parent.type == "function" then
			insertPoint = node
		elseif node.parent.type == "call" then
			insertPoint = findAnchor(node.parent)
		end
	end
	return insertPoint, assignPoint
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

			local parent = ast._do
			
			local result = parent(unpack(body))
			if init then
				result = ast._block(init, result)
			end
			if #rets>0 then
				result = ast._block(result, ast._label(labend))
			end
			local insertPoint, assignPoint = findAnchor(node)
			if insertPoint and insertPoint ~= node then
				if insertPoint.insertBefore then
					insertPoint.insertBefore = ast._block(insertPoint.insertBefore, result)
				else
					insertPoint.insertBefore = result
				end

				if #rets>1 then
					assignPoint.exprs = rets
					return
				elseif #rets == 1 then
					return rets[1]
				else
					return ast._nil()
				end
			else
				if node.insertBefore then
                    result = ast._block(node.insertBefore, result)
                end
				return result
			end
		end
	end
	return node
end

local function applyInsertBefore  (node)
	if node.insertBefore then
		local before = node.insertBefore
		node.insertBefore = nil
		local result = ast._block(before, node)
		result:traverse(applyInsertBefore)
		return result
	end
	return node
end

local function applyInsertExprs  (node)
	if node.insertExprs then
		local exprs = node.insertExprs
		node.insertExprs = nil
		node.exprs = exprs
	end
	return node
end


return {
	loadCode = loadCode,
	applyCommands = applyCommands,
	applyInsertBefore=applyInsertBefore,
	applyInsertExprs=applyInsertExprs,
	saveFunctionsToInline = function(node)
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
	end,
	inlineFunctions = inlineFunctions,
	inlineRequire = function (node)
		if node.type == "call" and node.func.name == "require" then
			local path = node.args[1].value .. ".lua"
			return ast._do(loadCode(path, true))
		end
		return node
	end,

	

	renameRun = function (node)
		if node.type == "function" and node.name then
			if node.name.key and node.name.key.value == "_run_dev" then
				node.name.key.value = "_run"
			end
		end
		return node
	end
}