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

function STORE_LOCAL (vm, arg1, arg2)
    --- Unstack 1 to vs
    --- Final offset: current frame + frame offset
    --- arg1: -
    --- arg2: frame offset

    _STACK_SET_FRAMED(
        vm.variableStack,
        arg2 - 1,
        0,
        _STACK_POP(vm.mainStack)
    )
end

function STORE_STATIC (vm, arg1, arg2)
    --- Unstack 1 static memory
    --- memory[mp] is a pointer to the current
    --- file intern memory
    --- arg1: -
    --- arg2: frame offset
    vm.static[arg2] = _STACK_POP(vm.mainStack)
end

function STORE_LEXICAL (vm, arg1, arg2)
    --- Unstack 1 to vs
    --- Offset: the anth last frame + frame offset
    --- arg1: frame offset
    --- arg2: frame offset
    _STACK_SET_FRAMED(
        vm.variableStack,
        arg2-1,
        -arg1,
        _STACK_POP(vm.mainStack)
    )
end
 function STORE_VOID (vm, arg1, arg2)
    --- Unstack 1
    --- arg1: -
    --- arg2: frame offset
    _STACK_POP(vm.mainStack)
end