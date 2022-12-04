--- The Jean Workspace plugin instance
local Iterator = require("jlua.iterator")
local List = require("jlua.list")
local Map = require("jlua.map")
local is_callable = require("jlua.type").is_callable

local BoundContext = require("jnvim.bound-context")
local Path = require("jnvim.path")

local Template = require("jworkspace.template")
local Workspace = require("jworkspace.workspace")

local Plugin = BoundContext:extend()

local function load_workspace_mapper(mapper_config)
	if is_callable(mapper_config) then
		return mapper_config
	end
	assert(false) -- TODO: log error
end

function Plugin:init(config)
	self:parent("init", "jworkspace#")

	Map:wrap(config)

	self._workspaces = List({})
	self._workspace_mappers = Iterator.from_values(config:pop("workspace_mappers", {})):map(load_workspace_mapper)
	self._templates = Iterator.from_values(config:pop("templates", {})):map(Template)

	self:bind_user_command("JWLoadWorkspace", "load_workspace", { nargs = "*" })
	self:bind_function("get_workspace_name")
	self:bind_function("get_workspace_root")
	self:bind_autocommand("BufAdd", "_on_buffer_add")
	self:enable()
end

--- Create a new workspace
--
-- Parameters
-- ----------
-- name : str
--     Name of the workspace.
-- root: str
--     Root directory of the workspace
function Plugin:load_workspace(args)
	local root = Path(args.fargs[1] or Path.cwd())
	local name = args.fargs[2] or root.basename
	self:_load_workspace(root, name)
end

--- Return the name of the workspace with the given id
--
-- Parameters
-- ----------
-- handle : int, optional
--     Handle of the workspace. If none, will return the name of the active workspace.
function Plugin:get_workspace_name(id)
	assert(self._workspaces[id], "Invalid workspace id")
	return self._workspaces[id].name
end

--- Return the root directory of the workspace with the given id
--
-- Parameters
-- ----------
-- handle : int, optional
--     Handle of the workspace. If none, will return the name of the active workspace.
function Plugin:get_workspace_root(id)
	assert(self._workspaces[id], "Invalid workspace id")
	return tostring(self._workspaces[id].root)
end

function Plugin:_on_buffer_add(args)
	local root, name = self._workspace_mappers
		:map(function(it)
			return it(args.buf)
		end)
		:first()

	if root and name then
		self:_load_workspace(root, name)
	end
end

function Plugin:_load_workspace(root, name)
	local template = self._templates:first(function(template_it)
		return template_it:matches(root, name)
	end)

	local config = {}
	if template then
		config = template.workspace_config
	end

	local new_workspace = Workspace(root, name)
	self._workspaces:push(new_workspace)
	local workspace_id = #self._workspaces
	self:execute_user_autocommand("workspace_loaded", { workspace = workspace_id, config = config })
end

return Plugin
