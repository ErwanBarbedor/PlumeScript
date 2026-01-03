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

function ENTER_SCOPE (vm, arg1, arg2)
    --- Reserve slots for locals variables and save scope begin offset
    --- Stack 1 to frame
    --- Stack 1 empty for each non already allocated variable
    --- arg1: Number of local variables already stacked
    --- arg2: Number of local variables

    _STACK_PUSH(
        vm.variableStack.frames,
        _STACK_GET_POINTER(vm.variableStack.frames) - arg1
    )
    
    for i = 1, arg2-arg1 do
        _STACK_PUSH(vm.variableStack, vm.empty)
    end
end

function LEAVE_SCOPE (vm, arg1, arg2)
    --- Unstack 1 from vsf
    --- Remove all local variables
    --- arg1: -
    --- arg2: -
    _STACK_POP_FRAME(vm.variableStack)
end