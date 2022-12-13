--- Extension managing lsp configuration, automatic buffer attachement
--- @module 'jlua.lsp'
local Object = require("jlua.object")
local Map = require("jlua.map")
local ContextHandler = require("jnvim.context-handler")
local iter = require("jlua.iterator").iter

local Lsp = ContextHandler:extend()

local LspWorkspace = Object:extend()

function LspWorkspace:init()
	self._servers = {}
end

---@param buffer jnvim.Buffer
function LspWorkspace:attach(buffer)
	local workspace_config = vim.fn["jw#get_workspace_config"]()
	local lsp_config = workspace_config.lsp

	if not lsp_config then
		return
	end

	local buffer_servers = iter(lsp_config.servers or {}):filter(function(_, config)
		return iter(config.filetypes or {}):contains(buffer.filetype)
	end):to_map()

	for name, config in buffer_servers:iter() do
		local client_id = self._servers[name]
		if not client_id then
			client_id = self:_start_server(name, config)
		end

		vim.lsp.buf_attach_client(buffer.handle, client_id)
	end
end

function LspWorkspace:_start_server(server_name, server_config)
	local workspace_root = vim.fn["jw#get_workspace_root"]()
	local client_id = vim.lsp.start({
		name = server_name,
		cmd = server_config.cmd,
		root_dir = workspace_root,
		settings = server_config.settings,
		opts = {
			reuse_client = function()
				return false
			end,
		},
	})

	self._servers[server_name] = client_id
	return client_id
end

function Lsp:init()
	self:parent("init", "jw")
	self._workspaces = Map()
	self:bind_autocommand("BufEnter", "buffer_enter")
	self:enable()
end

function Lsp:buffer_enter(args)
	local workspace_config = vim.fn["jw#get_workspace_config"]()
	local lsp_config = workspace_config.lsp

	if not lsp_config then
		return
	end

	local workspace_id = vim.fn["jw#get_current_workspace"]()
	local workspace = self._workspaces[workspace_id]
	if not workspace then
		workspace = LspWorkspace()
		self._workspaces[workspace_id] = workspace
	end

	workspace:attach(args.buf)
end

Lsp()
