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

    local function raiseWrongParameterName(name, t)
        local message = "Unknow named parameter '" .. name .. "'."
        local suggestions = plume.searchWord(name, t)

        if #suggestions > 0 then
            local suggestion_str = table.concat(suggestions, ", ")
            suggestion_str = suggestion_str:gsub(',([^,]*)$', " or%1") 
            message = message
                .. " Perhaps you mean "
                .. suggestion_str
                .. "?"
        end

        error(message, 4)
    end
    
    -- Visibles from Plume:
        -- table plume: methods/table exposed to user
        -- all _G methods, to be use with Plume calling convention.
        -- table __lua: use Lua calling convention, cannot be used by user.
    function plume.initRuntime ()
        local env = {plume = {}, __lua = _G}

        for k, v in pairs(plume.plumeStdLib) do
            env.plume[k] = v
        end

        for k, v in pairs(plume.luaStdLib) do
            env[k] = v
        end

        for k, v in pairs(plume.envStdLib) do
            env[k] = function (...) return v(env, ...) end
        end

        env.plume.package = {
            loaded    = {},
            path      = {"./<name>.<ext>"},
            map       = {},
            anonymous = 0,
            fileTrace = {}
        }

        env._G = env

        return env
    end

    function plume.plumeStdLib.checkConcat(x)
        local t = type(x)
        if t == "nil" then
            return ""
        elseif t == "table" then
            if type(getmetatable(t).__tostring) == "function" then
                return tostring(t)
            else
                error("Cannot convert table to string implicitly.", 2)
            end
        else
            return x
        end
    end

    --- Copy the contents of one table to another.
    --- process list and hash separately to preserve
    --- data order.
    --- @param source table
    --- @param dest table
    function plume.plumeStdLib.expandList(dest, source)
        if type(source) ~= "table" then
            error("Cannot expand a '" .. type(source) .. "' variable.", 2)
        end

        for k, v in ipairs(source) do
            table.insert(dest, v)
        end
    end

    function plume.plumeStdLib.expandHash(dest, source)
        if type(source) ~= "table" then
            error("Cannot expand a '" .. type(source) .. "' variable.", 2)
        end
        
        for k, v in pairs(source) do
            if type(k) ~= "number" then
                dest[k] = v
            end
        end
    end
   
    --- Check and initialize function arguments. It validates the number of arguments
    --- and assigns default values to named parameters if they are not provided.
    ---@param argsTable table The table of arguments passed to the function.
    ---@param positionalArgsCount integer The number of required positional arguments.
    ---@param namedArgs table<string,any> A list of named arguments with their default values. Format: {{name1, defaultValue1}, {name2, defaultValue2}, ...} 
    ---@param varargPos bool 
    ---@param varargNamed bool
    function plume.plumeStdLib.initArgs(argsTable, positionalArgsCount, namedArgs, varargPos, varargNamed)
        local result = {argsTable.self or false} -- Store the 'self' parameter if present

        argsTable.self = nil -- Remove 'self' from argsTable

        -- Process positional arguments
        local notEnoughtArgs
        for i=1, positionalArgsCount do
            local item = table.remove(argsTable, 1)
            if item then
                table.insert(result, item)
            else
                notEnoughtArgs = true -- Flag if not enough positional arguments are provided
                break
            end
        end

        -- Error handling for incorrect number of arguments
        if notEnoughtArgs or (not  varargPos and #argsTable > 0) then
            error('Wrong number of arguments, ' .. (#result+#argsTable-1) .. ' instead of '..positionalArgsCount .. '.', 3)
        end

        -- Process named arguments
        for _, infos in ipairs(namedArgs) do
            local name  = infos[1]
            local value = infos[2]
            if argsTable[name] then
                table.insert(result, argsTable[name])
                argsTable[name] = nil -- Remove the named argument from argsTable after processing
            else
                table.insert(result, value) -- Use default value if named argument is not provided
            end
        end

        -- Check for surplus named arguments if vararg is not used
        local excessNamed = {}
        -- Iterate through remaining entries in argsTable
        for name, value in pairs(argsTable) do
            -- Check if the key is not a number (indicating a named argument)
            if type(name) ~= "number" then
                if varargNamed then
                    excessNamed[name] = value
                    argsTable[name] = nil
                else
                    local names = {}
                    for _, infos in ipairs(namedArgs) do
                        names[infos[1]] = true
                    end
                    -- Raise an error if an surplus named argument is found
                    raiseWrongParameterName(name, names)
                end
            end
        end

        -- Add varargs to the result if enabled
        if varargPos then
            table.insert(result, argsTable) -- Vararg is the remaining entries
        end

        if varargNamed then
            table.insert(result, excessNamed)
        end

        return unpack(result) -- Return the processed arguments
    end


    plume.plumeStdLib.importLuaFunction = importLuaFunction(importLuaFunction)

    --- Loads a library/module into the given environment, searching for 'plume' or 'lua' files.
    -- @param env Table The environment to use for loading the module.
    -- @param __plume_args Table Table of arguments. __plume_args[1] is the module name. __plume_args.ext (optional) is a space-separated list of extensions to search for (default 'plume lua').
    -- @return Any The result of loading/executing the module file.
    -- @error Raises an error if the module cannot be found or loaded.
    function plume.envStdLib.require(env, __plume_args)
        local libname     = __plume_args[1]
        local exts        = __plume_args.ext or 'plume lua'
        local triedPath   = {}
        local file, filename, fileext

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