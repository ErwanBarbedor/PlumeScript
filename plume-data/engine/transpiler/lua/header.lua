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

return function(plume, transpiler)
    transpiler.headerContent = {
        {
            name = "expandList",
            content = "local __plume_expand_list = plume.expandList\n"
        },
        {
            name = "expandHash",
            content = "local __plume_expand_hash = plume.expandHash\n"
        },
        {
            name = "initArgs",
            content = "local __plume_init_args = plume.initArgs\n"
        },
        {
            name = "check",
            content = "local __plume_check = plume.checkConcat\n"
        },
        {
            name = "insert",
            content = "local __plume_insert = __lua.table.insert\n"
        },
        {
            name = "concat",
            content = "local __plume_concat = __lua.table.concat\n"
        }
    }
end