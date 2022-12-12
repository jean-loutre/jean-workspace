local TestSuite = require("jnvim.test-suite")

local in_source_templates = require("jworkspace.builtin.common.in-source-templates")

local Suite = TestSuite()

function Suite.in_source_templates()
	local templates = in_source_templates("tests/data/caiman_shredder", "Caiman Shredder")
	assert_equals(templates, "tests/data/caiman_shredder/.workspace.*")
end

return Suite
