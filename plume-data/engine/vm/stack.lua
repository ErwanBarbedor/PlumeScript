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

function _STACK_GET(stack, index)
    return stack[index or stack.pointer]
end

function _STACK_GET_OFFSET(stack, offset)
    return stack[stack.pointer + offset]
end

function _STACK_SET(stack, index, value)
    stack[index] = value
end

function _STACK_POS(stack)
    return stack.pointer
end

function _STACK_POP(stack)
    stack.pointer = stack.pointer - 1
    return stack[stack.pointer + 1]
end

function _STACK_PUSH(stack, value)
    stack.pointer = stack.pointer + 1
    stack[stack.pointer] = value
end

function _STACK_MOVE(stack, value)
    stack.pointer = value
end

function _STACK_MOVE_FRAMED(stack)
     _STACK_MOVE(
        stack,
        _STACK_GET(stack.frames)
    )
end

function _STACK_POP_FRAME(stack)
    _STACK_MOVE(stack, _STACK_POP(stack.frames)-1)
end

function _STACK_SET_FRAMED(stack, offset, frameOffset, value)
    _STACK_SET(
        stack,
        _STACK_GET_OFFSET(stack.frames, frameOffset or 0) + (offset or 0),
        value
    )
end

function _STACK_GET_FRAMED(stack, offset, frameOffset)
    return _STACK_GET(
        stack,
        _STACK_GET_OFFSET(stack.frames, frameOffset or 0) + (offset or 0)
    )
end