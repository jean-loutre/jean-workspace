--- Load lsp terminals extension if needed
--- @module 'jworkspace.builtin.terminals'

return function(_, _, config)
	if config["terminals"] then
		require("jworkspace.terminals")
	end
end
