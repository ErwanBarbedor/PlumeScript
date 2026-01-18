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
--- Switch two top stack values
--! inline
function SWITCH (vm, arg1, arg2)
    local x = _STACK_POP(vm.mainStack)
    local y = _STACK_POP(vm.mainStack)
    _STACK_PUSH(vm.mainStack, x)
    _STACK_PUSH(vm.mainStack, y)
    
end

--- @opcode
--- Stack 1 more top stack value
--! inline
function DUPLICATE (vm, arg1, arg2)
    _STACK_PUSH(vm.mainStack, _STACK_GET(vm.mainStack))
end