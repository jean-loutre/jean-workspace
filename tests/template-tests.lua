local Map = require("jlua.map")
local iter = require("jlua.iterator").iter

local TestSuite = require("jnvim.test-suite")
local load_config = require("jworkspace.template").load_config

local Suite = TestSuite()

function Suite.load_function()
	local function return_config(root, name, config)
		assert_equals(root, "/caiman_shredder")
		assert_equals(name, "caiman_shredder")
		assert_equals(config, {})
		assert(Map:is_class_of(config))
		return { power = "12kw" }
	end

	local function fail(root, name, config)
		assert_equals(root, "/caiman_shredder")
		assert_equals(name, "caiman_shredder")
		assert_equals(config, {})
		assert(Map:is_class_of(config))
		return false
	end

	local function update(root, name, config)
		assert_equals(root, "/caiman_shredder")
		assert_equals(name, "caiman_shredder")
		assert_equals(config, {})
		assert(Map:is_class_of(config))
		config:update({
			power = "12kw",
		})
	end

	local config

	config = load_config("/caiman_shredder", "caiman_shredder", Map(), return_config)
	assert_equals(config, { power = "12kw" })

	config = load_config("/caiman_shredder", "caiman_shredder", Map(), fail)
	assert_equals(config, {})

	config = load_config("/caiman_shredder", "caiman_shredder", Map(), update)
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
	local config = load_config("/caiman_shredder", "caiman_shredder", Map(), template)
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

	local config = load_config("/caiman_shredder", "caiman_shredder", Map(), "caiman_shredder")
	assert_equals(config, { power = "12kw" })

	package.loaded["caiman_shredder"] = nil
end

function Suite.load_lua_file()
	local config = load_config("", "", Map(), "tests/data/templates/caiman_shredder.lua")
	assert_equals(config, { power = "12kw" })
end

function Suite.load_yaml_file()
	for extension in iter({ "yml", "yaml", "json" }) do
		local config = load_config("", "", Map(), "tests/data/templates/caiman_shredder." .. extension)
		assert_equals(config, { rpm = 15264 })
	end
end

function Suite.load_glob()
	local config = load_config("", "", Map(), "tests/data/templates/caiman_shredder.*")
	assert_equals(config, {
		power = "12kw",
		rpm = 15264,
	})
end

return Suite
