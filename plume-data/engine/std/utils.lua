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

-- utils functions used by the transpiled code

return function(plume)
    local buffer = require("string.buffer")
    
    local function items(t)
        return plume.std.plume.items(nil, {t})
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

    plume.std.utils.__plume_smt          = setmetatable
    plume.std.utils.__plume_gmt          = getmetatable
    plume.std.utils.__plume_table_insert = table.insert
    plume.std.utils.__plume_concat       = table.concat
    plume.std.utils.__plume_table        = plume.table
    plume.std.utils._VERSION             = plume._VERSION
    plume.std.utils._LUA_VERSION         = _VERSION
    plume.std.utils._LUAJIT_VERSION      = jit.version
    
    function plume.std.utils.__plume_table_set(t, k, v)
        t[k] = v
    end
    
    function plume.std.utils.__plume_table_metaset(t, k, v)
        getmetatable(t)[k] = v
    end
    
    function plume.std.utils.__plume_buffer()
        return buffer.new()
    end

    function plume.std.utils.__plume_buffer_insert(buffer, s)
        buffer:put(s)
    end

    function plume.std.utils.__plume_check_concat (x)
        local t = type(x)
        if t == "nil" then
            return ""
        elseif t == "table" then
            if type(getmetatable(x).__tostring) == "function" then
                return tostring(x)
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
    function plume.std.utils.__plume_expand_list (dest, source)
        if type(source) ~= "table" then
            error("Cannot expand a '" .. type(source) .. "' variable.", 2)
        end

        for k, v in ipairs(source) do
            table.insert(dest, v)
        end
    end

    function plume.std.utils.__plume_expand_hash (dest, source)
        if type(source) ~= "table" then
            error("Cannot expand a '" .. type(source) .. "' variable.", 2)
        end
        
        for k, v in items(source) do
            dest[k] = v
        end
    end

    function plume.std.utils.__plume_validate(f, x, fname, name)
        if not f then
            error("Unknow validator '" .. fname .. "'.", 2)
        end

        if not f(x) then
            error("Validation '"..fname.."' failed against argument '" .. name .. "'.", 4)
        end
    end

    function plume.std.utils.__plume_validator_number(x)
        return type(x) == "number"
    end
    function plume.std.utils.__plume_validator_string(x)
        return type(x) == "string"
    end
    function plume.std.utils.__plume_validator_table(x)
        return type(x) == "table"
    end
   
    --- Check and initialize function arguments. It validates the number of arguments
    --- and assigns default values to named parameters if they are not provided.
    ---@param argsTable table The table of arguments passed to the function.
    ---@param positionalArgsCount integer The number of required positional arguments.
    ---@param namedArgs table<string,any> A list of named arguments with their default values. Format: {{name1, defaultValue1}, {name2, defaultValue2}, ...} 
    ---@param varargPos bool 
    ---@param varargNamed bool
    function plume.std.utils.__plume_initArgs (argsTable, positionalArgsCount, namedArgs,  varargPos, varargNamed)
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

    function plume.std.utils.__plume_iter(x, y, z)
        if type(x) == "nil" then
            error("Cannot iterate over a nil value.", 2)
        end

        if type(x) == "table" then
            local mt = getmetatable(x)
            if not mt or not mt.__call then
                local i = 0
                return function ()
                    i = i+1
                    return x[i]
                end
            end
        end

        return x, y, z
    end

    
end