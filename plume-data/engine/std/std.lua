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
    local lfs = require('lfs')

    --- Loads a library/module into the given environment, searching for 'plume' or 'lua' files.
    -- @param env Table The environment to use for loading the module.
    -- @param __plume_args Table Table of arguments. __plume_args[1] is the module name. __plume_args.ext (optional) is a space-separated list of extensions to search for (default 'plume lua').
    -- @return Any The result of loading/executing the module file.
    -- @error Raises an error if the module cannot be found or loaded.
    local function plumeRequire (env, __plume_args)
        local _, libname, exts, namespace = plume.std.utils.__plume_initArgs(
            __plume_args, 1, {{'ext', "plume lua"}, {"namespace", nil}}, false, false
        )
        if namespace then
            plume.std.utils.__plume_validate(nil, plume.std.utils.tableValidator, namespace, 'table', 'namespace', 0)
        end
        local triedPath   = {}
        local file, filename, fileext

        libname = tostring(libname):gsub('^.[\\/]', '')

        -- Attempt to find and open the module file with the specified extensions and paths
        for ext in tostring(exts):gmatch "%S+" do
            for _, basepath in ipairs(env.config.package.path) do
                local path = tostring(basepath)
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
                return plume.execute(filename, false, env, namespace)
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

    -- Read/write files
    plume.std.plume.file = {}
    local function mkdir(path)
        local sep = package.config:sub(1,1)
        local currentPath = ""

        for chunk in path:gmatch('[^\\/]+') do
            currentPath = currentPath .. chunk .. "/"
            local attr = lfs.attributes(currentPath)
            if not attr then
                local ok, err = lfs.mkdir(currentPath)
                if not ok then
                    return error(err, 4)
                end
            end
        end
    end

    --- Write a file
    --- @param path string
    --- @param content string
    --- @param binary bool
    --- @param makeDirs bool Create path if not exists?
    function plume.std.plume.file.Write(env, __plume_args)
        local _, path, content, binary, makeDirs = plume.std.utils.__plume_initArgs(
            __plume_args, 2, {{'binary', false}, {'makeDirs', false}}, false, false
        )
        
        if plume.type(path) ~= "string" then
            error("bad argument #1 (path) (string expected, got "..plume.type(path)..")", 3)
        end
        if plume.type(content) ~= "string" then
            error("bad argument #2 (content) (string expected, got "..plume.type(content)..")", 3)
        end
        
        path, content = tostring(path), tostring(content) -- plume string to lua string

        if makeDirs then
            local dirpath = path:match('(.+)[/\\]')
            mkdir(dirpath)
        end

        local file
        if binary then
            file = io.open(path, "wb")
        else
            file = io.open(path, "w")
        end

        if not file then
            error("Cannot write file '" .. path .. "'", 3)
        end

        file:write(content)
        file:close()
    end

    --- Read the content of a file
    --- @param path string
    --- @param binary bool
    function plume.std.plume.file.Read(env, __plume_args)
        local _, path, binary = plume.std.utils.__plume_initArgs(
            __plume_args, 1, {{'binary', false}}, false, false
        )
        path = tostring(path)
        local file
        if binary then
            file = io.open(path, "rb")
        else
            file = io.open(path, "r")
        end

        if not file then
            error("Cannot read file '" .. path .. "'", 3)
        end

        local content = file:read("*a")
        file:close()

        return content
    end

    --- Return all givens arguments as one table.
    --- Usefull for 
        --- Declaring empty tables:`t = $table()`
        --- Declaring tables inlines: `t = $table(foo, bar: baz, *args)`
        --- Mergin tables inline: `t = $table(**t1, **t2)`
    function plume.std.plume.table(env, __plume_args)
        return __plume_args
    end
    
    function plume.std.plume.string(env, __plume_args)
        local _, x = plume.std.utils.__plume_initArgs(
            __plume_args, 1, {}, false, false
        )

        return plume.string(x)
    end

    --- Exactly the `#` lua opperator
    function plume.std.plume.len(env, __plume_args)
        local _, x = plume.std.utils.__plume_initArgs(
            __plume_args, 1, {}, false, false
        )

        local tx = type(x)
        if tx == "table" or tx == "string" then
            return #x
        else
            error("Error: attempt to get length of a " .. tx .. " value.", 2)
        end
    end
    
    function plume.items (t)
        local mt = getmetatable(t)
        
        if mt and mt.__plume and mt.__plume.keys then
            local i = 0
            return function ()
                i = i+1
                while true do
                    local key = mt.__plume.keys[i]
                    if not key then
                        return
                    end
                    
                    if t[key] then
                        return key, t[key]
                    else -- remove key if value is nil
                        table.remove(mt.__plume.keys, i)
                    end
                    
                end
            end
        else
            return function () end
        end
    end
        
    function plume.std.plume.items (env, __plume_args)
        local _, t = plume.std.utils.__plume_initArgs(
            __plume_args, 1, {}, false, false
        )

        return plume.items(t)
    end
    
    function plume.std.utils.numberValidator(__plume_args)
        local _, x = plume.std.utils.__plume_initArgs(
            __plume_args, 1, {}, false, false
        )
        return plume.type(x) == "number"
    end
    function plume.std.utils.stringValidator(__plume_args)
        local _, x = plume.std.utils.__plume_initArgs(
            __plume_args, 1, {}, false, false
        )
        return plume.type(x) == "string"
    end
    function plume.std.utils.tableValidator(__plume_args)
        local _, x = plume.std.utils.__plume_initArgs(
            __plume_args, 1, {}, false, false
        )
        return plume.type(x) == "table"
    end
    function plume.std.utils.macroValidator(__plume_args)
        local _, x = plume.std.utils.__plume_initArgs(
            __plume_args, 1, {}, false, false
        )
        return plume.type(x) == "macro"
    end
end