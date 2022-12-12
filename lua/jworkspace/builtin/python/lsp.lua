return function(_, _, config)
	config.lsp = config.lsp or {}
	config.lsp.cmd = config.lsp.cmd or { "pylsp" }
end
