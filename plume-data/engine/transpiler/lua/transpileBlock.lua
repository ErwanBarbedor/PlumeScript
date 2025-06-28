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

return function(plume)
    function plume.transpileBlock(node, builder, children, returnType, returnMethod, isFirstBlock, endLabel)
        
        if not isFirstBlock then
            builder:open(node, "do")
        end

        local deep    = builder.deep
        local accName = "__plume_temp_" .. deep
        
        if node.kind ~= "VOID" then
            if returnType == "TEXT" then
                builder:write(node, "local " .. accName .. " = __plume_buffer()")
            elseif returnType == "TABLE" then
                builder:write(node, "local " .. accName .. " = __plume_table()")
            end
        end

        for _, child in ipairs(children) do
            local value = plume.transpileASTToLua(child, builder, accName, node.returnType == "VALUE")
            
            if value and node.kind ~= "VOID" then
                if returnType == "TEXT" then
                    builder:write(node, "__plume_buffer_insert(" .. accName .. ", " .. value .. ")")
                end
            end
        end
        
        if endLabel then
            builder:write(node, "::" .. endLabel .. "::")
        end
        
        if node.kind ~= "VOID" then
            if returnType == "TEXT" then
                builder:write(node, accName .. " = " .. accName .. ":tostring()")
            end

            if returnType == "NIL" then
                builder:write(node, "local " .. accName)
            end
        end
        
        local returnedChunk = returnMethod(accName)
        if returnedChunk then
            builder:write(node, returnedChunk)
        end

        if not isFirstBlock then
            builder:close(node, "end")
        end
    end

end