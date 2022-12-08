local TestSuite = require("jnvim.test-suite")

local in_source_templates = require("jworkspace.builtins.common.in-source-templates")

local Suite = TestSuite()

function Suite.in_source_templates()
	local templates = in_source_templates("tests/data/caiman_shredder", "Caiman Shredder")
	assert_equals(templates, {
		"file:tests/data/caiman_shredder/.workspace.lua",
		"file:tests/data/caiman_shredder/.workspace.yml",
	})
end

return Suite
