--- Togglable window hosting a terminal buffer
-- @module gerard.terminals.terminal
local Object = require("jlua.object")
local ContextHandler = require("jnvim.context-handler")
local iter = require("jlua.iterator").iter

local TerminalWindow = Object:extend()

--- Initialize a new togglable terminal window
-- @param config The terminal window configuration
function TerminalWindow:init(config)
	self.config = config
end

--- Toggle this terminal windowc
function TerminalWindow:toggle()
	if self.window_id == nil or not vim.api.nvim_win_is_valid(self.window_id) then
		self:open()
	else
		self:close()
	end
end

--- Open this terminal window
function TerminalWindow:open()
	local mode = self.config.mode
	local buffer_id = self:_get_buffer()
	if mode == "floating" then
		self:_open_floating(buffer_id)
	elseif mode == "current_window" then
		self.window_id = vim.api.nvim_get_current_win()
		self.old_buffer_id = vim.api.nvim_win_get_buf(self.window_id)
		vim.api.nvim_win_set_buf(self.window_id, buffer_id)
	else
		self:_open_split(buffer_id)
	end
	vim.cmd("startinsert")
end

function TerminalWindow:close()
	local mode = self.config.mode
	if mode == "current_window" then
		if self.window_id then
			assert(self.old_buffer_id)
			vim.api.nvim_win_set_buf(self.window_id, self.old_buffer_id)
		end
	else
		vim.api.nvim_win_close(self.window_id, true)
	end
	self.window_id = nil
end

--- Send a command to the hosted terminal
-- @param command Command to send to this terminal, as a string
function TerminalWindow:send(command)
	vim.api.nvim_chan_send(self.job, command .. "\n")
end

function TerminalWindow:_get_buffer()
	if self.buffer == nil or not vim.api.nvim_buf_is_valid(self.buffer) then
		self.buffer = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_buf_call(self.buffer, function()
			self:_spawn()
		end)
	end

	return self.buffer
end

function TerminalWindow:_spawn()
	print(vim.inspect(self.config.command))
	self.job = vim.fn.termopen(self.config.command, {
		cwd = vim.fn.getcwd(),
		on_exit = function()
			self:_on_exit()
		end,
	})
end

function TerminalWindow:_on_exit()
	self.job = nil
	vim.api.nvim_buf_delete(self.buffer, { force = true })
end

function TerminalWindow:_open_split(buffer_id)
	local mode = self.config.mode
	local size
	local command
	if mode == "top" then
		size = self.config.height
		command = "topleft"
	elseif mode == "bottom" then
		size = self.config.height
		command = "botright"
	elseif mode == "right" then
		size = self.config.width
		command = "botright"
	elseif mode == "left" then
		size = self.config.width
		command = "topleft"
	end

	vim.cmd(command .. " " .. size .. "split")
	self.window_id = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(self.window_id, buffer_id)
end

function TerminalWindow:_open_floating(buffer_id)
	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")

	local win_height = math.ceil(height - 4)
	local win_width = math.ceil(width - 10)

	local row = math.ceil((height - win_height) / 2 - 1)
	local col = math.ceil((width - win_width) / 2)

	local opts = {
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
		border = "rounded",
	}

	self.window_id = vim.api.nvim_open_win(buffer_id, true, opts)
end

local TerminalWorkspace = ContextHandler:extend()

function TerminalWorkspace:init(config)
	self:parent("init", "jw")

	self._windows = {}
	for name, term_config in iter(config) do
		self._windows[name] = TerminalWindow(term_config)
	end
	self:bind_user_command("toggle_terminal", { nargs = 1 })
end

function TerminalWorkspace:toggle_terminal(args)
	self._windows[args.args]:toggle()
end

function TerminalWorkspace:disable()
	self:parent("disable")
	for _, window in iter(self._windows) do
		window:close()
	end
end

local Terminals = ContextHandler:extend()

function Terminals:init()
	self:parent("init", "jw")
	self:bind_user_autocommand("workspace_enter")
	self:bind_user_autocommand("workspace_leave")
	self._workspaces = {}
	self:enable()
end

function Terminals:workspace_enter()
	local workspace_config = vim.fn["jw#get_workspace_config"]()
	local term_config = workspace_config.terminals

	if not term_config then
		return
	end

	local workspace_id = vim.fn["jw#get_current_workspace"]()

	if not self._workspaces[workspace_id] then
		self._workspaces[workspace_id] = TerminalWorkspace(term_config)
	end

	self._workspaces[workspace_id]:enable()
end

function Terminals:workspace_leave()
	local workspace_id = vim.fn["jw#get_current_workspace"]()

	if self._workspaces[workspace_id] then
		self._workspaces[workspace_id]:disable()
	end
end

Terminals()
