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
    local function defaultBinarySymetric(t, mt, name)
        return function (self, x)
            local base = "__"..name
            local alt
            if self == t then
                alt = "r"
            else
                alt = "l"
                self, x = x, self
            end
            
            f = mt.__plume[base..alt] or mt.__plume[base]
            if f then
                local __plume_args = {self=self, x}
                return f(__plume_args)
            else
                error("This table has no @" .. name .. " or @" .. name .. alt .. " metafield.", 2)
            end
        end
    end
    
    local function defaultUnary(t, mt, name)
        return function (self, ...)
            local f = mt.__plume["__"..name]
            if f then
                local __plume_args = plume.table({...})
                __plume_args.self = self
                return f(__plume_args)
            else
                error("This table has no @" .. name .. " metafield.", 2)
            end
        end
    end
    
    local function defaultCall(t, mt, name)
        return function (self, __plume_args)
            local f = mt.__plume["__"..name]
            if f then
                __plume_args.self = self
                return f(__plume_args)
            else
                error("This table has no @" .. name .. " metafield.", 2)
            end
        end
    end
    
    plume.table = function (initialTable)
        local keys = {}
        local plumeTable = {}
        
        local plumeTableMT = {}
        function plumeTableMT.__newindex (self, k, v)
            rawset(plumeTable, k, v)
            if type(k) ~= "number" or math.floor(k) ~= k then
                table.insert(keys, k)
            end
        end
        
        for method in ("add mul"):gmatch('%S+') do
            plumeTableMT["__" .. method] = defaultBinarySymetric(plumeTable, plumeTableMT, method)
        end
        
        for method in ("call"):gmatch('%S+') do
            plumeTableMT["__" .. method] = defaultCall(plumeTable, plumeTableMT, method)
        end
        
        for method in ("tostring"):gmatch('%S+') do
            plumeTableMT["__" .. method] = defaultUnary(plumeTable, plumeTableMT, method)
        end
            
        plumeTableMT.__plume = {
            keys = keys
        }
    
        setmetatable(plumeTable, plumeTableMT)
        
        for k, v in pairs(initialTable or {}) do
            plumeTable[k] = v --Initial order is lost
        end
        
        return plumeTable
    end
end