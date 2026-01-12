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

--! inline
function LOAD_CONSTANT (vm, arg1, arg2)
    --- Stack 1 from constant
    --- arg1: -
    --- arg2: constant offset
    _STACK_PUSH(vm.mainStack, vm.constants[arg2])
end

--! inline
function LOAD_LEXICAL (vm, arg1, arg2)
    --- Stack 1 from vs.
    --- Final offset: the nth last frame + vs offset
    --- arg1: frame offset
    --- arg2: vs offset
    _STACK_PUSH(
        vm.mainStack,
        _STACK_GET_FRAMED(vm.variableStack, arg2 - 1, -arg1)
    )
end

--! inline
function LOAD_LOCAL (vm, arg1, arg2)
    --- Stack 1 from vs.
    --- Final offset: current frame + vs offset
    --- arg1: -
    --- arg2: vs offset
    _STACK_PUSH(
        vm.mainStack,
        _STACK_GET_FRAMED(vm.variableStack, arg2 - 1)
    )
end

--! inline
function LOAD_STATIC (vm, arg1, arg2)
    --- Stack 1 from static memory
    --- memory[mp] is a pointer to the current
    --- file intern memory
    --- arg1: -
    --- arg2: vs offset
    _STACK_PUSH(
        vm.mainStack,
        vm.static[arg2]
    )
end
--! inline

function LOAD_TRUE (vm, arg1, arg2)
    --- Stack 1 constant true
    --- arg1: -
    --- arg2: -
    _STACK_PUSH(vm.mainStack, true)
end

--! inline
function LOAD_FALSE (vm, arg1, arg2)
    --- Stack 1 constant false
    --- arg1: -
    --- arg2: -
    _STACK_PUSH(vm.mainStack, false)
end

--! inline
function LOAD_EMPTY (vm, arg1, arg2)
    --- Stack 1 constant empty
    --- arg1: -
    --- arg2: -
    _STACK_PUSH(vm.mainStack, vm.empty)
end