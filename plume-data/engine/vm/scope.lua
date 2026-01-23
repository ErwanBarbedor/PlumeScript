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
--- Create a new frame and set all it's variable to empty
--- @param arg1 number Number of local variables already stacked
--- @param arg2 number Number of local variables
--! inline
function ENTER_SCOPE (vm, arg1, arg2)
    _STACK_PUSH(
        vm.variableStack.frames,
        _STACK_POS(vm.variableStack) + 1 - arg1
    )
    
    for i = 1, arg2-arg1 do
        _STACK_PUSH(vm.variableStack, vm.empty)
    end
end

--- @opcode
--- Close a frame
--! inline
function LEAVE_SCOPE (vm, arg1, arg2)
    _STACK_POP_FRAME(vm.variableStack)
end

--- @opcode
--! inline
function RETURN_FILE(vm, arg1, arg2)
    LEAVE_SCOPE(vm)
    _STACK_POP(vm.fileStack)

    if _STACK_POS(vm.fileStack) == 0 then
        _INJECTION_PUSH(vm, vm.plume.ops.END, 0, 0) -- last file, end the program
    else
        JUMP(vm, 0, _STACK_POP(vm.macroStack)) -- return in the previous position
    end
end