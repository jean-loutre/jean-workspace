--- Builtin workspace root mappers
local Path = require("jnvim.path")
local iter = require("jlua.iterator").iter

local root_mappers = {}

function root_mappers.match_patterns(config, buffer)
	local patterns = config["root_patterns"] or {}
	local buffer_path = Path(buffer.name)

	for parent in buffer_path.parents do
		for pattern in iter(patterns) do
			if parent:glob(pattern):any() then
				return parent, parent.basename
			end
		end
	end

	return nil
end

return root_mappers
