--- Extension managing lsp configuration, automatic buffer attachement
--- @module 'jworkspace.mappings'
local Map = require("jlua.map")
local Object = require("jlua.object")
local Context = require("jnvim.context")
local ContextHandler = require("jnvim.context-handler")
local iter = require("jlua.iterator").iter
local is_table = require("jlua.type").is_table

local Mappings = ContextHandler:extend()

local MappingWorkspace = Object:extend()

local function map_mode(context, mode, mappings)
	for lhs, mapping in iter(mappings) do
		local options = {}
		local rhs = mapping
		if is_table(mapping) then
			options = mapping
			rhs = Map.pop(options, "rhs")
		end
		context:map(mode, lhs, rhs, options)
	end
end

function MappingWorkspace:init(mappings)
	self._global_context = Context()
	self._named_contextes = Map()

	for mode, mode_mappings in iter(mappings) do
		if mode == "n" or mode == "v" or mode == "i" then
			map_mode(self._global_context, mode, mode_mappings)
		else
			local named_context = Context()
			for actual_mode, context_mode_mappings in iter(mode_mappings) do
				map_mode(named_context, actual_mode, context_mode_mappings)
			end
			self._named_contextes[mode] = named_context
		end
	end

	self._global_context:add_user_command("JWEnableCustomMode", function(mode)
		self:_enable_custom_mode(mode)
	end, { nargs = 1 })

	self._global_context:add_user_command("JWDisableCustomMode", function()
		self:_disable_custom_mode()
	end)
end

function MappingWorkspace:enable()
	self._global_context:enable()
	if self._active_custom_mode then
		self._active_custom_mode:enable()
	end
end

function MappingWorkspace:disable()
	if self._active_custom_mode then
		self._active_custom_mode:disable()
	end
	self._global_context:disable()
end

function MappingWorkspace:_enable_custom_mode(args)
	if self._active_custom_mode then
		self._active_custom_mode:disable()
	end

	self._active_custom_mode = self._named_contextes[args.args]

	if self._active_custom_mode then
		self._active_custom_mode:enable()
	end
end

function MappingWorkspace:_disable_custom_mode()
	if self._active_custom_mode then
		self._active_custom_mode:disable()
	end

	self._active_custom_mode = nil
end

function Mappings:init()
	self:parent("init", "jw")
	self._workspaces = Map()
	self:bind_user_autocommand("workspace_enter")
	self:bind_user_autocommand("workspace_leave")
	self:enable()
end

function Mappings:workspace_enter()
	assert(self._mappings == nil)
	local workspace_config = vim.fn["jw#get_workspace_config"]()
	local mappings = workspace_config.mappings

	if not mappings then
		return
	end

	local workspace_id = vim.fn["jw#get_current_workspace"]()
	if not self._workspaces[workspace_id] then
		self._workspaces[workspace_id] = MappingWorkspace(mappings)
	end
	self._workspaces[workspace_id]:enable()
end

function Mappings:workspace_leave()
	local workspace_id = vim.fn["jw#get_current_workspace"]()
	if not self._workspaces[workspace_id] then
		return
	end
	self._workspaces[workspace_id]:disable()
end

Mappings()
