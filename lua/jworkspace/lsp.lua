local Map = require("jlua.map")
local ContextHandler = require("jnvim.context-handler")
local iter = require("jlua.iterator").iter

local Lsp = ContextHandler:extend()

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
		workspace = Map()
		self._workspaces[workspace_id] = workspace
	end

	local buffer_filetype = vim.bo[args.buf.handle].filetype

	local _, client_id = workspace:first(function(filetype, _)
		return buffer_filetype == filetype
	end)

	if not client_id then
		local server_config = iter(lsp_config):first(function(server_config)
			return iter(server_config.filetypes or {}):any(function(filetype)
				return buffer_filetype == filetype
			end)
		end)

		if not server_config then
			return
		end

		local workspace_root = vim.fn["jw#get_workspace_root"]()

		client_id = vim.lsp.start({
			name = server_config.server_name or "LSP",
			cmd = server_config.cmd,
			root_dir = workspace_root,
			settings = server_config.settings,
		})

		for filetype in iter(server_config.filetypes) do
			workspace[filetype] = client_id
		end
	end

	vim.lsp.buf_attach_client(args.buf.handle, client_id)
end

Lsp()
