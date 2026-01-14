return function (plume)
    function plume._run (chunk, arguments)
        do
        end
        do
        end
        do
        end
        do
        end
        do
        end
        do
        end
        do
        end
        do
        end
        do
        end
        do
        end
        do
            function _STACK_GET_OFFSET (stack, offset)
                return stack[stack.pointer + offset]
            end
        end
        do
        end
        do
        end
        do
        end
        local _ret1
        do
            require ("table.new")
            local vm = {}
            vm.plume = plume
            do
                vm.chunk = chunk
                vm.bytecode = chunk.bytecode
                vm.constants = chunk.constants
                vm.static = chunk.static
                vm.ip = 0
                vm.tic = 0
                vm.mainStack = table.new (2 ^ 14, 0)
                vm.mainStack.frames = table.new (2 ^ 8, 0)
                vm.mainStack.pointer = 0
                vm.mainStack.frames.pointer = 0
                vm.variableStack = table.new (2 ^ 10, 0)
                vm.variableStack.frames = table.new (2 ^ 8, 0)
                vm.variableStack.pointer = 0
                vm.variableStack.frames.pointer = 0
                vm.jump = 0
                vm.empty = vm.plume.obj.empty
            end
            do
                if arguments then
                    if chunk.isFile then
                        for k, v in pairs (arguments)
                         do
                            local offset = chunk.namedParamOffset[k]
                            if offset then
                                chunk.static[offset] = v
                            end
                        end
                    else
                        for i = 1, chunk.localsCount do
                            if arguments[i] == nil then
                                do
                                    vm.variableStack[i] = vm.empty
                                end
                            else
                                do
                                    vm.variableStack[i] = arguments[i]
                                end
                            end
                        end
                        do
                            vm.variableStack.pointer = chunk.localsCount
                        end
                        do
                            vm.variableStack.frames.pointer = vm.variableStack.frames.pointer + 1
                            vm.variableStack.frames[vm.variableStack.frames.pointer] = 1
                        end
                    end
                end
            end
            _ret1 = vm
            goto _inline_end1
        end
        ::_inline_end1::
        local vm = _ret1
        local op, arg1, arg2
        ::DISPATCH::
            if vm.err then
                return false, vm.err, vm.ip, vm.chunk
            end
            if vm.serr then
                return false, unpack (vm.serr)
            end
            do
                if vm.jump > 0 then
                    vm.ip = vm.jump
                    vm.jump = 0
                else
                    vm.ip = vm.ip + 1
                end
                vm.tic = vm.tic + 1
            end
            local _ret2, _ret3, _ret4
            do
                local bit = require ("bit")
                local OP_BITS = 7
                local ARG1_BITS = 5
                local ARG2_BITS = 20
                local ARG1_SHIFT = ARG2_BITS
                local OP_SHIFT = ARG1_BITS + ARG2_BITS
                local MASK_OP = bit.lshift (1, OP_BITS) - 1
                local MASK_ARG1 = bit.lshift (1, ARG1_BITS) - 1
                local MASK_ARG2 = bit.lshift (1, ARG2_BITS) - 1
                local instr, op, arg1, arg2
                instr = vm.bytecode[vm.ip]
                op = bit.band (bit.rshift (instr, OP_SHIFT)
                , MASK_OP)
                arg1 = bit.band (bit.rshift (instr, ARG1_SHIFT)
                , MASK_ARG1)
                arg2 = bit.band (instr, MASK_ARG2)
                _ret2, _ret3, _ret4 = op, arg1, arg2
                goto _inline_end9
            end
            ::_inline_end9::
            op, arg1, arg2 = _ret2, _ret3, _ret4
            if op == 1 then goto LOAD_CONSTANT
            elseif op == 2 then goto LOAD_TRUE
            elseif op == 3 then goto LOAD_FALSE
            elseif op == 4 then goto LOAD_EMPTY
            elseif op == 5 then goto LOAD_LOCAL
            elseif op == 6 then goto LOAD_LEXICAL
            elseif op == 7 then goto LOAD_STATIC
            elseif op == 8 then goto STORE_LOCAL
            elseif op == 9 then goto STORE_LEXICAL
            elseif op == 10 then goto STORE_STATIC
            elseif op == 11 then goto STORE_VOID
            elseif op == 12 then goto TABLE_NEW
            elseif op == 13 then goto TABLE_ADD
            elseif op == 14 then goto TABLE_SET
            elseif op == 15 then goto TABLE_INDEX
            elseif op == 16 then goto TABLE_INDEX_ACC_SELF
            elseif op == 17 then goto TABLE_SET_META
            elseif op == 18 then goto TABLE_INDEX_META
            elseif op == 19 then goto TABLE_SET_ACC
            elseif op == 20 then goto TABLE_SET_ACC_META
            elseif op == 21 then goto TABLE_EXPAND
            elseif op == 22 then goto ENTER_SCOPE
            elseif op == 23 then goto LEAVE_SCOPE
            elseif op == 24 then goto BEGIN_ACC
            elseif op == 25 then goto ACC_TABLE
            elseif op == 26 then goto ACC_TEXT
            elseif op == 27 then goto ACC_EMPTY
            elseif op == 28 then goto ACC_CALL
            elseif op == 29 then goto ACC_CHECK_TEXT
            elseif op == 30 then goto JUMP_IF
            elseif op == 31 then goto JUMP_IF_NOT
            elseif op == 32 then goto JUMP_IF_NOT_EMPTY
            elseif op == 33 then goto JUMP
            elseif op == 34 then goto JUMP_IF_PEEK
            elseif op == 35 then goto JUMP_IF_NOT_PEEK
            elseif op == 36 then goto GET_ITER
            elseif op == 37 then goto FOR_ITER
            elseif op == 38 then goto OPP_ADD
            elseif op == 39 then goto OPP_MUL
            elseif op == 40 then goto OPP_SUB
            elseif op == 41 then goto OPP_DIV
            elseif op == 42 then goto OPP_NEG
            elseif op == 43 then goto OPP_MOD
            elseif op == 44 then goto OPP_POW
            elseif op == 45 then goto OPP_LT
            elseif op == 46 then goto OPP_EQ
            elseif op == 47 then goto OPP_AND
            elseif op == 48 then goto OPP_NOT
            elseif op == 49 then goto OPP_OR
            elseif op == 50 then goto DUPLICATE
            elseif op == 51 then goto SWITCH
            elseif op == 52 then goto END
            end
            ::LOAD_CONSTANT::
                do
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                        vm.mainStack[vm.mainStack.pointer] = vm.constants[arg2]
                    end
                end
                goto DISPATCH
            ::LOAD_TRUE::
                do
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                        vm.mainStack[vm.mainStack.pointer] = true
                    end
                end
                goto DISPATCH
            ::LOAD_FALSE::
                do
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                        vm.mainStack[vm.mainStack.pointer] = false
                    end
                end
                goto DISPATCH
            ::LOAD_EMPTY::
                do
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                        vm.mainStack[vm.mainStack.pointer] = vm.empty
                    end
                end
                goto DISPATCH
            ::LOAD_LOCAL::
                do
                    local _ret5
                    do
                        local _ret6
                        do
                            _ret6 = vm.variableStack[_STACK_GET_OFFSET (vm.variableStack.frames, nil or 0) + (arg2 - 1 or 0) or vm.variableStack.pointer]
                            goto _inline_end20
                        end
                        ::_inline_end20::
                        _ret5 = _ret6
                        goto _inline_end19
                    end
                    ::_inline_end19::
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                        vm.mainStack[vm.mainStack.pointer] = _ret5
                    end
                end
                goto DISPATCH
            ::LOAD_LEXICAL::
                do
                    local _ret7
                    do
                        local _ret8
                        do
                            _ret8 = vm.variableStack[_STACK_GET_OFFSET (vm.variableStack.frames, -arg1 or 0) + (arg2 - 1 or 0) or vm.variableStack.pointer]
                            goto _inline_end24
                        end
                        ::_inline_end24::
                        _ret7 = _ret8
                        goto _inline_end23
                    end
                    ::_inline_end23::
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                        vm.mainStack[vm.mainStack.pointer] = _ret7
                    end
                end
                goto DISPATCH
            ::LOAD_STATIC::
                do
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                        vm.mainStack[vm.mainStack.pointer] = vm.static[arg2]
                    end
                end
                goto DISPATCH
            ::STORE_LOCAL::
                do
                    local _ret9
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret9 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end29
                    end
                    ::_inline_end29::
                    do
                        do
                            vm.variableStack[_STACK_GET_OFFSET (vm.variableStack.frames, 0 or 0) + (arg2 - 1 or 0)] = _ret9
                        end
                    end
                end
                goto DISPATCH
            ::STORE_LEXICAL::
                do
                    local _ret10
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret10 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end33
                    end
                    ::_inline_end33::
                    do
                        do
                            vm.variableStack[_STACK_GET_OFFSET (vm.variableStack.frames, -arg1 or 0) + (arg2 - 1 or 0)] = _ret10
                        end
                    end
                end
                goto DISPATCH
            ::STORE_STATIC::
                do
                    local _ret11
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret11 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end37
                    end
                    ::_inline_end37::
                    vm.static[arg2] = _ret11
                end
                goto DISPATCH
            ::STORE_VOID::
                do
                    local _ret12
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret12 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end39
                    end
                    ::_inline_end39::
                end
                goto DISPATCH
            ::TABLE_NEW::
                do
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                        vm.mainStack[vm.mainStack.pointer] = table.new (0, arg1)
                    end
                end
                goto DISPATCH
            ::TABLE_ADD::
                TABLE_ADD (vm, arg1, arg2)
                goto DISPATCH
            ::TABLE_SET::
                do
                    local _ret13
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret13 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end43
                    end
                    ::_inline_end43::
                    local t = _ret13
                    local _ret14
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret14 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end44
                    end
                    ::_inline_end44::
                    local key = _ret14
                    local _ret15
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret15 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end45
                    end
                    ::_inline_end45::
                    local value = _ret15
                    if not t.table[key] then
                        table.insert (t.keys, key)
                        if t.meta.table.setindex then
                            local meta = t.meta.table.setindex
                            local args = {key, value}
                            local _ret16
                            do
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, args)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret16 = callResult
                                        goto _inline_end46
                                    else
                                        do
                                            vm.serr = {callResult, cip, (source or meta)}
                                        end
                                    end
                                else
                                    do
                                        vm.err = "stack overflow"
                                    end
                                end
                            end
                            ::_inline_end46::
                            value = _ret16
                        end
                    end
                    key = tonumber (key) or key
                    t.table[key] = value
                end
                goto DISPATCH
            ::TABLE_INDEX::
                do
                    local _ret17
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret17 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end50
                    end
                    ::_inline_end50::
                    local t = _ret17
                    local _ret18
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret18 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end51
                    end
                    ::_inline_end51::
                    local key = _ret18
                    key = tonumber (key) or key
                    if key == vm.empty then
                        if arg1 == 1 then
                            do
                                do
                                    vm.mainStack.pointer = vm.mainStack.pointer + 1
                                    vm.mainStack[vm.mainStack.pointer] = vm.empty
                                end
                            end
                        else
                            do
                                vm.err = "Cannot use empty as key."
                            end
                        end
                    else
                        local _ret20
                        do
                            _ret20 = type (t) == "table" and (t == vm.empty or t.type) or type (t)
                            goto _inline_end67
                        end
                        ::_inline_end67::
                        local tt = _ret20
                        if tt ~= "table" then
                            if arg1 == 1 then
                                do
                                    do
                                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                                        vm.mainStack[vm.mainStack.pointer] = vm.empty
                                    end
                                end
                            else
                                do
                                    vm.err = "Try to index a '" .. tt .. "' value."
                                end
                            end
                        else
                            local value = t.table[key]
                            if value then
                                do
                                    vm.mainStack.pointer = vm.mainStack.pointer + 1
                                    vm.mainStack[vm.mainStack.pointer] = value
                                end
                            else
                                if arg1 == 1 then
                                    do
                                        do
                                            vm.mainStack.pointer = vm.mainStack.pointer + 1
                                            vm.mainStack[vm.mainStack.pointer] = vm.empty
                                        end
                                    end
                                elseif t.meta.table.getindex then
                                    local meta = t.meta.table.getindex
                                    local args = {key}
                                    local _ret19
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, args)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret19 = callResult
                                                goto _inline_end61
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end61::
                                    do
                                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                                        vm.mainStack[vm.mainStack.pointer] = _ret19
                                    end
                                else
                                    if tonumber (key)
                                     then
                                        do
                                            vm.err = "Invalid index '" .. key .. "'."
                                        end
                                    else
                                        do
                                            vm.err = "Unregistered key '" .. key .. "'."
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                goto DISPATCH
            ::TABLE_INDEX_ACC_SELF::
                do
                    local _ret21
                    do
                        local _ret22
                        do
                            _ret22 = vm.mainStack[_STACK_GET_OFFSET (vm.mainStack.frames, nil or 0) + (nil or 0) or vm.mainStack.pointer]
                            goto _inline_end70
                        end
                        ::_inline_end70::
                        _ret21 = _ret22
                        goto _inline_end69
                    end
                    ::_inline_end69::
                    local t = _ret21
                    table.insert (t, "self")
                    local _ret23
                    do
                        _ret23 = vm.mainStack[nil or vm.mainStack.pointer]
                        goto _inline_end71
                    end
                    ::_inline_end71::
                    table.insert (t, _ret23)
                    table.insert (t, false)
                    do
                        local _ret24
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret24 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end73
                        end
                        ::_inline_end73::
                        local t = _ret24
                        local _ret25
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret25 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end74
                        end
                        ::_inline_end74::
                        local key = _ret25
                        key = tonumber (key) or key
                        if key == vm.empty then
                            if 0 == 1 then
                                do
                                    do
                                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                                        vm.mainStack[vm.mainStack.pointer] = vm.empty
                                    end
                                end
                            else
                                do
                                    vm.err = "Cannot use empty as key."
                                end
                            end
                        else
                            local _ret27
                            do
                                _ret27 = type (t) == "table" and (t == vm.empty or t.type) or type (t)
                                goto _inline_end90
                            end
                            ::_inline_end90::
                            local tt = _ret27
                            if tt ~= "table" then
                                if 0 == 1 then
                                    do
                                        do
                                            vm.mainStack.pointer = vm.mainStack.pointer + 1
                                            vm.mainStack[vm.mainStack.pointer] = vm.empty
                                        end
                                    end
                                else
                                    do
                                        vm.err = "Try to index a '" .. tt .. "' value."
                                    end
                                end
                            else
                                local value = t.table[key]
                                if value then
                                    do
                                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                                        vm.mainStack[vm.mainStack.pointer] = value
                                    end
                                else
                                    if 0 == 1 then
                                        do
                                            do
                                                vm.mainStack.pointer = vm.mainStack.pointer + 1
                                                vm.mainStack[vm.mainStack.pointer] = vm.empty
                                            end
                                        end
                                    elseif t.meta.table.getindex then
                                        local meta = t.meta.table.getindex
                                        local args = {key}
                                        local _ret26
                                        do
                                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                            if #vm.chunk.callstack <= 1000 then
                                                local success, callResult, cip, source = vm.plume.run (meta, args)
                                                if success then
                                                    table.remove (vm.chunk.callstack)
                                                    _ret26 = callResult
                                                    goto _inline_end84
                                                else
                                                    do
                                                        vm.serr = {callResult, cip, (source or meta)}
                                                    end
                                                end
                                            else
                                                do
                                                    vm.err = "stack overflow"
                                                end
                                            end
                                        end
                                        ::_inline_end84::
                                        do
                                            vm.mainStack.pointer = vm.mainStack.pointer + 1
                                            vm.mainStack[vm.mainStack.pointer] = _ret26
                                        end
                                    else
                                        if tonumber (key)
                                         then
                                            do
                                                vm.err = "Invalid index '" .. key .. "'."
                                            end
                                        else
                                            do
                                                vm.err = "Unregistered key '" .. key .. "'."
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                goto DISPATCH
            ::TABLE_SET_META::
                do
                    local _ret28
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret28 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end92
                    end
                    ::_inline_end92::
                    local t = _ret28
                    local _ret29
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret29 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end93
                    end
                    ::_inline_end93::
                    local key = _ret29
                    local _ret30
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret30 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end94
                    end
                    ::_inline_end94::
                    local value = _ret30
                    t.meta.table[key] = value
                end
                goto DISPATCH
            ::TABLE_INDEX_META::
                TABLE_INDEX_META (vm, arg1, arg2)
                goto DISPATCH
            ::TABLE_SET_ACC::
                do
                    local _ret31
                    do
                        local _ret32
                        do
                            _ret32 = vm.mainStack[_STACK_GET_OFFSET (vm.mainStack.frames, nil or 0) + (nil or 0) or vm.mainStack.pointer]
                            goto _inline_end97
                        end
                        ::_inline_end97::
                        _ret31 = _ret32
                        goto _inline_end96
                    end
                    ::_inline_end96::
                    local t = _ret31
                    local _ret33
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret33 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end98
                    end
                    ::_inline_end98::
                    table.insert (t, _ret33)
                    local _ret34
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret34 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end99
                    end
                    ::_inline_end99::
                    table.insert (t, _ret34)
                    table.insert (t, arg2 == 1)
                end
                goto DISPATCH
            ::TABLE_SET_ACC_META::
                TABLE_SET_ACC_META (vm, arg1, arg2)
                goto DISPATCH
            ::TABLE_EXPAND::
                do
                    local _ret35
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret35 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end101
                    end
                    ::_inline_end101::
                    local t = _ret35
                    local _ret36
                    do
                        _ret36 = type (t) == "table" and (t == vm.empty or t.type) or type (t)
                        goto _inline_end102
                    end
                    ::_inline_end102::
                    local tt = _ret36
                    if tt == "table" then
                        for _, item in ipairs (t.table)
                         do
                            do
                                vm.mainStack.pointer = vm.mainStack.pointer + 1
                                vm.mainStack[vm.mainStack.pointer] = item
                            end
                        end
                        local _ret37
                        do
                            local _ret38
                            do
                                _ret38 = vm.mainStack[_STACK_GET_OFFSET (vm.mainStack.frames, nil or 0) + (nil or 0) or vm.mainStack.pointer]
                                goto _inline_end105
                            end
                            ::_inline_end105::
                            _ret37 = _ret38
                            goto _inline_end104
                        end
                        ::_inline_end104::
                        local ft = _ret37
                        for _, key in ipairs (t.keys)
                         do
                            table.insert (ft, key)
                            table.insert (ft, t.table[key])
                            table.insert (ft, false)
                        end
                    else
                        do
                            vm.err = "Try to expand a '" .. tt .. "' value."
                        end
                    end
                end
                goto DISPATCH
            ::ENTER_SCOPE::
                do
                    local _ret39
                    do
                        _ret39 = vm.variableStack.pointer
                        goto _inline_end108
                    end
                    ::_inline_end108::
                    do
                        vm.variableStack.frames.pointer = vm.variableStack.frames.pointer + 1
                        vm.variableStack.frames[vm.variableStack.frames.pointer] = _ret39 + 1 - arg1
                    end
                    for i = 1, arg2 - arg1 do
                        do
                            vm.variableStack.pointer = vm.variableStack.pointer + 1
                            vm.variableStack[vm.variableStack.pointer] = vm.empty
                        end
                    end
                end
                goto DISPATCH
            ::LEAVE_SCOPE::
                do
                    do
                        local _ret40
                        do
                            vm.variableStack.frames.pointer = vm.variableStack.frames.pointer - 1
                            _ret40 = vm.variableStack.frames[vm.variableStack.frames.pointer + 1]
                            goto _inline_end113
                        end
                        ::_inline_end113::
                        do
                            vm.variableStack.pointer = _ret40 - 1
                        end
                    end
                end
                goto DISPATCH
            ::BEGIN_ACC::
                do
                    do
                        vm.mainStack.frames.pointer = vm.mainStack.frames.pointer + 1
                        vm.mainStack.frames[vm.mainStack.frames.pointer] = vm.mainStack.pointer + 1
                    end
                end
                goto DISPATCH
            ::ACC_TABLE::
                do
                    local _ret41
                    do
                        _ret41 = vm.mainStack.frames[nil or vm.mainStack.frames.pointer]
                        goto _inline_end118
                    end
                    ::_inline_end118::
                    local limit = _ret41 + 1
                    local _ret42
                    do
                        _ret42 = vm.mainStack.pointer
                        goto _inline_end119
                    end
                    ::_inline_end119::
                    local current = _ret42
                    local _ret43
                    do
                        _ret43 = vm.mainStack[limit - 1 or vm.mainStack.pointer]
                        goto _inline_end120
                    end
                    ::_inline_end120::
                    local t = _ret43
                    local keyCount = #t / 2
                    local args = vm.plume.obj.table (current - limit + 1, keyCount)
                    for i = 1, current - limit + 1 do
                        local _ret44
                        do
                            _ret44 = vm.mainStack[limit + i - 1 or vm.mainStack.pointer]
                            goto _inline_end121
                        end
                        ::_inline_end121::
                        args.table[i] = _ret44
                    end
                    for i = 1, #t, 3 do
                        if t[i + 2] then
                            do
                                local _ret45, _ret46
                                do
                                    local comopps = "add mul div sub mod pow"
                                    local binopps = "eq lt"
                                    local unopps = "minus"
                                    local expectedParamCount
                                    for opp in comopps:gmatch ("%S+")
                                     do
                                        if t[i] == opp then
                                            expectedParamCount = 2
                                        elseif t[i]:match ("^" .. opp .. "[rl]")
                                             then
                                            expectedParamCount = 1
                                        end
                                    end
                                    for opp in binopps:gmatch ("%S+")
                                     do
                                        if t[i] == opp then
                                            expectedParamCount = 1
                                        end
                                    end
                                    for opp in unopps:gmatch ("%S+")
                                     do
                                        if t[i] == opp then
                                            expectedParamCount = 0
                                        end
                                    end
                                    if expectedParamCount then
                                        if t[i + 1].positionalParamCount ~= expectedParamCount then
                                            _ret45, _ret46 = false, "Wrong number of positionnal parameters for meta-macro '" .. t[i] .. "', " .. t[i + 1].positionalParamCount .. " instead of " .. expectedParamCount .. "."
                                            goto _inline_end123
                                        end
                                        if t[i + 1].namedParamCount > 1 then
                                            _ret45, _ret46 = false, "Meta-macro '" .. t[i] .. "' dont support named parameters."
                                            goto _inline_end123
                                        end
                                    elseif t[i] ~= "call" and t[i] ~= "tostring" and t[i] ~= "tonumber" and t[i] ~= "getindex" and t[i] ~= "setindex" and t[i] ~= "next" and t[i] ~= "iter" then
                                        _ret45, _ret46 = false, "'" .. t[i] .. "' isn't a valid meta-macro name."
                                        goto _inline_end123
                                    end
                                    _ret45, _ret46 = true
                                    goto _inline_end123
                                end
                                ::_inline_end123::
                                local success, err = _ret45, _ret46
                                if success then
                                    args.meta.table[t[i]] = t[i + 1]
                                else
                                    do
                                        vm.err = err
                                    end
                                end
                            end
                        else
                            do
                                local key = t[i]
                                local value = t[i + 1]
                                key = tonumber (key) or key
                                if not args.table[key] then
                                    table.insert (args.keys, t[i])
                                end
                                args.table[key] = value
                            end
                        end
                    end
                    do
                        vm.mainStack.pointer = limit - 2
                    end
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                        vm.mainStack[vm.mainStack.pointer] = args
                    end
                    do
                        local _ret47
                        do
                            vm.mainStack.frames.pointer = vm.mainStack.frames.pointer - 1
                            _ret47 = vm.mainStack.frames[vm.mainStack.frames.pointer + 1]
                            goto _inline_end129
                        end
                        ::_inline_end129::
                    end
                end
                goto DISPATCH
            ::ACC_TEXT::
                do
                    local _ret48
                    do
                        _ret48 = vm.mainStack.frames[nil or vm.mainStack.frames.pointer]
                        goto _inline_end131
                    end
                    ::_inline_end131::
                    local start = _ret48
                    local _ret49
                    do
                        _ret49 = vm.mainStack.pointer
                        goto _inline_end132
                    end
                    ::_inline_end132::
                    local stop = _ret49
                    for i = start, stop do
                        local _ret50
                        do
                            _ret50 = vm.mainStack[i or vm.mainStack.pointer]
                            goto _inline_end134
                        end
                        ::_inline_end134::
                        if _ret50 == vm.empty then
                            do
                                vm.mainStack[i] = ""
                            end
                        end
                    end
                    local acc_text = table.concat (vm.mainStack, "", start, stop)
                    do
                        vm.mainStack.pointer = start
                    end
                    do
                        vm.mainStack[start] = acc_text
                    end
                    do
                        local _ret51
                        do
                            vm.mainStack.frames.pointer = vm.mainStack.frames.pointer - 1
                            _ret51 = vm.mainStack.frames[vm.mainStack.frames.pointer + 1]
                            goto _inline_end138
                        end
                        ::_inline_end138::
                    end
                end
                goto DISPATCH
            ::ACC_EMPTY::
                do
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                        vm.mainStack[vm.mainStack.pointer] = vm.empty
                    end
                    do
                        local _ret52
                        do
                            vm.mainStack.frames.pointer = vm.mainStack.frames.pointer - 1
                            _ret52 = vm.mainStack.frames[vm.mainStack.frames.pointer + 1]
                            goto _inline_end142
                        end
                        ::_inline_end142::
                    end
                end
                goto DISPATCH
            ::ACC_CALL::
                do
                    local _ret53
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret53 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end144
                    end
                    ::_inline_end144::
                    local tocall = _ret53
                    local _ret54
                    do
                        _ret54 = type (tocall) == "table" and (tocall == vm.empty or tocall.type) or type (tocall)
                        goto _inline_end145
                    end
                    ::_inline_end145::
                    local t = _ret54
                    local self
                    if t == "table" then
                        if tocall.meta and tocall.meta.table.call then
                            self = tocall
                            tocall = tocall.meta.table.call
                            t = tocall.type
                        end
                    end
                    if t == "macro" then
                        local capture = vm.plume.obj.table (0, 0)
                        local arguments = {}
                        do
                            local _ret55
                            do
                                _ret55 = vm.mainStack.pointer
                                goto _inline_end147
                            end
                            ::_inline_end147::
                            local _ret56
                            do
                                _ret56 = vm.mainStack.frames[nil or vm.mainStack.frames.pointer]
                                goto _inline_end148
                            end
                            ::_inline_end148::
                            local argcount = _ret55 - _ret56
                            if argcount ~= tocall.positionalParamCount and tocall.variadicOffset == 0 then
                                local name
                                if vm.chunk.mapping[vm.ip - 1] then
                                    name = vm.chunk.mapping[vm.ip - 1].content
                                end
                                if not name then
                                    name = tocall.name or "???"
                                end
                                do
                                    vm.err = "Wrong number of positionnal arguments for macro '" .. name .. "', " .. argcount .. " instead of " .. tocall.positionalParamCount .. "."
                                end
                            end
                            for i = 1, tocall.positionalParamCount do
                                arguments[i] = _STACK_GET_OFFSET (vm.mainStack, i - argcount)
                            end
                            for i = tocall.positionalParamCount + 1, argcount do
                                table.insert (capture.table, _STACK_GET_OFFSET (vm.mainStack, i - argcount))
                            end
                            do
                                local _ret57
                                do
                                    _ret57 = vm.mainStack.frames[nil or vm.mainStack.frames.pointer]
                                    goto _inline_end151
                                end
                                ::_inline_end151::
                                do
                                    vm.mainStack.pointer = _ret57
                                end
                            end
                        end
                        do
                            local _ret58
                            do
                                local _ret59
                                do
                                    _ret59 = vm.mainStack[_STACK_GET_OFFSET (vm.mainStack.frames, nil or 0) + (nil or 0) or vm.mainStack.pointer]
                                    goto _inline_end155
                                end
                                ::_inline_end155::
                                _ret58 = _ret59
                                goto _inline_end154
                            end
                            ::_inline_end154::
                            local stack_bottom = _ret58
                            local err
                            for i = 1, #stack_bottom, 3 do
                                local k = stack_bottom[i]
                                local v = stack_bottom[i + 1]
                                local m = stack_bottom[i + 2]
                                local j = tocall.namedParamOffset[k]
                                if m then
                                    do
                                        local _ret60, _ret61
                                        do
                                            local comopps = "add mul div sub mod pow"
                                            local binopps = "eq lt"
                                            local unopps = "minus"
                                            local expectedParamCount
                                            for opp in comopps:gmatch ("%S+")
                                             do
                                                if k == opp then
                                                    expectedParamCount = 2
                                                elseif k:match ("^" .. opp .. "[rl]")
                                                     then
                                                    expectedParamCount = 1
                                                end
                                            end
                                            for opp in binopps:gmatch ("%S+")
                                             do
                                                if k == opp then
                                                    expectedParamCount = 1
                                                end
                                            end
                                            for opp in unopps:gmatch ("%S+")
                                             do
                                                if k == opp then
                                                    expectedParamCount = 0
                                                end
                                            end
                                            if expectedParamCount then
                                                if v.positionalParamCount ~= expectedParamCount then
                                                    _ret60, _ret61 = false, "Wrong number of positionnal parameters for meta-macro '" .. k .. "', " .. v.positionalParamCount .. " instead of " .. expectedParamCount .. "."
                                                    goto _inline_end157
                                                end
                                                if v.namedParamCount > 1 then
                                                    _ret60, _ret61 = false, "Meta-macro '" .. k .. "' dont support named parameters."
                                                    goto _inline_end157
                                                end
                                            elseif k ~= "call" and k ~= "tostring" and k ~= "tonumber" and k ~= "getindex" and k ~= "setindex" and k ~= "next" and k ~= "iter" then
                                                _ret60, _ret61 = false, "'" .. k .. "' isn't a valid meta-macro name."
                                                goto _inline_end157
                                            end
                                            _ret60, _ret61 = true
                                            goto _inline_end157
                                        end
                                        ::_inline_end157::
                                        local success, err = _ret60, _ret61
                                        if success then
                                            capture.meta.table[k] = v
                                        else
                                            do
                                                vm.err = err
                                            end
                                        end
                                    end
                                elseif j then
                                    arguments[j] = v
                                elseif tocall.variadicOffset > 0 then
                                    do
                                        local key = k
                                        local value = v
                                        key = tonumber (key) or key
                                        if not capture.table[key] then
                                            table.insert (capture.keys, k)
                                        end
                                        capture.table[key] = value
                                    end
                                else
                                    local name = tocall.name or "???"
                                    err = "Unknow named parameter '" .. k .. "' for macro '" .. name .. "'."
                                end
                            end
                            if err then
                                do
                                    vm.err = err
                                end
                            else
                                local _ret62
                                do
                                    vm.mainStack.pointer = vm.mainStack.pointer - 1
                                    _ret62 = vm.mainStack[vm.mainStack.pointer + 1]
                                    goto _inline_end161
                                end
                                ::_inline_end161::
                            end
                        end
                        if self then
                            table.insert (arguments, self)
                        end
                        if tocall.variadicOffset > 0 then
                            arguments[tocall.variadicOffset] = capture
                        end
                        do
                            local _ret63
                            do
                                vm.mainStack.frames.pointer = vm.mainStack.frames.pointer - 1
                                _ret63 = vm.mainStack.frames[vm.mainStack.frames.pointer + 1]
                                goto _inline_end163
                            end
                            ::_inline_end163::
                        end
                        local _ret64
                        do
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = tocall, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (tocall, arguments)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret64 = callResult
                                    goto _inline_end164
                                else
                                    do
                                        vm.serr = {callResult, cip, (source or tocall)}
                                    end
                                end
                            else
                                do
                                    vm.err = "stack overflow"
                                end
                            end
                        end
                        ::_inline_end164::
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer + 1
                            vm.mainStack[vm.mainStack.pointer] = _ret64
                        end
                    elseif t == "luaFunction" then
                        do
                            local _ret65
                            do
                                _ret65 = vm.mainStack.frames[nil or vm.mainStack.frames.pointer]
                                goto _inline_end169
                            end
                            ::_inline_end169::
                            local limit = _ret65 + 1
                            local _ret66
                            do
                                _ret66 = vm.mainStack.pointer
                                goto _inline_end170
                            end
                            ::_inline_end170::
                            local current = _ret66
                            local _ret67
                            do
                                _ret67 = vm.mainStack[limit - 1 or vm.mainStack.pointer]
                                goto _inline_end171
                            end
                            ::_inline_end171::
                            local t = _ret67
                            local keyCount = #t / 2
                            local args = vm.plume.obj.table (current - limit + 1, keyCount)
                            for i = 1, current - limit + 1 do
                                local _ret68
                                do
                                    _ret68 = vm.mainStack[limit + i - 1 or vm.mainStack.pointer]
                                    goto _inline_end172
                                end
                                ::_inline_end172::
                                args.table[i] = _ret68
                            end
                            for i = 1, #t, 3 do
                                if t[i + 2] then
                                    do
                                        local _ret69, _ret70
                                        do
                                            local comopps = "add mul div sub mod pow"
                                            local binopps = "eq lt"
                                            local unopps = "minus"
                                            local expectedParamCount
                                            for opp in comopps:gmatch ("%S+")
                                             do
                                                if t[i] == opp then
                                                    expectedParamCount = 2
                                                elseif t[i]:match ("^" .. opp .. "[rl]")
                                                     then
                                                    expectedParamCount = 1
                                                end
                                            end
                                            for opp in binopps:gmatch ("%S+")
                                             do
                                                if t[i] == opp then
                                                    expectedParamCount = 1
                                                end
                                            end
                                            for opp in unopps:gmatch ("%S+")
                                             do
                                                if t[i] == opp then
                                                    expectedParamCount = 0
                                                end
                                            end
                                            if expectedParamCount then
                                                if t[i + 1].positionalParamCount ~= expectedParamCount then
                                                    _ret69, _ret70 = false, "Wrong number of positionnal parameters for meta-macro '" .. t[i] .. "', " .. t[i + 1].positionalParamCount .. " instead of " .. expectedParamCount .. "."
                                                    goto _inline_end174
                                                end
                                                if t[i + 1].namedParamCount > 1 then
                                                    _ret69, _ret70 = false, "Meta-macro '" .. t[i] .. "' dont support named parameters."
                                                    goto _inline_end174
                                                end
                                            elseif t[i] ~= "call" and t[i] ~= "tostring" and t[i] ~= "tonumber" and t[i] ~= "getindex" and t[i] ~= "setindex" and t[i] ~= "next" and t[i] ~= "iter" then
                                                _ret69, _ret70 = false, "'" .. t[i] .. "' isn't a valid meta-macro name."
                                                goto _inline_end174
                                            end
                                            _ret69, _ret70 = true
                                            goto _inline_end174
                                        end
                                        ::_inline_end174::
                                        local success, err = _ret69, _ret70
                                        if success then
                                            args.meta.table[t[i]] = t[i + 1]
                                        else
                                            do
                                                vm.err = err
                                            end
                                        end
                                    end
                                else
                                    do
                                        local key = t[i]
                                        local value = t[i + 1]
                                        key = tonumber (key) or key
                                        if not args.table[key] then
                                            table.insert (args.keys, t[i])
                                        end
                                        args.table[key] = value
                                    end
                                end
                            end
                            do
                                vm.mainStack.pointer = limit - 2
                            end
                            do
                                vm.mainStack.pointer = vm.mainStack.pointer + 1
                                vm.mainStack[vm.mainStack.pointer] = args
                            end
                            do
                                local _ret71
                                do
                                    vm.mainStack.frames.pointer = vm.mainStack.frames.pointer - 1
                                    _ret71 = vm.mainStack.frames[vm.mainStack.frames.pointer + 1]
                                    goto _inline_end180
                                end
                                ::_inline_end180::
                            end
                        end
                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = tocall, ip = vm.ip})
                        local _ret72
                        do
                            _ret72 = vm.mainStack[nil or vm.mainStack.pointer]
                            goto _inline_end181
                        end
                        ::_inline_end181::
                        local success, result = pcall (tocall.callable, _ret72, vm.chunk)
                        if success then
                            table.remove (vm.chunk.callstack)
                            if result == nil then
                                result = vm.empty
                            end
                            local _ret73
                            do
                                vm.mainStack.pointer = vm.mainStack.pointer - 1
                                _ret73 = vm.mainStack[vm.mainStack.pointer + 1]
                                goto _inline_end182
                            end
                            ::_inline_end182::
                            do
                                vm.mainStack.pointer = vm.mainStack.pointer + 1
                                vm.mainStack[vm.mainStack.pointer] = result
                            end
                        else
                            do
                                vm.err = result
                            end
                        end
                    else
                        do
                            vm.err = "Try to call a '" .. t .. "' value"
                        end
                    end
                end
                goto DISPATCH
            ::ACC_CHECK_TEXT::
                do
                    local _ret74
                    do
                        _ret74 = vm.mainStack[nil or vm.mainStack.pointer]
                        goto _inline_end187
                    end
                    ::_inline_end187::
                    local value = _ret74
                    local _ret75
                    do
                        _ret75 = type (value) == "table" and (value == vm.empty or value.type) or type (value)
                        goto _inline_end188
                    end
                    ::_inline_end188::
                    local t = _ret75
                    if t ~= "number" and t ~= "string" and value ~= vm.empty then
                        if t == "table" and value.meta.table.tostring then
                            local meta = value.meta.table.tostring
                            local args = {}
                            local _ret76
                            do
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, args)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret76 = callResult
                                        goto _inline_end189
                                    else
                                        do
                                            vm.serr = {callResult, cip, (source or meta)}
                                        end
                                    end
                                else
                                    do
                                        vm.err = "stack overflow"
                                    end
                                end
                            end
                            ::_inline_end189::
                            local _ret77
                            do
                                _ret77 = vm.mainStack.pointer
                                goto _inline_end192
                            end
                            ::_inline_end192::
                            do
                                vm.mainStack[_ret77] = _ret76
                            end
                        else
                            do
                                vm.err = "Cannot concat a '" .. t .. "' value."
                            end
                        end
                    end
                end
                goto DISPATCH
            ::JUMP_IF::
                do
                    local _ret78
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret78 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end196
                    end
                    ::_inline_end196::
                    local test = _ret78
                    local _ret79
                    do
                        if test == vm.empty then
                            _ret79 = false
                            goto _inline_end197
                        end
                        _ret79 = test
                        goto _inline_end197
                    end
                    ::_inline_end197::
                    if _ret79 then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::JUMP_IF_NOT::
                do
                    local _ret80
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret80 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end199
                    end
                    ::_inline_end199::
                    local test = _ret80
                    local _ret81
                    do
                        if test == vm.empty then
                            _ret81 = false
                            goto _inline_end200
                        end
                        _ret81 = test
                        goto _inline_end200
                    end
                    ::_inline_end200::
                    if not _ret81 then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::JUMP_IF_NOT_EMPTY::
                do
                    local _ret82
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret82 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end202
                    end
                    ::_inline_end202::
                    local test = _ret82
                    if test ~= vm.empty then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::JUMP::
                do
                    vm.jump = arg2
                end
                goto DISPATCH
            ::JUMP_IF_PEEK::
                do
                    local _ret83
                    do
                        _ret83 = vm.mainStack[nil or vm.mainStack.pointer]
                        goto _inline_end205
                    end
                    ::_inline_end205::
                    local test = _ret83
                    local _ret84
                    do
                        if test == vm.empty then
                            _ret84 = false
                            goto _inline_end206
                        end
                        _ret84 = test
                        goto _inline_end206
                    end
                    ::_inline_end206::
                    if _ret84 then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::JUMP_IF_NOT_PEEK::
                do
                    local _ret85
                    do
                        _ret85 = vm.mainStack[nil or vm.mainStack.pointer]
                        goto _inline_end208
                    end
                    ::_inline_end208::
                    local test = _ret85
                    local _ret86
                    do
                        if test == vm.empty then
                            _ret86 = false
                            goto _inline_end209
                        end
                        _ret86 = test
                        goto _inline_end209
                    end
                    ::_inline_end209::
                    if not _ret86 then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::GET_ITER::
                do
                    local _ret87
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret87 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end211
                    end
                    ::_inline_end211::
                    local obj = _ret87
                    local _ret88
                    do
                        _ret88 = type (obj) == "table" and (obj == vm.empty or obj.type) or type (obj)
                        goto _inline_end212
                    end
                    ::_inline_end212::
                    local tobj = _ret88
                    if tobj == "table" then
                        local iter
                        if obj.meta.table.next then
                            iter = obj
                        else
                            iter = obj.meta.table.iter or vm.plume.defaultMeta.iter
                        end
                        local value
                        if iter.type == "luaFunction" then
                            value = iter.callable ({obj})
                        elseif iter.type == "table" then
                            value = iter
                        elseif iter.type == "macro" then
                            local _ret89
                            do
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = iter, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (iter, {obj})
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret89 = callResult
                                        goto _inline_end213
                                    else
                                        do
                                            vm.serr = {callResult, cip, (source or iter)}
                                        end
                                    end
                                else
                                    do
                                        vm.err = "stack overflow"
                                    end
                                end
                            end
                            ::_inline_end213::
                            value = _ret89
                        end
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer + 1
                            vm.mainStack[vm.mainStack.pointer] = value
                        end
                    else
                        do
                            vm.err = "Try to iterate over a non-table '" .. tobj .. "' value."
                        end
                    end
                end
                goto DISPATCH
            ::FOR_ITER::
                do
                    local _ret90
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret90 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end219
                    end
                    ::_inline_end219::
                    local obj = _ret90
                    local iter = obj.meta.table.next
                    local result
                    if iter.type == "luaFunction" then
                        result = iter.callable ()
                    else
                        local _ret91
                        do
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = iter, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (iter, {obj})
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret91 = callResult
                                    goto _inline_end220
                                else
                                    do
                                        vm.serr = {callResult, cip, (source or iter)}
                                    end
                                end
                            else
                                do
                                    vm.err = "stack overflow"
                                end
                            end
                        end
                        ::_inline_end220::
                        result = _ret91
                    end
                    if result == vm.empty then
                        do
                            vm.jump = arg2
                        end
                    else
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer + 1
                            vm.mainStack[vm.mainStack.pointer] = result
                        end
                    end
                end
                goto DISPATCH
            ::OPP_ADD::
                do
                    do
                        local _ret92
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret92 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end227
                        end
                        ::_inline_end227::
                        local right = _ret92
                        local _ret93
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret93 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end228
                        end
                        ::_inline_end228::
                        local left = _ret93
                        local rerr, lerr, success, result
                        local _ret94, _ret95
                        do
                            local _ret96
                            do
                                _ret96 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                                goto _inline_end230
                            end
                            ::_inline_end230::
                            local tx = _ret96
                            if tx == "string" then
                                right = tonumber (right)
                                if not right then
                                    _ret94, _ret95 = right, "Cannot convert the string value to a number."
                                    goto _inline_end229
                                end
                            elseif tx ~= "number" then
                                if tx == "table" and right.meta.table.tonumber then
                                    local meta = right.meta.table.tonumber
                                    local params = {}
                                    local _ret97
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, params)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret97 = callResult
                                                goto _inline_end231
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end231::
                                    _ret94, _ret95 = _ret97
                                    goto _inline_end229
                                else
                                    _ret94, _ret95 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                    goto _inline_end229
                                end
                            end
                            _ret94, _ret95 = right
                            goto _inline_end229
                        end
                        ::_inline_end229::
                        right, rerr = _ret94, _ret95
                        local _ret98, _ret99
                        do
                            local _ret100
                            do
                                _ret100 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                                goto _inline_end235
                            end
                            ::_inline_end235::
                            local tx = _ret100
                            if tx == "string" then
                                left = tonumber (left)
                                if not left then
                                    _ret98, _ret99 = left, "Cannot convert the string value to a number."
                                    goto _inline_end234
                                end
                            elseif tx ~= "number" then
                                if tx == "table" and left.meta.table.tonumber then
                                    local meta = left.meta.table.tonumber
                                    local params = {}
                                    local _ret101
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, params)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret101 = callResult
                                                goto _inline_end236
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end236::
                                    _ret98, _ret99 = _ret101
                                    goto _inline_end234
                                else
                                    _ret98, _ret99 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                    goto _inline_end234
                                end
                            end
                            _ret98, _ret99 = left
                            goto _inline_end234
                        end
                        ::_inline_end234::
                        left, lerr = _ret98, _ret99
                        if lerr or rerr then
                            local _ret102, _ret103
                            do
                                local meta, params
                                local _ret104
                                do
                                    _ret104 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                                    goto _inline_end240
                                end
                                ::_inline_end240::
                                local tleft = _ret104
                                local _ret105
                                do
                                    _ret105 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                                    goto _inline_end241
                                end
                                ::_inline_end241::
                                local tright = _ret105
                                if tleft == "table" and left.meta and left.meta.table["add" .. "r"] then
                                    meta = left.meta.table["add" .. "r"]
                                    params = {right, left}
                                elseif tright == "table" and right.meta and right.meta.table["add" .. "l"] then
                                    meta = right.meta.table["add" .. "l"]
                                    params = {left, right}
                                elseif tleft == "table" and left.meta and left.meta.table.add then
                                    meta = left.meta.table.add
                                    params = {left, right, left}
                                elseif tright == "table" and right.meta and right.meta.table.add then
                                    meta = right.meta.table.add
                                    params = {left, right, right}
                                end
                                if not meta then
                                    _ret102 = false
                                    goto _inline_end239
                                end
                                local _ret106
                                do
                                    table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                    if #vm.chunk.callstack <= 1000 then
                                        local success, callResult, cip, source = vm.plume.run (meta, params)
                                        if success then
                                            table.remove (vm.chunk.callstack)
                                            _ret106 = callResult
                                            goto _inline_end242
                                        else
                                            do
                                                vm.serr = {callResult, cip, (source or meta)}
                                            end
                                        end
                                    else
                                        do
                                            vm.err = "stack overflow"
                                        end
                                    end
                                end
                                ::_inline_end242::
                                _ret102, _ret103 = true, _ret106
                                goto _inline_end239
                            end
                            ::_inline_end239::
                            success, result = _ret102, _ret103
                        else
                            success = true
                            local _ret107
                            do
                                _ret107 = left + right
                                goto _inline_end245
                            end
                            ::_inline_end245::
                            result = _ret107
                        end
                        if success then
                            do
                                vm.mainStack.pointer = vm.mainStack.pointer + 1
                                vm.mainStack[vm.mainStack.pointer] = result
                            end
                        else
                            do
                                vm.err = lerr or rerr
                            end
                        end
                    end
                end
                goto DISPATCH
            ::OPP_MUL::
                do
                    do
                        local _ret108
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret108 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end250
                        end
                        ::_inline_end250::
                        local right = _ret108
                        local _ret109
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret109 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end251
                        end
                        ::_inline_end251::
                        local left = _ret109
                        local rerr, lerr, success, result
                        local _ret110, _ret111
                        do
                            local _ret112
                            do
                                _ret112 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                                goto _inline_end253
                            end
                            ::_inline_end253::
                            local tx = _ret112
                            if tx == "string" then
                                right = tonumber (right)
                                if not right then
                                    _ret110, _ret111 = right, "Cannot convert the string value to a number."
                                    goto _inline_end252
                                end
                            elseif tx ~= "number" then
                                if tx == "table" and right.meta.table.tonumber then
                                    local meta = right.meta.table.tonumber
                                    local params = {}
                                    local _ret113
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, params)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret113 = callResult
                                                goto _inline_end254
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end254::
                                    _ret110, _ret111 = _ret113
                                    goto _inline_end252
                                else
                                    _ret110, _ret111 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                    goto _inline_end252
                                end
                            end
                            _ret110, _ret111 = right
                            goto _inline_end252
                        end
                        ::_inline_end252::
                        right, rerr = _ret110, _ret111
                        local _ret114, _ret115
                        do
                            local _ret116
                            do
                                _ret116 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                                goto _inline_end258
                            end
                            ::_inline_end258::
                            local tx = _ret116
                            if tx == "string" then
                                left = tonumber (left)
                                if not left then
                                    _ret114, _ret115 = left, "Cannot convert the string value to a number."
                                    goto _inline_end257
                                end
                            elseif tx ~= "number" then
                                if tx == "table" and left.meta.table.tonumber then
                                    local meta = left.meta.table.tonumber
                                    local params = {}
                                    local _ret117
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, params)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret117 = callResult
                                                goto _inline_end259
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end259::
                                    _ret114, _ret115 = _ret117
                                    goto _inline_end257
                                else
                                    _ret114, _ret115 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                    goto _inline_end257
                                end
                            end
                            _ret114, _ret115 = left
                            goto _inline_end257
                        end
                        ::_inline_end257::
                        left, lerr = _ret114, _ret115
                        if lerr or rerr then
                            local _ret118, _ret119
                            do
                                local meta, params
                                local _ret120
                                do
                                    _ret120 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                                    goto _inline_end263
                                end
                                ::_inline_end263::
                                local tleft = _ret120
                                local _ret121
                                do
                                    _ret121 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                                    goto _inline_end264
                                end
                                ::_inline_end264::
                                local tright = _ret121
                                if tleft == "table" and left.meta and left.meta.table["mul" .. "r"] then
                                    meta = left.meta.table["mul" .. "r"]
                                    params = {right, left}
                                elseif tright == "table" and right.meta and right.meta.table["mul" .. "l"] then
                                    meta = right.meta.table["mul" .. "l"]
                                    params = {left, right}
                                elseif tleft == "table" and left.meta and left.meta.table.mul then
                                    meta = left.meta.table.mul
                                    params = {left, right, left}
                                elseif tright == "table" and right.meta and right.meta.table.mul then
                                    meta = right.meta.table.mul
                                    params = {left, right, right}
                                end
                                if not meta then
                                    _ret118 = false
                                    goto _inline_end262
                                end
                                local _ret122
                                do
                                    table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                    if #vm.chunk.callstack <= 1000 then
                                        local success, callResult, cip, source = vm.plume.run (meta, params)
                                        if success then
                                            table.remove (vm.chunk.callstack)
                                            _ret122 = callResult
                                            goto _inline_end265
                                        else
                                            do
                                                vm.serr = {callResult, cip, (source or meta)}
                                            end
                                        end
                                    else
                                        do
                                            vm.err = "stack overflow"
                                        end
                                    end
                                end
                                ::_inline_end265::
                                _ret118, _ret119 = true, _ret122
                                goto _inline_end262
                            end
                            ::_inline_end262::
                            success, result = _ret118, _ret119
                        else
                            success = true
                            local _ret123
                            do
                                _ret123 = left * right
                                goto _inline_end268
                            end
                            ::_inline_end268::
                            result = _ret123
                        end
                        if success then
                            do
                                vm.mainStack.pointer = vm.mainStack.pointer + 1
                                vm.mainStack[vm.mainStack.pointer] = result
                            end
                        else
                            do
                                vm.err = lerr or rerr
                            end
                        end
                    end
                end
                goto DISPATCH
            ::OPP_SUB::
                do
                    do
                        local _ret124
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret124 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end273
                        end
                        ::_inline_end273::
                        local right = _ret124
                        local _ret125
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret125 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end274
                        end
                        ::_inline_end274::
                        local left = _ret125
                        local rerr, lerr, success, result
                        local _ret126, _ret127
                        do
                            local _ret128
                            do
                                _ret128 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                                goto _inline_end276
                            end
                            ::_inline_end276::
                            local tx = _ret128
                            if tx == "string" then
                                right = tonumber (right)
                                if not right then
                                    _ret126, _ret127 = right, "Cannot convert the string value to a number."
                                    goto _inline_end275
                                end
                            elseif tx ~= "number" then
                                if tx == "table" and right.meta.table.tonumber then
                                    local meta = right.meta.table.tonumber
                                    local params = {}
                                    local _ret129
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, params)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret129 = callResult
                                                goto _inline_end277
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end277::
                                    _ret126, _ret127 = _ret129
                                    goto _inline_end275
                                else
                                    _ret126, _ret127 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                    goto _inline_end275
                                end
                            end
                            _ret126, _ret127 = right
                            goto _inline_end275
                        end
                        ::_inline_end275::
                        right, rerr = _ret126, _ret127
                        local _ret130, _ret131
                        do
                            local _ret132
                            do
                                _ret132 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                                goto _inline_end281
                            end
                            ::_inline_end281::
                            local tx = _ret132
                            if tx == "string" then
                                left = tonumber (left)
                                if not left then
                                    _ret130, _ret131 = left, "Cannot convert the string value to a number."
                                    goto _inline_end280
                                end
                            elseif tx ~= "number" then
                                if tx == "table" and left.meta.table.tonumber then
                                    local meta = left.meta.table.tonumber
                                    local params = {}
                                    local _ret133
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, params)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret133 = callResult
                                                goto _inline_end282
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end282::
                                    _ret130, _ret131 = _ret133
                                    goto _inline_end280
                                else
                                    _ret130, _ret131 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                    goto _inline_end280
                                end
                            end
                            _ret130, _ret131 = left
                            goto _inline_end280
                        end
                        ::_inline_end280::
                        left, lerr = _ret130, _ret131
                        if lerr or rerr then
                            local _ret134, _ret135
                            do
                                local meta, params
                                local _ret136
                                do
                                    _ret136 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                                    goto _inline_end286
                                end
                                ::_inline_end286::
                                local tleft = _ret136
                                local _ret137
                                do
                                    _ret137 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                                    goto _inline_end287
                                end
                                ::_inline_end287::
                                local tright = _ret137
                                if tleft == "table" and left.meta and left.meta.table["sub" .. "r"] then
                                    meta = left.meta.table["sub" .. "r"]
                                    params = {right, left}
                                elseif tright == "table" and right.meta and right.meta.table["sub" .. "l"] then
                                    meta = right.meta.table["sub" .. "l"]
                                    params = {left, right}
                                elseif tleft == "table" and left.meta and left.meta.table.sub then
                                    meta = left.meta.table.sub
                                    params = {left, right, left}
                                elseif tright == "table" and right.meta and right.meta.table.sub then
                                    meta = right.meta.table.sub
                                    params = {left, right, right}
                                end
                                if not meta then
                                    _ret134 = false
                                    goto _inline_end285
                                end
                                local _ret138
                                do
                                    table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                    if #vm.chunk.callstack <= 1000 then
                                        local success, callResult, cip, source = vm.plume.run (meta, params)
                                        if success then
                                            table.remove (vm.chunk.callstack)
                                            _ret138 = callResult
                                            goto _inline_end288
                                        else
                                            do
                                                vm.serr = {callResult, cip, (source or meta)}
                                            end
                                        end
                                    else
                                        do
                                            vm.err = "stack overflow"
                                        end
                                    end
                                end
                                ::_inline_end288::
                                _ret134, _ret135 = true, _ret138
                                goto _inline_end285
                            end
                            ::_inline_end285::
                            success, result = _ret134, _ret135
                        else
                            success = true
                            local _ret139
                            do
                                _ret139 = left - right
                                goto _inline_end291
                            end
                            ::_inline_end291::
                            result = _ret139
                        end
                        if success then
                            do
                                vm.mainStack.pointer = vm.mainStack.pointer + 1
                                vm.mainStack[vm.mainStack.pointer] = result
                            end
                        else
                            do
                                vm.err = lerr or rerr
                            end
                        end
                    end
                end
                goto DISPATCH
            ::OPP_DIV::
                do
                    do
                        local _ret140
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret140 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end296
                        end
                        ::_inline_end296::
                        local right = _ret140
                        local _ret141
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret141 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end297
                        end
                        ::_inline_end297::
                        local left = _ret141
                        local rerr, lerr, success, result
                        local _ret142, _ret143
                        do
                            local _ret144
                            do
                                _ret144 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                                goto _inline_end299
                            end
                            ::_inline_end299::
                            local tx = _ret144
                            if tx == "string" then
                                right = tonumber (right)
                                if not right then
                                    _ret142, _ret143 = right, "Cannot convert the string value to a number."
                                    goto _inline_end298
                                end
                            elseif tx ~= "number" then
                                if tx == "table" and right.meta.table.tonumber then
                                    local meta = right.meta.table.tonumber
                                    local params = {}
                                    local _ret145
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, params)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret145 = callResult
                                                goto _inline_end300
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end300::
                                    _ret142, _ret143 = _ret145
                                    goto _inline_end298
                                else
                                    _ret142, _ret143 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                    goto _inline_end298
                                end
                            end
                            _ret142, _ret143 = right
                            goto _inline_end298
                        end
                        ::_inline_end298::
                        right, rerr = _ret142, _ret143
                        local _ret146, _ret147
                        do
                            local _ret148
                            do
                                _ret148 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                                goto _inline_end304
                            end
                            ::_inline_end304::
                            local tx = _ret148
                            if tx == "string" then
                                left = tonumber (left)
                                if not left then
                                    _ret146, _ret147 = left, "Cannot convert the string value to a number."
                                    goto _inline_end303
                                end
                            elseif tx ~= "number" then
                                if tx == "table" and left.meta.table.tonumber then
                                    local meta = left.meta.table.tonumber
                                    local params = {}
                                    local _ret149
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, params)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret149 = callResult
                                                goto _inline_end305
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end305::
                                    _ret146, _ret147 = _ret149
                                    goto _inline_end303
                                else
                                    _ret146, _ret147 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                    goto _inline_end303
                                end
                            end
                            _ret146, _ret147 = left
                            goto _inline_end303
                        end
                        ::_inline_end303::
                        left, lerr = _ret146, _ret147
                        if lerr or rerr then
                            local _ret150, _ret151
                            do
                                local meta, params
                                local _ret152
                                do
                                    _ret152 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                                    goto _inline_end309
                                end
                                ::_inline_end309::
                                local tleft = _ret152
                                local _ret153
                                do
                                    _ret153 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                                    goto _inline_end310
                                end
                                ::_inline_end310::
                                local tright = _ret153
                                if tleft == "table" and left.meta and left.meta.table["div" .. "r"] then
                                    meta = left.meta.table["div" .. "r"]
                                    params = {right, left}
                                elseif tright == "table" and right.meta and right.meta.table["div" .. "l"] then
                                    meta = right.meta.table["div" .. "l"]
                                    params = {left, right}
                                elseif tleft == "table" and left.meta and left.meta.table.div then
                                    meta = left.meta.table.div
                                    params = {left, right, left}
                                elseif tright == "table" and right.meta and right.meta.table.div then
                                    meta = right.meta.table.div
                                    params = {left, right, right}
                                end
                                if not meta then
                                    _ret150 = false
                                    goto _inline_end308
                                end
                                local _ret154
                                do
                                    table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                    if #vm.chunk.callstack <= 1000 then
                                        local success, callResult, cip, source = vm.plume.run (meta, params)
                                        if success then
                                            table.remove (vm.chunk.callstack)
                                            _ret154 = callResult
                                            goto _inline_end311
                                        else
                                            do
                                                vm.serr = {callResult, cip, (source or meta)}
                                            end
                                        end
                                    else
                                        do
                                            vm.err = "stack overflow"
                                        end
                                    end
                                end
                                ::_inline_end311::
                                _ret150, _ret151 = true, _ret154
                                goto _inline_end308
                            end
                            ::_inline_end308::
                            success, result = _ret150, _ret151
                        else
                            success = true
                            local _ret155
                            do
                                _ret155 = left / right
                                goto _inline_end314
                            end
                            ::_inline_end314::
                            result = _ret155
                        end
                        if success then
                            do
                                vm.mainStack.pointer = vm.mainStack.pointer + 1
                                vm.mainStack[vm.mainStack.pointer] = result
                            end
                        else
                            do
                                vm.err = lerr or rerr
                            end
                        end
                    end
                end
                goto DISPATCH
            ::OPP_NEG::
                do
                    do
                        local _ret156
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret156 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end319
                        end
                        ::_inline_end319::
                        local x = _ret156
                        local err
                        local _ret157, _ret158
                        do
                            local _ret159
                            do
                                _ret159 = type (x) == "table" and (x == vm.empty or x.type) or type (x)
                                goto _inline_end321
                            end
                            ::_inline_end321::
                            local tx = _ret159
                            if tx == "string" then
                                x = tonumber (x)
                                if not x then
                                    _ret157, _ret158 = x, "Cannot convert the string value to a number."
                                    goto _inline_end320
                                end
                            elseif tx ~= "number" then
                                if tx == "table" and x.meta.table.tonumber then
                                    local meta = x.meta.table.tonumber
                                    local params = {}
                                    local _ret160
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, params)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret160 = callResult
                                                goto _inline_end322
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end322::
                                    _ret157, _ret158 = _ret160
                                    goto _inline_end320
                                else
                                    _ret157, _ret158 = x, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                    goto _inline_end320
                                end
                            end
                            _ret157, _ret158 = x
                            goto _inline_end320
                        end
                        ::_inline_end320::
                        x, err = _ret157, _ret158
                        if err then
                            local _ret161, _ret162
                            do
                                local meta
                                local params = {x}
                                local _ret163
                                do
                                    _ret163 = type (x) == "table" and (x == vm.empty or x.type) or type (x)
                                    goto _inline_end326
                                end
                                ::_inline_end326::
                                if _ret163 == "table" and x.meta and x.meta.table.minus then
                                    meta = x.meta.table.minus
                                end
                                if not meta then
                                    _ret161 = false
                                    goto _inline_end325
                                end
                                local _ret164
                                do
                                    table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                    if #vm.chunk.callstack <= 1000 then
                                        local success, callResult, cip, source = vm.plume.run (meta, params)
                                        if success then
                                            table.remove (vm.chunk.callstack)
                                            _ret164 = callResult
                                            goto _inline_end327
                                        else
                                            do
                                                vm.serr = {callResult, cip, (source or meta)}
                                            end
                                        end
                                    else
                                        do
                                            vm.err = "stack overflow"
                                        end
                                    end
                                end
                                ::_inline_end327::
                                _ret161, _ret162 = true, _ret164
                                goto _inline_end325
                            end
                            ::_inline_end325::
                            success, result = _ret161, _ret162
                        else
                            success = true
                            local _ret165
                            do
                                _ret165 = -x
                                goto _inline_end330
                            end
                            ::_inline_end330::
                            result = _ret165
                        end
                        if success then
                            do
                                vm.mainStack.pointer = vm.mainStack.pointer + 1
                                vm.mainStack[vm.mainStack.pointer] = result
                            end
                        else
                            do
                                vm.err = err
                            end
                        end
                    end
                end
                goto DISPATCH
            ::OPP_MOD::
                do
                    do
                        local _ret166
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret166 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end335
                        end
                        ::_inline_end335::
                        local right = _ret166
                        local _ret167
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret167 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end336
                        end
                        ::_inline_end336::
                        local left = _ret167
                        local rerr, lerr, success, result
                        local _ret168, _ret169
                        do
                            local _ret170
                            do
                                _ret170 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                                goto _inline_end338
                            end
                            ::_inline_end338::
                            local tx = _ret170
                            if tx == "string" then
                                right = tonumber (right)
                                if not right then
                                    _ret168, _ret169 = right, "Cannot convert the string value to a number."
                                    goto _inline_end337
                                end
                            elseif tx ~= "number" then
                                if tx == "table" and right.meta.table.tonumber then
                                    local meta = right.meta.table.tonumber
                                    local params = {}
                                    local _ret171
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, params)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret171 = callResult
                                                goto _inline_end339
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end339::
                                    _ret168, _ret169 = _ret171
                                    goto _inline_end337
                                else
                                    _ret168, _ret169 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                    goto _inline_end337
                                end
                            end
                            _ret168, _ret169 = right
                            goto _inline_end337
                        end
                        ::_inline_end337::
                        right, rerr = _ret168, _ret169
                        local _ret172, _ret173
                        do
                            local _ret174
                            do
                                _ret174 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                                goto _inline_end343
                            end
                            ::_inline_end343::
                            local tx = _ret174
                            if tx == "string" then
                                left = tonumber (left)
                                if not left then
                                    _ret172, _ret173 = left, "Cannot convert the string value to a number."
                                    goto _inline_end342
                                end
                            elseif tx ~= "number" then
                                if tx == "table" and left.meta.table.tonumber then
                                    local meta = left.meta.table.tonumber
                                    local params = {}
                                    local _ret175
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, params)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret175 = callResult
                                                goto _inline_end344
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end344::
                                    _ret172, _ret173 = _ret175
                                    goto _inline_end342
                                else
                                    _ret172, _ret173 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                    goto _inline_end342
                                end
                            end
                            _ret172, _ret173 = left
                            goto _inline_end342
                        end
                        ::_inline_end342::
                        left, lerr = _ret172, _ret173
                        if lerr or rerr then
                            local _ret176, _ret177
                            do
                                local meta, params
                                local _ret178
                                do
                                    _ret178 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                                    goto _inline_end348
                                end
                                ::_inline_end348::
                                local tleft = _ret178
                                local _ret179
                                do
                                    _ret179 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                                    goto _inline_end349
                                end
                                ::_inline_end349::
                                local tright = _ret179
                                if tleft == "table" and left.meta and left.meta.table["mod" .. "r"] then
                                    meta = left.meta.table["mod" .. "r"]
                                    params = {right, left}
                                elseif tright == "table" and right.meta and right.meta.table["mod" .. "l"] then
                                    meta = right.meta.table["mod" .. "l"]
                                    params = {left, right}
                                elseif tleft == "table" and left.meta and left.meta.table.mod then
                                    meta = left.meta.table.mod
                                    params = {left, right, left}
                                elseif tright == "table" and right.meta and right.meta.table.mod then
                                    meta = right.meta.table.mod
                                    params = {left, right, right}
                                end
                                if not meta then
                                    _ret176 = false
                                    goto _inline_end347
                                end
                                local _ret180
                                do
                                    table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                    if #vm.chunk.callstack <= 1000 then
                                        local success, callResult, cip, source = vm.plume.run (meta, params)
                                        if success then
                                            table.remove (vm.chunk.callstack)
                                            _ret180 = callResult
                                            goto _inline_end350
                                        else
                                            do
                                                vm.serr = {callResult, cip, (source or meta)}
                                            end
                                        end
                                    else
                                        do
                                            vm.err = "stack overflow"
                                        end
                                    end
                                end
                                ::_inline_end350::
                                _ret176, _ret177 = true, _ret180
                                goto _inline_end347
                            end
                            ::_inline_end347::
                            success, result = _ret176, _ret177
                        else
                            success = true
                            local _ret181
                            do
                                _ret181 = left % right
                                goto _inline_end353
                            end
                            ::_inline_end353::
                            result = _ret181
                        end
                        if success then
                            do
                                vm.mainStack.pointer = vm.mainStack.pointer + 1
                                vm.mainStack[vm.mainStack.pointer] = result
                            end
                        else
                            do
                                vm.err = lerr or rerr
                            end
                        end
                    end
                end
                goto DISPATCH
            ::OPP_POW::
                do
                    do
                        local _ret182
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret182 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end358
                        end
                        ::_inline_end358::
                        local right = _ret182
                        local _ret183
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret183 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end359
                        end
                        ::_inline_end359::
                        local left = _ret183
                        local rerr, lerr, success, result
                        local _ret184, _ret185
                        do
                            local _ret186
                            do
                                _ret186 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                                goto _inline_end361
                            end
                            ::_inline_end361::
                            local tx = _ret186
                            if tx == "string" then
                                right = tonumber (right)
                                if not right then
                                    _ret184, _ret185 = right, "Cannot convert the string value to a number."
                                    goto _inline_end360
                                end
                            elseif tx ~= "number" then
                                if tx == "table" and right.meta.table.tonumber then
                                    local meta = right.meta.table.tonumber
                                    local params = {}
                                    local _ret187
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, params)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret187 = callResult
                                                goto _inline_end362
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end362::
                                    _ret184, _ret185 = _ret187
                                    goto _inline_end360
                                else
                                    _ret184, _ret185 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                    goto _inline_end360
                                end
                            end
                            _ret184, _ret185 = right
                            goto _inline_end360
                        end
                        ::_inline_end360::
                        right, rerr = _ret184, _ret185
                        local _ret188, _ret189
                        do
                            local _ret190
                            do
                                _ret190 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                                goto _inline_end366
                            end
                            ::_inline_end366::
                            local tx = _ret190
                            if tx == "string" then
                                left = tonumber (left)
                                if not left then
                                    _ret188, _ret189 = left, "Cannot convert the string value to a number."
                                    goto _inline_end365
                                end
                            elseif tx ~= "number" then
                                if tx == "table" and left.meta.table.tonumber then
                                    local meta = left.meta.table.tonumber
                                    local params = {}
                                    local _ret191
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, params)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret191 = callResult
                                                goto _inline_end367
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end367::
                                    _ret188, _ret189 = _ret191
                                    goto _inline_end365
                                else
                                    _ret188, _ret189 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                    goto _inline_end365
                                end
                            end
                            _ret188, _ret189 = left
                            goto _inline_end365
                        end
                        ::_inline_end365::
                        left, lerr = _ret188, _ret189
                        if lerr or rerr then
                            local _ret192, _ret193
                            do
                                local meta, params
                                local _ret194
                                do
                                    _ret194 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                                    goto _inline_end371
                                end
                                ::_inline_end371::
                                local tleft = _ret194
                                local _ret195
                                do
                                    _ret195 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                                    goto _inline_end372
                                end
                                ::_inline_end372::
                                local tright = _ret195
                                if tleft == "table" and left.meta and left.meta.table["pow" .. "r"] then
                                    meta = left.meta.table["pow" .. "r"]
                                    params = {right, left}
                                elseif tright == "table" and right.meta and right.meta.table["pow" .. "l"] then
                                    meta = right.meta.table["pow" .. "l"]
                                    params = {left, right}
                                elseif tleft == "table" and left.meta and left.meta.table.pow then
                                    meta = left.meta.table.pow
                                    params = {left, right, left}
                                elseif tright == "table" and right.meta and right.meta.table.pow then
                                    meta = right.meta.table.pow
                                    params = {left, right, right}
                                end
                                if not meta then
                                    _ret192 = false
                                    goto _inline_end370
                                end
                                local _ret196
                                do
                                    table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                    if #vm.chunk.callstack <= 1000 then
                                        local success, callResult, cip, source = vm.plume.run (meta, params)
                                        if success then
                                            table.remove (vm.chunk.callstack)
                                            _ret196 = callResult
                                            goto _inline_end373
                                        else
                                            do
                                                vm.serr = {callResult, cip, (source or meta)}
                                            end
                                        end
                                    else
                                        do
                                            vm.err = "stack overflow"
                                        end
                                    end
                                end
                                ::_inline_end373::
                                _ret192, _ret193 = true, _ret196
                                goto _inline_end370
                            end
                            ::_inline_end370::
                            success, result = _ret192, _ret193
                        else
                            success = true
                            local _ret197
                            do
                                _ret197 = left ^ right
                                goto _inline_end376
                            end
                            ::_inline_end376::
                            result = _ret197
                        end
                        if success then
                            do
                                vm.mainStack.pointer = vm.mainStack.pointer + 1
                                vm.mainStack[vm.mainStack.pointer] = result
                            end
                        else
                            do
                                vm.err = lerr or rerr
                            end
                        end
                    end
                end
                goto DISPATCH
            ::OPP_LT::
                do
                    do
                        local _ret198
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret198 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end381
                        end
                        ::_inline_end381::
                        local right = _ret198
                        local _ret199
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret199 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end382
                        end
                        ::_inline_end382::
                        local left = _ret199
                        local rerr, lerr, success, result
                        local _ret200, _ret201
                        do
                            local _ret202
                            do
                                _ret202 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                                goto _inline_end384
                            end
                            ::_inline_end384::
                            local tx = _ret202
                            if tx == "string" then
                                right = tonumber (right)
                                if not right then
                                    _ret200, _ret201 = right, "Cannot convert the string value to a number."
                                    goto _inline_end383
                                end
                            elseif tx ~= "number" then
                                if tx == "table" and right.meta.table.tonumber then
                                    local meta = right.meta.table.tonumber
                                    local params = {}
                                    local _ret203
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, params)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret203 = callResult
                                                goto _inline_end385
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end385::
                                    _ret200, _ret201 = _ret203
                                    goto _inline_end383
                                else
                                    _ret200, _ret201 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                    goto _inline_end383
                                end
                            end
                            _ret200, _ret201 = right
                            goto _inline_end383
                        end
                        ::_inline_end383::
                        right, rerr = _ret200, _ret201
                        local _ret204, _ret205
                        do
                            local _ret206
                            do
                                _ret206 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                                goto _inline_end389
                            end
                            ::_inline_end389::
                            local tx = _ret206
                            if tx == "string" then
                                left = tonumber (left)
                                if not left then
                                    _ret204, _ret205 = left, "Cannot convert the string value to a number."
                                    goto _inline_end388
                                end
                            elseif tx ~= "number" then
                                if tx == "table" and left.meta.table.tonumber then
                                    local meta = left.meta.table.tonumber
                                    local params = {}
                                    local _ret207
                                    do
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, params)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret207 = callResult
                                                goto _inline_end390
                                            else
                                                do
                                                    vm.serr = {callResult, cip, (source or meta)}
                                                end
                                            end
                                        else
                                            do
                                                vm.err = "stack overflow"
                                            end
                                        end
                                    end
                                    ::_inline_end390::
                                    _ret204, _ret205 = _ret207
                                    goto _inline_end388
                                else
                                    _ret204, _ret205 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                    goto _inline_end388
                                end
                            end
                            _ret204, _ret205 = left
                            goto _inline_end388
                        end
                        ::_inline_end388::
                        left, lerr = _ret204, _ret205
                        if lerr or rerr then
                            local _ret208, _ret209
                            do
                                local meta, params
                                local _ret210
                                do
                                    _ret210 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                                    goto _inline_end394
                                end
                                ::_inline_end394::
                                local tleft = _ret210
                                local _ret211
                                do
                                    _ret211 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                                    goto _inline_end395
                                end
                                ::_inline_end395::
                                local tright = _ret211
                                if tleft == "table" and left.meta and left.meta.table["lt" .. "r"] then
                                    meta = left.meta.table["lt" .. "r"]
                                    params = {right, left}
                                elseif tright == "table" and right.meta and right.meta.table["lt" .. "l"] then
                                    meta = right.meta.table["lt" .. "l"]
                                    params = {left, right}
                                elseif tleft == "table" and left.meta and left.meta.table.lt then
                                    meta = left.meta.table.lt
                                    params = {left, right, left}
                                elseif tright == "table" and right.meta and right.meta.table.lt then
                                    meta = right.meta.table.lt
                                    params = {left, right, right}
                                end
                                if not meta then
                                    _ret208 = false
                                    goto _inline_end393
                                end
                                local _ret212
                                do
                                    table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                    if #vm.chunk.callstack <= 1000 then
                                        local success, callResult, cip, source = vm.plume.run (meta, params)
                                        if success then
                                            table.remove (vm.chunk.callstack)
                                            _ret212 = callResult
                                            goto _inline_end396
                                        else
                                            do
                                                vm.serr = {callResult, cip, (source or meta)}
                                            end
                                        end
                                    else
                                        do
                                            vm.err = "stack overflow"
                                        end
                                    end
                                end
                                ::_inline_end396::
                                _ret208, _ret209 = true, _ret212
                                goto _inline_end393
                            end
                            ::_inline_end393::
                            success, result = _ret208, _ret209
                        else
                            success = true
                            local _ret213
                            do
                                _ret213 = left < right
                                goto _inline_end399
                            end
                            ::_inline_end399::
                            result = _ret213
                        end
                        if success then
                            do
                                vm.mainStack.pointer = vm.mainStack.pointer + 1
                                vm.mainStack[vm.mainStack.pointer] = result
                            end
                        else
                            do
                                vm.err = lerr or rerr
                            end
                        end
                    end
                end
                goto DISPATCH
            ::OPP_EQ::
                do
                    local _ret214
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret214 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end403
                    end
                    ::_inline_end403::
                    local right = _ret214
                    local _ret215
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret215 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end404
                    end
                    ::_inline_end404::
                    local left = _ret215
                    local _ret216, _ret217
                    do
                        local meta, params
                        local _ret218
                        do
                            _ret218 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                            goto _inline_end406
                        end
                        ::_inline_end406::
                        local tleft = _ret218
                        local _ret219
                        do
                            _ret219 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                            goto _inline_end407
                        end
                        ::_inline_end407::
                        local tright = _ret219
                        if tleft == "table" and left.meta and left.meta.table["eq" .. "r"] then
                            meta = left.meta.table["eq" .. "r"]
                            params = {right, left}
                        elseif tright == "table" and right.meta and right.meta.table["eq" .. "l"] then
                            meta = right.meta.table["eq" .. "l"]
                            params = {left, right}
                        elseif tleft == "table" and left.meta and left.meta.table.eq then
                            meta = left.meta.table.eq
                            params = {left, right, left}
                        elseif tright == "table" and right.meta and right.meta.table.eq then
                            meta = right.meta.table.eq
                            params = {left, right, right}
                        end
                        if not meta then
                            _ret216 = false
                            goto _inline_end405
                        end
                        local _ret220
                        do
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret220 = callResult
                                    goto _inline_end408
                                else
                                    do
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                end
                            else
                                do
                                    vm.err = "stack overflow"
                                end
                            end
                        end
                        ::_inline_end408::
                        _ret216, _ret217 = true, _ret220
                        goto _inline_end405
                    end
                    ::_inline_end405::
                    local success, result = _ret216, _ret217
                    if not success then
                        result = left == right or tonumber (left) and tonumber (left) == tonumber (right)
                    end
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                        vm.mainStack[vm.mainStack.pointer] = result
                    end
                end
                goto DISPATCH
            ::OPP_AND::
                do
                    do
                        local _ret221
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret221 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end414
                        end
                        ::_inline_end414::
                        local right = _ret221
                        local _ret222
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret222 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end415
                        end
                        ::_inline_end415::
                        local left = _ret222
                        local _ret223
                        do
                            if right == vm.empty then
                                _ret223 = false
                                goto _inline_end416
                            end
                            _ret223 = right
                            goto _inline_end416
                        end
                        ::_inline_end416::
                        right = _ret223
                        local _ret224
                        do
                            if left == vm.empty then
                                _ret224 = false
                                goto _inline_end417
                            end
                            _ret224 = left
                            goto _inline_end417
                        end
                        ::_inline_end417::
                        left = _ret224
                        local _ret225
                        do
                            _ret225 = right and left
                            goto _inline_end418
                        end
                        ::_inline_end418::
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer + 1
                            vm.mainStack[vm.mainStack.pointer] = _ret225
                        end
                    end
                end
                goto DISPATCH
            ::OPP_NOT::
                do
                    do
                        local _ret226
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret226 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end422
                        end
                        ::_inline_end422::
                        local x = _ret226
                        local _ret227
                        do
                            if x == vm.empty then
                                _ret227 = false
                                goto _inline_end423
                            end
                            _ret227 = x
                            goto _inline_end423
                        end
                        ::_inline_end423::
                        x = _ret227
                        local _ret228
                        do
                            _ret228 = not x
                            goto _inline_end424
                        end
                        ::_inline_end424::
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer + 1
                            vm.mainStack[vm.mainStack.pointer] = _ret228
                        end
                    end
                end
                goto DISPATCH
            ::OPP_OR::
                do
                    do
                        local _ret229
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret229 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end428
                        end
                        ::_inline_end428::
                        local right = _ret229
                        local _ret230
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer - 1
                            _ret230 = vm.mainStack[vm.mainStack.pointer + 1]
                            goto _inline_end429
                        end
                        ::_inline_end429::
                        local left = _ret230
                        local _ret231
                        do
                            if right == vm.empty then
                                _ret231 = false
                                goto _inline_end430
                            end
                            _ret231 = right
                            goto _inline_end430
                        end
                        ::_inline_end430::
                        right = _ret231
                        local _ret232
                        do
                            if left == vm.empty then
                                _ret232 = false
                                goto _inline_end431
                            end
                            _ret232 = left
                            goto _inline_end431
                        end
                        ::_inline_end431::
                        left = _ret232
                        local _ret233
                        do
                            _ret233 = right or left
                            goto _inline_end432
                        end
                        ::_inline_end432::
                        do
                            vm.mainStack.pointer = vm.mainStack.pointer + 1
                            vm.mainStack[vm.mainStack.pointer] = _ret233
                        end
                    end
                end
                goto DISPATCH
            ::DUPLICATE::
                do
                    local _ret234
                    do
                        _ret234 = vm.mainStack[nil or vm.mainStack.pointer]
                        goto _inline_end435
                    end
                    ::_inline_end435::
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                        vm.mainStack[vm.mainStack.pointer] = _ret234
                    end
                end
                goto DISPATCH
            ::SWITCH::
                do
                    local _ret235
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret235 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end438
                    end
                    ::_inline_end438::
                    local x = _ret235
                    local _ret236
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer - 1
                        _ret236 = vm.mainStack[vm.mainStack.pointer + 1]
                        goto _inline_end439
                    end
                    ::_inline_end439::
                    local y = _ret236
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                        vm.mainStack[vm.mainStack.pointer] = x
                    end
                    do
                        vm.mainStack.pointer = vm.mainStack.pointer + 1
                        vm.mainStack[vm.mainStack.pointer] = y
                    end
                end
                goto DISPATCH
            ::END::
            local _ret237
            do
                _ret237 = vm.mainStack[nil or vm.mainStack.pointer]
                goto _inline_end442
            end
            ::_inline_end442::
            return true, _ret237
        end
    end
    