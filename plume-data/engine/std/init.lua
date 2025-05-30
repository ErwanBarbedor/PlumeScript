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

return function(plume)
    plume.std = {}

    require ("engine/std/utils") (plume)
    require ("engine/std/std")   (plume)
    require ("engine/std/plume") (plume)
    require ("engine/std/lua")   (plume)

    function plume.initRuntime ()
        local env = {
            lua    = {}, -- Used by required lua files
            plume  = {}, -- Used by plume files
            config = {}  -- runtime infos
        }
        
        env.config = {}
        for k, v in pairs(plume.std.getPlume()) do
            env.config[k] = v
        end

        for k, v in pairs(plume.std.__lua) do
            env.plume[k] = v
        end

        for k, v in pairs(plume.std.__utils) do
            env.plume[k] = v
        end

        for k, v in pairs(plume.std.__std) do
            env.plume[k] = function (...) return v(env, ...) end
        end

        env.plume._G = env.plume
        env.lua._G   = env.lua
        env.plume._LUA = env.lua
        env.lua._PLUME   = env.plume

        return env
    end
end