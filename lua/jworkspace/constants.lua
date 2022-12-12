--- Constants and default values

local constants = {}

constants.default_config = {
	templates = "jworkpace.builtin",
	root_patterns = {
		".git",
		".workspace.*",
		"setup.py",
		"package.json",
	},
}

return constants
