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
	plume.warning = {}
	plume.warning.cache = {}

	--- Emits a runtime warning with deduplication.
	-- Displays the warning once per unique message globally, and once per specific
	-- position (instruction pointer). The detailed help text is only shown on the
	-- first global occurrence of the message, regardless of call site.
	-- @param msg string the warning message
	-- @param help string|nil detailed help text (displayed once globally, then omitted)
	-- @param runtime table current execution context
	-- @param ip number instruction pointer identifying the call site
	function plume.warning.runtimeWarning(msg, help, runtime, ip)
	    if plume.warning.cache[msg] then
	        help = nil
	    else
	        plume.warning.cache[msg] = {}
	    end

	    if plume.warning.cache[msg][ip] then
	        return
	    end
	    plume.warning.cache[msg][ip] = true

	    print("Warning: " .. msg)
	    local node = plume.error.getNode(runtime, ip)
	    local lineInfos = plume.error.getLineInfos(node)
	    print(plume.error.formatLine(lineInfos))

	    if help then
	    	print("=== Migration help ===")
	        print(help)
	        print("======================")
	    end
	end

	--- Emits a deprecation warning for features scheduled for removal.
	-- Formats the description with target version and indents the help text.
	-- Inherits deduplication logic from runtimeWarning.
	-- @param version string target version for removal (e.g., "1.0")
	-- @param description string description of the deprecated feature
	-- @param help string migration instructions or alternatives
	-- @param runtime table current execution context
	-- @param ip number instruction pointer identifying the call site
	function plume.warning.deprecated(version, description, help, runtime, ip, issue)
	    help = "  "..help:gsub('\n', '\n  ')
	    plume.warning.runtimeWarning(
	        string.format("%s will be removed in version %s (#%s).", description, version, issue),
	        help,
	        runtime,
	        ip
	    )
	end
end