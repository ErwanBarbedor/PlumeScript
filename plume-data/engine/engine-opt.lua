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
            function _CALL (vm, macro, arguments)
                table.insert (vm.chunk.callstack, {chunk = vm.chunk, macro = macro, ip = vm.ip})
                if #vm.chunk.callstack <= 1000 then
                    local success, callResult, cip, source = vm.plume.run (macro, arguments)
                    if success then
                        table.remove (vm.chunk.callstack)
                        return callResult
                    else
                        vm.serr = {callResult, cip, (source or macro)}
                    end
                else
                    vm.err = "stack overflow"
                end
            end
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
                local tt = _GET_TYPE (vm, t)
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
            function _GET_TYPE (vm, x)
                return type (x) == "table" and (x == vm.empty or x.type) or type (x)
            end
            function _CHECK_BOOL (vm, x)
                if x == vm.empty then
                    return false
                end
                return x
            end
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
            _VM_INIT_ARGUMENTS (vm, chunk, arguments)
            _ret1 = vm
            goto _inline_end5
        end
        ::_inline_end5::
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
                goto _inline_end8
            end
            ::_inline_end8::
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
                            value = _CALL (vm, meta, args)
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
                        local tt = _GET_TYPE (vm, t)
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
                                    _STACK_PUSH (vm.mainStack, _CALL (vm, meta, args))
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
                            local tt = _GET_TYPE (vm, t)
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
                                        _STACK_PUSH (vm.mainStack, _CALL (vm, meta, args))
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
                    local t = _GET_TYPE (vm, tocall)
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
                        _STACK_PUSH (vm.mainStack, _CALL (vm, tocall, arguments))
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
                    local t = _GET_TYPE (vm, value)
                    if t ~= "number" and t ~= "string" and value ~= vm.empty then
                        if t == "table" and value.meta.table.tostring then
                            local meta = value.meta.table.tostring
                            local args = {}
                            _STACK_SET (vm.mainStack, _STACK_POS (vm.mainStack)
                            , _CALL (vm, meta, args))
                        else
                            vm.err = "Cannot concat a '" .. t .. "' value."
                        end
                    end
                end
                goto DISPATCH
            ::JUMP_IF::
                do
                    local test = _STACK_POP (vm.mainStack)
                    if _CHECK_BOOL (vm, test)
                     then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::JUMP_IF_NOT::
                do
                    local test = _STACK_POP (vm.mainStack)
                    if not _CHECK_BOOL (vm, test)
                     then
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
                    if _CHECK_BOOL (vm, test)
                     then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::JUMP_IF_NOT_PEEK::
                do
                    local test = _STACK_GET (vm.mainStack)
                    if not _CHECK_BOOL (vm, test)
                     then
                        vm.jump = arg2
                    end
                end
                goto DISPATCH
            ::GET_ITER::
                do
                    local obj = _STACK_POP (vm.mainStack)
                    local tobj = _GET_TYPE (vm, obj)
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
                            value = _CALL (vm, iter, {obj})
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
                        result = _CALL (vm, iter, {obj})
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
                    local _ret5, _ret6
                    do
                        local tx = _GET_TYPE (vm, right)
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret5, _ret6 = right, "Cannot convert the string value to a number."
                                goto _inline_end92
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                _ret5, _ret6 = _CALL (vm, meta, params)
                                goto _inline_end92
                            else
                                _ret5, _ret6 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end92
                            end
                        end
                        _ret5, _ret6 = right
                        goto _inline_end92
                    end
                    ::_inline_end92::
                    right, rerr = _ret5, _ret6
                    local _ret7, _ret8
                    do
                        local tx = _GET_TYPE (vm, left)
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret7, _ret8 = left, "Cannot convert the string value to a number."
                                goto _inline_end93
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                _ret7, _ret8 = _CALL (vm, meta, params)
                                goto _inline_end93
                            else
                                _ret7, _ret8 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end93
                            end
                        end
                        _ret7, _ret8 = left
                        goto _inline_end93
                    end
                    ::_inline_end93::
                    left, lerr = _ret7, _ret8
                    if lerr or rerr then
                        local _ret9, _ret10
                        do
                            local meta, params
                            local tleft = _GET_TYPE (vm, left)
                            local tright = _GET_TYPE (vm, right)
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
                                _ret9 = false
                                goto _inline_end94
                            end
                            _ret9, _ret10 = true, _CALL (vm, meta, params)
                            goto _inline_end94
                        end
                        ::_inline_end94::
                        success, result = _ret9, _ret10
                    else
                        success = true
                        local _ret11
                        _ret11 = left + right
                        goto _inline_end95
                        ::_inline_end95::
                        result = _ret11
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
                    local _ret12, _ret13
                    do
                        local tx = _GET_TYPE (vm, right)
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret12, _ret13 = right, "Cannot convert the string value to a number."
                                goto _inline_end99
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                _ret12, _ret13 = _CALL (vm, meta, params)
                                goto _inline_end99
                            else
                                _ret12, _ret13 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end99
                            end
                        end
                        _ret12, _ret13 = right
                        goto _inline_end99
                    end
                    ::_inline_end99::
                    right, rerr = _ret12, _ret13
                    local _ret14, _ret15
                    do
                        local tx = _GET_TYPE (vm, left)
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret14, _ret15 = left, "Cannot convert the string value to a number."
                                goto _inline_end100
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                _ret14, _ret15 = _CALL (vm, meta, params)
                                goto _inline_end100
                            else
                                _ret14, _ret15 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end100
                            end
                        end
                        _ret14, _ret15 = left
                        goto _inline_end100
                    end
                    ::_inline_end100::
                    left, lerr = _ret14, _ret15
                    if lerr or rerr then
                        local _ret16, _ret17
                        do
                            local meta, params
                            local tleft = _GET_TYPE (vm, left)
                            local tright = _GET_TYPE (vm, right)
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
                                _ret16 = false
                                goto _inline_end101
                            end
                            _ret16, _ret17 = true, _CALL (vm, meta, params)
                            goto _inline_end101
                        end
                        ::_inline_end101::
                        success, result = _ret16, _ret17
                    else
                        success = true
                        local _ret18
                        _ret18 = left * right
                        goto _inline_end102
                        ::_inline_end102::
                        result = _ret18
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
                    local _ret19, _ret20
                    do
                        local tx = _GET_TYPE (vm, right)
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret19, _ret20 = right, "Cannot convert the string value to a number."
                                goto _inline_end106
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                _ret19, _ret20 = _CALL (vm, meta, params)
                                goto _inline_end106
                            else
                                _ret19, _ret20 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end106
                            end
                        end
                        _ret19, _ret20 = right
                        goto _inline_end106
                    end
                    ::_inline_end106::
                    right, rerr = _ret19, _ret20
                    local _ret21, _ret22
                    do
                        local tx = _GET_TYPE (vm, left)
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret21, _ret22 = left, "Cannot convert the string value to a number."
                                goto _inline_end107
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                _ret21, _ret22 = _CALL (vm, meta, params)
                                goto _inline_end107
                            else
                                _ret21, _ret22 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end107
                            end
                        end
                        _ret21, _ret22 = left
                        goto _inline_end107
                    end
                    ::_inline_end107::
                    left, lerr = _ret21, _ret22
                    if lerr or rerr then
                        local _ret23, _ret24
                        do
                            local meta, params
                            local tleft = _GET_TYPE (vm, left)
                            local tright = _GET_TYPE (vm, right)
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
                                _ret23 = false
                                goto _inline_end108
                            end
                            _ret23, _ret24 = true, _CALL (vm, meta, params)
                            goto _inline_end108
                        end
                        ::_inline_end108::
                        success, result = _ret23, _ret24
                    else
                        success = true
                        local _ret25
                        _ret25 = left - right
                        goto _inline_end109
                        ::_inline_end109::
                        result = _ret25
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
                    local _ret26, _ret27
                    do
                        local tx = _GET_TYPE (vm, right)
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret26, _ret27 = right, "Cannot convert the string value to a number."
                                goto _inline_end113
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                _ret26, _ret27 = _CALL (vm, meta, params)
                                goto _inline_end113
                            else
                                _ret26, _ret27 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end113
                            end
                        end
                        _ret26, _ret27 = right
                        goto _inline_end113
                    end
                    ::_inline_end113::
                    right, rerr = _ret26, _ret27
                    local _ret28, _ret29
                    do
                        local tx = _GET_TYPE (vm, left)
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret28, _ret29 = left, "Cannot convert the string value to a number."
                                goto _inline_end114
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                _ret28, _ret29 = _CALL (vm, meta, params)
                                goto _inline_end114
                            else
                                _ret28, _ret29 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end114
                            end
                        end
                        _ret28, _ret29 = left
                        goto _inline_end114
                    end
                    ::_inline_end114::
                    left, lerr = _ret28, _ret29
                    if lerr or rerr then
                        local _ret30, _ret31
                        do
                            local meta, params
                            local tleft = _GET_TYPE (vm, left)
                            local tright = _GET_TYPE (vm, right)
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
                                _ret30 = false
                                goto _inline_end115
                            end
                            _ret30, _ret31 = true, _CALL (vm, meta, params)
                            goto _inline_end115
                        end
                        ::_inline_end115::
                        success, result = _ret30, _ret31
                    else
                        success = true
                        local _ret32
                        _ret32 = left / right
                        goto _inline_end116
                        ::_inline_end116::
                        result = _ret32
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
                    local _ret33, _ret34
                    do
                        local tx = _GET_TYPE (vm, x)
                        if tx == "string" then
                            x = tonumber (x)
                            if not x then
                                _ret33, _ret34 = x, "Cannot convert the string value to a number."
                                goto _inline_end120
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and x.meta.table.tonumber then
                                local meta = x.meta.table.tonumber
                                local params = {}
                                _ret33, _ret34 = _CALL (vm, meta, params)
                                goto _inline_end120
                            else
                                _ret33, _ret34 = x, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end120
                            end
                        end
                        _ret33, _ret34 = x
                        goto _inline_end120
                    end
                    ::_inline_end120::
                    x, err = _ret33, _ret34
                    if err then
                        local _ret35, _ret36
                        do
                            local meta
                            local params = {x}
                            if _GET_TYPE (vm, x) == "table" and x.meta and x.meta.table.minus then
                                meta = x.meta.table.minus
                            end
                            if not meta then
                                _ret35 = false
                                goto _inline_end121
                            end
                            _ret35, _ret36 = true, _CALL (vm, meta, params)
                            goto _inline_end121
                        end
                        ::_inline_end121::
                        success, result = _ret35, _ret36
                    else
                        success = true
                        local _ret37
                        _ret37 = -x
                        goto _inline_end122
                        ::_inline_end122::
                        result = _ret37
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
                    local _ret38, _ret39
                    do
                        local tx = _GET_TYPE (vm, right)
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret38, _ret39 = right, "Cannot convert the string value to a number."
                                goto _inline_end126
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                _ret38, _ret39 = _CALL (vm, meta, params)
                                goto _inline_end126
                            else
                                _ret38, _ret39 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end126
                            end
                        end
                        _ret38, _ret39 = right
                        goto _inline_end126
                    end
                    ::_inline_end126::
                    right, rerr = _ret38, _ret39
                    local _ret40, _ret41
                    do
                        local tx = _GET_TYPE (vm, left)
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret40, _ret41 = left, "Cannot convert the string value to a number."
                                goto _inline_end127
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                _ret40, _ret41 = _CALL (vm, meta, params)
                                goto _inline_end127
                            else
                                _ret40, _ret41 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end127
                            end
                        end
                        _ret40, _ret41 = left
                        goto _inline_end127
                    end
                    ::_inline_end127::
                    left, lerr = _ret40, _ret41
                    if lerr or rerr then
                        local _ret42, _ret43
                        do
                            local meta, params
                            local tleft = _GET_TYPE (vm, left)
                            local tright = _GET_TYPE (vm, right)
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
                                _ret42 = false
                                goto _inline_end128
                            end
                            _ret42, _ret43 = true, _CALL (vm, meta, params)
                            goto _inline_end128
                        end
                        ::_inline_end128::
                        success, result = _ret42, _ret43
                    else
                        success = true
                        local _ret44
                        _ret44 = left % right
                        goto _inline_end129
                        ::_inline_end129::
                        result = _ret44
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
                    local _ret45, _ret46
                    do
                        local tx = _GET_TYPE (vm, right)
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret45, _ret46 = right, "Cannot convert the string value to a number."
                                goto _inline_end133
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                _ret45, _ret46 = _CALL (vm, meta, params)
                                goto _inline_end133
                            else
                                _ret45, _ret46 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end133
                            end
                        end
                        _ret45, _ret46 = right
                        goto _inline_end133
                    end
                    ::_inline_end133::
                    right, rerr = _ret45, _ret46
                    local _ret47, _ret48
                    do
                        local tx = _GET_TYPE (vm, left)
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret47, _ret48 = left, "Cannot convert the string value to a number."
                                goto _inline_end134
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                _ret47, _ret48 = _CALL (vm, meta, params)
                                goto _inline_end134
                            else
                                _ret47, _ret48 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end134
                            end
                        end
                        _ret47, _ret48 = left
                        goto _inline_end134
                    end
                    ::_inline_end134::
                    left, lerr = _ret47, _ret48
                    if lerr or rerr then
                        local _ret49, _ret50
                        do
                            local meta, params
                            local tleft = _GET_TYPE (vm, left)
                            local tright = _GET_TYPE (vm, right)
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
                                _ret49 = false
                                goto _inline_end135
                            end
                            _ret49, _ret50 = true, _CALL (vm, meta, params)
                            goto _inline_end135
                        end
                        ::_inline_end135::
                        success, result = _ret49, _ret50
                    else
                        success = true
                        local _ret51
                        _ret51 = left ^ right
                        goto _inline_end136
                        ::_inline_end136::
                        result = _ret51
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
                    local _ret52, _ret53
                    do
                        local tx = _GET_TYPE (vm, right)
                        if tx == "string" then
                            right = tonumber (right)
                            if not right then
                                _ret52, _ret53 = right, "Cannot convert the string value to a number."
                                goto _inline_end140
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and right.meta.table.tonumber then
                                local meta = right.meta.table.tonumber
                                local params = {}
                                _ret52, _ret53 = _CALL (vm, meta, params)
                                goto _inline_end140
                            else
                                _ret52, _ret53 = right, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end140
                            end
                        end
                        _ret52, _ret53 = right
                        goto _inline_end140
                    end
                    ::_inline_end140::
                    right, rerr = _ret52, _ret53
                    local _ret54, _ret55
                    do
                        local tx = _GET_TYPE (vm, left)
                        if tx == "string" then
                            left = tonumber (left)
                            if not left then
                                _ret54, _ret55 = left, "Cannot convert the string value to a number."
                                goto _inline_end141
                            end
                        elseif tx ~= "number" then
                            if tx == "table" and left.meta.table.tonumber then
                                local meta = left.meta.table.tonumber
                                local params = {}
                                _ret54, _ret55 = _CALL (vm, meta, params)
                                goto _inline_end141
                            else
                                _ret54, _ret55 = left, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                                goto _inline_end141
                            end
                        end
                        _ret54, _ret55 = left
                        goto _inline_end141
                    end
                    ::_inline_end141::
                    left, lerr = _ret54, _ret55
                    if lerr or rerr then
                        local _ret56, _ret57
                        do
                            local meta, params
                            local tleft = _GET_TYPE (vm, left)
                            local tright = _GET_TYPE (vm, right)
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
                                _ret56 = false
                                goto _inline_end142
                            end
                            _ret56, _ret57 = true, _CALL (vm, meta, params)
                            goto _inline_end142
                        end
                        ::_inline_end142::
                        success, result = _ret56, _ret57
                    else
                        success = true
                        local _ret58
                        _ret58 = left < right
                        goto _inline_end143
                        ::_inline_end143::
                        result = _ret58
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
                    local _ret59, _ret60
                    do
                        local meta, params
                        local tleft = _GET_TYPE (vm, left)
                        local tright = _GET_TYPE (vm, right)
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
                            _ret59 = false
                            goto _inline_end146
                        end
                        _ret59, _ret60 = true, _CALL (vm, meta, params)
                        goto _inline_end146
                    end
                    ::_inline_end146::
                    local success, result = _ret59, _ret60
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
                    right = _CHECK_BOOL (vm, right)
                    left = _CHECK_BOOL (vm, left)
                    _STACK_PUSH (vm.mainStack, _AND (right, left))
                end
                goto DISPATCH
            ::OPP_NOT::
                do
                    local x = _STACK_POP (vm.mainStack)
                    x = _CHECK_BOOL (vm, x)
                    _STACK_PUSH (vm.mainStack, _NOT (x))
                end
                goto DISPATCH
            ::OPP_OR::
                do
                    local right = _STACK_POP (vm.mainStack)
                    local left = _STACK_POP (vm.mainStack)
                    right = _CHECK_BOOL (vm, right)
                    left = _CHECK_BOOL (vm, left)
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
    