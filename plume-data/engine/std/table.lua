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

-- functions and variables exposed directly to users (in Plume)

return function(plume)
    plume.table = function (initialTable)
        local keys = {}
        local plumeTable = {}
        
        setmetatable(plumeTable, {
            __newindex = function (self, k, v)
                rawset(plumeTable, k, v)
                if type(k) ~= "number" or math.floor(k) ~= k then
                    table.insert(keys, k)
                end
            end,
            __plume_keys = keys
        })
        
        for _, x in ipairs(initialTable or {}) do
            table.insert(plumeTable, x)
        end
        
        return plumeTable
    end
end