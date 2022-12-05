local Mock = require("jlua.mock")
local TestSuite = require("jnvim.test-suite")
local Autocommand = require("jnvim.autocommand")
local Plugin = require("jworkspace.plugin")

local Suite = TestSuite()

local function mock_autocommand(jw_pattern)
	local mock = Mock()
	Autocommand("User", { pattern = "jworkspace#" .. jw_pattern, callback = mock })
	return mock
end

function Suite.load_workspace()
	Plugin({})

	local mock = mock_autocommand("workspace_loaded")

	vim.cmd("JWLoadWorkspace /caiman_shredder caiman_shredder")

	local id = mock.call.data.workspace
	assert_equals(vim.fn["jworkspace#get_workspace_name"](id), "caiman_shredder")
	assert_equals(vim.fn["jworkspace#get_workspace_root"](id), "/caiman_shredder")
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

	local mock = mock_autocommand("workspace_loaded")

	vim.cmd("e /caiman_shredder/setup.py")

	local id = mock.call.data.workspace
	assert_equals(vim.fn["jworkspace#get_workspace_name"](id), "Caiman Shredder")
	assert_equals(vim.fn["jworkspace#get_workspace_root"](id), "/caiman_shredder")
end

function Suite.apply_template()
	Plugin({
		templates = {
			{
				workspace_filters = {
					function(_, name)
						return name == "caiman_shredder"
					end,
				},
				config = {
					power = "12kw",
				},
			},
		},
	})

	local mock = mock_autocommand("workspace_loaded")

	vim.cmd("JWLoadWorkspace /caiman_electrifier caiman_electrifier")
	assert_equals(mock.call.data.config, {})

	mock:reset()
	vim.cmd("JWLoadWorkspace /caiman_shredder caiman_shredder")
	assert_equals(mock.call.data.config, { power = "12kw" })
end

function Suite.merge_templates()
	Plugin({
		templates = {
			{
				config = {
					power = "12kw",
				},
			},
			{
				config = {
					rpm = 15000,
				},
			},
		},
	})

	local mock = mock_autocommand("workspace_loaded")

	vim.cmd("JWLoadWorkspace /caiman_shredder caiman_shredder")
	assert_equals(mock.call.data.config, { power = "12kw", rpm = 15000 })
end

return Suite
