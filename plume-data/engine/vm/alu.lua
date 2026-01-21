--[[This file is part of Plume

Plume🪶 is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.

Plume🪶 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Plume🪶.
If not, see <https://www.gnu.org/licenses/>.
]]

--- Try to convert any value into number.
--- Via tonumber, or try to call the metafield tonumber.
--- @param x any
--- @return number|nil, string The converted value, or nil + an error message
--! inline
function _CHECK_NUMBER_META (vm, x)
    local tx = _GET_TYPE(vm, x)
    if tx  == "string" then
        x = tonumber(x)
        if not x then
            return x, "Cannot convert the string value to a number."
        end
    elseif tx  ~= "number" then
        if tx  == "table" and x.meta.table.tonumber then
            local meta = x.meta.table.tonumber
            local params = {}
            return _CALL (vm, meta, params)
        else
            return x, "Cannot do comparison or arithmetic with " .. tostring(tx) .. " value."
        end
    end
    return x
end

--- For a given operation name, try to find a meta macro to do the operation.
--- If find one, call it.
--- @param left any
--- @param right any
--- @param name string Operation name
--- @return false|true, any(call result)
--! inline
function _HANDLE_META_BIN (vm, left, right, name)
    local meta, param1, param2, paramself
    local tleft  = _GET_TYPE(vm, left)
    local tright = _GET_TYPE(vm, right)

    if tleft == "table" and left.meta and left.meta.table[name.."r"] then
        meta = left.meta.table[name.."r"]
        param1 = right
        paramself = left
    elseif tright == "table" and right.meta and right.meta.table[name.."l"] then
        meta = right.meta.table[name.."l"]
        param1 = left
        paramself = right
    elseif tleft == "table" and left.meta and left.meta.table[name] then
        meta = left.meta.table[name]
        param1 = left
        param2 = right
        paramself = left
    elseif tright == "table" and right.meta and right.meta.table[name] then
        meta = right.meta.table[name]
        param1 = left
        param2 = right
        paramself = right
    end

    if meta then
        BEGIN_ACC(vm, 0, 0)
        TABLE_NEW(vm, 0, 0)
        _STACK_PUSH(vm.mainStack, param1)
        if param2 then
            _STACK_PUSH(vm.mainStack, param2)
        end

        _STACK_PUSH(vm.mainStack, paramself)
        TABLE_REGISTER_SELF(vm, 0, 0)
        _STACK_POP(vm.mainStack) -- TABLE_REGISTER_SELF dont pop

        _STACK_PUSH(vm.mainStack, meta)
        _INJECTION_PUSH(vm, vm.plume.ops.CONCAT_CALL, 0, 0)
    end

    return meta
end

--- For a given operation name, try to find a meta macro to do the operation.
--- If find one, call it.
--- @param x any The value to process
--- @param name string Operation name
--- @return false|true, any(call result)
--! inline
function _HANDLE_META_UN (vm, x, name)
    local meta
    local params = {x}
    if _GET_TYPE(vm, x) == "table" and x.meta and x.meta.table[name] then
        meta = x.meta.table[name]
    end

    if not meta then
        return false
    end

    return true, _CALL (vm, meta, params)
end

--- Unstack 2 value, apply an boolean operation, stack the result.
--- If an value is `empty`, act like it was false.
--- @param op function Operation to apply
--! inline
function _BIN_OP_BOOL (vm, op)
    local right = _STACK_POP(vm.mainStack)
    local left  = _STACK_POP(vm.mainStack)

    right = _CHECK_BOOL (vm, right)
    left  = _CHECK_BOOL (vm, left)

    _STACK_PUSH(vm.mainStack, op(right, left))
end

--- Unstack 1 value, apply an boolean operation, stack the result.
--- If the value is `empty`, act like it was false.
--- @param op function Operation to apply
--! inline
function _UN_OP_BOOL (vm, op)
    local x = _STACK_POP(vm.mainStack)
    x = _CHECK_BOOL (vm, x)
    _STACK_PUSH(vm.mainStack, op(x))
end

--- `_BIN_OP_NUMBER` isn't an opcode, but tag as opcode for be integrated in the documentation.
--- @opcode
--- Unstack 2 value, apply an operation, stack the result.
--- Try to convert values to number.
--- If cannot, try to call meta macro based on operator name
--- @param op function Operation to apply
--- @param name string Name used to find meta macro and debug messages
--! inline
function _BIN_OP_NUMBER (vm, op, name)
    local right = _STACK_POP(vm.mainStack)
    local left  = _STACK_POP(vm.mainStack)

    local rightNumber = tonumber(right)
    local leftNumber = tonumber(left)

    -- Only number
    if rightNumber and leftNumber then
        result = op(leftNumber, rightNumber)
        _STACK_PUSH(vm.mainStack, result)
    else

        local rerr, lerr

        right, rerr = _CHECK_NUMBER_META (vm, right)
        left, lerr  = _CHECK_NUMBER_META (vm, left)

        -- table with metafield for this operator
        if lerr or rerr then
            local meta = _HANDLE_META_BIN (vm, left, right, name)
            if not meta then
                _ERROR(vm, lerr or rerr)
            end
        -- table with tonumber metafield
        else
            result = op(left, right)
            _STACK_PUSH(vm.mainStack, result)
        end

        
    end
end

--- Unstack 1 value, apply an operation, stack the result.
--- @param op function Operation to apply
--- @param name string Name used to find meta macro and debug messages
--! inline
function _UN_OP_NUMBER (vm, op, name)
    local x = _STACK_POP(vm.mainStack)
    local err

    x, err = _CHECK_NUMBER_META (vm, x)

    if err then
        success, result = _HANDLE_META_UN (vm, x, name)
    else
        success = true
        result = op(x)
    end

    if success then
        _STACK_PUSH(vm.mainStack, result)
    else
        _ERROR(vm, err)
    end  
end

----------------
--- Arithmetics
----------------

--! inline
function _ADD(x, y) return x+y end
--! inline
function _MUL(x, y) return x*y end
--! inline
function _SUB(x, y) return x-y end
--! inline
function _DIV(x, y) return x/y end
--! inline
function _MOD(x, y) return x%y end
--! inline
function _POW(x, y) return x^y end
--! inline
function _NEG(x)    return -x end

--- @opcode
--- Add two stack top value and stack the result based on `_BIN_OP_NUMBER`.
--! inline
function OP_ADD (vm, arg1, arg2)
    _BIN_OP_NUMBER (vm, _ADD,   "add")  
end
--- @opcode
--- Multiply two stack top value and stack the result based on `_BIN_OP_NUMBER`.
--! inline
function OP_MUL (vm, arg1, arg2)
    _BIN_OP_NUMBER (vm, _MUL,   "mul")  
end
--- @opcode
--- Substract two stack top value and stack the result based on `_BIN_OP_NUMBER`.
--! inline
function OP_SUB (vm, arg1, arg2)
    _BIN_OP_NUMBER (vm, _SUB,   "sub")  
end
--- @opcode
--- Divide two stack top value and stack the result based on `_BIN_OP_NUMBER`.
--! inline
function OP_DIV (vm, arg1, arg2)
    _BIN_OP_NUMBER (vm, _DIV,   "div")  
end
--- @opcode
--- Take the modulo of stack top value and stack the result based on `_BIN_OP_NUMBER`.
--! inline
function OP_MOD (vm, arg1, arg2)
    _BIN_OP_NUMBER (vm, _MOD,   "mod")  
end
--- @opcode
--- Take the power of two stack top value and stack the result based on `_BIN_OP_NUMBER`.
--! inline
function OP_POW (vm, arg1, arg2)
    _BIN_OP_NUMBER (vm, _POW,   "pow")  
end
--- @opcode
--- Give opposite of a value 
--! inline
function OP_NEG (vm, arg1, arg2)
    _UN_OP_NUMBER  (vm, _NEG,   "minus")
end

---------
--- Bool
---------

--! inline
function _AND(x, y) return x and y end
--! inline
function _OR(x, y)  return x or y end
--! inline
function _NOT(x)    return not x end

--- @opcode
--- Do boolean `and` between two stack top values based on `_BIN_OP_BOOL`.
--! inline
function OP_AND (vm, arg1, arg2)
    _BIN_OP_BOOL (vm, _AND)
end
--- @opcode
--- Do boolean `or` between two stack top values based on `_BIN_OP_BOOL`.
--! inline
function OP_OR  (vm, arg1, arg2)
    _BIN_OP_BOOL (vm, _OR)
end
--- @opcode
--- Do boolean `not` between stack top value based on `_BIN_OP_BOOL`.
--! inline
function OP_NOT (vm, arg1, arg2)
    _UN_OP_BOOL  (vm, _NOT)
end

---------------
--- Comparison
---------------

--- Do comparison `<` between two stack top values based on `_BIN_OP_NUMBER`.
--- @param x left value
--- @param y right value
--! inline
function _LT(x, y) return x < y end

--- @opcode
--- Do comparison `<` between two stack top values based on `_BIN_OP_NUMBER`.
--! inline
function OP_LT (vm, arg1, arg2)
    _BIN_OP_NUMBER (vm, _LT, "lt")
end

--- @opcode
--- Do comparison `==` between two values.
--- If both value are string representations of number,
--- return the comparison between theses two numbers.
--! inline
function OP_EQ (vm, arg1, arg2)
    local right = _STACK_POP(vm.mainStack)
    local left  = _STACK_POP(vm.mainStack)

    local meta  = _HANDLE_META_BIN (vm, left, right, "eq")

    if not meta then
        -- `(false)` instead of `false` preventing make-engine-opt optimization
        local result = left == right or tonumber(left) and tonumber(left) == tonumber(right) or (false)
        _STACK_PUSH(vm.mainStack, result)  
    end

    
end