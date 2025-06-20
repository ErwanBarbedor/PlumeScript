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
    local builder = {}

    function plume.builder()
        return setmetatable({
            deep  = 0,
            stack = {},
            label = 0,

            map = {},
            code = ""
        }, {
            __index = builder
        })
    end

    function builder:getUniqueLabel(name)
        self.label = self.label + 1
        return "__plume_label_" .. name .. "_" .. self.label
    end

    function builder:finalize()
        local lines = {}

        for _, line in ipairs(self.stack) do
            table.insert(lines, ("    "):rep(line.deep) .. line.code)
            table.insert(self.map, {line.node})
        end

        self.code = table.concat(lines, "\n")
    end

    function builder:write(node, code)
        table.insert(self.stack, {
            node = node,
            code = code,
            deep = self.deep
        })
    end

    function builder:open(node, code)
        self:write(node, code)
        self.deep = self.deep + 1
    end

    function builder:close(node, code)
        self.deep = self.deep - 1
        self:write(node, code)
    end
end