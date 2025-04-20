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
    local Builder = {}
    local insert = table.insert

    -- Temps functions
    function Builder:insertAll(t)
        for i = 1, #t do
            insert(self.code, t[i])
        end
    end
    function Builder:insert(x)
        insert(self.code, x)
    end

    function Builder:use (node)
        insert(self.map[#self.map], node)
    end

    -- Create a newline in the code and the map
    -- Follow indentation
    function Builder:newline()
        self.forceBreak = false
        insert(self.map, {})
        self:write("\n")
        self:write(("  "):rep(self.deep))
    end

    -- Add code to the output
    function Builder:write(code)
        if self.forceBreak then
            self:newline()
        end
        insert(self.code, code)
    end

    -- Functions to format code
    function Builder:emitASSIGNMENT(node, variable, compound, islocal)
        self:newline()
        self:use(node)

        if islocal then
            insert(self.code, "local ")
        end

        self:write(variable)
        self:write(" = ")

        if compound then
            self:write(variable)
            self:write(" " .. compound .. " ")
        end
    end

    function Builder:emitDEFINITION(node, name, islocal, inline)
        if not inline then
            self:newline()
        end

        self:use(node)

        if islocal then
            self:write("local ")
        end

        self:write("function " .. (name or "") .. "(__plume_args)")
        self.deep = self.deep + 1
    end

    function Builder:emitCALL(node, name)
        self:use(node)
        self:write(name)
    end

    function Builder:emitEMPTY_ARGS(node, tableName)
        self:write('{')
        if tableName then
            self:write("self = " .. tableName)
        end
        self:write('}')
    end

    function Builder:emitIF(node, condition)
        self:newline()
        self:use(node)
        self:write("if")
        self:write(condition)
        self:write(" then")
        self.deep = self.deep + 1
    end

    function Builder:emitELSEIF(node, condition)
        self:newline()
        self:use(node)
        self:write("elseif")
        self:write(condition)
        self:write(" then")
        self.deep = self.deep + 1
    end

    function Builder:emitFOR(node, iteration)
        self:newline()
        self:use(node)
        self:write("for")
        self:write(iteration)
        self:write(" do")
        self.deep = self.deep + 1
    end

    function Builder:emitWHILE(node, condition)
        self:newline()
        self:use(node)
        self:write("while")
        self:write(condition)
        self:write(" do")
        self.deep = self.deep + 1
    end

    function Builder:emitELSE()
        self.deep = self.deep - 1
        self:newline()
        self:write("else")
        self.deep = self.deep + 1
    end

    function Builder:emitBREAK()
        self:newline()
        self:write("break")
    end

    function Builder:emitRETURN()
        self:newline()
        self:write("return ")
    end

    function Builder:emitEND()
        self.deep = self.deep - 1
        self:newline()
        self:write("end")
    end

    function Builder:emitTEXT(node, text)
        text = text:gsub('"', '\\"')

        self:use(node)
        self:write('"')
        self:write(text)
        self:write('"')
    end

    function Builder:emitLUA(node, code)
        self:use(node)

        if #code > 0 then
            self:write('(')
            self:write(code)
            self:write(')')
        else
            self:write("nil")
        end
    end

    function Builder:emitVARIABLE(node, variable)
        self:use(node)
        self:write(variable)
    end

    function Builder:emitOPEN(char)
        self:write(char)
        self.deep = self.deep + 1
        self.forceBreak = true
    end

    function Builder:emitCLOSE(char)
        self.deep = self.deep - 1
        self:newline()
        self:write(char)   
    end

    -- Predefined chuncks of code
    function Builder:chunckINIT_VARARG(argName, argCount)
        self:emitASSIGNMENT(nil, argName, nil, true)
        self:write("__plume_args")
    end

    function Builder:chunckINIT_NAMED_PARAM(argName, callback)
        self:emitASSIGNMENT(nil, argName, nil, true)
        self:write("__plume_args." .. argName)

        self:emitIF(nil, " " .. argName .. " == nil")
        self:emitASSIGNMENT(nil, argName)

        callback()

        self:emitELSE()
        self:emitASSIGNMENT(nil, "__plume_args." .. argName)
        self:write("nil")
        self:emitEND()
    end

    function Builder:chunckINIT_SELF_PARAM(argName, callback)
        self:emitASSIGNMENT(nil, "self", nil, true)
        self:write("__plume_args.self")
        self:emitASSIGNMENT(nil, "__plume_args.self")
        self:write("nil")
    end

    function Builder:chunckINIT_PARAM(argName, pos, vararg)
        self:emitASSIGNMENT(nil, argName, nil, true)
        if vararg then
            self:write("__plume_remove(__plume_args, 1)")
        else
            self:write("__plume_args[" .. pos .. "]")
        end
    end

    function Builder:chunckEXPAND(name)
        self:emitFOR(nil, " k, v in __lua.ipairs(" .. name .. ")")
            self:newline()
            self:write("__plume_insert(__plume_temp, v)")
        self:emitEND()

        self:emitFOR(nil, " k, v in __lua.pairs(" .. name .. ")")
            self:emitIF(nil,  " not __lua.tonumber(k)")
                self:newline()
                self:write("__plume_temp[k] = v")
            self:emitEND()
        self:emitEND()
    end

    function plume.Builder(map)
        local builder = setmetatable({}, {__index=Builder})

        builder.code = {}
        builder.map  = map
        builder.deep = 0

        builder.forceBreak = false

        return builder
    end
end