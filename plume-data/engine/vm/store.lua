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
--- Set a value in the static table
--- Unstack 1, the value to set
--- @param arg2 variable offset
--! inline
function STORE_STATIC (vm, arg1, arg2)
    local currentStatic = _GET_STATIC(vm)
    currentStatic[arg2] = _STACK_POP(vm.mainStack)
end

--- @opcode
--- Set a local value
--- Unstack 1, the value to set
--- @param arg1 frame offset
--- @param arg2 variable offset
--! inline
function STORE_LOCAL (vm, arg1, arg2)
    _STACK_SET_FRAMED(
        vm.variableStack,
        arg2-1,
        -arg1,
        _STACK_POP(vm.mainStack)
    )
end

--- @opcode
--- Unstack 1, do nothing with it.
--- Used to remove a value at stack top.
--! inline
function STORE_VOID (vm, arg1, arg2)
    _STACK_POP(vm.mainStack)
end