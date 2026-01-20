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


package.path = "build-tools/?.lua;build-tools/thenumbernine/?.lua;build-tools/thenumbernine/ext/?.lua;;build-tools/thenumbernine/parser/?.lua;;build-tools/thenumbernine/template/?.lua;" .. package.path
local Parser = require "parser"
local tolua = require 'ext.tolua'

local function printTable(t)
    print(tolua(t))
end

local beautifier = function(node)
    local result = {}
    local indent = 0

    local function newline()
        table.insert(result, "\n" .. ("    "):rep(indent))
    end

    local function correctIndentation()
        if result[#result]:match('^%s*$') then
            table.remove(result)
            newline()
        end
    end

    local function removeNewLine()
        if result[#result]:match('^%s*$') then
            table.remove(result)
        end
    end

    local dispatch, beautify
    local function beautifyAll(nodes)
        for _, child in ipairs(nodes) do
            beautify(child)
        end
    end

    
    function beautify(node)
        local handler = dispatch[node.type]
        if handler then
            handler(node)
        else
            error("NYI " .. node.type)
        end
    end

    -- Table de dispatch
    dispatch = {
        block = function(node)
            beautifyAll(node)
        end,

        ["function"] = function(node)
            table.insert(result, "function")
            if node.name then
            	if type(node.name) == "string" then
	                table.insert(result, " ")
	                table.insert(result, node.name.name)
	            else
	                table.insert(result, " ")
	                beautify(node.name)
	            end
            end

            table.insert(result, " (")
            local args = {}
            for i, arg in ipairs(node.args) do
                beautify(arg)
                if i < #node.args then
                    table.insert(result, ", ")
                end
            end
            table.insert(result, ")")

            if #node > 0 then
                indent = indent + 1
                newline()
                beautifyAll(node)
                indent = indent - 1
            end
            correctIndentation()
            table.insert(result, "end")
            newline()
        end,

        ["if"] = function(node)
        	table.insert(result, "if ")
        	beautify(node.cond)
        	table.insert(result, " then")
        		indent = indent + 1
        		newline()
        		beautifyAll(node)
        	for _, _elseif in ipairs(node.elseifs) do
        		indent = indent - 1
        		correctIndentation()
        		indent = indent + 1
        		table.insert(result, "elseif ")
        		beautify(_elseif.cond)
        		table.insert(result, " then")
        		newline()
        		
        		beautifyAll(_elseif)
        	end

        	if node.elsestmt then
        		indent = indent - 1
        		correctIndentation()
        		indent = indent + 1
        		table.insert(result, "else")
        		newline()
        		
        		beautifyAll(node.elsestmt)
        	end
        	indent = indent - 1
        	correctIndentation()
        	table.insert(result, "end")
        	newline()
        end,

        foreq = function(node)
        	table.insert(result, "for ")
        	beautify(node.var)
        	table.insert(result, " = ")
        	beautify(node.min)
        	table.insert(result, ", ")
        	beautify(node.max)
        	if node.step then
        		table.insert(result, ", ")
        		beautify(node.step)
        	end
        	table.insert(result, " do")
        		indent = indent + 1
        		newline()
        		beautifyAll(node)
        		indent = indent - 1
        		correctIndentation()
        	table.insert(result, "end")
        	newline()
        end,

        forin = function(node)
        	table.insert(result, "for ")
        	for i, var in ipairs(node.vars) do
        		beautify(var)
        		if i < #node.vars then
        			table.insert(result, ", ")
        		end
        	end

        	table.insert(result, " in ")
        	beautifyAll(node.iterexprs)

        	table.insert(result, " do")
        		indent = indent + 1
        		newline()
        		beautifyAll(node)
        		indent = indent - 1
        		correctIndentation()
        	table.insert(result, "end")
        	newline()
        end,
        ["do"] = function(node)
        	table.insert(result, "do")
        		indent = indent + 1
        		newline()
        		beautifyAll(node)
        		indent = indent - 1
        		correctIndentation()
        	table.insert(result, "end")
        	newline()
        end,

        call = function(node)
            if node.func.name then
                table.insert(result, node.func.name)
            else
                beautify(node.func)
            end
            table.insert(result, " (")
            for i, arg in ipairs(node.args) do
                beautify(arg)
                if i < #node.args then
                    table.insert(result, ", ")
                end
            end
            removeNewLine()
            table.insert(result, ")")
            newline()
        end,

        ["return"] = function(node)
            table.insert(result, "return")
            if #node.exprs > 0 then
                table.insert(result, " ")
            end

            for i, elem in ipairs(node.exprs) do
                beautify(elem)
                if i < #node.exprs then
                	table.insert(result, ", ")
                end
            end
            newline()
            
        end,

        ["local"] = function(node)
            table.insert(result, "local")
            if #node.exprs > 0 then
                table.insert(result, " ")
            end

             for i, elem in ipairs(node.exprs) do
                beautify(elem)
                if i < #node.exprs then
                	table.insert(result, ", ")
                end
            end
            newline()
        end,

        assign = function(node)
            for i, var in ipairs(node.vars) do
        		if var.type == "string" then
        			if var.value:match("^[a-zA-Z_][a-zA-Z_0-9]*$") then
	                	table.insert(result, var.value)
	                else
	                	table.insert(result, "[")
	                	beautify(var)
	                	table.insert(result, "]")
	                end
	            else
	                beautify(var)
	            end
        		if i < #node.vars then
        			table.insert(result, ", ")
        		end
        	end
            table.insert(result, " = ")
            for i, elem in ipairs(node.exprs) do
                beautify(elem)
                if i<#node.exprs then
                    removeNewLine()
                    table.insert(result, ", ")
                end
            end
            newline()
        end,

        par = function(node)
            table.insert(result, "(")
            beautify(node.expr)
            table.insert(result, ")")
        end,

        label = function(node)
            table.insert(result, "::")
            table.insert(result, node.name)
            table.insert(result, "::")

            -- harcoded style for engine.lua
            if node.name ~= "END" and node.name:sub(1, 1) ~= "_" then
                indent = indent + 1
            end
            --
            newline()
        end,

        ["goto"] = function(node)
        	table.insert(result, "goto ")
            table.insert(result, node.name)
            -- harcoded style for engine.lua
            if node.name == "DISPATCH" then
                indent = indent - 1
            end
            --
            newline()
    	end,

        index = function(node)
            beautify(node.expr)
            
            if node.key.type == "string" and node.key.value:match("^[a-zA-Z_][a-zA-Z_0-9]*$") then
            	table.insert(result, ".")
                table.insert(result, node.key.value)
            else
            	table.insert(result, "[")
                beautify(node.key)
                table.insert(result, "]")
            end
        end,

        indexself = function(node)
            beautify(node.expr)
            table.insert(result, ":")
            if type(node.key) == "string" then
                table.insert(result, node.key)
            else
                beautify(node.key)
            end
        end,

        number = function(node)
            table.insert(result, node.value)
        end,

        var = function(node)
            table.insert(result, node.name)
        end,

        string = function(node)
            table.insert(result, '"' .. node.value:gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\t', '\\t') .. '"')
        end,

        table = function(node)
        	table.insert(result, "{")
        	for i, elem in ipairs(node) do
        		beautify(elem)
        		removeNewLine()
        		if i < #node then
        			table.insert(result, ", ")
        		end
        	end
        	table.insert(result, "}")
        end,

        ["false"] = function(node)
        	table.insert(result, "false")
        end,
        ["true"] = function(node)
        	table.insert(result, "true")
        end,
        ["nil"] = function(node)
        	table.insert(result, "nil")
        end
    }

    local binopps = {
    	add="+", sub="-", div="/", mul="*", mod="%",pow="^",
    	concat="..",
    	eq="==", ne="~=", lt="<", gt=">", le="<=", ge=">=",
    	["and"]="and", ["or"]="or"
    }
    for name, opp in pairs(binopps) do
    	dispatch[name]= function(node)
    		for i, arg in ipairs(node) do
                beautify(arg)
                if i < #node then
                	removeNewLine()
                    table.insert(result, " "..opp.." ")
                end
            end
    	end
    end

    local unopps = {len="#", ["not"]="not ", unm="-"}
    for name, opp in pairs(unopps) do
    	dispatch[name] = function(node)
    		table.insert(result, opp)
    		if #node > 1 then
                table.insert(result, '(')
            end
            beautifyAll(node)
            if #node > 1 then
                table.insert(result, ')')
            end
    	end
    end

    beautify(node)

    -- harcoded style for engine.lua
    result = table.concat(result):gsub('%s*\n', '\n'):gsub('if op == ([0-9]+) then%s*goto (%S+)', 'if op == %1 then goto %2')
    -- 
    return result
end

-- code = [[
-- function foobar ()
-- end
-- ]]

-- print(beautifier(Parser.parse(code, nil, '5.2', true)))

return beautifier