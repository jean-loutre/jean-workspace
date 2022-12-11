local iter = require("jlua.iterator").iter

local TestSuite = require("jnvim.test-suite")
local load_templates = require("jworkspace.template").load_templates

local Suite = TestSuite()

function Suite.load_function()
	local function caiman_shredder()
		return { power = "12kw" }
	end
	assert_equals(load_templates("", "", {}, caiman_shredder), { power = "12kw" })
end

function Suite.load_table_import()
	local function caiman_shredder()
		return { rpm = 12564 }
	end
	local function caiman_electrifier()
		return { power = "12kw" }
	end
	local templates = { caiman_shredder, caiman_electrifier, test = "bah" }

	assert_equals(load_templates("", "", {}, templates), { rpm = 12564, power = "12kw" })
end

function Suite.load_lua_module()
	local function caiman_shredder()
		return { power = "12kw" }
	end
	package.loaded["caiman_shredder"] = caiman_shredder

	-- Default loader is lua module
	assert_equals(load_templates("", "", {}, "caiman_shredder"), { power = "12kw" })
	assert_equals(load_templates("", "", {}, "require:caiman_shredder"), { power = "12kw" })
end

function Suite.load_lua_file()
	local template = load_templates("", "", {}, "file:tests/data/templates/caiman_shredder.lua")
	assert_equals(template, { power = "12kw" })
end

function Suite.load_yaml_file()
	for extension in iter({ "yml", "yaml", "json" }) do
		local template = load_templates("", "", {}, "file:tests/data/templates/caiman_shredder." .. extension)

		assert_equals(template, { rpm = 15264 })
	end
end

function Suite.load_glob()
	local result = load_templates("", "", {}, "glob:tests/data/templates/caiman_shredder.*")
	assert_equals(result, {
		power = "12kw",
		rpm = 15264,
	})
end

return Suite
