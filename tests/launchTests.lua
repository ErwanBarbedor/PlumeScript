local lib = require "tests/lib"
local plume = require"plume-data/engine/init"

local tests = lib.loadTests("tests/plume")
lib.executeTests(tests, plume)
lib.analyzeResults(tests)

plume.debug.pprint(tests)
lib.generateReport(tests, "tests/report.html")