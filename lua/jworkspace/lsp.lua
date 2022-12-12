local Map = require("jlua.map")
local ContextHandler = require("jnvim.context-handler")

local Lsp = ContextHandler:extend()

function Lsp:init()
	self:parent("init", "jw")
	self._clients = Map()
	self:bind_user_autocommand("workspace_enter")
	self:bind_autocommand("BufEnter", "buffer_enter")
	self:enable()
end

function Lsp:workspace_enter()
	local workspace_id = vim.fn["jw#get_current_workspace"]()
	if self._clients[workspace_id] ~= nil then
		return
	end

	local workspace_config = vim.fn["jw#get_workspace_config"]()
	local lsp_config = workspace_config.lsp
	if not lsp_config then
		return
	end

	local workspace_root = vim.fn["jw#get_workspace_root"]()

	self._clients[workspace_id] = vim.lsp.start({
		name = lsp_config.server_name or "LSP",
		cmd = lsp_config.cmd,
		root_dir = workspace_root,
	})
end

function Lsp:buffer_enter(args)
	local workspace_id = vim.fn["jw#get_current_workspace"]()
	local client_id = self._clients[workspace_id]
	if not client_id then
		return
	end

	vim.lsp.buf_attach_client(args.buf.handle, client_id)
end

Lsp()
