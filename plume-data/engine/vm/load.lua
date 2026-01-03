LOAD_CONSTANT = function (vm, arg1, arg2)
    --- Stack 1 from constant
    --- arg1: -
    --- arg2: constant offset
    msp = msp+1
    ms[msp] = constants[arg2]
end

LOAD_EMPTY = function (vm, arg1, arg2)
    --- Stack 1 constant empty
    --- arg1: -
    --- arg2: -
    msp = msp+1
    ms[msp] = empty
end

LOAD_TRUE = function (vm, arg1, arg2)
    --- Stack 1 constant true
    --- arg1: -
    --- arg2: -
    msp = msp+1
    ms[msp] = true
end

LOAD_FALSE = function (vm, arg1, arg2)
    --- Stack 1 constant false
    --- arg1: -
    --- arg2: -
    msp = msp+1
    ms[msp] = false
end


-- Variables
LOAD_LOCAL = function (vm, arg1, arg2)
    --- Stack 1 from vs.
    --- Final offset: current frame + vs offset
    --- arg1: -
    --- arg2: vs offset
    msp = msp+1
    ms[msp] = vs[vsf[vsfp] + arg2-1]
end

LOAD_LEXICAL = function (vm, arg1, arg2)
    --- Stack 1 from vs.
    --- Final offset: the nth last frame + vs offset
    --- arg1: frame offset
    --- arg2: vs offset
    msp = msp+1
    ms[msp] = vs[vsf[vsfp-arg1]+arg2-1]
end

LOAD_STATIC = function (vm, arg1, arg2)
    --- Stack 1 from static memory
    --- memory[mp] is a pointer to the current
    --- file intern memory
    --- arg1: -
    --- arg2: vs offset
    msp = msp+1
    ms[msp] = static[arg2]
end