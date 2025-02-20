return function(plume)
    plume.plumeStdLib = {table={}}

    function plume.plumeStdLib.table.merge(...)
        local result = {}
        local index = 1

        for i = 1, select('#', ...) do
            local tbl = select(i, ...)
            if tbl then -- Gérer le cas où un argument est nil
                local len = #tbl
                table.move(tbl, 1, len, index, result)
                index = index + len
            end
        end

      return result
    end
end