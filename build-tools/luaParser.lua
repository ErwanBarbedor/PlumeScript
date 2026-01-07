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

-- Minimalist parser that captures only what is strictly necessary for engine optimization

local beautifier = require "build-tools/luaBeautifier"

local function fallback(state, match)
    state.add({kind="raw", value=match[1]})
end

local patterns = {
    {
        pattern = {"function%s*([a-zA-Z_%.]*)%s*%((.-)%)",},
        action = function (state, match)
            local params = {}
            for m in match[3]:gmatch('[^,%s]+') do
                table.insert(params, m)
            end
            state.push({kind="function", name=match[2], params=params})
        end
    },
    {
        pattern = {"end"},
        action = function (state, match)
            state.popReturn()
            state.pop()
        end
    },
    {
        pattern = {"return"},
        action = function (state, match)
            state.push({kind="return"})
        end
    },
    {
        pattern = {
            "()()([a-zA-Z_][a-zA-Z_%.]*)%(",
            "()([a-zA-Z_][a-zA-Z_%.]*)%s*=%s*([a-zA-Z_][a-zA-Z_%.]*)%(",
            "(local)%s+([a-zA-Z_][a-zA-Z_]*)%s*=%s*([a-zA-Z_][a-zA-Z_%.]*)%("
        },
        action = function (state, match)
            local affected = match[3]
            local isLocal = match[2]

            if affected == 1 then
                affected = nil
            end
            if isLocal == 1 then
                isLocal = nil
            end

            state.push({kind="call", name=match[4], affected=affected, isLocal=isLocal})
            state.push({kind="arg"})
        end
    },
    {
        pattern = {
            "([a-zA-Z_][a-zA-Z_%.]*)%s*('.-')",
            "([a-zA-Z_][a-zA-Z_%.]*)%s*(\".-\")",
        },
        action = function (state, match)
            local affected = match[3]
            local isLocal = match[2]

            state.push({kind="call", name=match[2]})
            state.push({kind="arg"})
            state.add({kind="string", value=match[3]})
            state.pop()
            state.pop()
        end
    },
    {
        pattern = {"%)"},
        action = function (state, match)
            if state.top.kind == "arg" then
                state.pop()
                state.pop()
            else
                fallback(state, match)
            end
        end
    },
    {
        pattern = {"%,"},
        action = function (state, match)
            if state.top.kind == "arg" then
                state.pop()
                state.push({kind="arg"})
            else
                fallback(state, match)
            end
        end
    },
    {
        pattern = {"[a-zA-Z_][a-zA-Z_%.]*"},
        action = function (state, match)
            if match[1] == "then" or match[1] == "do" then
                if state.top.kind == "elseif" then
                    state.pop()
                    state.add({kind="then"})
                else
                    state.push({kind="open", name=match[1]})
                end
            elseif match[1] == "elseif" then
                state.popReturn()
                state.push({kind="elseif"})
            else
                if match[1] == "else" then
                    state.popReturn()
                end
                state.add({kind="var", name=match[1]})
            end
        end
    },
    {
        pattern = {"%-%-!%s*([^\n]*)"},
        action = function (state, match)
            local args = {}
            for word in match[2]:gmatch('%S+') do
                table.insert(args, word)
            end

            state.add({
                kind="command",
                name=table.remove(args, 1),
                args=args
            })
        end
    },
    {
        pattern = {"%-%-%[%[.-%]%]", "%-%-[^\n]+\n?"},
        action = function (state, match)
        end
    },
    {
        pattern = {'".-"', "'.-'"},
        action = function (state, match)
            state.add({kind="string", value=match[1]})
        end
    },
}

local function parse(code)
    local state = {ast={children={}}, stack={}}
    state.top = state.ast
    local pos = 1
    local acc
    

    function state.flushacc()
        if acc then
            fallback(state, {code:sub(acc, pos-1)})
        end
    end
    function state.popReturn()
        if state.top.kind == "return" and #state.stack > 0 then
            state.pop()
        end
    end

    function state.push(t)
        table.insert(state.top.children, t)
        table.insert(state.stack, state.top)
        state.top = t
        if not state.top.children then
            state.top.children = {}
        end
    end

    function state.pop()
        state.top = table.remove(state.stack)
    end

    function state.add(t)
         table.insert(state.top.children, t)
    end

    while pos < #code do
        local match = {}
        for _, patternList in ipairs(patterns) do
            for _, pattern in ipairs(patternList.pattern) do
                match = {code:sub(pos):match("^("..pattern..")")}
                if #match>0 then
                    state.flushacc()
                    acc = nil
                    patternList.action(state, match)
                    break
                end
            end
            if #match>0 then
                break
            end
        end

        if #match>0 then
            pos = pos + #match[1]
        else
            if not acc then
                acc = pos
            end
            pos = pos+1
        end
    end
    state.flushacc()
    state.popReturn()

    return state.top
end

local function _export(ast)
    local result = {}

    for _, child in ipairs(ast.children) do
        if child.kind == "function" then
            table.insert(result, "function " .. child.name .. "(" .. table.concat(child.params, ", ") .. ")")
                table.insert(result, _export(child))
            table.insert(result, "end ")
        elseif child.kind == "call" then
            if child.affected then
                if child.isLocal then
                    table.insert(result, "local ")
                end
                table.insert(result, child.affected .. " = ")
            end
            table.insert(result, child.name .. "(")
            for i, childchild in ipairs(child.children) do
                table.insert(result, _export(childchild))
                if i < #child.children then
                    table.insert(result, ",")
                end
            end
            table.insert(result,  ")")
        elseif child.kind == "open" then
            table.insert(result, child.name)
            table.insert(result, _export(child))
            table.insert(result, "end")
        elseif child.kind == "return" then
            table.insert(result, "return")
            table.insert(result, _export(child))
        elseif child.kind == "var" then
            table.insert(result, child.name)
        elseif child.kind == "elseif" then
            table.insert(result, child.kind.." ")
            table.insert(result, _export(child))
        elseif child.kind == "then" then
            table.insert(result, child.kind.." ")
        elseif child.kind == "raw" then
            table.insert(result, child.value)
        elseif child.kind == "string" then
            table.insert(result, child.value)
        elseif not child.kind and child.children then
            table.insert(result, _export(child))
        elseif child.kind == "command" then
        else
            error("NYI '" .. child.kind .. "'")
        end
    end
    return table.concat(result)
end

local function export(ast)
    return beautifier(_export(ast))
end

return {parse=parse, export=export}