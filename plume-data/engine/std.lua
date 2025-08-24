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
	plume.std = {
		print = function(positionnals, named)
			print(table.unpack(positionnals))
		end,

		type = function(positionnals, named)
			local t = type(positionnals[1])
            if t=="table" then
                if t==plume.obj.empty then
                    return "empty"
                else
                    return t[1]
                end
            else
                return t
            end
        end
	}
end