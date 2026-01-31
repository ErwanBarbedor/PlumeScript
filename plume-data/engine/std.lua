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
    local function append (args)
        local t = args.table[1]
        local value = args.table[2]
        table.insert(t.table, value)
        table.insert(t.keys, #t.table)
    end

    local function remove (args)
        local t = args.table[1]
        local index = args.table[2]

        t.keys[#t.table] = nil

        return table.remove(t.table, index)
    end

    ---------------------------------
    -- WILL BE REMOVED IN 1.0 (#230)
    ---------------------------------
    plume.stdLua.remove = remove
    plume.stdLua.append = append
    ---------------------------------


    plume.std = {}
    for name, f in pairs(plume.stdLua) do
        plume.std[name] = plume.obj.luaFunction(name, f)
    end
    for name, obj in pairs(plume.stdVM) do
        plume.std[name] = obj
    end

    local _table = plume.obj.table (0, 2)
    _table.table.keys = {"append", "remove", "removeKey"}
    _table.table.remove = plume.std.remove
    _table.table.append = plume.std.append
    _table.table.removeKey = plume.obj.luaFunction("removeKey", function (args)
        local t = args.table[1]
        local key = args.table[2]

        key = tonumber(key) or key
        local index = 0
        for k, v in ipairs(t.keys) do
            if v == key then
                index = k
                break
            end
        end

        t.table[key] = nil
        table.remove(t.keys, index)
    end)
    _table.table.hasKey = plume.obj.luaFunction("hasKey", function (args)
        local t = args.table[1]
        local key = args.table[2]

        key = tonumber(key) or key
        for k, v in ipairs(t.keys) do
            if v == key then
                return true
            end
        end

        return false
    end)
    _table.table.find = plume.obj.luaFunction("find", function (args)
        local t = args.table[1]
        local x = args.table[2]

        for k, v in ipairs(t.keys) do
            if t.table[v] == x then
                return v
            end
        end
    end)
    _table.table.finds = plume.obj.luaFunction("finds", function (args)
        local t = args.table[1]
        local x = args.table[2]

        local result = plume.obj.table(0, 0)
        for k, v in ipairs(t.keys) do
            if t.table[v] == x then
                table.insert(result.table, v)
                table.insert(result.keys, #result.table)
            end
        end

        return result
    end)

    plume.std.table = _table
    plume.std.tostring = {} -- hardcoded

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

    plume.std.lua.table.require =  plume.obj.luaFunction("require", function(args, runtime, fileID)
        local firstFilename = runtime.files[1].name
        local lastFilename  = runtime.files[fileID].name

        local filename, searchPaths = plume.getFilenameFromPath(args.table[1], true, runtime, firstFilename, lastFilename)
        if filename then
            return dofile(filename)(plume) 
        else
            msg = "Error: cannot open '" .. args.table[1] .. "'.\nPaths tried:\n\t" .. table.concat(searchPaths, '\n\t')
            error(msg, 0)
        end
    end)
end