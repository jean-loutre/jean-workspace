--- Templates allow to define skeletons for workspaces
local is_callable = require("jlua.type").is_callable
local is_string = require("jlua.type").is_string
local is_table = require("jlua.type").is_table
local iter = require("jlua.iterator").iter

local template = {}

local function split_source(source)
	assert(is_string(source), "Bad argument")
	local type_start, type_end = string.find(source, "^[^:]+:")

	local source_type
	local source_name
	if type_start == nil then
		source_type = "module"
		source_name = source
	else
		source_type = string.sub(source, type_start, type_end - 1)
		source_name = string.sub(source, type_end + 1)
	end

	return source_type, source_name
end

local function load_module(name)
	return require(name)
end

local loaders = {
	module = load_module,
}

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
	elseif is_string(sources) then
		local source_type, source_name = split_source(sources)
		local loader = loaders[source_type]
		assert(loader, "Unknown source type " .. source_type)
		return template.load_templates(loader(source_name))
	end

	assert(false, "Bad argument")
end

return template
