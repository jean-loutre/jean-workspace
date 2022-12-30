--- Extension managing lsp configuration, automatic buffer attachement
--- @module 'jworkspace.mappings'
local Map = require("jlua.map")
local bind = require("jlua.functional").bind
local get_logger = require("jlua.logging").get_logger
local is_table = require("jlua.type").is_table
local iter = require("jlua.iterator").iter

local log = get_logger(...)

local Context = require("jnvim.context")

local Extension = require("jworkspace.extension")

local Mappings = Extension:extend()

Mappings.Workspace = Extension.Workspace:extend()

local function map_mode(context, mode, mappings, default_options)
	for lhs, mapping in iter(mappings) do
		local options = Map(default_options)
		local rhs = mapping
		if is_table(mapping) then
			rhs = Map.pop(mapping, "rhs")
			options:update(mapping)
		end
		context:map(mode, lhs, rhs, options)
	end
end

function Mappings.Workspace:init(mappings)
	self._global_context = Context()
	self._named_contextes = Map()

	local default_options = Map.pop(mappings, "default_options", {})
	for mode, mode_mappings in iter(mappings) do
		if mode == "n" or mode == "v" or mode == "i" or mode == "t" then
			map_mode(self._global_context, mode, mode_mappings, default_options)
		else
			local named_context = Context()
			for actual_mode, context_mode_mappings in iter(mode_mappings) do
				map_mode(named_context, actual_mode, context_mode_mappings, default_options)
			end
			self._named_contextes[mode] = named_context
		end
	end

	self._global_context:add_user_command("JWEnableCustomMode", bind(self._enable_custom_mode, self), { nargs = 1 })

	self._global_context:add_user_command("JWDisableCustomMode", bind(self._disable_custom_mode, self))
end

function Mappings.Workspace:enable()
	self._global_context:enable()
	if self._active_custom_mode then
		self._active_custom_mode:enable()
	end
end

function Mappings.Workspace:disable()
	if self._active_custom_mode then
		self._active_custom_mode:disable()
	end
	self._global_context:disable()
end

function Mappings.Workspace:_enable_custom_mode(args)
	if self._active_custom_mode then
		self._active_custom_mode:disable()
	end

	self._active_custom_mode = self._named_contextes[args.args]

	if self._active_custom_mode then
		log:debug("Enabling custom mapping mode {}", args.args)
		self._active_custom_mode:enable()
	end
end

function Mappings.Workspace:_disable_custom_mode()
	if self._active_custom_mode then
		self._active_custom_mode:disable()
	end

	self._active_custom_mode = nil
end

function Mappings:init()
	self:parent("init")
	self:enable()
end

function Mappings._create_workspace(_, config)
	if not config.mappings then
		return nil
	end

	return Mappings.Workspace(config.mappings)
end

local instance = nil

return function(_, _, config)
	if config["mappings"] and not instance then
		instance = Mappings()
	end
end
