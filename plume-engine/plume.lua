return function(plume)
    plume.plumeStdLib = {table={}, _VERSION = plume._VERSION}

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

    function plume.plumeStdLib:getFunctionInfo(fname)
        return self.store.f[fname]
    end

    function plume.initRuntime ()
        local result = {}

        for k, v in pairs(plume.plumeStdLib) do
            result[k] = v
        end

        result.store = {f=setmetatable({}, {__mode = "k"})}

        return result
    end

    
end