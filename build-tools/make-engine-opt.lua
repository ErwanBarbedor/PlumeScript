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

-- Optimize engine.lua to performances
-- Thanks for thenumbernine lua-parser lib.

package.path =  "build-tools/?.lua;build-tools/thenumbernine/?.lua;build-tools/thenumbernine/ext/?.lua;;build-tools/thenumbernine/parser/?.lua;;build-tools/thenumbernine/template/?.lua;" .. package.path
require "make-engine"

local plume  = require "plume-data/engine/init"
local Parser = require "parser"

local VM_PATH = "plume-data/engine/engine.lua"

local tree = Parser.parse(io.open(VM_PATH):read('*a'), 'plume-data/engine/engine.lua', '5.2', true)