local iter = require("jlua.iterator").iter

local TestSuite = require("jnvim.test-suite")
local load_config = require("jworkspace.template").load_config

local Suite = TestSuite()

function Suite.load_function()
	local function template(root, name, config)
		assert_equals(root, "/caiman_shredder")
		assert_equals(name, "caiman_shredder")
		assert_equals(config, {})
		return { power = "12kw" }
	end

	local config = load_config("/caiman_shredder", "caiman_shredder", {}, template)
	assert_equals(config, { power = "12kw" })
end

function Suite.load_table_import()
	local function caiman_shredder(root, name, config)
		assert_equals(root, "/caiman_shredder")
		assert_equals(name, "caiman_shredder")
		assert_equals(config, {})
		return { rpm = 12564 }
	end

	local function caiman_electrifier(root, name, config)
		assert_equals(root, "/caiman_shredder")
		assert_equals(name, "caiman_shredder")
		assert_equals(config, { rpm = 12564 })
		return { power = "12kw" }
	end

	local template = { caiman_shredder, caiman_electrifier, blade_count = 10 }
	local config = load_config("/caiman_shredder", "caiman_shredder", {}, template)
	assert_equals(config, { rpm = 12564, power = "12kw", blade_count = 10 })
end

function Suite.load_lua_module()
	local function caiman_shredder(root, name, config)
		assert_equals(root, "/caiman_shredder")
		assert_equals(name, "caiman_shredder")
		assert_equals(config, {})
		return { power = "12kw" }
	end

	package.loaded["caiman_shredder"] = caiman_shredder

	local config = load_config("/caiman_shredder", "caiman_shredder", {}, "caiman_shredder")
	assert_equals(config, { power = "12kw" })

	package.loaded["caiman_shredder"] = nil
end

function Suite.load_lua_file()
	local config = load_config("", "", {}, "tests/data/templates/caiman_shredder.lua")
	assert_equals(config, { power = "12kw" })
end

function Suite.load_yaml_file()
	for extension in iter({ "yml", "yaml", "json" }) do
		local config = load_config("", "", {}, "tests/data/templates/caiman_shredder." .. extension)
		assert_equals(config, { rpm = 15264 })
	end
end

function Suite.load_glob()
	local config = load_config("", "", {}, "tests/data/templates/caiman_shredder.*")
	assert_equals(config, {
		power = "12kw",
		rpm = 15264,
	})
end

return Suite
