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

	local mock = mock_autocommand("WorkspaceAdd")

	vim.cmd("JWAddWorkspace /caiman_shredder caiman_shredder")

	assert_equals(#mock.calls, 1)
	assert_equals(vim.fn["jw#get_workspace_name"](), "caiman_shredder")
	assert_equals(vim.fn["jw#get_workspace_root"](), "/caiman_shredder")
end

function Suite.map_root()
	Plugin({
		root_mappers = {
			function(_, buffer)
				assert_equals(buffer.name, "/caiman_shredder/setup.py")
				return "/caiman_shredder", "Caiman Shredder"
			end,
		},
	})

	local mock = mock_autocommand("WorkspaceAdd")

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

	local mock = mock_autocommand("WorkspaceAdd")

	vim.cmd("JWAddWorkspace /caiman_electrifier caiman_electrifier")
	assert_equals(#mock.calls, 1)
	assert_equals(vim.fn["jw#get_workspace_config"](), {})

	mock:reset()
	vim.cmd("JWAddWorkspace /caiman_shredder caiman_shredder")
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

	local mock = mock_autocommand("WorkspaceAdd")

	vim.cmd("JWAddWorkspace /caiman_shredder caiman_shredder")
	assert_equals(#mock.calls, 1)
	assert_equals(vim.fn["jw#get_workspace_config"](), { power = "12kw", rpm = 15000 })
end

function Suite.file_filters()
	Plugin({
		root_mappers = {
			function()
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

	local mock = mock_autocommand("WorkspaceAdd")

	vim.cmd("e /caiman_shredder/setup.py")
	assert_equals(#mock.calls, 0)

	vim.cmd("e /caiman_shredder/dinglepop.lua")

	assert_equals(#mock.calls, 1)
	assert_equals(vim.fn["jw#get_workspace_name"](), "Caiman Shredder")
	assert_equals(vim.fn["jw#get_workspace_root"](), "/caiman_shredder")
end

function Suite.enter_workspace()
	Plugin({})

	vim.cmd("JWAddWorkspace /caiman_shredder caiman_shredder")

	local id = vim.fn["jw#get_current_workspace"]()

	vim.cmd("JWEnterWorkspace 0")

	local enter_mock = mock_autocommand("WorkspaceEnter")
	local leave_mock = mock_autocommand("WorkspaceLeave")

	vim.cmd("JWEnterWorkspace " .. id)
	assert_equals(#enter_mock.calls, 1)
	assert_equals(#leave_mock.calls, 0)
	assert_equals(vim.fn["jw#get_current_workspace"](), id)

	enter_mock:reset()
	leave_mock:reset()

	-- Nothing happen if the workspace is already enter
	vim.cmd("JWEnterWorkspace " .. id)
	assert_equals(#enter_mock.calls, 0)
	assert_equals(#leave_mock.calls, 0)

	vim.cmd("JWEnterWorkspace 0")
	assert_equals(#enter_mock.calls, 0)
	assert_equals(#leave_mock.calls, 1)
end

function Suite.enter_workspace_on_load()
	Plugin({})
	local mock = mock_autocommand("WorkspaceEnter")

	vim.cmd("JWAddWorkspace /caiman_shredder caiman_shredder")
	assert_equals(#mock.calls, 1)
end

function Suite.enter_workspace_on_buffer_switch()
	Plugin({
		root_mappers = {
			function(_, buffer)
				if buffer.name == "/caiman_shredder/setup.py" then
					return "/caiman_shredder", "Caiman Shredder"
				end
				return "/caiman_electrifier", "Caiman Electrifier"
			end,
		},
	})

	vim.cmd("e /caiman_shredder/setup.py")
	local shredder_id = vim.fn["jw#get_current_workspace"]()

	vim.cmd("e /caiman_electrifier/setup.py")
	local electrifier_id = vim.fn["jw#get_current_workspace"]()

	local enter_mock = mock_autocommand("WorkspaceEnter")
	local leave_mock = mock_autocommand("WorkspaceLeave")

	vim.cmd("e /caiman_shredder/setup.py")

	assert_equals(#leave_mock.calls, 1)
	assert_equals(#enter_mock.calls, 1)
	assert_equals(vim.fn["jw#get_current_workspace"](), shredder_id)

	enter_mock:reset()
	leave_mock:reset()

	vim.cmd("e /caiman_electrifier/setup.py")
	assert_equals(#leave_mock.calls, 1)
	assert_equals(#enter_mock.calls, 1)
	assert_equals(vim.fn["jw#get_current_workspace"](), electrifier_id)
end

function Suite.load_builtin()
	Plugin({
		templates = { "jworkspace.builtin" },
	})
	vim.cmd("JWAddWorkspace /caiman_shredder caiman_shredder")
end

return Suite
