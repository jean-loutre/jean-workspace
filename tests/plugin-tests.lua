local List = require("jlua.list")
local Mock = require("jlua.mock")
local with = require("jlua.context").with

local Autocommand = require("jnvim.autocommand")
local TestSuite = require("jnvim.test-suite")

local Plugin = require("jworkspace.plugin")
local Template = require("jworkspace.template")

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

function Suite.load_templates()
	with(
		Mock.patch(Template, "load_templates", function()
			return List({ Template({
				config = {
					power = "12kw",
				},
			}) })
		end),
		function()
			Plugin({})

			local mock = mock_autocommand("workspace_loaded")
			vim.cmd("JWLoadWorkspace /caiman_shredder caiman_shredder")
			assert_equals(mock.call.data.config, { power = "12kw" })
		end
	)
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

function Suite.file_filters()
	Plugin({
		workspace_mappers = {
			function(_)
				return "/caiman_shredder", "Caiman Shredder"
			end,
		},
		templates = {
			{
				config = {
					file_filters = {
						function(path)
							return path.basename == "dinglepop.lua"
						end,
					},
				},
			},
		},
	})

	local mock = mock_autocommand("workspace_loaded")

	vim.cmd("e /caiman_shredder/setup.py")
	assert_equals(#mock.calls, 0)

	vim.cmd("e /caiman_shredder/dinglepop.lua")

	local id = mock.call.data.workspace
	assert_equals(vim.fn["jworkspace#get_workspace_name"](id), "Caiman Shredder")
	assert_equals(vim.fn["jworkspace#get_workspace_root"](id), "/caiman_shredder")
end

function Suite.enable_workspace()
	Plugin({})

	vim.cmd("JWLoadWorkspace /caiman_shredder caiman_shredder")

	local loaded_mock = mock_autocommand("workspace_loaded")

	vim.cmd("JWLoadWorkspace /caiman_shredder caiman_shredder")

	local id = loaded_mock.call.data.workspace

	vim.cmd("JWActivateWorkspace 0")

	local activated_mock = mock_autocommand("workspace_activated")
	local deactivated_mock = mock_autocommand("workspace_deactivated")

	vim.cmd("JWActivateWorkspace " .. id)
	assert_equals(activated_mock.call.data.workspace, id)
	assert_equals(#deactivated_mock.calls, 0)

	activated_mock:reset()
	deactivated_mock:reset()

	-- Nothing happen if the workspace is already enabled
	vim.cmd("JWActivateWorkspace " .. id)
	assert_equals(#activated_mock.calls, 0)
	assert_equals(#deactivated_mock.calls, 0)

	vim.cmd("JWActivateWorkspace 0")
	assert_equals(#activated_mock.calls, 0)
	assert_equals(deactivated_mock.call.data.workspace, id)
end

function Suite.enable_workspace_on_load()
	Plugin({})

	vim.cmd("JWLoadWorkspace /caiman_shredder caiman_shredder")

	local loaded_mock = mock_autocommand("workspace_loaded")
	local activated_mock = mock_autocommand("workspace_activated")

	vim.cmd("JWLoadWorkspace /caiman_shredder caiman_shredder")

	assert_equals(loaded_mock.data.workspace, activated_mock.data.workspace)
end

function Suite.enable_workspace_on_buffer_switch()
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

	local loaded_mock = mock_autocommand("workspace_loaded")
	vim.cmd("e /caiman_shredder/setup.py")
	vim.cmd("e /caiman_electrifier/setup.py")
	local shredder_id = loaded_mock.calls[1][1].data.workspace
	local electrifier_id = loaded_mock.calls[2][1].data.workspace

	local activated_mock = mock_autocommand("workspace_activated")
	local deactivated_mock = mock_autocommand("workspace_deactivated")

	vim.cmd("e /caiman_shredder/setup.py")

	assert_equals(deactivated_mock.call.data.workspace, electrifier_id)
	assert_equals(activated_mock.call.data.workspace, shredder_id)

	activated_mock:reset()
	deactivated_mock:reset()

	vim.cmd("e /caiman_electrifier/setup.py")
	assert_equals(deactivated_mock.call.data.workspace, shredder_id)
	assert_equals(activated_mock.call.data.workspace, electrifier_id)
end

return Suite
