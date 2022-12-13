--- Default configuration for lua-language-server.
--
-- https://github.com/sumneko/lua-language-server
-- If lua-language-server is found on the system, will add a default
-- configuration to attach it on lua buffers in the workspace. If the config
-- already have a ["lsp"]["servers"]["lua-language-server"] configuration key,
-- it will do nothing.
--
-- You can force this server off by setting lsp.servers.lua-language-server key
-- to false in your workspace configuration.
return function(_, _, config)
	if not vim.fn.executable("lua-luangage-server") then
		return nil
	end

	config:deep_update({
		lsp = {
			servers = {
				["lua-language-server"] = {
					filetypes = { "lua" },
					cmd = { "lua-language-server" },
				},
			},
		},
	})
end
