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

-- This module is responsible for initializing the core Plume runtime, including
-- its standard library functions and the mechanism for importing Lua's standard
-- library functions into a Plume-callable format.

local function importEnvFunction(f, env)
    if type(f) == "function" then
        return function (...) return f(env, ...) end
    elseif type(f) == "table" then
        local result = {}
        for k, v in pairs(f) do
            result[k] = importEnvFunction(v, env)
        end
        return result
    else
        return f
    end
end

return function(plume)
    plume.std = {plume={}, lua={}, luastd={}, luaPlume={}, utils={}}

    require ("engine/std/table")  (plume)
    require ("engine/std/string") (plume)
    require ("engine/std/utils")  (plume)
    require ("engine/std/std")    (plume)
    require ("engine/std/lua")    (plume)
    require ("engine/std/config") (plume)

    function plume.initRuntime ()
        local env = {
            -- Used by required lua files
            lua = {
                plume={}
            }, 

            plume  = plume.table(), -- Used by plume files
            config = {}  -- runtime infos
        }
        
        env.config = {}
        for k, v in pairs(plume.std.getPlume()) do
            env.config[k] = v
        end

        for k, v in pairs(plume.std.luaPlume) do
            env.plume[k] = v
        end

        for k, v in pairs(plume.std.utils) do
            env.plume[k] = v
        end

        for k, v in pairs(plume.std.plume) do
            env.plume[k] = importEnvFunction(v, env)
        end

        for k, v in pairs(plume.std.lua) do
            env.lua[k] = v
        end

        for k, v in pairs(plume.std.luastd) do
            env.lua.plume[k] = function (...) return v(env, ...) end
        end

        env.plume._G = env.plume
        env.lua._G   = env.lua
        env.lua._PLUME   = env.plume

        return env
    end
end