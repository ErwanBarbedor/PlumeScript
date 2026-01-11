package.path =  "build-tools/?.lua;build-tools/thenumbernine/?.lua;build-tools/thenumbernine/ext/?.lua;;build-tools/thenumbernine/parser/?.lua;;build-tools/thenumbernine/template/?.lua;" .. package.path
local Parser = require "parser"
local tolua = require 'ext.tolua'

local function printTable(t)
	print(tolua(t))
end

local beautifier = function (node)
	local result = {}
	local indent = 0

	local function newline(t)
		table.insert(result, "\n"..("    "):rep(indent))
	end

	local function correctIndentation()
		if result[#result]:match('^%s*$') then
			table.remove(result)
			newline()
		end
	end

	local beautify, beautifyAll
	function beautifyAll(node)
		for _, child in ipairs(node) do
			beautify(child, indent)
		end
	end

	function beautify(node)
		if node.type == "block" then
			beautifyAll(node)

		elseif node.type == "function" then
			table.insert(result, "function")
			if node.name and type(node.name.name) == "string" then
				table.insert(result, " ")
				table.insert(result, node.name.name)
			elseif #node.name>0 then
				table.insert(result, " ")
				beautifyAll(node.name)
			end

			table.insert(result, " (")
				local args = {}
				for i, arg in ipairs(node.args) do
					beautify(arg)
					if i <#node.args then
						table.insert(result, ", ")
					end
				end
				
			table.insert(result, ")")
			if #node>0 then
				indent = indent+1
				newline()
				beautifyAll(node)
				indent = indent-1
			end
			correctIndentation()
			table.insert(result, "end")
			newline()

		elseif node.type == "call" then
			if node.func.name then
				table.insert(result, node.func.name)
			else
				beautify(node.func)
			end
			table.insert(result, " (")
				local args = {}
				for i, arg in ipairs(node.args) do
					beautify(arg)
					if i <#node.args then
						table.insert(result, ", ")
					end
				end
				
			table.insert(result, ")")
			newline()

		elseif node.type == "return" or node.type == "local" then
			table.insert(result, node.type)
			if #node.exprs > 0 then
				table.insert(result, " ")
				beautifyAll(node.exprs)
			end
		elseif node.type == "assign" then
			beautifyAll(node.vars)
			table.insert(result, " = ")
			beautifyAll(node.exprs)
			newline()

		elseif node.type == "index" then
			beautify(node.expr)
			table.insert(result, ".")
			if node.key.type == "string" and node.key.value:match("^[a-zA-Z_][a-zA-Z_0-9]*$")then
				table.insert(result, node.key.value)
			else
				beautify(node.key)
			end

		elseif node.type == "add" then
			for i, arg in ipairs(node) do
				if #arg > 1 then
					table.insert(result, '(')
				end
				beautify(arg)
				if #arg > 1 then
					table.insert(result, ')')
				end
				if i <#node then
					table.insert(result, " + ")
				end
			end

		elseif node.type == "number" then
			table.insert(result, node.value)
		elseif node.type == "var" then
			table.insert(result, node.name)
		elseif node.type == "string" then
			table.insert(result, '"'..node.value:gsub('"', '\\"')..'"')

		else
			error("NYI " .. node.type)
		end
	end
	

	beautify(node)
	return table.concat(result)
end

code = [[
function BEGIN_ACC(vm, arg1, arg2)
    --- Stack 1 to main stack frame, the current msp
    --- arg1: -
    --- arg2: -
    x._STACK_PUSH(
        vm.mainStack.frames,
        vm.mainStack.pointer+1
    )
end
]]
print(beautifier(Parser.parse(code,  nil, '5.2', true)))

return beautifier