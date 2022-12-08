--- Template loading templates in the workspace root directory.
local Path = require("jnvim.path")

return function(root, _)
	return Path(root)
		:glob(".workspace.*")
		:map(function(template)
			return "file:" .. tostring(template)
		end)
		:to_list()
end
