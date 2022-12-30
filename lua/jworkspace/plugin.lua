--- The Jean Workspace plugin instance
local List = require("jlua.list")
local Map = require("jlua.map")
local get_logger = require("jlua.logging").get_logger
local is_string = require("jlua.type").is_string
local iter = require("jlua.iterator").iter

local ContextHandler = require("jnvim.context-handler")
local Buffer = require("jnvim.buffer")
local Path = require("jnvim.path")
local load_commands = require("jnvim.tools").load_commands

local Workspace = require("jworkspace.workspace")
local load_config = require("jworkspace.template").load_config
local constants = require("jworkspace.constants")

local Plugin = ContextHandler:extend()

local log = get_logger(...)

function Plugin:init(config)
	self:parent("init", "jw")

	load_commands({ "JNOpenLog" })

	self._config = Map(constants.default_config)
	self._config:update(config)

	self._active_workspace_id = 0
	self._root_mappers = List(self._config:pop("root_mappers", {}))
	self._templates = self._config:pop("templates", {})
	self._workspaces = List({})

	self:bind_user_command("add_workspace", { nargs = "*" })
	self:bind_user_command("enter_workspace", { nargs = 1 })
	self:bind_function("get_current_workspace")
	self:bind_function("get_workspace_config")
	self:bind_function("get_workspace_name")
	self:bind_function("get_workspace_root")
	self:bind_function("buf_matches_workspace")
	self:bind_autocommand("BufEnter", "_on_buffer_enter")
	self:enable()
end

--- Return the active workspace id
function Plugin:get_current_workspace()
	return self._active_workspace_id
end

--- Create a new workspace
--
-- Parameters
-- ----------
-- name : str
--     Name of the workspace.
-- root: str
--     Root directory of the workspace
function Plugin:add_workspace(args)
	local root = Path(args.fargs[1] or Path.cwd())
	local name = args.fargs[2] or root.basename
	self:_add_workspace(tostring(root), name)
end

--- Return the name of the workspace with the given id
--
-- Parameters
-- ----------
-- handle : int, optional
--     Handle of the workspace. If none, will return the name of the active workspace.
function Plugin:get_workspace_name(id)
	id = id or self._active_workspace_id
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
	id = id or self._active_workspace_id
	assert(self._workspaces[id], "Invalid workspace id")
	return tostring(self._workspaces[id].root)
end

--- Return the configuration of the workspace with the given id.
--
-- Parameters
-- ----------
-- handle : int, optional
--     Handle of the workspace. If none, will return the config of the active workspace.
function Plugin:get_workspace_config(id)
	id = id or self._active_workspace_id
	assert(self._workspaces[id], "Invalid workspace id")
	return self._workspaces[id].config
end

--- Activate a workspace.
--
-- Parameters
-- ----------
--
-- id : int
--     The workspace id
function Plugin:enter_workspace(opts)
	self:_enter_workspace(tonumber(opts.args))
end

--- Return true if a buffer matches a workspace filter
--
-- @param workspace int : Id of the workspace, or 0 to match against active workspace
-- @param buffer int : Id of the buffer
--- @returns boolean : true if the given buffer matches the given workspace
function Plugin:buf_matches_workspace(buffer, workspace)
	workspace = workspace or self._active_workspace_id

	if workspace == 0 then
		workspace = self._active_workspace_id
	end

	if not self._workspaces[workspace] then
		return true
	end

	buffer = buffer or 0

	assert(self._workspaces[workspace], "Invalid workspace id")
	return self._workspaces[workspace]:matches_file(Path(Buffer.from_handle(buffer).name))
end

function Plugin:_on_buffer_enter(args)
	local buffer_path = Path(args.buf.name)
	local workspace_id_to_activate = iter(pairs(self._workspaces)):first(function(_, workspace)
		return workspace:matches_file(buffer_path)
	end)

	if not workspace_id_to_activate then
		local root, name = self._root_mappers
			:map(function(it)
				return it(self._config, args.buf)
			end)
			:first()

		if root and name then
			assert(is_string(root))
			assert(is_string(name))
			self:_add_workspace(root, name, Path(args.buf.name))
		end
	else
		self:_enter_workspace(workspace_id_to_activate)
	end
end

function Plugin:_add_workspace(root, name, trigger_path)
	assert(is_string(root))
	assert(is_string(name))
	assert(trigger_path == nil or Path:is_class_of(trigger_path))
	log:debug("creating new workspace {} with root {}.", name, tostring(root))
	local config = load_config(root, name, Map(), self._templates)
	local new_workspace = Workspace(Path(root), name, config:to_raw())

	if trigger_path ~= nil and not new_workspace:matches_file(trigger_path) then
		return
	end

	self._workspaces:push(new_workspace)
	local workspace_id = #self._workspaces
	self:execute_user_autocommand("WorkspaceAdd")
	self:_enter_workspace(workspace_id)
end

function Plugin:_enter_workspace(id)
	assert(id == 0 or self._workspaces[id], "Invalid workspace id")

	if self._active_workspace_id == id then
		return
	end

	assert(self._active_workspace_id ~= nil)
	if self._active_workspace_id ~= 0 then
		log:debug("leaving workspace {}.", self:get_workspace_name())
		self:execute_user_autocommand("WorkspaceLeave")
	end

	self._active_workspace_id = id

	if self._active_workspace_id ~= 0 then
		log:debug("entering workspace {}.", self:get_workspace_name())
		self:execute_user_autocommand("WorkspaceEnter")
	end
end

return Plugin
