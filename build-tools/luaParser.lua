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

local function fallback(state, match)
    state.add({kind="raw", value=match[1]})
end

local patterns = {
    {
        pattern = {"function%s*([a-zA-Z_]+)%s*%((.-)%)"},
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
            state.pop()
        end
    },
    {
        pattern = {"end"},
        action = function (state, match)
            state.pop()
        end
    },
    {
        pattern = {
            "()()([a-zA-Z_][a-zA-Z_]*)%(",
            "()([a-zA-Z_][a-zA-Z_]*)%s*=%s*([a-zA-Z_][a-zA-Z_]*)%(",
            "(local)%s+([a-zA-Z_][a-zA-Z_]*)%s*=%s*([a-zA-Z_][a-zA-Z_]*)%("
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
        pattern = {"[a-zA-Z_][a-zA-Z_]*"},
        action = function (state, match)
            if ("then do"):match(match[1]) then
                state.push({kind="var", name=match[1]})
            else
                state.add({kind="var", name=match[1]})
            end
        end
    },
    {
        pattern = {"[\t]"},
        action = function (state, match)
        end
    },
}



local plume = require "plume-data/engine/init"

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

    -- plume.debug.pprint(state.ast)
    return state.top
end

local function export(ast, indent)
    local result = {}

    for _, child in ipairs(ast.children) do
        if child.kind == "function" then
            table.insert(result, "function " .. child.name .. "(" .. table.concat(child.params, ", ") .. ")")
                table.insert(result, export(child, "\t"))
            table.insert(result, "end")
        
        elseif child.kind == "call" then
            if child.affected then
                if child.isLocal then
                    table.insert(result, "local ")
                end
                table.insert(result, child.affected .. " = ")
            end

            table.insert(result, child.name .. "(")
            table.insert(result,  ")")
        elseif child.kind == "var" then
            table.insert(result, child.name)
    elseif child.kind == "raw" then
            table.insert(result, child.value)
        elseif not child.kind and child.children then
            table.insert(result, export(child))
        else
            error("NYI '" .. child.kind .. "'")
        end
    end
    return table.concat(result)
end

local ast = parse [=[

function JUMP (vm, arg1, arg2)
    --- Jump to offset
    --- arg1: -
    --- arg2: target offset
    vm.jump = arg2
end

function JUMP_IF_NOT (vm, arg1, arg2)
    --- Unstack 1
    --- Jump to offset if false
    --- arg1: -
    --- arg2: target offset
    local test = _STACK_POP(vm.mainStack)
    if not _CHECK_BOOL (vm, test) then
        vm.jump = arg2
    end
end

function JUMP_IF (vm, arg1, arg2)
    --- Unstack 1
    --- Jump to offset if true
    --- arg1: -
    --- arg2: target offset
    local test = _STACK_POP(vm.mainStack)
    if _CHECK_BOOL (vm, test) then
        vm.jump = arg2
    end
end
function JUMP_IF_PEEK (vm, arg1, arg2)
    --- Jump to offset if top is true, without unpacking
    --- arg1: -
    --- arg2: target offset
    local test = _STACK_GET(vm.mainStack)
    if _CHECK_BOOL (vm, test) then
        vm.jump = arg2
    end
end

function JUMP_IF_NOT_PEEK (vm, arg1, arg2)
    --- Jump to offset if top is false, without unpacking
    --- arg1: -
    --- arg2: target offset
    local test = _STACK_GET(vm.mainStack)
    if not _CHECK_BOOL (vm, test) then
        vm.jump = arg2
    end
end

function JUMP_IF_NOT_EMPTY (vm, arg1, arg2)
    --- Unstack 1
    --- Jump to offset if not empty
    --- Used by macro when setting defaut values
    --- arg1: -
    --- arg2: target offset
    local test = _STACK_POP(vm.mainStack)
    if test ~= vm.empty then
        vm.jump = arg2
    end
end
]=]

print(export(ast))

return parse