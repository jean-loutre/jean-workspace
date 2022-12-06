--- A loaded workspace
local Object = require("jlua.object")
local Map = require("jlua.map")
local List = require("jlua.list")

local Workspace = Object:extend()

--- Initialize a workspace
function Workspace:init(root, name, config)
	config = config or {}
	self._root = root
	self._name = name
	self._file_filters = List(Map.pop(config, "file_filters", {}))
end

--- Get the workspace name
function Workspace.properties.name:get()
	return self._name
end

--- Get the workspace root directory
function Workspace.properties.root:get()
	return self._root
end

--- Check if a file belongs to this workspace.
--
-- Parameters
-- ----------
-- path : `stylua.Path`
--     The path to the file to check.
--
-- Returns
-- -------
-- bool
--     True if the file belongs to the workspace, false otherwise.
function Workspace:matches_file(path)
	return path:is_child_of(self._root) and self._file_filters:all(function(filter_it)
		return filter_it(path)
	end)
end

return Workspace
