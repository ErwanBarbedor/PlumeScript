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

--- To rewrite
function JUMP (vm, arg1, arg2)
    --- Jump to offset
    --- arg1: -
    --- arg2: target offset
    jump = arg2
end
function JUMP_IF (vm, arg1, arg2)
    --- Unstack 1
    --- Jump to offset if true
    --- arg1: -
    --- arg2: target offset
    local test = ms[msp]
    _CHECK_BOOL (test)
    if test then
        jump = arg2
    end
    msp = msp-1
end
function JUMP_IF_PEEK (vm, arg1, arg2)
    --- Jump to offset if top is true, without unpacking
    --- arg1: -
    --- arg2: target offset
    local test = ms[msp]
    _CHECK_BOOL (test)
    if test then
        jump = arg2
    end
end
function JUMP_IF_NOT (vm, arg1, arg2)
    --- Unstack 1
    --- Jump to offset if false
    --- arg1: -
    --- arg2: target offset
    local test = ms[msp]
    _CHECK_BOOL (test)
    if not test then
        jump = arg2
    end
    msp = msp-1
end
function JUMP_IF_NOT_PEEK (vm, arg1, arg2)
    --- Unstack 1
    --- Jump to offset if top is false, without unpacking
    --- arg1: -
    --- arg2: target offset
    local test = ms[msp]
    _CHECK_BOOL (test)
    if not test then
        jump = arg2
    end
end
function JUMP_IF_NOT_EMPTY (vm, arg1, arg2)
    --- Unstack 1
    --- Jump to offset if not empty
    --- Used by macro when setting defaut values
    --- arg1: -
    --- arg2: target offset
    if ms[msp] ~= empty then
        jump = arg2
    end
    msp = msp-1
end