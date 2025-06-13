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
    plume.table = function (t)
        local keys = {}
        t = t or {}
        
        local n = 0
        return setmetatable({}, {
            __newindex = function (self, k, v)
                rawset(t, k, v)
                if type(k) ~= "number" or math.floor(k) == k then
                    if v == nil then-- remove key
                        for i, key in ipairs(keys) do
                            if key == k then
                                table.remove(keys, i)
                                return
                            end
                        end
                    else
                        table.insert(keys, k)
                    end
                end
            end,
            __index = t,
            __plume_keys = keys
        })
    end
end