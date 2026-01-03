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

function _GET_TYPE(vm, x)
    return type(x) == "table" and (x == vm.empty or x.type) or type(x)
end

--- To rewrite
function _ERROR (msg)
    return false, msg, ip, chunk
end

function _START ()
    if hook then
        if ip>0 then
            hook(
                chunk,
                tic, ip, jump,
                instr, op, vm, arg1, arg2,
                ms, msp, msf, msfp,
                vs, vsp, vsf, vsfp
            )
        end
    end

    if jump>0 then
        ip = jump
        jump = 0-- 0 instead of nil to preserve type
    else
        ip = ip+1
    end
    tic = tic+1
end