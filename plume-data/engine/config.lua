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

return function(plume)
	------------------------
    -- Instruction format --
    ------------------------
    local bit = require("bit")
    plume.OP_BITS   = 7
    plume.ARG1_BITS = 5
    plume.ARG2_BITS = 20
    plume.ARG1_SHIFT = plume.ARG2_BITS
    plume.OP_SHIFT   = plume.ARG1_BITS + plume.ARG2_BITS
    plume.MASK_OP   = bit.lshift(1, plume.OP_BITS) - 1
    plume.MASK_ARG1 = bit.lshift(1, plume.ARG1_BITS) - 1
    plume.MASK_ARG2 = bit.lshift(1, plume.ARG2_BITS) - 1
    ------------------------
end