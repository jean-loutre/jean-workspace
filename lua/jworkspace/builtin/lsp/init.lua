--- Load lsp jworkspace extension if needed
--- @module 'jworkspace.builtin.lsp'

--- @param config jlua.Map The workspace configuration
return {
	require("jworkspace.builtin.lsp.pylsp"),
	function(_, _, config)
		if config["lsp"] then
			require("jworkspace.lsp")
		end
	end,
}
