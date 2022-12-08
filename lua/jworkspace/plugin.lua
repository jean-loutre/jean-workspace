--- The Jean Workspace plugin instance
local iter = require("jlua.iterator").iter
local List = require("jlua.list")
local Map = require("jlua.map")
local is_callable = require("jlua.type").is_callable

local BoundContext = require("jnvim.bound-context")
local Path = require("jnvim.path")

local Workspace = require("jworkspace.workspace")
local load_templates = require("jworkspace.template").load_templates
local constants = require("jworkspace.template")

local Plugin = BoundContext:extend()

local function load_workspace_mapper(mapper_config)
	if is_callable(mapper_config) then
		return mapper_config
	end
	assert(false) -- TODO: log error
end

function Plugin:init(config)
	self:parent("init", "jw")
	self._config = Map(constants.default_config)
	self._config:update(config)

	local workspace_mappers = self._config:pop("workspace_mappers", {})

	self._active_workspace_id = 0
	self._templates = self._config:pop("templates", {})
	self._workspace_mappers = iter(workspace_mappers):map(load_workspace_mapper):to_list()
	self._workspaces = List({})

	self:bind_user_command("load_workspace", { nargs = "*" })
	self:bind_user_command("activate_workspace", { nargs = 1 })
	self:bind_function("get_workspace_name")
	self:bind_function("get_workspace_root")
	self:bind_autocommand("BufAdd", "_on_buffer_add")
	self:bind_autocommand("BufEnter", "_on_buffer_enter")
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

--- Activate a workspace.
--
-- Parameters
-- ----------
--
-- id : int
--     The workspace id
function Plugin:activate_workspace(opts)
	self:_activate_workspace(tonumber(opts.args))
end

function Plugin:_on_buffer_add(args)
	local root, name = self._workspace_mappers
		:map(function(it)
			return it(args.buf)
		end)
		:first()

	if root and name then
		self:_load_workspace(root, name, Path(args.buf.name))
	end
end

function Plugin:_on_buffer_enter(args)
	local buffer_path = Path(args.buf.name)
	local workspace_id_to_activate = iter(pairs(self._workspaces)):first(function(_, workspace)
		return workspace:matches_file(buffer_path)
	end)

	if not workspace_id_to_activate then
		return
	end

	self:_activate_workspace(workspace_id_to_activate)
end

function Plugin:_load_workspace(root, name, trigger_path)
	local config = load_templates(self._templates):reduce(function(config, template_it)
		Map.update(config, template_it(root, name) or {})
		return config
	end, {})

	local new_workspace = Workspace(Path(root), name, config)

	if trigger_path ~= nil and not new_workspace:matches_file(trigger_path) then
		return
	end

	self._workspaces:push(new_workspace)
	local workspace_id = #self._workspaces
	self:execute_user_autocommand("WorkspaceLoaded", { workspace = workspace_id, config = config })
	self:_activate_workspace(workspace_id)
end

function Plugin:_activate_workspace(id)
	assert(id == 0 or self._workspaces[id], "Invalid workspace id")

	if self._active_workspace_id == id then
		return
	end

	if self._active_workspace_id ~= 0 then
		self:execute_user_autocommand("WorkspaceDeactivated", { workspace = self._active_workspace_id })
	end

	self._active_workspace_id = id

	if self._active_workspace_id ~= 0 then
		self:execute_user_autocommand("WorkspaceActivated", { workspace = self._active_workspace_id })
	end
end

return Plugin
