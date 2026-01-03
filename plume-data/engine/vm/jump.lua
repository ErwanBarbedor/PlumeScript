JUMP = function (vm, arg1, arg2)
    --- Jump to offset
    --- arg1: -
    --- arg2: target offset
    jump = arg2
end
JUMP_IF = function (vm, arg1, arg2)
    --- Unstack 1
    --- Jump to offset if true
    --- arg1: -
    --- arg2: target offset
    local test = ms[msp]
    _CHECK_BOOL test
    if test then
        jump = arg2
    end
    msp = msp-1
end
JUMP_IF_PEEK = function (vm, arg1, arg2)
    --- Jump to offset if top is true, without unpacking
    --- arg1: -
    --- arg2: target offset
    local test = ms[msp]
    _CHECK_BOOL test
    if test then
        jump = arg2
    end
end
JUMP_IF_NOT = function (vm, arg1, arg2)
    --- Unstack 1
    --- Jump to offset if false
    --- arg1: -
    --- arg2: target offset
    local test = ms[msp]
    _CHECK_BOOL test
    if not test then
        jump = arg2
    end
    msp = msp-1
end
JUMP_IF_NOT_PEEK = function (vm, arg1, arg2)
    --- Unstack 1
    --- Jump to offset if top is false, without unpacking
    --- arg1: -
    --- arg2: target offset
    local test = ms[msp]
    _CHECK_BOOL test
    if not test then
        jump = arg2
    end
end
JUMP_IF_NOT_EMPTY = function (vm, arg1, arg2)
    --- Unstack 1
    --- Jump to offset if not empty
    --- Used by macro when setting defaut values
    --- arg1: -
    --- arg2: target offset
    if ms[msp] ~= empty then
        jump = arg2
    end
    msp = msp-1
end