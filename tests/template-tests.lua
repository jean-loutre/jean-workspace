local TestSuite = require("jnvim.test-suite")

local Template = require("jworkspace.template")

local Suite = TestSuite()

function Suite.load_templates()
	local templates

	templates = Template.load_templates({ { config = { target = "caiman" } } }, {})
	assert_equals(#templates, 1)
	assert_equals(templates[1].workspace_config, { target = "caiman" })

	local loaders = {
		{
			extensions = {},
			load = function(path)
				assert_equals(tostring(path), "./tests/data/templates/dummy.ott")
				return { config = { target = "caiman" } }
			end,
		},
	}

	templates = Template.load_templates({ "./tests/data/templates/dummy.ott" }, loaders)
	assert_equals(#templates, 0)

	loaders[1].extensions = { "ott" }
	templates = Template.load_templates({ "./tests/data/templates/dummy.ott" }, loaders)
	assert_equals(#templates, 1)
	assert_equals(templates[1].workspace_config, { target = "caiman" })
end

return Suite
