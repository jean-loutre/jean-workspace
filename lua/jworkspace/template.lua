--- Templates allow to define skeletons for workspaces
local is_table = require("jlua.type").is_table
local is_callable = require("jlua.type").is_callable
local iter = require("jlua.iterator").iter

local template = {}

--- Load templates from a source list.
--
-- Parameters
-- ----------
-- sources : { table | str }
--     Source list. Each item can be an array, in which case it'll be
--     considered as the template config itself, or a path glob. For
--     each path glob, all files with an extension matching one of the
--     loaders will be loaded.
-- loaders : { { extensions={str}, load=function(Path)-> table } }
-- 		List of loaders. Each loader must have a list of extensions it
-- 		can handle, and a load method taking path as input, and returning
-- 		template config as output.
--
-- Returns
-- -------
-- `jlua.iterator[Template]`
--      An iterator of templates loaded from the given sources.
function template.load_templates(sources)
	if is_callable(sources) then
		return iter({ sources })
	elseif is_table(sources) then
		return iter(sources):map(template.load_templates):flatten()
	end

	assert(false, "Bad argument")
end

return template
