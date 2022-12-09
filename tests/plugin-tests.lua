local Mock = require("jlua.test.mock")

local Autocommand = require("jnvim.autocommand")
local TestSuite = require("jnvim.test-suite")

local Plugin = require("jworkspace.plugin")

local Suite = TestSuite()

local function mock_autocommand(jw_pattern)
	local mock = Mock()
	Autocommand("User", { pattern = "JW" .. jw_pattern, callback = mock })
	return mock
end

function Suite.load_workspace()
	Plugin({})

	local mock = mock_autocommand("WorkspaceLoaded")

	vim.cmd("JWLoadWorkspace /caiman_shredder caiman_shredder")

	assert_equals(#mock.calls, 1)
	assert_equals(vim.fn["jw#get_workspace_name"](), "caiman_shredder")
	assert_equals(vim.fn["jw#get_workspace_root"](), "/caiman_shredder")
end

function Suite.map_workspace()
	Plugin({
		workspace_mappers = {
			function(buffer)
				assert_equals(buffer.name, "/caiman_shredder/setup.py")
				return "/caiman_shredder", "Caiman Shredder"
			end,
		},
	})

	local mock = mock_autocommand("WorkspaceLoaded")

	vim.cmd("e /caiman_shredder/setup.py")

	assert_equals(#mock.calls, 1)
	assert_equals(vim.fn["jw#get_workspace_name"](), "Caiman Shredder")
	assert_equals(vim.fn["jw#get_workspace_root"](), "/caiman_shredder")
end

function Suite.apply_template()
	Plugin({
		templates = function(_, name)
			if name == "caiman_shredder" then
				return {
					power = "12kw",
				}
			end
		end,
	})

	local mock = mock_autocommand("WorkspaceLoaded")

	vim.cmd("JWLoadWorkspace /caiman_electrifier caiman_electrifier")
	assert_equals(#mock.calls, 1)
	assert_equals(vim.fn["jw#get_workspace_config"](), {})

	mock:reset()
	vim.cmd("JWLoadWorkspace /caiman_shredder caiman_shredder")
	assert_equals(#mock.calls, 1)
	assert_equals(vim.fn["jw#get_workspace_config"](), { power = "12kw" })
end

function Suite.merge_templates()
	Plugin({
		templates = {
			{ power = "12kw" },
			{ rpm = 15000 },
		},
	})

	local mock = mock_autocommand("WorkspaceLoaded")

	vim.cmd("JWLoadWorkspace /caiman_shredder caiman_shredder")
	assert_equals(#mock.calls, 1)
	assert_equals(vim.fn["jw#get_workspace_config"](), { power = "12kw", rpm = 15000 })
end

function Suite.file_filters()
	Plugin({
		workspace_mappers = {
			function(_)
				return "/caiman_shredder", "Caiman Shredder"
			end,
		},
		templates = {
			file_filters = {
				function(path)
					return path.basename == "dinglepop.lua"
				end,
			},
		},
	})

	local mock = mock_autocommand("WorkspaceLoaded")

	vim.cmd("e /caiman_shredder/setup.py")
	assert_equals(#mock.calls, 0)

	vim.cmd("e /caiman_shredder/dinglepop.lua")

	assert_equals(#mock.calls, 1)
	assert_equals(vim.fn["jw#get_workspace_name"](), "Caiman Shredder")
	assert_equals(vim.fn["jw#get_workspace_root"](), "/caiman_shredder")
end

function Suite.activate_workspace()
	Plugin({})

	vim.cmd("JWLoadWorkspace /caiman_shredder caiman_shredder")

	local id = vim.fn["jw#get_active_workspace"]()

	vim.cmd("JWActivateWorkspace 0")

	local activated_mock = mock_autocommand("WorkspaceActivated")
	local deactivated_mock = mock_autocommand("WorkspaceDeactivated")

	vim.cmd("JWActivateWorkspace " .. id)
	assert_equals(#activated_mock.calls, 1)
	assert_equals(#deactivated_mock.calls, 0)
	assert_equals(vim.fn["jw#get_active_workspace"](), id)

	activated_mock:reset()
	deactivated_mock:reset()

	-- Nothing happen if the workspace is already activated
	vim.cmd("JWActivateWorkspace " .. id)
	assert_equals(#activated_mock.calls, 0)
	assert_equals(#deactivated_mock.calls, 0)

	vim.cmd("JWActivateWorkspace 0")
	assert_equals(#activated_mock.calls, 0)
	assert_equals(#deactivated_mock.calls, 1)
end

function Suite.activate_workspace_on_load()
	Plugin({})
	local mock = mock_autocommand("WorkspaceActivated")

	vim.cmd("JWLoadWorkspace /caiman_shredder caiman_shredder")
	assert_equals(#mock.calls, 1)
end

function Suite.activate_workspace_on_buffer_switch()
	Plugin({
		workspace_mappers = {
			function(buffer)
				if buffer.name == "/caiman_shredder/setup.py" then
					return "/caiman_shredder", "Caiman Shredder"
				end
				return "/caiman_electrifier", "Caiman Electrifier"
			end,
		},
	})

	vim.cmd("e /caiman_shredder/setup.py")
	local shredder_id = vim.fn["jw#get_active_workspace"]()

	vim.cmd("e /caiman_electrifier/setup.py")
	local electrifier_id = vim.fn["jw#get_active_workspace"]()

	local activated_mock = mock_autocommand("WorkspaceActivated")
	local deactivated_mock = mock_autocommand("WorkspaceDeactivated")

	vim.cmd("e /caiman_shredder/setup.py")

	assert_equals(#deactivated_mock.calls, 1)
	assert_equals(#activated_mock.calls, 1)
	assert_equals(vim.fn["jw#get_active_workspace"](), shredder_id)

	activated_mock:reset()
	deactivated_mock:reset()

	vim.cmd("e /caiman_electrifier/setup.py")
	assert_equals(#deactivated_mock.calls, 1)
	assert_equals(#activated_mock.calls, 1)
	assert_equals(vim.fn["jw#get_active_workspace"](), electrifier_id)
end

function Suite.load_builtin()
	Plugin({
		templates = { "jworkspace.builtin" },
	})
	vim.cmd("JWLoadWorkspace /caiman_shredder caiman_shredder")
end

return Suite
