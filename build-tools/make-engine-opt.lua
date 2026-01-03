require "build-tools/make-engine"

local function parse(text)
end

local function inline(ast)
end

local function export(ast)
	return ""
end

local base = io.open('plume-data/engine/engine.lua')

local ast = parse(base:read())
inline(ast)
io.open('plume-data/engine/engine-opt.lua', "w"):write(export(ast))