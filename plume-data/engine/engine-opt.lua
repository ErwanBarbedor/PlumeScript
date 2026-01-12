return function (plume)
    function plume._run (chunk, arguments)
        do
        end
        do
            function _CHECK_NUMBER_META (vm, x)
                local tx = _GET_TYPE (vm, x)
                if tx == "string" then
                    x = tonumber (x)
                    if not x then
                        return x, "Cannot convert the string value to a number."
                    end
                elseif tx ~= "number" then
                    if tx == "table" and x.meta.table.tonumber then
                        local meta = x.meta.table.tonumber
                        local params = {}
                        return _CALL (vm, meta, params)
                    else
                        return x, "Cannot do comparison or arithmetic with " .. tostring (tx) .. " value."
                    end
                end
                return x
            end
            function _HANDLE_META_BIN (vm, left, right, name)
                local meta, params
                local tleft = _GET_TYPE (vm, left)
                local tright = _GET_TYPE (vm, right)
                if tleft == "table" and left.meta and left.meta.table[name .. "r"] then
                    meta = left.meta.table[name .. "r"]
                    params = {right, left}
                elseif tright == "table" and right.meta and right.meta.table[name .. "l"] then
                    meta = right.meta.table[name .. "l"]
                    params = {left, right}
                elseif tleft == "table" and left.meta and left.meta.table[name] then
                    meta = left.meta.table[name]
                    params = {left, right, left}
                elseif tright == "table" and right.meta and right.meta.table[name] then
                    meta = right.meta.table[name]
                    params = {left, right, right}
                end
                if not meta then
                    return false
                end
                return true, _CALL (vm, meta, params)
            end
            function _HANDLE_META_UN (vm, x, name)
                local meta
                local params = {x}
                if _GET_TYPE (vm, x) == "table" and x.meta and x.meta.table[name] then
                    meta = x.meta.table[name]
                end
                if not meta then
                    return false
                end
                return true, _CALL (vm, meta, params)
            end
            function _ADD (x, y)
                return x + y
            end
            function _MUL (x, y)
                return x * y
            end
            function _SUB (x, y)
                return x - y
            end
            function _DIV (x, y)
                return x / y
            end
            function _MOD (x, y)
                return x % y
            end
            function _POW (x, y)
                return x ^ y
            end
            function _NEG (x)
                return -x
            end
            function _AND (x, y)
                return x and y
            end
            function _OR (x, y)
                return x or y
            end
            function _NOT (x)
                return not x
            end
            function _LT (x, y)
                return x < y
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
            local bit = require ("bit")
            local OP_BITS = 7
            local ARG1_BITS = 5
            local ARG2_BITS = 20
            local ARG1_SHIFT = ARG2_BITS
            local OP_SHIFT = ARG1_BITS + ARG2_BITS
            local MASK_OP = bit.lshift (1, OP_BITS) - 1
            local MASK_ARG1 = bit.lshift (1, ARG1_BITS) - 1
            local MASK_ARG2 = bit.lshift (1, ARG2_BITS) - 1
            function _VM_INIT (plume, chunk, arguments)
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
                return vm
            end
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
                        _STACK_MOVE (vm.variableStack, chunk.localsCount)
                        _STACK_PUSH (vm.variableStack.frames, 1)
                    end
                end
            end
            function _VM_DECODE_CURRENT_INSTRUCTION (vm)
                local instr, op, arg1, arg2
                instr = vm.bytecode[vm.ip]
                op = bit.band (bit.rshift (instr, OP_SHIFT)
                , MASK_OP)
                arg1 = bit.band (bit.rshift (instr, ARG1_SHIFT)
                , MASK_ARG1)
                arg2 = bit.band (instr, MASK_ARG2)
                return op, arg1, arg2
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
            function _STACK_MOVE (stack, value)
                stack.pointer = value
            end
            function _STACK_MOVE_FRAMED (stack)
                _STACK_MOVE (stack, _STACK_GET (stack.frames))
            end
            function _STACK_POP_FRAME (stack)
                _STACK_MOVE (stack, _STACK_POP (stack.frames) - 1)
            end
            function _STACK_SET_FRAMED (stack, offset, frameOffset, value)
                _STACK_SET (stack, _STACK_GET_OFFSET (stack.frames, frameOffset or 0) + (offset or 0), value)
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
        local vm = _VM_INIT (plume, chunk, arguments)
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
        op, arg1, arg2 = _VM_DECODE_CURRENT_INSTRUCTION (vm)
        if op == 1 then
            goto LOAD_CONSTANT
        elseif op == 2 then
            goto LOAD_TRUE
        elseif op == 3 then
            goto LOAD_FALSE
        elseif op == 4 then
            goto LOAD_EMPTY
        elseif op == 5 then
            goto LOAD_LOCAL
        elseif op == 6 then
            goto LOAD_LEXICAL
        elseif op == 7 then
            goto LOAD_STATIC
        elseif op == 8 then
            goto STORE_LOCAL
        elseif op == 9 then
            goto STORE_LEXICAL
        elseif op == 10 then
            goto STORE_STATIC
        elseif op == 11 then
            goto STORE_VOID
        elseif op == 12 then
            goto TABLE_NEW
        elseif op == 13 then
            goto TABLE_ADD
        elseif op == 14 then
            goto TABLE_SET
        elseif op == 15 then
            goto TABLE_INDEX
        elseif op == 16 then
            goto TABLE_INDEX_ACC_SELF
        elseif op == 17 then
            goto TABLE_SET_META
        elseif op == 18 then
            goto TABLE_INDEX_META
        elseif op == 19 then
            goto TABLE_SET_ACC
        elseif op == 20 then
            goto TABLE_SET_ACC_META
        elseif op == 21 then
            goto TABLE_EXPAND
        elseif op == 22 then
            goto ENTER_SCOPE
        elseif op == 23 then
            goto LEAVE_SCOPE
        elseif op == 24 then
            goto BEGIN_ACC
        elseif op == 25 then
            goto ACC_TABLE
        elseif op == 26 then
            goto ACC_TEXT
        elseif op == 27 then
            goto ACC_EMPTY
        elseif op == 28 then
            goto ACC_CALL
        elseif op == 29 then
            goto ACC_CHECK_TEXT
        elseif op == 30 then
            goto JUMP_IF
        elseif op == 31 then
            goto JUMP_IF_NOT
        elseif op == 32 then
            goto JUMP_IF_NOT_EMPTY
        elseif op == 33 then
            goto JUMP
        elseif op == 34 then
            goto JUMP_IF_PEEK
        elseif op == 35 then
            goto JUMP_IF_NOT_PEEK
        elseif op == 36 then
            goto GET_ITER
        elseif op == 37 then
            goto FOR_ITER
        elseif op == 38 then
            goto OPP_ADD
        elseif op == 39 then
            goto OPP_MUL
        elseif op == 40 then
            goto OPP_SUB
        elseif op == 41 then
            goto OPP_DIV
        elseif op == 42 then
            goto OPP_NEG
        elseif op == 43 then
            goto OPP_MOD
        elseif op == 44 then
            goto OPP_POW
        elseif op == 45 then
            goto OPP_LT
        elseif op == 46 then
            goto OPP_EQ
        elseif op == 47 then
            goto OPP_AND
        elseif op == 48 then
            goto OPP_NOT
        elseif op == 49 then
            goto OPP_OR
        elseif op == 50 then
            goto DUPLICATE
        elseif op == 51 then
            goto SWITCH
        elseif op == 52 then
            goto END
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
        _STACK_SET_FRAMED (vm.variableStack, arg2 - 1, 0, _STACK_POP (vm.mainStack))
        goto DISPATCH
        ::STORE_LEXICAL::
        _STACK_SET_FRAMED (vm.variableStack, arg2 - 1, -arg1, _STACK_POP (vm.mainStack))
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
                    LOAD_EMPTY (vm)
                else
                    _ERROR (vm, "Cannot use empty as key.")
                end
            else
                local tt = _GET_TYPE (vm, t)
                if tt ~= "table" then
                    if arg1 == 1 then
                        LOAD_EMPTY (vm)
                    else
                        _ERROR (vm, "Try to index a '" .. tt .. "' value.")
                    end
                else
                    local value = t.table[key]
                    if value then
                        _STACK_PUSH (vm.mainStack, value)
                    else
                        if arg1 == 1 then
                            LOAD_EMPTY (vm)
                        elseif t.meta.table.getindex then
                            local meta = t.meta.table.getindex
                            local args = {key}
                            _STACK_PUSH (vm.mainStack, _CALL (vm, meta, args))
                        else
                            if tonumber (key)
                             then
                                _ERROR (vm, "Invalid index '" .. key .. "'.")
                            else
                                _ERROR (vm, "Unregistered key '" .. key .. "'.")
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
            TABLE_INDEX (vm, 0, 0)
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
        _STACK_POP_FRAME (vm.variableStack)
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
                    _TABLE_META_SET (vm, args, t[i], t[i + 1])
                else
                    _TABLE_SET (vm, args, t[i], t[i + 1])
                end
            end
            _STACK_MOVE (vm.mainStack, limit - 2)
            _STACK_PUSH (vm.mainStack, args)
            _END_ACC (vm)
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
            _STACK_MOVE (vm.mainStack, start)
            _STACK_SET (vm.mainStack, start, acc_text)
            _END_ACC (vm)
        end
        goto DISPATCH
        ::ACC_EMPTY::
        _STACK_PUSH (vm.mainStack, vm.empty)
        _END_ACC (vm)
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
                _UNSTACK_POS (vm, tocall, arguments, capture)
                _UNSTACK_NAMED (vm, tocall, arguments, capture)
                if self then
                    table.insert (arguments, self)
                end
                if tocall.variadicOffset > 0 then
                    arguments[tocall.variadicOffset] = capture
                end
                _END_ACC (vm)
                _STACK_PUSH (vm.mainStack, _CALL (vm, tocall, arguments))
            elseif t == "luaFunction" then
                ACC_TABLE (vm)
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
                    _ERROR (vm, result)
                end
            else
                _ERROR (vm, "Try to call a '" .. t .. "' value")
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
                    _ERROR (vm, "Cannot concat a '" .. t .. "' value.")
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
                _ERROR (vm, "Try to iterate over a non-table '" .. tobj .. "' value.")
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
                JUMP (vm, 0, arg2)
            else
                _STACK_PUSH (vm.mainStack, result)
            end
        end
        goto DISPATCH
        ::OPP_ADD::
        _BIN_OPP_NUMBER (vm, _ADD, "add")
        goto DISPATCH
        ::OPP_MUL::
        _BIN_OPP_NUMBER (vm, _MUL, "mul")
        goto DISPATCH
        ::OPP_SUB::
        _BIN_OPP_NUMBER (vm, _SUB, "sub")
        goto DISPATCH
        ::OPP_DIV::
        _BIN_OPP_NUMBER (vm, _DIV, "div")
        goto DISPATCH
        ::OPP_NEG::
        _UN_OPP_NUMBER (vm, _NEG, "minus")
        goto DISPATCH
        ::OPP_MOD::
        _BIN_OPP_NUMBER (vm, _MOD, "mod")
        goto DISPATCH
        ::OPP_POW::
        _BIN_OPP_NUMBER (vm, _POW, "pow")
        goto DISPATCH
        ::OPP_LT::
        _BIN_OPP_NUMBER (vm, _LT, "lt")
        goto DISPATCH
        ::OPP_EQ::
        do
            local right = _STACK_POP (vm.mainStack)
            local left = _STACK_POP (vm.mainStack)
            local success, result = _HANDLE_META_BIN (vm, left, right, "eq")
            if not success then
                result = left == right or tonumber (left) and tonumber (left) == tonumber (right)
            end
            _STACK_PUSH (vm.mainStack, result)
        end
        goto DISPATCH
        ::OPP_AND::
        _BIN_OPP_BOOL (vm, _AND)
        goto DISPATCH
        ::OPP_NOT::
        _UN_OPP_BOOL (vm, _NOT)
        goto DISPATCH
        ::OPP_OR::
        _BIN_OPP_BOOL (vm, _OR)
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
