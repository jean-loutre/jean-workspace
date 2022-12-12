--- Template loading templates in the workspace root directory.
return function(_, _, config)
	if config.lsp then
		require("jworkspace.lsp")
	end
end
