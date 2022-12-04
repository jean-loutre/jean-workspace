--- Templates allow to define skeletons for workspaces
local Map = require("jlua.map")
local List = require("jlua.list")
local Object = require("jlua.object")

local Template = Object:extend()

local function matches_root_filter(template_root)
	assert(template_root)
	return function(workspace_root, _)
		return workspace_root:is_child_of(template_root)
	end
end

local function matches_name_filter(template_name)
	assert(template_name)
	return function(_, workspace_name)
		return workspace_name == template_name
	end
end

--- Initialize the template
--
-- Parameters
-- ----------
-- config.root : jnvim.Path, optional
--     If set, this template will be applied to workspace in child directories
--     of config.root
--
-- config.name : str, optional
--     If set, this template will be applied to workspaces with this name.
--
-- config.config : {str, *}, optional
--     The configuration to apply to workspace matching this template.
function Template:init(config)
	Map:wrap(config or {})
	self._workspace_filters = List()

	local root = config:pop("root")
	if root then
		self._workspace_filter:push(matches_root_filter(self._root))
	end

	local name = config:pop("name")
	if name then
		self._workspace_filter:push(matches_name_filter(self._root))
	end

	self._workspace_config = config:pop("config")
end

--- Get the configuration for workspaces matching this template.
function Template.properties.workspace_config:get()
	return self._workspace_config
end

--- Check if the template should be appiled to a workspace.
--
-- Parameters
-- ----------
-- root : `jnvim.Path`
--     The root of the workspace to test.
-- name : str
--     The name of the workspace to test.
--
-- Returns
-- -------
-- bool
--     True if this template should be applied to the workspace with the given
--     root and name.
function Template:matches(root, name)
	return self._workspace_filters:iter():all(function(filter_it)
		return filter_it(root, name)
	end)
end

return Template
