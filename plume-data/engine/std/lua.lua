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

return function (plume)
    
    local function callPlumeMacro(macro, args, chunk)
        table.insert(chunk.callstack, {chunk=chunk, macro=macro})
        if #chunk.callstack>1000 then
            error("stack overflow", 0)
        end

        local success, callResult, cip, source  = plume.run(macro, args)
        if not success then
            error("Error running the macro.", 0)
        end
        table.remove(chunk.callstack)

        return callResult
    end

    

    plume.stdLua = {
        print = function(args, chunk)
            local result = {}
            for _, x in ipairs(args.table) do
                if x == plume.obj.empty then
                elseif type(x) == "table" and x.type == "table" and x.meta.table.tostring then
                    table.insert(result, callPlumeMacro(x.meta.table.tostring, {x}, chunk))
                else
                    table.insert(result, tostring(x))
                end
            end
            print(table.unpack(result))
        end,

        join = function(args)
            local sep = args.table.sep
            if sep == plume.obj.empty then
                sep = ""
            end
            return table.concat(args.table, sep)
        end,

        tonumber = function(args, chunk)
            local x = args.table[1]
            if x == plume.obj.empty then
                error("Cannot convert empty into number", 0)
            elseif type(x) == "number" then
                return x
            else
               error(string.format("Cannot convert %s into number", type(x)), 0)
            end
            return table.concat(result)
        end,

        -- path
        setPlumePath = function(args, runtime)
            runtime.env.plume_path = args.table[1]
        end,

        addToPlumePath = function(args, runtime)
            runtime.env.plume_path = (runtime.env.plume_path or "") .. ";" .. args.table[1]
        end,

        -- io
        write = function(args)
            local filename = args.table[1]
            local content = table.concat(args.table, 2,  #args.table)
            local file = io.open(filename, "w")
                if not file then
                    error("Cannot write file '" .. filename .. "'.")
                end
                file:write(content)
            file:close()
        end,

        read = function(args)
            local filename = args.table[1]
            local file = io.open(filename)
                if not file then
                    error("Cannot read file '" .. filename .. "'.")
                end
                local content = file:read("*a")
            file:close()
            return content
        end,

        rawset = function(args)
            local obj   = args.table[1]
            local key   = args.table[2]
            local value = args.table[3]

            if not obj.table[key] then
                table.insert(obj.keys, key)
            end
            obj.table[key] = value
        end
    }
end