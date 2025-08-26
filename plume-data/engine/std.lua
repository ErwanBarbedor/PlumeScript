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
	local std = {
		print = function(arg)
			print(table.unpack(arg))
		end,

		type = function(args)
            local value = args[2][1]
			local t = type(value)
            if t=="table" then
                if value==plume.obj.empty then
                    return "empty"
                else
                    return value[1]
                end
            else
                return t
            end
        end,

        table = function(args)
            return args
        end,

        join = function(args)
            return table.concat(args[2], args[2].sep or "")
        end,

        void = function(args)
        end,

        -- temporary name
        tostring = function(args)
            local result = {}
            for _, x in ipairs(args[2]) do
                if x == plume.obj.empty then
                else
                    table.insert(result, tostring(x))
                end
            end
            return table.concat(result)
        end,

        seq = function(args)
            local start = args[2][1]
            local stop  = args[2][2]

            if not stop then
                stop = start
                start = 1
            end

            local iterator = plume.obj.table(1, 2)
            iterator[2][1] = start-1
            iterator[2].next = plume.obj.luaFunction("next", function()
                iterator[2][1]  = iterator[2][1] +1
                if iterator[2][1] == stop+1 then
                    return plume.obj.empty
                else
                    return iterator[2][1]
                end
            end)

            iterator[4].iter = plume.obj.luaFunction("iter", function()
                return iterator
            end)

            return iterator
        end,

        enumerate = function(args)
            local t = args[2][1]

            local iterator = plume.obj.table(1, 2)
            iterator[2][1] = 0
            iterator[2].next = plume.obj.luaFunction("next", function()
                iterator[2][1]  = iterator[2][1] +1
                local value = t[2][iterator[2][1]]
                if not value then
                    return plume.obj.empty
                else
                    local result = plume.obj.table(0, 2)
                    result[2].index = iterator[2][1]
                    result[2].value = value

                    result[3] = {"index", "value"}
                    return result
                end
            end)

            iterator[4].iter = plume.obj.luaFunction("iter", function()
                return iterator
            end)

            return iterator
        end,

        items = function(args)
            local t = args[2][1]

            local iterator = plume.obj.table(1, 2)
            iterator[2][1] = 0
            iterator[2].next = plume.obj.luaFunction("next", function()
                iterator[2][1]  = iterator[2][1] +1
                local key = t[3][iterator[2][1]]
                if not key then
                    return plume.obj.empty
                else
                    local result = plume.obj.table(0, 2)
                    result[2].key = key
                    result[2].value = t[2][key]

                    result[3] = {"key", "value"}
                    return result
                end
            end)

            iterator[4].iter = plume.obj.luaFunction("iter", function()
                return iterator
            end)

            return iterator
        end
	}

    plume.std = {}
    for name, f in pairs(std) do
        plume.std[name] = plume.obj.luaFunction(name, f)
    end

end