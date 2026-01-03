function _STACK_GET(stack, index)
    return stack[index or stack.pointer]
end

function _STACK_SET(stack, index, value)
    stack[index] = value
end

function _STACK_POP(stack)
    stack.pointer = stack.pointer - 1
    return stack[stack.pointer + 1]
end

function _STACK_PUSH(stack, value)
    stack.pointer = stack.pointer + 1
    stack[stack.pointer] = value
end

function _STACK_MOVE(stack, ivalue)
    stack.pointer = value
end

function _STACK_GET_POINTER(stack)
    return stack.pointer
end

function _STACK_POP_FRAME(stack)
    _STACK_SET(stack, _STACK_POP(stack.frames)-1)
end