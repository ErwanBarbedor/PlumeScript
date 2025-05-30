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

local function importLuaFunction (f)
    return function(__plume_args)
        return f(unpack(__plume_args))
    end
end

local function importLuaStdLib ()
    local result = {}
    
    for k, v in pairs(_G) do
        if type(v) == "function" then
            result[k] = importLuaFunction (v)
        elseif type(v) == "table" then
            result[k] = {}
            for kk, vv in pairs(v) do
                result[k][kk] = importLuaFunction (vv)
            end
        end
    end

    return result
end

return function(plume)
    plume.std = {}

    require ("engine/std/utils") (plume)
    require ("engine/std/std") (plume)

    plume.plumeStdLib = {table={}}
    plume.luaStdLib = importLuaStdLib()

    function plume.initRuntime (scriptDir)
        local env = {plume = {}}

        for k, v in pairs(plume.plumeStdLib) do
            env.plume[k] = v
        end
        for k, v in pairs(plume.luaStdLib) do
            env[k] = v
        end

        for k, v in pairs(plume.std.__utils) do
            env[k] = v
        end

        for k, v in pairs(plume.std.__std) do
            env[k] = function (...) return v(env, ...) end
        end

        env.plume.package = {
            loaded    = {},
            path      = {
                "./<name>.<ext>",
                "./<name>/init.<ext>",
                scriptDir .. "/plume-libs/<name>.<ext>",
                scriptDir .. "/plume-libs/<name>/init.<ext>"
            },
            map       = {},
            anonymous = 0,
            fileTrace = {},
            caching   = true
        }

        env._G = env

        return env
    end
end