return function(_, _, config)
	config.lsp = config.lsp or {}
	table.insert(config.lsp, {
		filetypes = { "python" },
		cmd = config.lsp.cmd or { "pylsp" },
	})
end
