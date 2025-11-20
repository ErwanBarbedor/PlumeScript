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
    local pathTemplates = {
        "%base%%path%.%ext%",
        "%base%%path%/init.%ext%",
    }
    local function formatDir(s)
        local result = s:gsub('\\', '/')
        if result ~= "" and not result:match('/$') then
            result = result .. "/"
        end
        return result
    end
    local function formatDirFromFilename(s)
        local result = formatDir(s:gsub('/[^/]+$', ''))
        if result ~= "" and not result:match('/$') then
            result = result .. "/"
        end
        return result
    end

    local function getFilenameFromPath(path, lua, chunk)
        path = path:gsub('\\', '/')
        
        local root
        if path:match('^%.+/') or path == "." then
            root = formatDirFromFilename(chunk.name)
        else
            root = formatDirFromFilename(chunk.state[1].name)
        end

        local ext
        if lua then
            ext = "lua"
        else
            ext = "plume"
        end

        local basedirs = {}
        local env = plume.env.plume_path
        if env then
            for dir in env:gmatch('[^;]+') do
                dir = formatDir(dir)
                table.insert(basedirs, dir)
            end
        end
        table.insert(basedirs, root)
        table.insert(basedirs, "")

        local searchPaths = {}
        for _, base in ipairs(basedirs) do
            for _, template in ipairs(pathTemplates) do
                template = template:gsub('%%base%%', base)
                template = template:gsub('%%path%%', path)
                template = template:gsub('%%ext%%', ext)

                table.insert(searchPaths, template)
            end
        end

        for _, search in ipairs(searchPaths) do
            local f = io.open(search)
            if f then
                f:close()
                return search
            end
        end
        
        return nil, searchPaths
    end

    local std = {
        print = function(arg)
            print(table.unpack(arg.table))
        end,

        type = function(args)
            local value = args.table[1]
            local t = type(value)
            if t=="table" then
                if value==plume.obj.empty then
                    return "empty"
                else
                    return value.type
                end
            else
                return t
            end
        end,

        table = function(args)
            return args
        end,

        join = function(args)
            local sep = args.table.sep
            if sep == plume.obj.empty then
                sep = ""
            end
            return table.concat(args.table, sep)
        end,

        -- temporary name
        tostring = function(args)
            local result = {}
            for _, x in ipairs(args.table) do
                if x == plume.obj.empty then
                else
                    table.insert(result, tostring(x))
                end
            end
            return table.concat(result)
        end,

        seq = function(args)
            local start = args.table[1]
            local stop  = args.table[2]

            if not stop then
                stop = start
                start = 1
            end

            start = tonumber(start)
            stop = tonumber(stop)

            local iterator = plume.obj.table(1, 2)
            iterator.table[1] = start-1
            iterator.table.next = plume.obj.luaFunction("next", function()
                iterator.table[1]  = iterator.table[1] + 1
                if iterator.table[1] > stop then
                    return plume.obj.empty
                else
                    return iterator.table[1]
                end
            end)

            iterator.meta.table.iter = plume.obj.luaFunction("iter", function()
                return iterator
            end)

            return iterator
        end,

        enumerate = function(args)
            local t = args.table[1]

            local iterator = plume.obj.table(1, 2)
            iterator.table[1] = 0
            iterator.table.next = plume.obj.luaFunction("next", function()
                iterator.table[1]  = iterator.table[1] +1
                local value = t.table[iterator.table[1]]
                if not value then
                    return plume.obj.empty
                else
                    local result = plume.obj.table(0, 2)
                    result.table.index = iterator.table[1]
                    result.table.value = value

                    result.keys = {"index", "value"}
                    return result
                end
            end)

            iterator.meta.table.iter = plume.obj.luaFunction("iter", function()
                return iterator
            end)

            return iterator
        end,

        items = function(args)
            local t = args.table[1]

            local iterator = plume.obj.table(1, 2)
            iterator.table[1] = 0
            iterator.table.next = plume.obj.luaFunction("next", function()
                iterator.table[1]  = iterator.table[1] +1
                local key = t.keys[iterator.table[1]]
                if not key then
                    return plume.obj.empty
                else
                    local result = plume.obj.table(0, 2)
                    result.table.key = key
                    result.table.value = t.table[key]

                    result.keys = {"key", "value"}
                    return result
                end
            end)

            iterator.meta.table.iter = plume.obj.luaFunction("iter", function()
                return iterator
            end)

            return iterator
        end,

        -- If start by ./ or ../, search relativly to current file
        -- Else, search from root file and dir from PLUME_PATH (separated by comma)
        -- For a given path, search for path.plume and path/init.plume
        import = function(args, chunk)
            local filename, searchPaths = getFilenameFromPath(args.table[1], args.table.lua, chunk)
            
            if filename then
                if args.table.lua then
                    return dofile(filename)(plume) 
                else
                    local success, result = plume.executeFile(filename, chunk.state, true)
                    if not success then
                        error(result, 0)
                    end
                    return result
                end
            else
                msg = "Error: cannot open '" .. args.table[1] .. "'.\nPaths tried:\n\t" .. table.concat(searchPaths, '\n\t')
                error(msg, 0)
            end
        end,

        -- path
        setPlumePath = function(args)
            plume.env.plume_path = args.table[1]
        end,

        addToPlumePath = function(args)
            plume.env.plume_path = (plume.env.plume_path or "") .. ";" .. args.table[1]
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

        -- table
        len = function(args)
            local t = args.table[1]
            return #t.table
        end,

        append = function(args)
            local t = args.table[1]
            local value = args.table[2]
            table.insert(t.table, value)
        end,

        remove = function(args)
            local t = args.table[1]
            return table.remove(t.table)
        end
    }

    plume.std = {}
    for name, f in pairs(std) do
        plume.std[name] = plume.obj.luaFunction(name, f)
    end

    local function importLuaFunction(name, f)
        return plume.obj.luaFunction(name, function(args)
            return (f(unpack(args.table)))
        end)
    end

    local function importLuaTable(name, t)
        local result = plume.obj.table(0, 0)

        for k, v in pairs(t) do
            table.insert(result.keys, k)
            if type(v) == "table" then
                v = importLuaTable(k, v)
            elseif type(v) == "function" then
                v = importLuaFunction(k, v)
            end
            result.table[k] = v
        end

        return result
    end
    
    plume.std.lua = plume.obj.table(0, 0)

    for name in ("assert error"):gmatch("%S+") do
        plume.std.lua.table[name] = importLuaFunction(name, _G[name])
    end

    for name in ("string math os io"):gmatch("%S+") do
        plume.std.lua.table[name] = importLuaTable(name, _G[name])
    end
end