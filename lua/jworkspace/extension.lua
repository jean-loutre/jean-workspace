--- Base class for Jean-Workspace extension, providing helpers methods.
--- @module 'jworkspace.mappings'
local Map = require("jlua.map")
local Object = require("jlua.object")
local bind = require("jlua.functional").bind

local Context = require("jnvim.context")

local Extension = Object:extend()

Extension.Workspace = Object:extend()

function Extension.Workspace.enable() end

function Extension.Workspace.disable() end

function Extension:init()
	self._context = Context()
	self._workspaces = Map()
	self._context:add_autocommand(
		"User",
		{ pattern = "JWWorkspaceEnter", callback = bind(self._workspace_enter, self) }
	)
	self._context:add_autocommand(
		"User",
		{ pattern = "JWWorkspaceLeave", callback = bind(self._workspace_leave, self) }
	)
end

function Extension:enable()
	self._context:enable()
end

function Extension:disable()
	self._context:disable()
end

function Extension:_workspace_enter()
	assert(self._mappings == nil)
	local config = vim.fn["jw#get_workspace_config"]()

	local workspace_id = vim.fn["jw#get_current_workspace"]()
	local workspace = self._workspaces[workspace_id]
	if not workspace then
		workspace = self:_create_workspace(config)
		if not workspace then
			return
		end

		self._workspaces[workspace_id] = workspace
	end
	assert(Extension.Workspace:is_class_of(workspace))

	workspace:enable()
end

function Extension:_workspace_leave()
	local workspace_id = vim.fn["jw#get_current_workspace"]()
	if not self._workspaces[workspace_id] then
		return
	end
	self._workspaces[workspace_id]:disable()
end

function Extension._create_workspace(_)
	assert(false)
end

return Extension
