local function importFunction (f)
    return function(...) return f((unpack or table.unpack)(...)) end
end

local function importAllFunction (t, tcache, tcacheNames)
    local result = {}
    tcache = tcache or {}
    tcacheNames = tcacheNames or {}

    for k, v in pairs(t) do
        if type(v) == "function" then
            result[k] = importFunction(v)
        elseif type(v) == "table" then
            if not tcacheNames[v] then
                tcacheNames[v] = true
                tcache[v] = importAllFunction (v, tcache, tcacheNames)
            end
            result[k] = tcache[v]
        end
    end

    return result
end

return function(plume)
    plume.plumeStdLib = {table={}, _VERSION = plume._VERSION}

    plume.luaStdLib = importAllFunction(_G)

    if table.move then
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
    else
        function plume.plumeStdLib.table.merge(...)
            local result = {}
            local index = 1

            for _, tbl in ipairs({...}) do
                if tbl then
                    for j = 1, #tbl do
                        result[index] = tbl[j]
                        index = index + 1
                    end
                end
            end

            return result
        end
    end

    plume.plumeStdLib.setk = importFunction (function (t, k, v)
        t[k] = v
    end)

    function plume.initRuntime ()
        local result = {plume = {}, __lua = _G}

        for k, v in pairs(plume.plumeStdLib) do
            result.plume[k] = v
        end

        for k, v in pairs(plume.luaStdLib) do
            result[k] = v
        end

        result._G = result

        return result
    end
end