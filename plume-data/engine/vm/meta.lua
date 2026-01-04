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

--- To rewrite
function _META_CHECK (name, macro)
	local comopps = "add mul div sub mod pow"
	local binopps = "eq lt"
	local unopps = "minus"

	local expectedParamCount
	for opp in comopps:gmatch('%S+') do
		if name == opp then
			expectedParamCount = 2
		elseif name:match("^" .. opp .. "[rl]") then
			expectedParamCount = 1
		end
	end
	for opp in binopps:gmatch('%S+') do
		if name == opp then
			expectedParamCount = 1
		end
	end
	for opp in unopps:gmatch('%S+') do
		if name == opp then
			expectedParamCount = 0
		end
	end

	if expectedParamCount then
		if macro.positionalParamCount ~= expectedParamCount then
			return false, "Wrong number of positionnal parameters for meta-macro '" .. name .. "', " .. macro.positionalParamCount .. " instead of " .. expectedParamCount .. "."
		end
		if macro.namedParamCount > 1 then -- 1 for self
			return false, "Meta-macro '" .. name .. "' dont support named parameters."
		end
	elseif name ~= "call" and name ~= "tostring" and name ~= "tonumber" and name ~= "getindex" and name ~= "setindex" and name ~= "next" and name ~= "iter" then
		return false, "'" .. name .. "' isn't a valid meta-macro name."
	end

	return true
end