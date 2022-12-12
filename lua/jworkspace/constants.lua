--- Constants and default values

local constants = {}

constants.default_config = {
	templates = "jworkspace.builtin",
	root_mappers = { require("jworkspace.builtin.root-mappers").match_patterns },
	root_patterns = {
		".git",
		".workspace.*",
		"setup.py",
		"package.json",
	},
}

return constants
