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

-- functions and variables exposed to users via the plume table

return function(plume)
    function plume.std.getPlume()
        return {
            package = {
                loaded    = {},
                path      = {
                    "./<name>.<ext>",
                    "./<name>/init.<ext>",
                    "<plumeDir>/plume-libs/<name>.<ext>",
                    "<plumeDir>/plume-libs/<name>/init.<ext>"
                },
                map       = {},
                anonymous = 0,
                fileTrace = {},
                caching   = true
            }
        }
    end
end