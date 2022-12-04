--- A loaded workspace
local Object = require("jlua.object")

local Workspace = Object:extend()

--- Initialize a workspace
function Workspace:init(root, name)
	self._root = root
	self._name = name
end

--- Get the workspace name
function Workspace.properties.name:get()
	return self._name
end

--- Get the workspace root directory
function Workspace.properties.root:get()
	return self._root
end

return Workspace
