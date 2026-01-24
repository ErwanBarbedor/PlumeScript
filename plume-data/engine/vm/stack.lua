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

---------------------------------------  
--- Utils function to manipulate stack  
---------------------------------------  

--- Retrieves the value at the specified index or the current pointer position.
---@param stack table The stack structure.
---@param index? integer The specific index to read (optional).
---@return any
--! inline  
function _STACK_GET(stack, index)  
	return stack[index or stack.pointer]  
end  

--- Retrieves a value relative to the current stack pointer position.
---@param stack table The stack structure.
---@param offset integer The offset relative to the pointer.
---@return any
--! inline  
function _STACK_GET_OFFSET(stack, offset)  
	return stack[stack.pointer + offset]  
end  

--- Sets a value at a specific index in the stack.
---@param stack table The stack structure.
---@param index integer The destination index.
---@param value any The value to store.
--! inline  
function _STACK_SET(stack, index, value)  
	stack[index] = value  
end  

--- Returns the current position of the stack pointer.
---@param stack table The stack structure.
---@return integer
--! inline  
function _STACK_POS(stack)  
	return stack.pointer  
end  

--- Pop a value from the stack.
---@param stack table The stack structure.
---@return any
--! inline  
function _STACK_POP(stack)  
	stack.pointer = stack.pointer - 1  
	return stack[stack.pointer + 1]  
end  

--- Pushes a value onto the stack.
---@param stack table The stack structure.
---@param value any The value to push.
--! inline  
function _STACK_PUSH(stack, value)  
	stack.pointer = stack.pointer + 1  
	stack[stack.pointer] = value  
end  

--- Manually moves the stack pointer to a specific position.
---@param stack table The stack structure.
---@param value integer The new pointer position.
--! inline  
function _STACK_MOVE(stack, value)  
	stack.pointer = value  
end  

--- Pops the top frame and restores the pointer to the position immediately before it.
---@param stack table The stack structure.
--! inline  
function _STACK_POP_FRAME(stack)  
	_STACK_MOVE(stack, _STACK_POP(stack.frames)-1)  
end  

--- Sets a value relative to a specific stack frame.
---@param stack table The stack structure.
---@param offset? integer Offset relative to the frame base (defaults to 0).
---@param frameOffset? integer Offset to access a parent frame (defaults to 0).
---@param value any The value to store.
--! inline  
function _STACK_SET_FRAMED(stack, offset, frameOffset, value)  
	_STACK_SET(  
		stack,  
		_STACK_GET_OFFSET(stack.frames, frameOffset or 0) + (offset or 0),  
		value  
	)  
end  

--- Retrieves a value relative to a specific stack frame.
---@param stack table The stack structure.
---@param offset? integer Offset relative to the frame base (defaults to 0).
---@param frameOffset? integer Offset to access a parent frame (defaults to 0).
---@return any
--! inline  
function _STACK_GET_FRAMED(stack, offset, frameOffset)  
	return _STACK_GET(  
		stack,  
		_STACK_GET_OFFSET(stack.frames, (frameOffset or 0)) + (offset or 0)  
	)  
end