require "build-tools/make-engine"

local lib = require "build-tools/luaParser"

local function inline(ast)
end

local base = io.open('plume-data/engine/engine.lua')

local ast = lib.parse(base:read("*a"))
inline(ast)
io.open('plume-data/engine/engine-opt.lua', "w"):write(lib.export(ast))