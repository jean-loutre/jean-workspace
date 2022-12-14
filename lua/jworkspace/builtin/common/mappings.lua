--- Load lsp jworkspace extension if needed
--- @module 'jworkspace.builtin.lsp'

return function(_, _, config)
	if config["mappings"] then
		require("jworkspace.mappings")
	end
end
