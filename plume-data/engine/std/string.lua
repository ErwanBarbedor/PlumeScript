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

-- Plume's calling procedure is different from that of lua, so you need to write a wrapper to use the standard functions
-- In the case of strings, this is not possible, as the strings in the interpreter and in the Plume transpiled code share the same functions, making it impossible to modify one without impacting the other.
-- A specific class is therefore needed to “emulate” a string.
return function(plume)
    plume.string = function (s)
        s = tostring(s)
        local stringT = {}
        local stringMT = {
            __tostring = function () return s end,
            __concat   = function (s1, s2)
                if s1 == stringT then
                    return s .. s2
                else
                    return s1 .. s
                end
            end,
            __type = "string"
        }
        
        for k, v in pairs(string) do
            if type(v) == "function" then
                stringT[k] = function(__plume_args)
                    
                    for i, x in ipairs(__plume_args) do
                        if type(x) == "table" and plume.type (x) == "string" then
                            __plume_args[i] = tostring(__plume_args[i])
                        end
                    end
                    
                    return v(s, unpack(__plume_args))
                end
            end
        end
        
        return setmetatable(stringT, stringMT)
    end
end