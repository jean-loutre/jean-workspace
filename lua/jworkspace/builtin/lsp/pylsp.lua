--- Default configuration for pylsp language server
--- @module 'jworkspace.builtin.lsp.pylsp'

--- Add default configuration for pylsp language server if it's found on the system.
--- @param config jlua.Map
--- @return nil
return function(_, _, config)
	if not vim.fn.executable("pylsp") then
		return nil
	end

	config:deep_update({
		lsp = {
			servers = {
				pylsp = {
					filetypes = { "python" },
					cmd = { "pylsp" },
				},
			},
		},
	})
end
