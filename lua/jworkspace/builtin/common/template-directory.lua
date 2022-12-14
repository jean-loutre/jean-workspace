local Path = require("jlua.path")

--- Load templates from the templates directory
return function(_, name)
	local templates_dir = Path(vim.fn["stdpath"]("config")) / "jworkspace"
	local common_templates = templates_dir:glob("common/**"):map(tostring)
	local workspace_templates = templates_dir:glob("workspaces/" .. name .. "**"):map(tostring)
	return workspace_templates:chain(common_templates):to_list()
end
