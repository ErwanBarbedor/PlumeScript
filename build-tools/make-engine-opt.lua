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
local tolua = require 'ext.tolua'

local function printTable(t)
	print(tolua(t))
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

	local result, msg = Parser.parse(code, isFile and path, '5.2', true)

	if not result then
		print("Cannot load " .. path .. ".")
		error(msg)
	end

	return result
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
-- local tree = loadCode ([[
-- function test()
-- end

-- ]], false)

tree:traverse(renameRun)

local f = io.open('plume-data/engine/engine-opt.lua', 'w')
	f:write(tree:toLua())
f:close()