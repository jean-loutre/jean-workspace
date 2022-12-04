local Mock = require("jlua.mock")
local TestSuite = require("jnvim.test-suite")
local Autocommand = require("jnvim.autocommand")
local Plugin = require("jworkspace.plugin")

local Suite = TestSuite()

function Suite.load_workspace()
	local _ = Plugin({})
	local workspace_loaded = Mock()

	local _ = {
		Autocommand("User", { pattern = "jworkspace#workspace_loaded", callback = workspace_loaded }),
	}

	vim.cmd("JWLoadWorkspace " .. vim.fn.getcwd() .. " otter_shredder")

	local workspace_id = workspace_loaded.calls[1][1].data.workspace
	assert_equals(vim.fn["jworkspace#get_workspace_name"](workspace_id), "otter_shredder")
	assert_equals(vim.fn["jworkspace#get_workspace_root"](workspace_id), vim.fn.getcwd())
end

return Suite
