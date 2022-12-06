--- Templates allow to define skeletons for workspaces
local List = require("jlua.list")
local Map = require("jlua.map")
local Path = require("jlua.path")
local is_string = require("jlua.type").is_string
local is_table = require("jlua.type").is_table
local is_callable = require("jlua.type").is_callable
local iter = require("jlua.iterator").iter

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
	self._workspace_filters = List(config:pop("workspace_filters", {}))

	local root = config:pop("root")
	if root then
		self._workspace_filter:push(matches_root_filter(root))
	end

	local name = config:pop("name")
	if name then
		self._workspace_filters:push(matches_name_filter(name))
	end

	self._workspace_config = config:pop("config")
end

--- Load templates from a source list.
--
-- Parameters
-- ----------
-- sources : { table | str }
--     Source list. Each item can be an array, in which case it'll be
--     considered as the template config itself, or a path glob. For
--     each path glob, all files with an extension matching one of the
--     loaders will be loaded.
-- loaders : { { extensions={str}, load=function(Path)-> table } }
-- 		List of loaders. Each loader must have a list of extensions it
-- 		can handle, and a load method taking path as input, and returning
-- 		template config as output.
--
-- Returns
-- -------
-- `jlua.iterator[Template]`
--      An iterator of templates loaded from the given sources.
function Template.load_templates(sources, loaders)
	local loader_index = Map()
	for loader in iter(loaders or {}) do
		assert(is_table(loader), "Bad argument.")
		assert(is_table(loader.extensions), "Bad argument")
		assert(is_callable(loader.load), "Bad argument")

		for extension in iter(loader.extensions or {}) do
			loader_index[extension] = loader.load
		end
	end

	local function load_file(path)
		local loader = loader_index[path.extension]
		if not loader then
			return false
		end

		return loader(path)
	end

	local function load_source(source)
		if is_table(source) then
			return iter({ source })
		end

		if is_string(source) then
			return Path.glob(source):filter(Path.is_file):map(load_file)
		end

		assert(false, "Invalid template source")
	end

	return iter(sources):map(load_source):flatten():filter():map(Template):to_list()
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
