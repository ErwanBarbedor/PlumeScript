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

--- @opcode
--- Stack 1 from the constants table
--- @param arg2 Constant offset
--! inline
function LOAD_CONSTANT (vm, arg1, arg2)
    --- Stack 1 from constant
    --- arg1: -
    --- arg2: constant offset
    _STACK_PUSH(vm.mainStack, vm.constants[arg2])
end

--- @opcode
--- Stack 1 variable value
--- @param arg1 Scope offset
--- @param arg2 Variable offset
--! inline
function LOAD_LOCAL (vm, arg1, arg2)
    _STACK_PUSH(
        vm.mainStack,
        _STACK_GET_FRAMED(vm.variableStack, arg2 - 1, -arg1)
    )
end

--- @opcode
--- Stack 1 from the static table
--- @param arg2 static offset
--! inline
function LOAD_STATIC (vm, arg1, arg2)
    local currentStatic = _GET_STATIC(vm)
    _STACK_PUSH(
        vm.mainStack,
        currentStatic[arg2]
    )
end

--- @opcode
--- Stack 1, `true`
--! inline
function LOAD_TRUE (vm, arg1, arg2)
    _STACK_PUSH(vm.mainStack, true)
end

--- @opcode
--- Stack 1, `false`
--! inline
function LOAD_FALSE (vm, arg1, arg2)
    _STACK_PUSH(vm.mainStack, false)
end

--- @opcode
--- Stack 1, `empty`
--! inline
function LOAD_EMPTY (vm, arg1, arg2)
    _STACK_PUSH(vm.mainStack, vm.empty)
end