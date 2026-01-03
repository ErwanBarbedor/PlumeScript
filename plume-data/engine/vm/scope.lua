ENTER_SCOPE = function (vm, arg1, arg2)
    --- Reserve slots for locals variables and save scope begin offset
    --- Stack 1 to frame
    --- Stack 1 empty for each non already allocated variable
    --- arg1: Number of local variables already stacked
    --- arg2: Number of local variables
    vsfp = vsfp+1
    vsf[vsfp] = vsp+1-arg1

    for i = 1, arg2-arg1 do
        vsp = vsp+1
        vs[vsp] = empty
    end
end

LEAVE_SCOPE = function (vm, arg1, arg2)
    --- Unstack 1 from vsf
    --- Remove all local variables
    --- arg1: -
    --- arg2: -
    vsp = vsf[vsfp]-1
    vsfp = vsfp-1
end