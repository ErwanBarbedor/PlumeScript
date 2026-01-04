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
            return x, "Cannot do comparison or arithmetic with " .. tx .. " value."
        end
    end
    return x
end

function _HANDLE_META_BIN (vm, left, right, name)
    local meta, params
    local tleft  = _GET_TYPE(vm, left)
    local tright = _GET_TYPE(vm, right)

    if tleft == "table" and left.meta and left.meta.table[name.."r"] then
        meta = left.meta.table[name.."r"]
        params = {right, left} -- self last
    elseif tright == "table" and right.meta and right.meta.table[name.."l"] then
        meta = right.meta.table[name.."l"]
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
    if _GET_TYPE(vm, x) == "table" and x.meta and x.meta.table[name] then
        meta = x.meta.table[name]
    end

    if not meta then
        return false
    end

    return true, _CALL (vm, meta, params)
end

function _BIN_OPP_BOOL (vm, opp)
    local right = _STACK_POP(vm.mainStack)
    local left  = _STACK_POP(vm.mainStack)

    right = _CHECK_BOOL (vm, right)
    left  = _CHECK_BOOL (vm, left)

    _STACK_PUSH(vm.mainStack, opp(right, left))
end

function _UN_OPP_BOOL (vm, opp)
    local x = _STACK_POP(vm.mainStack)
    x = _CHECK_BOOL (vm, x)
    _STACK_PUSH(vm.mainStack, opp(x))
end

function _BIN_OPP_NUMBER (vm, opp, name)
    local right = _STACK_POP(vm.mainStack)
    local left  = _STACK_POP(vm.mainStack)

    local rerr, lerr, success, result

    right, rerr = _CHECK_NUMBER_META (vm, right)
    left, lerr  = _CHECK_NUMBER_META (vm, left)

    if lerr or rerr then
        success, result = _HANDLE_META_BIN (vm, left, right, name)
    else
        success = true
        result = opp(left, right)
    end

    if success then
        _STACK_PUSH(vm.mainStack, result)
    else
        _ERROR(vm, lerr or rerr)
    end    
end

function _UN_OPP_NUMBER (vm, opp, name)
    local x = _STACK_POP(vm.mainStack)
    local err

    x, err = _CHECK_NUMBER_META (vm, x)

    if err then
        success, result = _HANDLE_META_UN (vm, x, name)
    else
        success = true
        result = opp(x)
    end

    if success then
        _STACK_PUSH(vm.mainStack, result)
    else
        _ERROR(vm, err)
    end  
end

--- Arithmetics
function _ADD(x, y) return x+y end
function _MUL(x, y) return x*y end
function _SUB(x, y) return x-y end
function _DIV(x, y) return x/y end
function _MOD(x, y) return x%y end
function _POW(x, y) return x^y end
function _NEG(x)    return -x end

function OPP_ADD (vm, arg1, arg2) _BIN_OPP_NUMBER (vm, _ADD,   "add")   end
function OPP_MUL (vm, arg1, arg2) _BIN_OPP_NUMBER (vm, _MUL,   "mul")   end
function OPP_SUB (vm, arg1, arg2) _BIN_OPP_NUMBER (vm, _SUB,   "sub")   end
function OPP_DIV (vm, arg1, arg2) _BIN_OPP_NUMBER (vm, _DIV,   "div")   end
function OPP_MOD (vm, arg1, arg2) _BIN_OPP_NUMBER (vm, _MOD,   "mod")   end
function OPP_POW (vm, arg1, arg2) _BIN_OPP_NUMBER (vm, _POW,   "pow")   end
function OPP_NEG (vm, arg1, arg2) _UN_OPP_NUMBER  (vm, _NEG,   "minus") end



--- Bool
function _AND(x, y) return x and y end
function _OR(x, y)  return x or y end
function _NOT(x)    return not x end

function OPP_AND (vm, arg1, arg2) _BIN_OPP_BOOL (vm, _AND) end
function OPP_OR  (vm, arg1, arg2) _BIN_OPP_BOOL (vm, _OR) end
function OPP_NOT (vm, arg1, arg2) _UN_OPP_BOOL  (vm, _NOT) end


--- Comparison
function _LT(x, y) return x < y end
function _GT(x, y) return x > y end

function OPP_LT (vm, arg1, arg2) _BIN_OPP_NUMBER (vm, _LT, "lt") end
function OPP_GT (vm, arg1, arg2) _BIN_OPP_NUMBER (vm, _GT, "gt") end

function OPP_EQ (vm, arg1, arg2)
    local right = _STACK_POP(vm.mainStack)
    local left  = _STACK_POP(vm.mainStack)

    local success, result = _HANDLE_META_BIN (vm, left, right, "eq")
    if not success then
        result = left == right
    end

    _STACK_PUSH(vm.mainStack, result)  
end

function OPP_NEQ (vm, arg1, arg2)
    local right = _STACK_POP(vm.mainStack)
    local left  = _STACK_POP(vm.mainStack)

    local success, result = _HANDLE_META_BIN (vm, left, right, "eq")
    if not success then
        result = left ~= right
    end

    _STACK_PUSH(vm.mainStack, result)  
end