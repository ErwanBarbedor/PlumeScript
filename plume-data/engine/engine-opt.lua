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
            function _STACK_GET (stack, index)
                return stack[index or stack.pointer]
            end
            function _STACK_GET_OFFSET (stack, offset)
                return stack[stack.pointer + offset]
            end
            function _STACK_SET (stack, index, value)
                stack[index] = value
            end
            function _STACK_POS (stack)
                return stack.pointer
            end
            function _STACK_POP (stack)
                stack.pointer = stack.pointer - 1
                return stack[stack.pointer + 1]
            end
            function _STACK_PUSH (stack, value)
                stack.pointer = stack.pointer + 1
                stack[stack.pointer] = value
            end
            function _STACK_GET_FRAMED (stack, offset, frameOffset)
                return _STACK_GET (stack, _STACK_GET_OFFSET (stack.frames, frameOffset or 0) + (offset or 0))
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
                            _STACK_SET (vm.variableStack, i, vm.empty)
                        else
                            _STACK_SET (vm.variableStack, i, arguments[i])
                        end
                    end
                    vm.variableStack.pointer = chunk.localsCount
                    _STACK_PUSH (vm.variableStack.frames, 1)
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
            if vm.jump > 0 then
                vm.ip = vm.jump
                vm.jump = 0
            else
                vm.ip = vm.ip + 1
            end
            vm.tic = vm.tic + 1
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
                goto _inline_end6
            end
            ::_inline_end6::
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
                _STACK_PUSH (vm.mainStack, vm.constants[arg2])
                goto DISPATCH
            ::LOAD_TRUE::
                _STACK_PUSH (vm.mainStack, true)
                goto DISPATCH
            ::LOAD_FALSE::
                _STACK_PUSH (vm.mainStack, false)
                goto DISPATCH
            ::LOAD_EMPTY::
                _STACK_PUSH (vm.mainStack, vm.empty)
                goto DISPATCH
            ::LOAD_LOCAL::
                _STACK_PUSH (vm.mainStack, _STACK_GET_FRAMED (vm.variableStack, arg2 - 1))
                goto DISPATCH
            ::LOAD_LEXICAL::
                _STACK_PUSH (vm.mainStack, _STACK_GET_FRAMED (vm.variableStack, arg2 - 1, -arg1))
                goto DISPATCH
            ::LOAD_STATIC::
                _STACK_PUSH (vm.mainStack, vm.static[arg2])
                goto DISPATCH
            ::STORE_LOCAL::
                _STACK_SET (vm.variableStack, _STACK_GET_OFFSET (vm.variableStack.frames, 0 or 0) + (arg2 - 1 or 0), _STACK_POP (vm.mainStack))
                goto DISPATCH
            ::STORE_LEXICAL::
                _STACK_SET (vm.variableStack, _STACK_GET_OFFSET (vm.variableStack.frames, -arg1 or 0) + (arg2 - 1 or 0), _STACK_POP (vm.mainStack))
                goto DISPATCH
            ::STORE_STATIC::
                vm.static[arg2] = _STACK_POP (vm.mainStack)
                goto DISPATCH
            ::STORE_VOID::
                _STACK_POP (vm.mainStack)
                goto DISPATCH
            ::TABLE_NEW::
                _STACK_PUSH (vm.mainStack, table.new (0, arg1))
                goto DISPATCH
            ::TABLE_ADD::
                TABLE_ADD (vm, arg1, arg2)
                goto DISPATCH
            ::TABLE_SET::
                do
                    local t = _STACK_POP (vm.mainStack)
                    local key = _STACK_POP (vm.mainStack)
                    local value = _STACK_POP (vm.mainStack)
                    if not t.table[key] then
                        table.insert (t.keys, key)
                        if t.meta.table.setindex then
                            local meta = t.meta.table.setindex
                            local args = {key, value}
                            local _ret5
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, args)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret5 = callResult
                                    goto _inline_end22
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end22::
                            value = _ret5
                        end
                    end
                    key = tonumber (key) or key
                    t.table[key] = value
                end
                goto DISPATCH
            ::TABLE_INDEX::
                do
                    local t = _STACK_POP (vm.mainStack)
                    local key = _STACK_POP (vm.mainStack)
                    key = tonumber (key) or key
                    if key == vm.empty then
                        if arg1 == 1 then
                            _STACK_PUSH (vm.mainStack, vm.empty)
                        else
                            vm.err = "Cannot use empty as key."
                        end
                    else
                        local _ret7
                        _ret7 = type (t) == "table" and (t == vm.empty or t.type) or type (t)
                        goto _inline_end36
                        ::_inline_end36::
                        local tt = _ret7
                        if tt ~= "table" then
                            if arg1 == 1 then
                                _STACK_PUSH (vm.mainStack, vm.empty)
                            else
                                vm.err = "Try to index a '" .. tt .. "' value."
                            end
                        else
                            local value = t.table[key]
                            if value then
                                _STACK_PUSH (vm.mainStack, value)
                            else
                                if arg1 == 1 then
                                    _STACK_PUSH (vm.mainStack, vm.empty)
                                elseif t.meta.table.getindex then
                                    local meta = t.meta.table.getindex
                                    local args = {key}
                                    local _ret6
                                    table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                    if #vm.chunk.callstack <= 1000 then
                                        local success, callResult, cip, source = vm.plume.run (meta, args)
                                        if success then
                                            table.remove (vm.chunk.callstack)
                                            _ret6 = callResult
                                            goto _inline_end31
                                        else
                                            vm.serr = {callResult, cip, (source or meta)}
                                        end
                                    else
                                        vm.err = "stack overflow"
                                    end
                                    ::_inline_end31::
                                    _STACK_PUSH (vm.mainStack, _ret6)
                                else
                                    if tonumber (key)
                                     then
                                        vm.err = "Invalid index '" .. key .. "'."
                                    else
                                        vm.err = "Unregistered key '" .. key .. "'."
                                    end
                                end
                            end
                        end
                    end
                end
                goto DISPATCH
            ::TABLE_INDEX_ACC_SELF::
                do
                    local t = _STACK_GET_FRAMED (vm.mainStack)
                    table.insert (t, "self")
                    table.insert (t, _STACK_GET (vm.mainStack))
                    table.insert (t, false)
                    do
                        local t = _STACK_POP (vm.mainStack)
                        local key = _STACK_POP (vm.mainStack)
                        key = tonumber (key) or key
                        if key == vm.empty then
                            if 0 == 1 then
                                _STACK_PUSH (vm.mainStack, vm.empty)
                            else
                                vm.err = "Cannot use empty as key."
                            end
                        else
                            local _ret9
                            _ret9 = type (t) == "table" and (t == vm.empty or t.type) or type (t)
                            goto _inline_end49
                            ::_inline_end49::
                            local tt = _ret9
                            if tt ~= "table" then
                                if 0 == 1 then
                                    _STACK_PUSH (vm.mainStack, vm.empty)
                                else
                                    vm.err = "Try to index a '" .. tt .. "' value."
                                end
                            else
                                local value = t.table[key]
                                if value then
                                    _STACK_PUSH (vm.mainStack, value)
                                else
                                    if 0 == 1 then
                                        _STACK_PUSH (vm.mainStack, vm.empty)
                                    elseif t.meta.table.getindex then
                                        local meta = t.meta.table.getindex
                                        local args = {key}
                                        local _ret8
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, args)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret8 = callResult
                                                goto _inline_end44
                                            else
                                                vm.serr = {callResult, cip, (source or meta)}
                                            end
                                        else
                                            vm.err = "stack overflow"
                                        end
                                        ::_inline_end44::
                                        _STACK_PUSH (vm.mainStack, _ret8)
                                    else
                                        if tonumber (key)
                                         then
                                            vm.err = "Invalid index '" .. key .. "'."
                                        else
                                            vm.err = "Unregistered key '" .. key .. "'."
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
                    local t = _STACK_POP (vm.mainStack)
                    local key = _STACK_POP (vm.mainStack)
                    local value = _STACK_POP (vm.mainStack)
                    t.meta.table[key] = value
                end
                goto DISPATCH
            ::TABLE_INDEX_META::
                TABLE_INDEX_META (vm, arg1, arg2)
                goto DISPATCH
            ::TABLE_SET_ACC::
                do
                    local t = _STACK_GET_FRAMED (vm.mainStack)
                    table.insert (t, _STACK_POP (vm.mainStack))
                    table.insert (t, _STACK_POP (vm.mainStack))
                    table.insert (t, arg2 == 1)
                end
                goto DISPATCH
            ::TABLE_SET_ACC_META::
                TABLE_SET_ACC_META (vm, arg1, arg2)
                goto DISPATCH
            ::TABLE_EXPAND::
                do
                    local t = _STACK_POP (vm.mainStack)
                    local _ret10
                    _ret10 = type (t) == "table" and (t == vm.empty or t.type) or type (t)
                    goto _inline_end53
                    ::_inline_end53::
                    local tt = _ret10
                    if tt == "table" then
                        for _, item in ipairs (t.table)
                         do
                            _STACK_PUSH (vm.mainStack, item)
                        end
                        local ft = _STACK_GET_FRAMED (vm.mainStack)
                        for _, key in ipairs (t.keys)
                         do
                            table.insert (ft, key)
                            table.insert (ft, t.table[key])
                            table.insert (ft, false)
                        end
                    else
                        vm.err = "Try to expand a '" .. tt .. "' value."
                    end
                end
                goto DISPATCH
            ::ENTER_SCOPE::
                _STACK_PUSH (vm.variableStack.frames, _STACK_POS (vm.variableStack) + 1 - arg1)
                for i = 1, arg2 - arg1 do
                    _STACK_PUSH (vm.variableStack, vm.empty)
                end
                goto DISPATCH
            ::LEAVE_SCOPE::
                vm.variableStack.pointer = _STACK_POP (vm.variableStack.frames) - 1
                goto DISPATCH
            ::BEGIN_ACC::
                _STACK_PUSH (vm.mainStack.frames, vm.mainStack.pointer + 1)
                goto DISPATCH
            ::ACC_TABLE::
                do
                    local limit = _STACK_GET (vm.mainStack.frames) + 1
                    local current = _STACK_POS (vm.mainStack)
                    local t = _STACK_GET (vm.mainStack, limit - 1)
                    local keyCount = #t / 2
                    local args = vm.plume.obj.table (current - limit + 1, keyCount)
                    for i = 1, current - limit + 1 do
                        args.table[i] = _STACK_GET (vm.mainStack, limit + i - 1)
                    end
                    for i = 1, #t, 3 do
                        if t[i + 2] then
                            do
                                local _ret11, _ret12
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
                                            _ret11, _ret12 = false, "Wrong number of positionnal parameters for meta-macro '" .. t[i] .. "', " .. t[i + 1].positionalParamCount .. " instead of " .. expectedParamCount .. "."
                                            goto _inline_end62
                                        end
                                        if t[i + 1].namedParamCount > 1 then
                                            _ret11, _ret12 = false, "Meta-macro '" .. t[i] .. "' dont support named parameters."
                                            goto _inline_end62
                                        end
                                    elseif t[i] ~= "call" and t[i] ~= "tostring" and t[i] ~= "tonumber" and t[i] ~= "getindex" and t[i] ~= "setindex" and t[i] ~= "next" and t[i] ~= "iter" then
                                        _ret11, _ret12 = false, "'" .. t[i] .. "' isn't a valid meta-macro name."
                                        goto _inline_end62
                                    end
                                    _ret11, _ret12 = true
                                    goto _inline_end62
                                end
                                ::_inline_end62::
                                local success, err = _ret11, _ret12
                                if success then
                                    args.meta.table[t[i]] = t[i + 1]
                                else
                                    vm.err = err
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
                    vm.mainStack.pointer = limit - 2
                    _STACK_PUSH (vm.mainStack, args)
                    _STACK_POP (vm.mainStack.frames)
                end
                goto DISPATCH
            ::ACC_TEXT::
                do
                    local start = _STACK_GET (vm.mainStack.frames)
                    local stop = _STACK_POS (vm.mainStack)
                    for i = start, stop do
                        if _STACK_GET (vm.mainStack, i) == vm.empty then
                            _STACK_SET (vm.mainStack, i, "")
                        end
                    end
                    local acc_text = table.concat (vm.mainStack, "", start, stop)
                    vm.mainStack.pointer = start
                    _STACK_SET (vm.mainStack, start, acc_text)
                    _STACK_POP (vm.mainStack.frames)
                end
                goto DISPATCH
            ::ACC_EMPTY::
                _STACK_PUSH (vm.mainStack, vm.empty)
                _STACK_POP (vm.mainStack.frames)
                goto DISPATCH
            ::ACC_CALL::
                do
                    local tocall = _STACK_POP (vm.mainStack)
                    local _ret13
                    _ret13 = type (tocall) == "table" and (tocall == vm.empty or tocall.type) or type (tocall)
                    goto _inline_end73
                    ::_inline_end73::
                    local t = _ret13
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
                            local argcount = _STACK_POS (vm.mainStack) - _STACK_GET (vm.mainStack.frames)
                            if argcount ~= tocall.positionalParamCount and tocall.variadicOffset == 0 then
                                local name
                                if vm.chunk.mapping[vm.ip - 1] then
                                    name = vm.chunk.mapping[vm.ip - 1].content
                                end
                                if not name then
                                    name = tocall.name or "???"
                                end
                                vm.err = "Wrong number of positionnal arguments for macro '" .. name .. "', " .. argcount .. " instead of " .. tocall.positionalParamCount .. "."
                            end
                            for i = 1, tocall.positionalParamCount do
                                arguments[i] = _STACK_GET_OFFSET (vm.mainStack, i - argcount)
                            end
                            for i = tocall.positionalParamCount + 1, argcount do
                                table.insert (capture.table, _STACK_GET_OFFSET (vm.mainStack, i - argcount))
                            end
                            vm.mainStack.pointer = _STACK_GET (vm.mainStack.frames)
                        end
                        do
                            local stack_bottom = _STACK_GET_FRAMED (vm.mainStack)
                            local err
                            for i = 1, #stack_bottom, 3 do
                                local k = stack_bottom[i]
                                local v = stack_bottom[i + 1]
                                local m = stack_bottom[i + 2]
                                local j = tocall.namedParamOffset[k]
                                if m then
                                    do
                                        local _ret14, _ret15
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
                                                    _ret14, _ret15 = false, "Wrong number of positionnal parameters for meta-macro '" .. k .. "', " .. v.positionalParamCount .. " instead of " .. expectedParamCount .. "."
                                                    goto _inline_end80
                                                end
                                                if v.namedParamCount > 1 then
                                                    _ret14, _ret15 = false, "Meta-macro '" .. k .. "' dont support named parameters."
                                                    goto _inline_end80
                                                end
                                            elseif k ~= "call" and k ~= "tostring" and k ~= "tonumber" and k ~= "getindex" and k ~= "setindex" and k ~= "next" and k ~= "iter" then
                                                _ret14, _ret15 = false, "'" .. k .. "' isn't a valid meta-macro name."
                                                goto _inline_end80
                                            end
                                            _ret14, _ret15 = true
                                            goto _inline_end80
                                        end
                                        ::_inline_end80::
                                        local success, err = _ret14, _ret15
                                        if success then
                                            capture.meta.table[k] = v
                                        else
                                            vm.err = err
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
                                vm.err = err
                            else
                                _STACK_POP (vm.mainStack)
                            end
                        end
                        if self then
                            table.insert (arguments, self)
                        end
                        if tocall.variadicOffset > 0 then
                            arguments[tocall.variadicOffset] = capture
                        end
                        _STACK_POP (vm.mainStack.frames)
                        local _ret16
                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = tocall, ip = vm.ip})
                        if #vm.chunk.callstack <= 1000 then
                            local success, callResult, cip, source = vm.plume.run (tocall, arguments)
                            if success then
                                table.remove (vm.chunk.callstack)
                                _ret16 = callResult
                                goto _inline_end85
                            else
                                vm.serr = {callResult, cip, (source or tocall)}
                            end
                        else
                            vm.err = "stack overflow"
                        end
                        ::_inline_end85::
                        _STACK_PUSH (vm.mainStack, _ret16)
                    elseif t == "luaFunction" then
                        do
                            local limit = _STACK_GET (vm.mainStack.frames) + 1
                            local current = _STACK_POS (vm.mainStack)
                            local t = _STACK_GET (vm.mainStack, limit - 1)
                            local keyCount = #t / 2
                            local args = vm.plume.obj.table (current - limit + 1, keyCount)
                            for i = 1, current - limit + 1 do
                                args.table[i] = _STACK_GET (vm.mainStack, limit + i - 1)
                            end
                            for i = 1, #t, 3 do
                                if t[i + 2] then
                                    do
                                        local _ret17, _ret18
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
                                                    _ret17, _ret18 = false, "Wrong number of positionnal parameters for meta-macro '" .. t[i] .. "', " .. t[i + 1].positionalParamCount .. " instead of " .. expectedParamCount .. "."
                                                    goto _inline_end90
                                                end
                                                if t[i + 1].namedParamCount > 1 then
                                                    _ret17, _ret18 = false, "Meta-macro '" .. t[i] .. "' dont support named parameters."
                                                    goto _inline_end90
                                                end
                                            elseif t[i] ~= "call" and t[i] ~= "tostring" and t[i] ~= "tonumber" and t[i] ~= "getindex" and t[i] ~= "setindex" and t[i] ~= "next" and t[i] ~= "iter" then
                                                _ret17, _ret18 = false, "'" .. t[i] .. "' isn't a valid meta-macro name."
                                                goto _inline_end90
                                            end
                                            _ret17, _ret18 = true
                                            goto _inline_end90
                                        end
                                        ::_inline_end90::
                                        local success, err = _ret17, _ret18
                                        if success then
                                            args.meta.table[t[i]] = t[i + 1]
                                        else
                                            vm.err = err
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
                            vm.mainStack.pointer = limit - 2
                            _STACK_PUSH (vm.mainStack, args)
                            _STACK_POP (vm.mainStack.frames)
                        end
                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = tocall, ip = vm.ip})
                        local success, result = pcall (tocall.callable, _STACK_GET (vm.mainStack)
                        , vm.chunk)
                        if success then
                            table.remove (vm.chunk.callstack)
                            if result == nil then
                                result = vm.empty
                            end
                            _STACK_POP (vm.mainStack)
                            _STACK_PUSH (vm.mainStack, result)
                        else
                            vm.err = result
                        end
                    else
                        vm.err = "Try to call a '" .. t .. "' value"
                    end
                end
                goto DISPATCH
            ::ACC_CHECK_TEXT::
                do
                    local value = _STACK_GET (vm.mainStack)
                    local _ret19
                    _ret19 = type (value) == "table" and (value == vm.empty or value.type) or type (value)
                    goto _inline_end98
                    ::_inline_end98::
                    local t = _ret19
                    if t ~= "number" and t ~= "string" and value ~= vm.empty then
                        if t == "table" and value.meta.table.tostring then
                            local meta = value.meta.table.tostring
                            local args = {}
                            local _ret20
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, args)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret20 = callResult
                                    goto _inline_end99
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end99::
                            _STACK_SET (vm.mainStack, _STACK_POS (vm.mainStack)
                            , _ret20)
                        else
                            vm.err = "Cannot concat a '" .. t .. "' value."
                        end
                    end
                end
                goto DISPATCH
            ::JUMP_IF::
                do
                    local test = _STACK_POP (vm.mainStack)
                    local _ret21
                    if test == vm.empty then
                        _ret21 = false
                        goto _inline_end104
                    end
                    _ret21 = test
                    goto _inline_end104
                    ::_inline_end104::
                    if _ret21 then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::JUMP_IF_NOT::
                do
                    local test = _STACK_POP (vm.mainStack)
                    local _ret22
                    if test == vm.empty then
                        _ret22 = false
                        goto _inline_end106
                    end
                    _ret22 = test
                    goto _inline_end106
                    ::_inline_end106::
                    if not _ret22 then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::JUMP_IF_NOT_EMPTY::
                do
                    local test = _STACK_POP (vm.mainStack)
                    if test ~= vm.empty then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::JUMP::
                vm.jump = arg2
                goto DISPATCH
            ::JUMP_IF_PEEK::
                do
                    local test = _STACK_GET (vm.mainStack)
                    local _ret23
                    if test == vm.empty then
                        _ret23 = false
                        goto _inline_end110
                    end
                    _ret23 = test
                    goto _inline_end110
                    ::_inline_end110::
                    if _ret23 then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::JUMP_IF_NOT_PEEK::
                do
                    local test = _STACK_GET (vm.mainStack)
                    local _ret24
                    if test == vm.empty then
                        _ret24 = false
                        goto _inline_end112
                    end
                    _ret24 = test
                    goto _inline_end112
                    ::_inline_end112::
                    if not _ret24 then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::GET_ITER::
                do
                    local obj = _STACK_POP (vm.mainStack)
                    local _ret25
                    _ret25 = type (obj) == "table" and (obj == vm.empty or obj.type) or type (obj)
                    goto _inline_end114
                    ::_inline_end114::
                    local tobj = _ret25
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
                            local _ret26
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = iter, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (iter, {obj})
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret26 = callResult
                                    goto _inline_end115
                                else
                                    vm.serr = {callResult, cip, (source or iter)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end115::
                            value = _ret26
                        end
                        _STACK_PUSH (vm.mainStack, value)
                    else
                        vm.err = "Try to iterate over a non-table '" .. tobj .. "' value."
                    end
                end
                goto DISPATCH
            ::FOR_ITER::
                do
                    local obj = _STACK_POP (vm.mainStack)
                    local iter = obj.meta.table.next
                    local result
                    if iter.type == "luaFunction" then
                        result = iter.callable ()
                    else
                        local _ret27
                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = iter, ip = vm.ip})
                        if #vm.chunk.callstack <= 1000 then
                            local success, callResult, cip, source = vm.plume.run (iter, {obj})
                            if success then
                                table.remove (vm.chunk.callstack)
                                _ret27 = callResult
                                goto _inline_end120
                            else
                                vm.serr = {callResult, cip, (source or iter)}
                            end
                        else
                            vm.err = "stack overflow"
                        end
                        ::_inline_end120::
                        result = _ret27
                    end
                    if result == vm.empty then
                        vm.jump = arg2
                    else
                        _STACK_PUSH (vm.mainStack, result)
                    end
                end
                goto DISPATCH
            ::OPP_ADD::
                do
                    local right = _STACK_POP (vm.mainStack)
                    local left = _STACK_POP (vm.mainStack)
                    local rerr, lerr, success, result
                    local _ret28, _ret29
                    do
                        local _ret30
                        _ret30 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end127
                        ::_inline_end127::
                        local tx = _ret30
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret28, _ret29 = right, "Cannot convert the string value to a number."
                                goto _inline_end126
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                local _ret31
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret31 = callResult
                                        goto _inline_end128
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end128::
                                _ret28, _ret29 = _ret31
                                goto _inline_end126
                            else
                                _ret28, _ret29 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end126
                            end
                        end
                        _ret28, _ret29 = right
                        goto _inline_end126
                    end
                    ::_inline_end126::
                    right, rerr = _ret28, _ret29
                    local _ret32, _ret33
                    do
                        local _ret34
                        _ret34 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end132
                        ::_inline_end132::
                        local tx = _ret34
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret32, _ret33 = left, "Cannot convert the string value to a number."
                                goto _inline_end131
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                local _ret35
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret35 = callResult
                                        goto _inline_end133
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end133::
                                _ret32, _ret33 = _ret35
                                goto _inline_end131
                            else
                                _ret32, _ret33 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end131
                            end
                        end
                        _ret32, _ret33 = left
                        goto _inline_end131
                    end
                    ::_inline_end131::
                    left, lerr = _ret32, _ret33
                    if lerr or rerr then
                        local _ret36, _ret37
                        do
                            local meta, params
                            local _ret38
                            _ret38 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                            goto _inline_end137
                            ::_inline_end137::
                            local tleft = _ret38
                            local _ret39
                            _ret39 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                            goto _inline_end138
                            ::_inline_end138::
                            local tright = _ret39
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
                                _ret36 = false
                                goto _inline_end136
                            end
                            local _ret40
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret40 = callResult
                                    goto _inline_end139
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end139::
                            _ret36, _ret37 = true, _ret40
                            goto _inline_end136
                        end
                        ::_inline_end136::
                        success, result = _ret36, _ret37
                    else
                        success = true
                        local _ret41
                        _ret41 = left + right
                        goto _inline_end142
                        ::_inline_end142::
                        result = _ret41
                    end
                    if success then
                        _STACK_PUSH (vm.mainStack, result)
                    else
                        vm.err = lerr or rerr
                    end
                end
                goto DISPATCH
            ::OPP_MUL::
                do
                    local right = _STACK_POP (vm.mainStack)
                    local left = _STACK_POP (vm.mainStack)
                    local rerr, lerr, success, result
                    local _ret42, _ret43
                    do
                        local _ret44
                        _ret44 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end147
                        ::_inline_end147::
                        local tx = _ret44
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret42, _ret43 = right, "Cannot convert the string value to a number."
                                goto _inline_end146
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                local _ret45
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret45 = callResult
                                        goto _inline_end148
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end148::
                                _ret42, _ret43 = _ret45
                                goto _inline_end146
                            else
                                _ret42, _ret43 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end146
                            end
                        end
                        _ret42, _ret43 = right
                        goto _inline_end146
                    end
                    ::_inline_end146::
                    right, rerr = _ret42, _ret43
                    local _ret46, _ret47
                    do
                        local _ret48
                        _ret48 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end152
                        ::_inline_end152::
                        local tx = _ret48
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret46, _ret47 = left, "Cannot convert the string value to a number."
                                goto _inline_end151
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                local _ret49
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret49 = callResult
                                        goto _inline_end153
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end153::
                                _ret46, _ret47 = _ret49
                                goto _inline_end151
                            else
                                _ret46, _ret47 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end151
                            end
                        end
                        _ret46, _ret47 = left
                        goto _inline_end151
                    end
                    ::_inline_end151::
                    left, lerr = _ret46, _ret47
                    if lerr or rerr then
                        local _ret50, _ret51
                        do
                            local meta, params
                            local _ret52
                            _ret52 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                            goto _inline_end157
                            ::_inline_end157::
                            local tleft = _ret52
                            local _ret53
                            _ret53 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                            goto _inline_end158
                            ::_inline_end158::
                            local tright = _ret53
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
                                _ret50 = false
                                goto _inline_end156
                            end
                            local _ret54
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret54 = callResult
                                    goto _inline_end159
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end159::
                            _ret50, _ret51 = true, _ret54
                            goto _inline_end156
                        end
                        ::_inline_end156::
                        success, result = _ret50, _ret51
                    else
                        success = true
                        local _ret55
                        _ret55 = left * right
                        goto _inline_end162
                        ::_inline_end162::
                        result = _ret55
                    end
                    if success then
                        _STACK_PUSH (vm.mainStack, result)
                    else
                        vm.err = lerr or rerr
                    end
                end
                goto DISPATCH
            ::OPP_SUB::
                do
                    local right = _STACK_POP (vm.mainStack)
                    local left = _STACK_POP (vm.mainStack)
                    local rerr, lerr, success, result
                    local _ret56, _ret57
                    do
                        local _ret58
                        _ret58 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end167
                        ::_inline_end167::
                        local tx = _ret58
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret56, _ret57 = right, "Cannot convert the string value to a number."
                                goto _inline_end166
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                local _ret59
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret59 = callResult
                                        goto _inline_end168
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end168::
                                _ret56, _ret57 = _ret59
                                goto _inline_end166
                            else
                                _ret56, _ret57 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end166
                            end
                        end
                        _ret56, _ret57 = right
                        goto _inline_end166
                    end
                    ::_inline_end166::
                    right, rerr = _ret56, _ret57
                    local _ret60, _ret61
                    do
                        local _ret62
                        _ret62 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end172
                        ::_inline_end172::
                        local tx = _ret62
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret60, _ret61 = left, "Cannot convert the string value to a number."
                                goto _inline_end171
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                local _ret63
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret63 = callResult
                                        goto _inline_end173
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end173::
                                _ret60, _ret61 = _ret63
                                goto _inline_end171
                            else
                                _ret60, _ret61 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end171
                            end
                        end
                        _ret60, _ret61 = left
                        goto _inline_end171
                    end
                    ::_inline_end171::
                    left, lerr = _ret60, _ret61
                    if lerr or rerr then
                        local _ret64, _ret65
                        do
                            local meta, params
                            local _ret66
                            _ret66 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                            goto _inline_end177
                            ::_inline_end177::
                            local tleft = _ret66
                            local _ret67
                            _ret67 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                            goto _inline_end178
                            ::_inline_end178::
                            local tright = _ret67
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
                                _ret64 = false
                                goto _inline_end176
                            end
                            local _ret68
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret68 = callResult
                                    goto _inline_end179
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end179::
                            _ret64, _ret65 = true, _ret68
                            goto _inline_end176
                        end
                        ::_inline_end176::
                        success, result = _ret64, _ret65
                    else
                        success = true
                        local _ret69
                        _ret69 = left - right
                        goto _inline_end182
                        ::_inline_end182::
                        result = _ret69
                    end
                    if success then
                        _STACK_PUSH (vm.mainStack, result)
                    else
                        vm.err = lerr or rerr
                    end
                end
                goto DISPATCH
            ::OPP_DIV::
                do
                    local right = _STACK_POP (vm.mainStack)
                    local left = _STACK_POP (vm.mainStack)
                    local rerr, lerr, success, result
                    local _ret70, _ret71
                    do
                        local _ret72
                        _ret72 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end187
                        ::_inline_end187::
                        local tx = _ret72
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret70, _ret71 = right, "Cannot convert the string value to a number."
                                goto _inline_end186
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                local _ret73
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret73 = callResult
                                        goto _inline_end188
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end188::
                                _ret70, _ret71 = _ret73
                                goto _inline_end186
                            else
                                _ret70, _ret71 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end186
                            end
                        end
                        _ret70, _ret71 = right
                        goto _inline_end186
                    end
                    ::_inline_end186::
                    right, rerr = _ret70, _ret71
                    local _ret74, _ret75
                    do
                        local _ret76
                        _ret76 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end192
                        ::_inline_end192::
                        local tx = _ret76
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret74, _ret75 = left, "Cannot convert the string value to a number."
                                goto _inline_end191
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                local _ret77
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret77 = callResult
                                        goto _inline_end193
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end193::
                                _ret74, _ret75 = _ret77
                                goto _inline_end191
                            else
                                _ret74, _ret75 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end191
                            end
                        end
                        _ret74, _ret75 = left
                        goto _inline_end191
                    end
                    ::_inline_end191::
                    left, lerr = _ret74, _ret75
                    if lerr or rerr then
                        local _ret78, _ret79
                        do
                            local meta, params
                            local _ret80
                            _ret80 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                            goto _inline_end197
                            ::_inline_end197::
                            local tleft = _ret80
                            local _ret81
                            _ret81 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                            goto _inline_end198
                            ::_inline_end198::
                            local tright = _ret81
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
                                _ret78 = false
                                goto _inline_end196
                            end
                            local _ret82
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret82 = callResult
                                    goto _inline_end199
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end199::
                            _ret78, _ret79 = true, _ret82
                            goto _inline_end196
                        end
                        ::_inline_end196::
                        success, result = _ret78, _ret79
                    else
                        success = true
                        local _ret83
                        _ret83 = left / right
                        goto _inline_end202
                        ::_inline_end202::
                        result = _ret83
                    end
                    if success then
                        _STACK_PUSH (vm.mainStack, result)
                    else
                        vm.err = lerr or rerr
                    end
                end
                goto DISPATCH
            ::OPP_NEG::
                do
                    local x = _STACK_POP (vm.mainStack)
                    local err
                    local _ret84, _ret85
                    do
                        local _ret86
                        _ret86 = type (x) == "table" and (x == vm.empty or x.type) or type (x)
                        goto _inline_end207
                        ::_inline_end207::
                        local tx = _ret86
                        if tx == "string" then
                            x = tonumber (x)
                            if not x then
                                _ret84, _ret85 = x, "Cannot convert the string value to a number."
                                goto _inline_end206
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and x.meta.table.tonumber then
                                local meta = x.meta.table.tonumber
                                local params = {}
                                local _ret87
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret87 = callResult
                                        goto _inline_end208
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end208::
                                _ret84, _ret85 = _ret87
                                goto _inline_end206
                            else
                                _ret84, _ret85 = x, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end206
                            end
                        end
                        _ret84, _ret85 = x
                        goto _inline_end206
                    end
                    ::_inline_end206::
                    x, err = _ret84, _ret85
                    if err then
                        local _ret88, _ret89
                        do
                            local meta
                            local params = {x}
                            local _ret90
                            _ret90 = type (x) == "table" and (x == vm.empty or x.type) or type (x)
                            goto _inline_end212
                            ::_inline_end212::
                            if _ret90 == "table" and x.meta and x.meta.table.minus then
                                meta = x.meta.table.minus
                            end
                            if not meta then
                                _ret88 = false
                                goto _inline_end211
                            end
                            local _ret91
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret91 = callResult
                                    goto _inline_end213
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end213::
                            _ret88, _ret89 = true, _ret91
                            goto _inline_end211
                        end
                        ::_inline_end211::
                        success, result = _ret88, _ret89
                    else
                        success = true
                        local _ret92
                        _ret92 = -x
                        goto _inline_end216
                        ::_inline_end216::
                        result = _ret92
                    end
                    if success then
                        _STACK_PUSH (vm.mainStack, result)
                    else
                        vm.err = err
                    end
                end
                goto DISPATCH
            ::OPP_MOD::
                do
                    local right = _STACK_POP (vm.mainStack)
                    local left = _STACK_POP (vm.mainStack)
                    local rerr, lerr, success, result
                    local _ret93, _ret94
                    do
                        local _ret95
                        _ret95 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end221
                        ::_inline_end221::
                        local tx = _ret95
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret93, _ret94 = right, "Cannot convert the string value to a number."
                                goto _inline_end220
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                local _ret96
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret96 = callResult
                                        goto _inline_end222
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end222::
                                _ret93, _ret94 = _ret96
                                goto _inline_end220
                            else
                                _ret93, _ret94 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end220
                            end
                        end
                        _ret93, _ret94 = right
                        goto _inline_end220
                    end
                    ::_inline_end220::
                    right, rerr = _ret93, _ret94
                    local _ret97, _ret98
                    do
                        local _ret99
                        _ret99 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end226
                        ::_inline_end226::
                        local tx = _ret99
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret97, _ret98 = left, "Cannot convert the string value to a number."
                                goto _inline_end225
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                local _ret100
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret100 = callResult
                                        goto _inline_end227
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end227::
                                _ret97, _ret98 = _ret100
                                goto _inline_end225
                            else
                                _ret97, _ret98 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end225
                            end
                        end
                        _ret97, _ret98 = left
                        goto _inline_end225
                    end
                    ::_inline_end225::
                    left, lerr = _ret97, _ret98
                    if lerr or rerr then
                        local _ret101, _ret102
                        do
                            local meta, params
                            local _ret103
                            _ret103 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                            goto _inline_end231
                            ::_inline_end231::
                            local tleft = _ret103
                            local _ret104
                            _ret104 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                            goto _inline_end232
                            ::_inline_end232::
                            local tright = _ret104
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
                                _ret101 = false
                                goto _inline_end230
                            end
                            local _ret105
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret105 = callResult
                                    goto _inline_end233
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end233::
                            _ret101, _ret102 = true, _ret105
                            goto _inline_end230
                        end
                        ::_inline_end230::
                        success, result = _ret101, _ret102
                    else
                        success = true
                        local _ret106
                        _ret106 = left % right
                        goto _inline_end236
                        ::_inline_end236::
                        result = _ret106
                    end
                    if success then
                        _STACK_PUSH (vm.mainStack, result)
                    else
                        vm.err = lerr or rerr
                    end
                end
                goto DISPATCH
            ::OPP_POW::
                do
                    local right = _STACK_POP (vm.mainStack)
                    local left = _STACK_POP (vm.mainStack)
                    local rerr, lerr, success, result
                    local _ret107, _ret108
                    do
                        local _ret109
                        _ret109 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end241
                        ::_inline_end241::
                        local tx = _ret109
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret107, _ret108 = right, "Cannot convert the string value to a number."
                                goto _inline_end240
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                local _ret110
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret110 = callResult
                                        goto _inline_end242
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end242::
                                _ret107, _ret108 = _ret110
                                goto _inline_end240
                            else
                                _ret107, _ret108 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end240
                            end
                        end
                        _ret107, _ret108 = right
                        goto _inline_end240
                    end
                    ::_inline_end240::
                    right, rerr = _ret107, _ret108
                    local _ret111, _ret112
                    do
                        local _ret113
                        _ret113 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end246
                        ::_inline_end246::
                        local tx = _ret113
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret111, _ret112 = left, "Cannot convert the string value to a number."
                                goto _inline_end245
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                local _ret114
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret114 = callResult
                                        goto _inline_end247
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end247::
                                _ret111, _ret112 = _ret114
                                goto _inline_end245
                            else
                                _ret111, _ret112 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end245
                            end
                        end
                        _ret111, _ret112 = left
                        goto _inline_end245
                    end
                    ::_inline_end245::
                    left, lerr = _ret111, _ret112
                    if lerr or rerr then
                        local _ret115, _ret116
                        do
                            local meta, params
                            local _ret117
                            _ret117 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                            goto _inline_end251
                            ::_inline_end251::
                            local tleft = _ret117
                            local _ret118
                            _ret118 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                            goto _inline_end252
                            ::_inline_end252::
                            local tright = _ret118
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
                                _ret115 = false
                                goto _inline_end250
                            end
                            local _ret119
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret119 = callResult
                                    goto _inline_end253
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end253::
                            _ret115, _ret116 = true, _ret119
                            goto _inline_end250
                        end
                        ::_inline_end250::
                        success, result = _ret115, _ret116
                    else
                        success = true
                        local _ret120
                        _ret120 = left ^ right
                        goto _inline_end256
                        ::_inline_end256::
                        result = _ret120
                    end
                    if success then
                        _STACK_PUSH (vm.mainStack, result)
                    else
                        vm.err = lerr or rerr
                    end
                end
                goto DISPATCH
            ::OPP_LT::
                do
                    local right = _STACK_POP (vm.mainStack)
                    local left = _STACK_POP (vm.mainStack)
                    local rerr, lerr, success, result
                    local _ret121, _ret122
                    do
                        local _ret123
                        _ret123 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end261
                        ::_inline_end261::
                        local tx = _ret123
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret121, _ret122 = right, "Cannot convert the string value to a number."
                                goto _inline_end260
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                local _ret124
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret124 = callResult
                                        goto _inline_end262
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end262::
                                _ret121, _ret122 = _ret124
                                goto _inline_end260
                            else
                                _ret121, _ret122 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end260
                            end
                        end
                        _ret121, _ret122 = right
                        goto _inline_end260
                    end
                    ::_inline_end260::
                    right, rerr = _ret121, _ret122
                    local _ret125, _ret126
                    do
                        local _ret127
                        _ret127 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end266
                        ::_inline_end266::
                        local tx = _ret127
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret125, _ret126 = left, "Cannot convert the string value to a number."
                                goto _inline_end265
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                local _ret128
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret128 = callResult
                                        goto _inline_end267
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end267::
                                _ret125, _ret126 = _ret128
                                goto _inline_end265
                            else
                                _ret125, _ret126 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end265
                            end
                        end
                        _ret125, _ret126 = left
                        goto _inline_end265
                    end
                    ::_inline_end265::
                    left, lerr = _ret125, _ret126
                    if lerr or rerr then
                        local _ret129, _ret130
                        do
                            local meta, params
                            local _ret131
                            _ret131 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                            goto _inline_end271
                            ::_inline_end271::
                            local tleft = _ret131
                            local _ret132
                            _ret132 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                            goto _inline_end272
                            ::_inline_end272::
                            local tright = _ret132
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
                                _ret129 = false
                                goto _inline_end270
                            end
                            local _ret133
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret133 = callResult
                                    goto _inline_end273
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end273::
                            _ret129, _ret130 = true, _ret133
                            goto _inline_end270
                        end
                        ::_inline_end270::
                        success, result = _ret129, _ret130
                    else
                        success = true
                        local _ret134
                        _ret134 = left < right
                        goto _inline_end276
                        ::_inline_end276::
                        result = _ret134
                    end
                    if success then
                        _STACK_PUSH (vm.mainStack, result)
                    else
                        vm.err = lerr or rerr
                    end
                end
                goto DISPATCH
            ::OPP_EQ::
                do
                    local right = _STACK_POP (vm.mainStack)
                    local left = _STACK_POP (vm.mainStack)
                    local _ret135, _ret136
                    do
                        local meta, params
                        local _ret137
                        _ret137 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end280
                        ::_inline_end280::
                        local tleft = _ret137
                        local _ret138
                        _ret138 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end281
                        ::_inline_end281::
                        local tright = _ret138
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
                            _ret135 = false
                            goto _inline_end279
                        end
                        local _ret139
                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                        if #vm.chunk.callstack <= 1000 then
                            local success, callResult, cip, source = vm.plume.run (meta, params)
                            if success then
                                table.remove (vm.chunk.callstack)
                                _ret139 = callResult
                                goto _inline_end282
                            else
                                vm.serr = {callResult, cip, (source or meta)}
                            end
                        else
                            vm.err = "stack overflow"
                        end
                        ::_inline_end282::
                        _ret135, _ret136 = true, _ret139
                        goto _inline_end279
                    end
                    ::_inline_end279::
                    local success, result = _ret135, _ret136
                    if not success then
                        result = left == right or tonumber (left) and tonumber (left) == tonumber (right)
                    end
                    _STACK_PUSH (vm.mainStack, result)
                end
                goto DISPATCH
            ::OPP_AND::
                do
                    local right = _STACK_POP (vm.mainStack)
                    local left = _STACK_POP (vm.mainStack)
                    local _ret140
                    if right == vm.empty then
                        _ret140 = false
                        goto _inline_end287
                    end
                    _ret140 = right
                    goto _inline_end287
                    ::_inline_end287::
                    right = _ret140
                    local _ret141
                    if left == vm.empty then
                        _ret141 = false
                        goto _inline_end288
                    end
                    _ret141 = left
                    goto _inline_end288
                    ::_inline_end288::
                    left = _ret141
                    local _ret142
                    _ret142 = right and left
                    goto _inline_end289
                    ::_inline_end289::
                    _STACK_PUSH (vm.mainStack, _ret142)
                end
                goto DISPATCH
            ::OPP_NOT::
                do
                    local x = _STACK_POP (vm.mainStack)
                    local _ret143
                    if x == vm.empty then
                        _ret143 = false
                        goto _inline_end292
                    end
                    _ret143 = x
                    goto _inline_end292
                    ::_inline_end292::
                    x = _ret143
                    local _ret144
                    _ret144 = not x
                    goto _inline_end293
                    ::_inline_end293::
                    _STACK_PUSH (vm.mainStack, _ret144)
                end
                goto DISPATCH
            ::OPP_OR::
                do
                    local right = _STACK_POP (vm.mainStack)
                    local left = _STACK_POP (vm.mainStack)
                    local _ret145
                    if right == vm.empty then
                        _ret145 = false
                        goto _inline_end296
                    end
                    _ret145 = right
                    goto _inline_end296
                    ::_inline_end296::
                    right = _ret145
                    local _ret146
                    if left == vm.empty then
                        _ret146 = false
                        goto _inline_end297
                    end
                    _ret146 = left
                    goto _inline_end297
                    ::_inline_end297::
                    left = _ret146
                    local _ret147
                    _ret147 = right or left
                    goto _inline_end298
                    ::_inline_end298::
                    _STACK_PUSH (vm.mainStack, _ret147)
                end
                goto DISPATCH
            ::DUPLICATE::
                _STACK_PUSH (vm.mainStack, _STACK_GET (vm.mainStack))
                goto DISPATCH
            ::SWITCH::
                do
                    local x = _STACK_POP (vm.mainStack)
                    local y = _STACK_POP (vm.mainStack)
                    _STACK_PUSH (vm.mainStack, x)
                    _STACK_PUSH (vm.mainStack, y)
                end
                goto DISPATCH
            ::END::
            return true, _STACK_GET (vm.mainStack)
        end
    end
    