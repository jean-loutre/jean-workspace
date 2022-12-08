local iter = require("jlua.iterator").iter

local TestSuite = require("jnvim.test-suite")
local load_templates = require("jworkspace.template").load_templates

local Suite = TestSuite()

function Suite.load_function()
	local function caiman_shredder() end
	assert_equals(load_templates(caiman_shredder):to_list(), { caiman_shredder })
end

function Suite.load_table()
	local function caiman_shredder() end
	local function caiman_electrifier() end
	local templates = { caiman_shredder, caiman_electrifier }

	assert_equals(load_templates(templates):to_list(), templates)
end

function Suite.load_lua_module()
	local function caiman_shredder() end
	package.loaded["caiman_shredder"] = caiman_shredder

	-- Default loader is lua module
	assert_equals(load_templates("caiman_shredder"):to_list(), { caiman_shredder })
	assert_equals(load_templates("require:caiman_shredder"):to_list(), { caiman_shredder })
end

function Suite.load_lua_file()
	local templates = load_templates("file:tests/data/templates/caiman_shredder.lua")
	local template = templates() -- iterator next

	assert_is_nil(templates())
	assert_equals(template(), { power = "12kw" })
end

function Suite.load_yaml_file()
	for extension in iter({ "yml", "yaml", "json" }) do
		local templates = load_templates("file:tests/data/templates/caiman_shredder." .. extension)
		local template = templates() -- iterator next

		assert_is_nil(templates())
		assert_equals(template(), { rpm = 15264 })
	end
end

return Suite
