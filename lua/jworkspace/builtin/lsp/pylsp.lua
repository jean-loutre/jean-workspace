--- Default configuration for pylsp language server.
--
-- If pylsp is found on the system, will add a default configuration to attach
-- a pylsp server on python files in the workspace. If the config already have
-- a ["lsp"]["servers"]["pylsp"] configuration key, it will do nothing.
--
-- You can force pylsp off by setting lsp.servers.pylsp key to false in your
-- workspace configuration.
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
