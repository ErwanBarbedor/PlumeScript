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
    --- Loads a library/module into the given environment, searching for 'plume' or 'lua' files.
    -- @param env Table The environment to use for loading the module.
    -- @param __plume_args Table Table of arguments. __plume_args[1] is the module name. __plume_args.ext (optional) is a space-separated list of extensions to search for (default 'plume lua').
    -- @return Any The result of loading/executing the module file.
    -- @error Raises an error if the module cannot be found or loaded.
    local function plumeRequire (env, __plume_args)
        local _, libname, exts = plume.std.utils.__plume_initArgs(
            __plume_args, 1, {{'ext', "plume lua"}}, false, false
        )
        local triedPath   = {}
        local file, filename, fileext

        libname = libname:gsub('^.[\\/]', '')

        -- Attempt to find and open the module file with the specified extensions and paths
        for ext in exts:gmatch "%S+" do
            for _, basepath in ipairs(env.config.package.path) do
                local path = basepath
                    :gsub('<name>', libname)
                    :gsub('<ext>', ext)
                    :gsub('<plumeDir>', env.config._PLUME_DIR)
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
                setfenv(chunk, env.lua)

                table.insert(env.config.package.fileTrace, filename)
                local result = chunk()
                table.remove(env.config.package.fileTrace)
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

    plume.std.plume.require = plumeRequire
    function plume.std.luastd.require (env, path, ext)
        return plumeRequire(env, {path, ext=ext})
    end

end