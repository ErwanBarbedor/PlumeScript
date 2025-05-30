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

    plume.plumeStdLib = {table={}, _VERSION = plume._VERSION}

    plume.luaStdLib = importLuaStdLib()
    plume.envStdLib = {}

    function plume.plumeStdLib.table.merge(...)
        local result = {}
        local index = 1

        for i = 1, select('#', ...) do
            local tbl = select(i, ...)
            if tbl then
                local len = #tbl
                table.move(tbl, 1, len, index, result)
                index = index + len
            end
        end

      return result
    end
    
    -- Visibles from Plume:
        -- table plume: methods/table exposed to user
        -- all _G methods, to be use with Plume calling convention.
        -- table __lua: use Lua calling convention, cannot be used by user.
    function plume.initRuntime (scriptDir)
        local env = {plume = {}, __lua = _G}

        for k, v in pairs(plume.plumeStdLib) do
            env.plume[k] = v
        end

        for k, v in pairs(plume.std.__utils) do
            env[k] = v
        end

        for k, v in pairs(plume.luaStdLib) do
            env[k] = v
        end

        for k, v in pairs(plume.envStdLib) do
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
    
    plume.plumeStdLib.importLuaFunction = importLuaFunction(importLuaFunction)

    --- Loads a library/module into the given environment, searching for 'plume' or 'lua' files.
    -- @param env Table The environment to use for loading the module.
    -- @param __plume_args Table Table of arguments. __plume_args[1] is the module name. __plume_args.ext (optional) is a space-separated list of extensions to search for (default 'plume lua').
    -- @return Any The result of loading/executing the module file.
    -- @error Raises an error if the module cannot be found or loaded.
    function plume.envStdLib.require(env, __plume_args)
        local _, libname, exts = plume.std.__utils.__plume_initArgs(
            __plume_args, 1, {{'ext', "plume lua"}}, false, false
        )
        local triedPath   = {}
        local file, filename, fileext

        libname = libname:gsub('^.[\\/]', '')

        -- Attempt to find and open the module file with the specified extensions and paths
        for ext in exts:gmatch "%S+" do
            for _, basepath in ipairs(env.plume.package.path) do
                local path = basepath:gsub('<name>', libname):gsub('<ext>', ext)
                file = io.open(path)
                if file then
                    filename, fileext = path, ext
                    break
                else
                    table.insert(triedPath, path)
                end
            end
            if file then
                break
            end
        end

        if file then
            if fileext == "plume" then
                file:close()
                return plume.execute(filename, false, env)
            elseif fileext == "lua" then
                -- Handle Lua files: load using Lua's standard loading mechanisms
                file:close()
                local chunk, err
                
                chunk, err = loadfile(filename)
                if not chunk then
                    error("Error when loading '" .. filename .. "': " .. tostring(err))
                end
                setfenv(chunk, env)

                table.insert(env.plume.package.fileTrace, filename)
                local result = chunk()
                table.remove(env.plume.package.fileTrace)
                return result
            else
                error("File '" .. filename .. "' found, but plume doesn't know how to handle '" .. fileext .. "' files.", -1)
            end
        else
            -- Construct detailed error message with all paths attempted
            local msg = {"Module '" .. libname .. "' not found:"}
            for _, path in ipairs(triedPath) do
                table.insert(msg, "    no file '" .. path .. "'")
            end
            error(table.concat(msg, "\n"), -1)
        end
    end

end