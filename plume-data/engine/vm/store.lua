 STORE_LOCAL = function (vm, arg1, arg2)
    --- Unstack 1 to vs
    --- Final offset: current frame + frame offset
    --- arg1: -
    --- arg2: frame offset
    vs[vsf[vsfp] + arg2-1] = ms[msp]
    msp = msp-1
end

STORE_LEXICAL = function (vm, arg1, arg2)
    --- Unstack 1 to vs
    --- Offset: the anth last frame + frame offset
    --- arg1: frame offset
    --- arg2: frame offset
    vs[vsf[vsfp-arg1]+arg2-1] = ms[msp]
    msp = msp-1
end

STORE_STATIC = function (vm, arg1, arg2)
    --- Unstack 1 static memory
    --- memory[mp] is a pointer to the current
    --- file intern memory
    --- arg1: -
    --- arg2: frame offset
    static[arg2] = ms[msp]
    msp = msp-1
end

 STORE_VOID = function (vm, arg1, arg2)
    --- Unstack 1
    --- arg1: -
    --- arg2: frame offset
    msp = msp-1
end