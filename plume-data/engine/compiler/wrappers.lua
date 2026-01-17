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
  
return function (plume, context)
    --- Initialize an accumulation table
    --- @return nil
    function context.accTableInit(node)  
        context.registerOP(node, plume.ops.BEGIN_ACC, 0, 0)  
        context.registerOP(node, plume.ops.TABLE_NEW, 0, 0)  
    end 

    --- Wrapper for accumulation block. Initialize accumulator and finalize the block.
    --- Accumulation block doesn't have its own scope.
    --- depending of its type.
    --- @param f|nil function Function used to process children. Default to context.childrenHandler 
    --- @return function
    function context.accBlock(f)  
        f = f or context.childrenHandler

        --- @param node node
        --- @param label|nil string Used to jump at block end, but before finalizer.
        --- @return nil
        return function (node, label)  
            if node.type == "TEXT" then  
                context.toggleConcatOn()
                context.registerOP(node, plume.ops.BEGIN_ACC, 0, 0)  
                f(node)  
                if label then  
                    context.registerLabel(node, label)  
                end  
                context.registerOP(nil, plume.ops.ACC_TEXT, 0, 0)  
            else  
                context.toggleConcatOff()
                -- More or less a TEXT block with 1 element.
                -- Don't use ACC_TEXT to prevent conversion to string
                if node.type == "VALUE" then  
                    f(node)  
                    if label then  
                        context.registerLabel(node, label)  
                    end  
                -- Handled by block in most cases  
                elseif node.type == "TABLE" then  
                    context.accTableInit(node)  
                    f(node)  
                    if label then  
                        context.registerLabel(node, label)  
                    end  
                    context.registerOP(nil, plume.ops.ACC_TABLE, 0, 0)  
                -- Exactly same behavior as BEGIN_ACC (nothing) ACC_TEXT  
                elseif node.type == "EMPTY" then  
                    f(node)  
                    if label then  
                        context.registerLabel(node, label)  
                    end  
                    context.registerOP(nil, plume.ops.LOAD_EMPTY, 0, 0)  
                end  
            end  
            context.toggleConcatPop()
        end          
    end  
    
    --- Wrapper for scope.
    --- Scope isn't created without local variable declaration.
    --- @param f|nil function Function used to process children. Default to context.childrenHandler 
    --- @param internVar|nil number
    --- @return function
    function context.scope(f, internVar)  
        f = f or context.childrenHandler  
        return function (node)  
            local lets = #plume.ast.getAll(node, "LET") + (internVar or 0)
            if lets>0 then  
                context.registerOP(node, plume.ops.ENTER_SCOPE, 0, lets)  
                table.insert(context.scopes, {})  
                f(node)  
                table.remove(context.scopes)  
                context.registerOP(nil, plume.ops.LEAVE_SCOPE, 0, 0)  
            else  
                f(node)  
            end  
        end          
    end  
    
    --- Wrapper for file
    --- @param f|nil function Function used to process children. Default to context.childrenHandler 
    --- @return function
    function context.file(f)  
        f = f or context.childrenHandler
        return function (node)  
            table.insert(context.roots, #context.scopes+1)  
            f(node)  
            table.remove(context.roots)  
        end          
    end  
end