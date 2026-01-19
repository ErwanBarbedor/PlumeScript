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
--! inline
function STD_LEN(vm, arg1, arg2)
	local t = _STACK_POP(vm.mainStack).table[1]
	local tt = type(t)
    local result
	if tt == "table" then
        result = #t.table
    elseif tt == "string" then
        result = #t
    else
        _ERROR(vm, vm.plume.error.hasNoLen(tt))
    end
    _STACK_PUSH(vm.mainStack, result)
end

--- @opcode
--! inline
function STD_TYPE(vm, arg1, arg2)
    local t = _STACK_POP(vm.mainStack).table[1]
    _STACK_PUSH(vm.mainStack, _GET_TYPE(vm, t))
end