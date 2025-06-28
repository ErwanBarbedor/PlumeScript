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

-- function imported from lua

return function(plume)
    local function importLuaFunction (f)
        return function(__plume_args)
            -- Replace plume.NIL by nil
            local argCount = #__plume_args
            local argTable = {}
            for i=1, #__plume_args do
                local arg = __plume_args[i]
                if arg == plume.NIL then
                    arg = nil
                end
                argTable[i] = arg
            end
            
            return f(unpack(argTable, 1, argCount))
        end
    end

    local function importLuaTable (t)
        local result = {}
        
        for k, v in pairs(t) do
            if type(v) == "function" then
                result[k] = importLuaFunction (v)
            elseif type(v) == "table" then
                result[k] = importLuaTable (v)
            else
                result[k] = v
            end
        end

        return result
    end

    -- Available from plume
    -- Excluded: arg, collectgarbage, coroutine, debug, dofile, gcinfo, getfenv, getmetatable, io, ipairs, jit, load, loadfile, loadstring, module, next, os, package, pcall, rawequal, rawget, rawset, require, select, setmetatable, string, table, unpack, xpcall, type
    for name in ("assert bit error pairs print tostring tonumber"):gmatch('%S+') do
        plume.std.luaPlume[name] = importLuaFunction (_G[name])
    end

    -- rename ipairs
    plume.std.luaPlume.enumerate = importLuaFunction (_G["ipairs"])

    for name in ("math"):gmatch('%S+') do
        plume.std.luaPlume[name] = importLuaTable (_G[name])
    end

    -- Available from lua
    for name in ("arg collectgarbage coroutine debug dofile gcinfo getfenv getmetatable io jit load loadfile loadstring module next os package pcall rawequal rawget rawset require select, setmetatable string table unpack xpcall assert bit error ipairs pairs print tostring tonumber type"):gmatch('%S+') do
        plume.std.lua[name] = _G[name]
    end
    
    function plume.std.luaPlume.type(__plume_args)
        local x = __plume_args[1]
        local t = type(x)
        if t == "function" then
            return "macro"
        end
        return t
    end
end