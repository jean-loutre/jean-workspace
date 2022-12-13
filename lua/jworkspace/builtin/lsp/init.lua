--- Load lsp jworkspace extension if needed
--- @module 'jworkspace.builtin.lsp'

return {
	require("jworkspace.builtin.lsp.pylsp"),
	require("jworkspace.builtin.lsp.lua-language-server"),
	function(_, _, config)
		if config["lsp"] then
			require("jworkspace.lsp")
		end
	end,
}
