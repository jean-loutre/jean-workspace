local TestSuite = require("jnvim.test-suite")

local match_patterns = require("jworkspace.builtin.root-mappers").match_patterns

local Suite = TestSuite()

function Suite.pattern()
	local buffer_mock = { name = "tests/data/caiman_shredder/subdirectory/file.lua" }
	local root, name, _

	root, name = match_patterns({ root_patterns = { ".workspace.*" } }, buffer_mock)
	assert_equals(tostring(root), "tests/data/caiman_shredder")
	assert_equals(name, "caiman_shredder")

	root, _ = match_patterns({ root_patterns = { ".i_dont_exists_anywhere" } }, buffer_mock)
	assert_is_nil(root)
end

return Suite
