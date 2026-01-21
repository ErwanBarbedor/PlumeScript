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

--- @param x any
--- @return string Type of x
--! inline
function _GET_TYPE(vm, x)
    return type(x) == "table" and (x == vm.empty or x.type) or (type(x) == "cdata" and x.type) or type(x)
end

--- Throw an error
--- @param msg string
--- @return nil
--! inline-keepret
function _ERROR (vm, msg)
    vm.err = msg
end

--- Throw an error from another runtime
--- @param msg string
--- @param ip number
--- @param chunk pec
--- @return nil
--! inline-keepret
function _SPECIAL_ERROR (vm, msg, ip, runtime)
    vm.serr = {msg, ip, runtime}
end

--- @param x any
--- @return any|false Return false if x is empty, else x it self.
--! inline
function _CHECK_BOOL (vm, x)
    if x == vm.empty then
        return false
    end
    return x
end