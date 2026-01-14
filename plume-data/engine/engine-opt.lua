return function (plume)
    function plume._run (chunk, arguments)
        do
        end
        do
            function _AND (x, y)
                return x and y
            end
            function _OR (x, y)
                return x or y
            end
            function _NOT (x)
                return not x
            end
        end
        do
        end
        do
            function _VM_INIT_ARGUMENTS (vm, chunk, arguments)
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
            end
        end
        do
        end
        do
        end
        do
        end
        do
            function _META_CHECK (name, macro)
                local comopps = "add mul div sub mod pow"
                local binopps = "eq lt"
                local unopps = "minus"
                local expectedParamCount
                for opp in comopps:gmatch ("%S+")
                 do
                    if name == opp then
                        expectedParamCount = 2
                    elseif name:match ("^" .. opp .. "[rl]")
                         then
                        expectedParamCount = 1
                    end
                end
                for opp in binopps:gmatch ("%S+")
                 do
                    if name == opp then
                        expectedParamCount = 1
                    end
                end
                for opp in unopps:gmatch ("%S+")
                 do
                    if name == opp then
                        expectedParamCount = 0
                    end
                end
                if expectedParamCount then
                    if macro.positionalParamCount ~= expectedParamCount then
                        return false, "Wrong number of positionnal parameters for meta-macro '" .. name .. "', " .. macro.positionalParamCount .. " instead of " .. expectedParamCount .. "."
                    end
                    if macro.namedParamCount > 1 then
                        return false, "Meta-macro '" .. name .. "' dont support named parameters."
                    end
                elseif name ~= "call" and name ~= "tostring" and name ~= "tonumber" and name ~= "getindex" and name ~= "setindex" and name ~= "next" and name ~= "iter" then
                    return false, "'" .. name .. "' isn't a valid meta-macro name."
                end
                return true
            end
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
            function TABLE_EXPAND (vm, arg1, arg2)
                local t = _STACK_POP (vm.mainStack)
                local _ret1
                _ret1 = type (t) == "table" and (t == vm.empty or t.type) or type (t)
                goto _inline_end2
                ::_inline_end2::
                local tt = _ret1
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
        end
        do
        end
        local _ret2
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
            _VM_INIT_ARGUMENTS (vm, chunk, arguments)
            _ret2 = vm
            goto _inline_end4
        end
        ::_inline_end4::
        local vm = _ret2
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
            local _ret3, _ret4, _ret5
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
                _ret3, _ret4, _ret5 = op, arg1, arg2
                goto _inline_end7
            end
            ::_inline_end7::
            op, arg1, arg2 = _ret3, _ret4, _ret5
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
                            local _ret6
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, args)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret6 = callResult
                                    goto _inline_end23
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end23::
                            value = _ret6
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
                        local _ret8
                        _ret8 = type (t) == "table" and (t == vm.empty or t.type) or type (t)
                        goto _inline_end37
                        ::_inline_end37::
                        local tt = _ret8
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
                                    local _ret7
                                    table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                    if #vm.chunk.callstack <= 1000 then
                                        local success, callResult, cip, source = vm.plume.run (meta, args)
                                        if success then
                                            table.remove (vm.chunk.callstack)
                                            _ret7 = callResult
                                            goto _inline_end32
                                        else
                                            vm.serr = {callResult, cip, (source or meta)}
                                        end
                                    else
                                        vm.err = "stack overflow"
                                    end
                                    ::_inline_end32::
                                    _STACK_PUSH (vm.mainStack, _ret7)
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
                            local _ret10
                            _ret10 = type (t) == "table" and (t == vm.empty or t.type) or type (t)
                            goto _inline_end50
                            ::_inline_end50::
                            local tt = _ret10
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
                                        local _ret9
                                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                        if #vm.chunk.callstack <= 1000 then
                                            local success, callResult, cip, source = vm.plume.run (meta, args)
                                            if success then
                                                table.remove (vm.chunk.callstack)
                                                _ret9 = callResult
                                                goto _inline_end45
                                            else
                                                vm.serr = {callResult, cip, (source or meta)}
                                            end
                                        else
                                            vm.err = "stack overflow"
                                        end
                                        ::_inline_end45::
                                        _STACK_PUSH (vm.mainStack, _ret9)
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
                TABLE_EXPAND (vm, arg1, arg2)
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
                                local success, err = _META_CHECK (t[i], t[i + 1])
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
                    local _ret11
                    _ret11 = type (tocall) == "table" and (tocall == vm.empty or tocall.type) or type (tocall)
                    goto _inline_end70
                    ::_inline_end70::
                    local t = _ret11
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
                                        local success, err = _META_CHECK (k, v)
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
                        local _ret12
                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = tocall, ip = vm.ip})
                        if #vm.chunk.callstack <= 1000 then
                            local success, callResult, cip, source = vm.plume.run (tocall, arguments)
                            if success then
                                table.remove (vm.chunk.callstack)
                                _ret12 = callResult
                                goto _inline_end81
                            else
                                vm.serr = {callResult, cip, (source or tocall)}
                            end
                        else
                            vm.err = "stack overflow"
                        end
                        ::_inline_end81::
                        _STACK_PUSH (vm.mainStack, _ret12)
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
                                        local success, err = _META_CHECK (t[i], t[i + 1])
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
                    local _ret13
                    _ret13 = type (value) == "table" and (value == vm.empty or value.type) or type (value)
                    goto _inline_end93
                    ::_inline_end93::
                    local t = _ret13
                    if t ~= "number" and t ~= "string" and value ~= vm.empty then
                        if t == "table" and value.meta.table.tostring then
                            local meta = value.meta.table.tostring
                            local args = {}
                            local _ret14
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, args)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret14 = callResult
                                    goto _inline_end94
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end94::
                            _STACK_SET (vm.mainStack, _STACK_POS (vm.mainStack)
                            , _ret14)
                        else
                            vm.err = "Cannot concat a '" .. t .. "' value."
                        end
                    end
                end
                goto DISPATCH
            ::JUMP_IF::
                do
                    local test = _STACK_POP (vm.mainStack)
                    local _ret15
                    if test == vm.empty then
                        _ret15 = false
                        goto _inline_end99
                    end
                    _ret15 = test
                    goto _inline_end99
                    ::_inline_end99::
                    if _ret15 then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::JUMP_IF_NOT::
                do
                    local test = _STACK_POP (vm.mainStack)
                    local _ret16
                    if test == vm.empty then
                        _ret16 = false
                        goto _inline_end101
                    end
                    _ret16 = test
                    goto _inline_end101
                    ::_inline_end101::
                    if not _ret16 then
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
                    local _ret17
                    if test == vm.empty then
                        _ret17 = false
                        goto _inline_end105
                    end
                    _ret17 = test
                    goto _inline_end105
                    ::_inline_end105::
                    if _ret17 then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::JUMP_IF_NOT_PEEK::
                do
                    local test = _STACK_GET (vm.mainStack)
                    local _ret18
                    if test == vm.empty then
                        _ret18 = false
                        goto _inline_end107
                    end
                    _ret18 = test
                    goto _inline_end107
                    ::_inline_end107::
                    if not _ret18 then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::GET_ITER::
                do
                    local obj = _STACK_POP (vm.mainStack)
                    local _ret19
                    _ret19 = type (obj) == "table" and (obj == vm.empty or obj.type) or type (obj)
                    goto _inline_end109
                    ::_inline_end109::
                    local tobj = _ret19
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
                            local _ret20
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = iter, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (iter, {obj})
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret20 = callResult
                                    goto _inline_end110
                                else
                                    vm.serr = {callResult, cip, (source or iter)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end110::
                            value = _ret20
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
                        local _ret21
                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = iter, ip = vm.ip})
                        if #vm.chunk.callstack <= 1000 then
                            local success, callResult, cip, source = vm.plume.run (iter, {obj})
                            if success then
                                table.remove (vm.chunk.callstack)
                                _ret21 = callResult
                                goto _inline_end115
                            else
                                vm.serr = {callResult, cip, (source or iter)}
                            end
                        else
                            vm.err = "stack overflow"
                        end
                        ::_inline_end115::
                        result = _ret21
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
                    local _ret22, _ret23
                    do
                        local _ret24
                        _ret24 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end122
                        ::_inline_end122::
                        local tx = _ret24
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret22, _ret23 = right, "Cannot convert the string value to a number."
                                goto _inline_end121
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                local _ret25
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret25 = callResult
                                        goto _inline_end123
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end123::
                                _ret22, _ret23 = _ret25
                                goto _inline_end121
                            else
                                _ret22, _ret23 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end121
                            end
                        end
                        _ret22, _ret23 = right
                        goto _inline_end121
                    end
                    ::_inline_end121::
                    right, rerr = _ret22, _ret23
                    local _ret26, _ret27
                    do
                        local _ret28
                        _ret28 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end127
                        ::_inline_end127::
                        local tx = _ret28
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret26, _ret27 = left, "Cannot convert the string value to a number."
                                goto _inline_end126
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                local _ret29
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret29 = callResult
                                        goto _inline_end128
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end128::
                                _ret26, _ret27 = _ret29
                                goto _inline_end126
                            else
                                _ret26, _ret27 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end126
                            end
                        end
                        _ret26, _ret27 = left
                        goto _inline_end126
                    end
                    ::_inline_end126::
                    left, lerr = _ret26, _ret27
                    if lerr or rerr then
                        local _ret30, _ret31
                        do
                            local meta, params
                            local _ret32
                            _ret32 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                            goto _inline_end132
                            ::_inline_end132::
                            local tleft = _ret32
                            local _ret33
                            _ret33 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                            goto _inline_end133
                            ::_inline_end133::
                            local tright = _ret33
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
                                _ret30 = false
                                goto _inline_end131
                            end
                            local _ret34
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret34 = callResult
                                    goto _inline_end134
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end134::
                            _ret30, _ret31 = true, _ret34
                            goto _inline_end131
                        end
                        ::_inline_end131::
                        success, result = _ret30, _ret31
                    else
                        success = true
                        local _ret35
                        _ret35 = left + right
                        goto _inline_end137
                        ::_inline_end137::
                        result = _ret35
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
                    local _ret36, _ret37
                    do
                        local _ret38
                        _ret38 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end142
                        ::_inline_end142::
                        local tx = _ret38
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret36, _ret37 = right, "Cannot convert the string value to a number."
                                goto _inline_end141
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                local _ret39
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret39 = callResult
                                        goto _inline_end143
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end143::
                                _ret36, _ret37 = _ret39
                                goto _inline_end141
                            else
                                _ret36, _ret37 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end141
                            end
                        end
                        _ret36, _ret37 = right
                        goto _inline_end141
                    end
                    ::_inline_end141::
                    right, rerr = _ret36, _ret37
                    local _ret40, _ret41
                    do
                        local _ret42
                        _ret42 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end147
                        ::_inline_end147::
                        local tx = _ret42
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret40, _ret41 = left, "Cannot convert the string value to a number."
                                goto _inline_end146
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                local _ret43
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret43 = callResult
                                        goto _inline_end148
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end148::
                                _ret40, _ret41 = _ret43
                                goto _inline_end146
                            else
                                _ret40, _ret41 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end146
                            end
                        end
                        _ret40, _ret41 = left
                        goto _inline_end146
                    end
                    ::_inline_end146::
                    left, lerr = _ret40, _ret41
                    if lerr or rerr then
                        local _ret44, _ret45
                        do
                            local meta, params
                            local _ret46
                            _ret46 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                            goto _inline_end152
                            ::_inline_end152::
                            local tleft = _ret46
                            local _ret47
                            _ret47 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                            goto _inline_end153
                            ::_inline_end153::
                            local tright = _ret47
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
                                _ret44 = false
                                goto _inline_end151
                            end
                            local _ret48
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret48 = callResult
                                    goto _inline_end154
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end154::
                            _ret44, _ret45 = true, _ret48
                            goto _inline_end151
                        end
                        ::_inline_end151::
                        success, result = _ret44, _ret45
                    else
                        success = true
                        local _ret49
                        _ret49 = left * right
                        goto _inline_end157
                        ::_inline_end157::
                        result = _ret49
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
                    local _ret50, _ret51
                    do
                        local _ret52
                        _ret52 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end162
                        ::_inline_end162::
                        local tx = _ret52
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret50, _ret51 = right, "Cannot convert the string value to a number."
                                goto _inline_end161
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                local _ret53
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret53 = callResult
                                        goto _inline_end163
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end163::
                                _ret50, _ret51 = _ret53
                                goto _inline_end161
                            else
                                _ret50, _ret51 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end161
                            end
                        end
                        _ret50, _ret51 = right
                        goto _inline_end161
                    end
                    ::_inline_end161::
                    right, rerr = _ret50, _ret51
                    local _ret54, _ret55
                    do
                        local _ret56
                        _ret56 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end167
                        ::_inline_end167::
                        local tx = _ret56
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret54, _ret55 = left, "Cannot convert the string value to a number."
                                goto _inline_end166
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                local _ret57
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret57 = callResult
                                        goto _inline_end168
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end168::
                                _ret54, _ret55 = _ret57
                                goto _inline_end166
                            else
                                _ret54, _ret55 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end166
                            end
                        end
                        _ret54, _ret55 = left
                        goto _inline_end166
                    end
                    ::_inline_end166::
                    left, lerr = _ret54, _ret55
                    if lerr or rerr then
                        local _ret58, _ret59
                        do
                            local meta, params
                            local _ret60
                            _ret60 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                            goto _inline_end172
                            ::_inline_end172::
                            local tleft = _ret60
                            local _ret61
                            _ret61 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                            goto _inline_end173
                            ::_inline_end173::
                            local tright = _ret61
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
                                _ret58 = false
                                goto _inline_end171
                            end
                            local _ret62
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret62 = callResult
                                    goto _inline_end174
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end174::
                            _ret58, _ret59 = true, _ret62
                            goto _inline_end171
                        end
                        ::_inline_end171::
                        success, result = _ret58, _ret59
                    else
                        success = true
                        local _ret63
                        _ret63 = left - right
                        goto _inline_end177
                        ::_inline_end177::
                        result = _ret63
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
                    local _ret64, _ret65
                    do
                        local _ret66
                        _ret66 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end182
                        ::_inline_end182::
                        local tx = _ret66
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret64, _ret65 = right, "Cannot convert the string value to a number."
                                goto _inline_end181
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                local _ret67
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret67 = callResult
                                        goto _inline_end183
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end183::
                                _ret64, _ret65 = _ret67
                                goto _inline_end181
                            else
                                _ret64, _ret65 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end181
                            end
                        end
                        _ret64, _ret65 = right
                        goto _inline_end181
                    end
                    ::_inline_end181::
                    right, rerr = _ret64, _ret65
                    local _ret68, _ret69
                    do
                        local _ret70
                        _ret70 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end187
                        ::_inline_end187::
                        local tx = _ret70
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret68, _ret69 = left, "Cannot convert the string value to a number."
                                goto _inline_end186
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                local _ret71
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret71 = callResult
                                        goto _inline_end188
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end188::
                                _ret68, _ret69 = _ret71
                                goto _inline_end186
                            else
                                _ret68, _ret69 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end186
                            end
                        end
                        _ret68, _ret69 = left
                        goto _inline_end186
                    end
                    ::_inline_end186::
                    left, lerr = _ret68, _ret69
                    if lerr or rerr then
                        local _ret72, _ret73
                        do
                            local meta, params
                            local _ret74
                            _ret74 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                            goto _inline_end192
                            ::_inline_end192::
                            local tleft = _ret74
                            local _ret75
                            _ret75 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                            goto _inline_end193
                            ::_inline_end193::
                            local tright = _ret75
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
                                _ret72 = false
                                goto _inline_end191
                            end
                            local _ret76
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret76 = callResult
                                    goto _inline_end194
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end194::
                            _ret72, _ret73 = true, _ret76
                            goto _inline_end191
                        end
                        ::_inline_end191::
                        success, result = _ret72, _ret73
                    else
                        success = true
                        local _ret77
                        _ret77 = left / right
                        goto _inline_end197
                        ::_inline_end197::
                        result = _ret77
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
                    local _ret78, _ret79
                    do
                        local _ret80
                        _ret80 = type (x) == "table" and (x == vm.empty or x.type) or type (x)
                        goto _inline_end202
                        ::_inline_end202::
                        local tx = _ret80
                        if tx == "string" then
                            x = tonumber (x)
                            if not x then
                                _ret78, _ret79 = x, "Cannot convert the string value to a number."
                                goto _inline_end201
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and x.meta.table.tonumber then
                                local meta = x.meta.table.tonumber
                                local params = {}
                                local _ret81
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret81 = callResult
                                        goto _inline_end203
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end203::
                                _ret78, _ret79 = _ret81
                                goto _inline_end201
                            else
                                _ret78, _ret79 = x, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end201
                            end
                        end
                        _ret78, _ret79 = x
                        goto _inline_end201
                    end
                    ::_inline_end201::
                    x, err = _ret78, _ret79
                    if err then
                        local _ret82, _ret83
                        do
                            local meta
                            local params = {x}
                            local _ret84
                            _ret84 = type (x) == "table" and (x == vm.empty or x.type) or type (x)
                            goto _inline_end207
                            ::_inline_end207::
                            if _ret84 == "table" and x.meta and x.meta.table.minus then
                                meta = x.meta.table.minus
                            end
                            if not meta then
                                _ret82 = false
                                goto _inline_end206
                            end
                            local _ret85
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret85 = callResult
                                    goto _inline_end208
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end208::
                            _ret82, _ret83 = true, _ret85
                            goto _inline_end206
                        end
                        ::_inline_end206::
                        success, result = _ret82, _ret83
                    else
                        success = true
                        local _ret86
                        _ret86 = -x
                        goto _inline_end211
                        ::_inline_end211::
                        result = _ret86
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
                    local _ret87, _ret88
                    do
                        local _ret89
                        _ret89 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end216
                        ::_inline_end216::
                        local tx = _ret89
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret87, _ret88 = right, "Cannot convert the string value to a number."
                                goto _inline_end215
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                local _ret90
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret90 = callResult
                                        goto _inline_end217
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end217::
                                _ret87, _ret88 = _ret90
                                goto _inline_end215
                            else
                                _ret87, _ret88 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end215
                            end
                        end
                        _ret87, _ret88 = right
                        goto _inline_end215
                    end
                    ::_inline_end215::
                    right, rerr = _ret87, _ret88
                    local _ret91, _ret92
                    do
                        local _ret93
                        _ret93 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end221
                        ::_inline_end221::
                        local tx = _ret93
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret91, _ret92 = left, "Cannot convert the string value to a number."
                                goto _inline_end220
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                local _ret94
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret94 = callResult
                                        goto _inline_end222
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end222::
                                _ret91, _ret92 = _ret94
                                goto _inline_end220
                            else
                                _ret91, _ret92 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end220
                            end
                        end
                        _ret91, _ret92 = left
                        goto _inline_end220
                    end
                    ::_inline_end220::
                    left, lerr = _ret91, _ret92
                    if lerr or rerr then
                        local _ret95, _ret96
                        do
                            local meta, params
                            local _ret97
                            _ret97 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                            goto _inline_end226
                            ::_inline_end226::
                            local tleft = _ret97
                            local _ret98
                            _ret98 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                            goto _inline_end227
                            ::_inline_end227::
                            local tright = _ret98
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
                                _ret95 = false
                                goto _inline_end225
                            end
                            local _ret99
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret99 = callResult
                                    goto _inline_end228
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end228::
                            _ret95, _ret96 = true, _ret99
                            goto _inline_end225
                        end
                        ::_inline_end225::
                        success, result = _ret95, _ret96
                    else
                        success = true
                        local _ret100
                        _ret100 = left % right
                        goto _inline_end231
                        ::_inline_end231::
                        result = _ret100
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
                    local _ret101, _ret102
                    do
                        local _ret103
                        _ret103 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end236
                        ::_inline_end236::
                        local tx = _ret103
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret101, _ret102 = right, "Cannot convert the string value to a number."
                                goto _inline_end235
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                local _ret104
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret104 = callResult
                                        goto _inline_end237
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end237::
                                _ret101, _ret102 = _ret104
                                goto _inline_end235
                            else
                                _ret101, _ret102 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end235
                            end
                        end
                        _ret101, _ret102 = right
                        goto _inline_end235
                    end
                    ::_inline_end235::
                    right, rerr = _ret101, _ret102
                    local _ret105, _ret106
                    do
                        local _ret107
                        _ret107 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end241
                        ::_inline_end241::
                        local tx = _ret107
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret105, _ret106 = left, "Cannot convert the string value to a number."
                                goto _inline_end240
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                local _ret108
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret108 = callResult
                                        goto _inline_end242
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end242::
                                _ret105, _ret106 = _ret108
                                goto _inline_end240
                            else
                                _ret105, _ret106 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end240
                            end
                        end
                        _ret105, _ret106 = left
                        goto _inline_end240
                    end
                    ::_inline_end240::
                    left, lerr = _ret105, _ret106
                    if lerr or rerr then
                        local _ret109, _ret110
                        do
                            local meta, params
                            local _ret111
                            _ret111 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                            goto _inline_end246
                            ::_inline_end246::
                            local tleft = _ret111
                            local _ret112
                            _ret112 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                            goto _inline_end247
                            ::_inline_end247::
                            local tright = _ret112
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
                                _ret109 = false
                                goto _inline_end245
                            end
                            local _ret113
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret113 = callResult
                                    goto _inline_end248
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end248::
                            _ret109, _ret110 = true, _ret113
                            goto _inline_end245
                        end
                        ::_inline_end245::
                        success, result = _ret109, _ret110
                    else
                        success = true
                        local _ret114
                        _ret114 = left ^ right
                        goto _inline_end251
                        ::_inline_end251::
                        result = _ret114
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
                    local _ret115, _ret116
                    do
                        local _ret117
                        _ret117 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end256
                        ::_inline_end256::
                        local tx = _ret117
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret115, _ret116 = right, "Cannot convert the string value to a number."
                                goto _inline_end255
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                local _ret118
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret118 = callResult
                                        goto _inline_end257
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end257::
                                _ret115, _ret116 = _ret118
                                goto _inline_end255
                            else
                                _ret115, _ret116 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end255
                            end
                        end
                        _ret115, _ret116 = right
                        goto _inline_end255
                    end
                    ::_inline_end255::
                    right, rerr = _ret115, _ret116
                    local _ret119, _ret120
                    do
                        local _ret121
                        _ret121 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end261
                        ::_inline_end261::
                        local tx = _ret121
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret119, _ret120 = left, "Cannot convert the string value to a number."
                                goto _inline_end260
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                local _ret122
                                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                                if #vm.chunk.callstack <= 1000 then
                                    local success, callResult, cip, source = vm.plume.run (meta, params)
                                    if success then
                                        table.remove (vm.chunk.callstack)
                                        _ret122 = callResult
                                        goto _inline_end262
                                    else
                                        vm.serr = {callResult, cip, (source or meta)}
                                    end
                                else
                                    vm.err = "stack overflow"
                                end
                                ::_inline_end262::
                                _ret119, _ret120 = _ret122
                                goto _inline_end260
                            else
                                _ret119, _ret120 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end260
                            end
                        end
                        _ret119, _ret120 = left
                        goto _inline_end260
                    end
                    ::_inline_end260::
                    left, lerr = _ret119, _ret120
                    if lerr or rerr then
                        local _ret123, _ret124
                        do
                            local meta, params
                            local _ret125
                            _ret125 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                            goto _inline_end266
                            ::_inline_end266::
                            local tleft = _ret125
                            local _ret126
                            _ret126 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                            goto _inline_end267
                            ::_inline_end267::
                            local tright = _ret126
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
                                _ret123 = false
                                goto _inline_end265
                            end
                            local _ret127
                            table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                            if #vm.chunk.callstack <= 1000 then
                                local success, callResult, cip, source = vm.plume.run (meta, params)
                                if success then
                                    table.remove (vm.chunk.callstack)
                                    _ret127 = callResult
                                    goto _inline_end268
                                else
                                    vm.serr = {callResult, cip, (source or meta)}
                                end
                            else
                                vm.err = "stack overflow"
                            end
                            ::_inline_end268::
                            _ret123, _ret124 = true, _ret127
                            goto _inline_end265
                        end
                        ::_inline_end265::
                        success, result = _ret123, _ret124
                    else
                        success = true
                        local _ret128
                        _ret128 = left < right
                        goto _inline_end271
                        ::_inline_end271::
                        result = _ret128
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
                    local _ret129, _ret130
                    do
                        local meta, params
                        local _ret131
                        _ret131 = type (left) == "table" and (left == vm.empty or left.type) or type (left)
                        goto _inline_end275
                        ::_inline_end275::
                        local tleft = _ret131
                        local _ret132
                        _ret132 = type (right) == "table" and (right == vm.empty or right.type) or type (right)
                        goto _inline_end276
                        ::_inline_end276::
                        local tright = _ret132
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
                            _ret129 = false
                            goto _inline_end274
                        end
                        local _ret133
                        table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = meta, ip = vm.ip})
                        if #vm.chunk.callstack <= 1000 then
                            local success, callResult, cip, source = vm.plume.run (meta, params)
                            if success then
                                table.remove (vm.chunk.callstack)
                                _ret133 = callResult
                                goto _inline_end277
                            else
                                vm.serr = {callResult, cip, (source or meta)}
                            end
                        else
                            vm.err = "stack overflow"
                        end
                        ::_inline_end277::
                        _ret129, _ret130 = true, _ret133
                        goto _inline_end274
                    end
                    ::_inline_end274::
                    local success, result = _ret129, _ret130
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
                    local _ret134
                    if right == vm.empty then
                        _ret134 = false
                        goto _inline_end282
                    end
                    _ret134 = right
                    goto _inline_end282
                    ::_inline_end282::
                    right = _ret134
                    local _ret135
                    if left == vm.empty then
                        _ret135 = false
                        goto _inline_end283
                    end
                    _ret135 = left
                    goto _inline_end283
                    ::_inline_end283::
                    left = _ret135
                    _STACK_PUSH (vm.mainStack, _AND (right, left))
                end
                goto DISPATCH
            ::OPP_NOT::
                do
                    local x = _STACK_POP (vm.mainStack)
                    local _ret136
                    if x == vm.empty then
                        _ret136 = false
                        goto _inline_end286
                    end
                    _ret136 = x
                    goto _inline_end286
                    ::_inline_end286::
                    x = _ret136
                    _STACK_PUSH (vm.mainStack, _NOT (x))
                end
                goto DISPATCH
            ::OPP_OR::
                do
                    local right = _STACK_POP (vm.mainStack)
                    local left = _STACK_POP (vm.mainStack)
                    local _ret137
                    if right == vm.empty then
                        _ret137 = false
                        goto _inline_end289
                    end
                    _ret137 = right
                    goto _inline_end289
                    ::_inline_end289::
                    right = _ret137
                    local _ret138
                    if left == vm.empty then
                        _ret138 = false
                        goto _inline_end290
                    end
                    _ret138 = left
                    goto _inline_end290
                    ::_inline_end290::
                    left = _ret138
                    _STACK_PUSH (vm.mainStack, _OR (right, left))
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
    