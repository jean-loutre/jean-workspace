local Mock = require("jlua.mock")
local Path = require("jnvim.path")
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

function Suite.map_workspace()
	local workspace_root = Path.cwd() / "caiman_shredder"
	local _ = Plugin({
		workspace_mappers = {
			function(buffer)
				assert_equals(buffer.name, tostring(workspace_root / "setup.py"))
				return workspace_root, "Caiman Shredder"
			end,
		},
	})

	local workspace_loaded = Mock()

	Autocommand("User", { pattern = "jworkspace#workspace_loaded", callback = workspace_loaded })

	vim.cmd("e " .. tostring(workspace_root / "setup.py"))

	local workspace_id = workspace_loaded.calls[1][1].data.workspace
	assert_equals(vim.fn["jworkspace#get_workspace_name"](workspace_id), "Caiman Shredder")
	assert_equals(vim.fn["jworkspace#get_workspace_root"](workspace_id), tostring(workspace_root))
end

return Suite
