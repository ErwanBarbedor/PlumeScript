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

--- Get the last instruction from the injectionStack
--- @return number, number, number
--! inline
function _INJECTION_POP(vm)
	local arg2 = _STACK_POP(vm.injectionStack)
	local arg1 = _STACK_POP(vm.injectionStack)
	local op   = _STACK_POP(vm.injectionStack)
	return op, arg1, arg2
end

--- Add an instruction at the injectionStack end
--- @param op number
--- @param arg1 number
--- @param arg2 number
--- @return nil
--! inline
function _INJECTION_PUSH(vm, op, arg1, arg2)
	_STACK_PUSH(vm.injectionStack, op)
	_STACK_PUSH(vm.injectionStack, arg1)
	_STACK_PUSH(vm.injectionStack, arg2)
end