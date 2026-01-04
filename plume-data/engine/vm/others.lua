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

function SWITCH (vm, arg1, arg2)
    --- Unstack 2, stack 2 in reverse order
    --- arg1: -
    --- arg2: -
    local x = _STACK_POP(vm.mainStack)
    local y = _STACK_POP(vm.mainStack)
    _STACK_PUSH(vm.mainStack, y)
    _STACK_PUSH(vm.mainStack, x)
end

function DUPLICATE (vm, arg1, arg2)
    --- Stack 1, current top
    --- arg1: -
    --- arg2: -
    _STACK_PUSH(vm.mainStack, _STACK_GET(vm.mainStack))
end

function NULL (vm, arg1, arg2)
    --- Do nothing
    --- arg1: -
    --- arg2: -
end