#!/usr/bin/env luajit
local run = require 'template.run'

local b = 1

-- template with explicit environment
run([[
local a = <?=b?>
assert(a == 1)
]], {
	b = b,
})

--b = 1 -- doesn't work ... why isn't this global scope?
_G.b = 1

-- template using env
run[[
local a = <?=b?>
assert(a == 1)
]]

print'done'
