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
            local value = arg[1]
			local t = type(value)
            if t=="table" then
                if t==plume.obj.empty then
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
        end
	}

    plume.std = {}
    for name, f in pairs(std) do
        plume.std[name] = plume.obj.luaFunction(name, f)
    end

end