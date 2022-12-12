local Path = require("jlua.path")

return function(root, _, _)
	if (Path(root) / "setup.py"):is_file() then
		return {
			require("jworkspace.builtin.python.lsp"),
		}
	end
end
