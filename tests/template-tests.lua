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
return Suite
