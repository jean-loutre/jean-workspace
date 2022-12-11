--- Templates allow to define skeletons for workspaces
local Map = require("jlua.map")
local is_callable = require("jlua.type").is_callable
local is_string = require("jlua.type").is_string
local is_table = require("jlua.type").is_table
local with = require("jlua.context").with

local yaml = require("yaml")

local Path = require("jnvim.path")

local template = {}

local function split_source(source)
	assert(is_string(source), "Bad argument")
	local type_start, type_end = string.find(source, "^[^:]+:")

	local source_type
	local source_name
	if type_start == nil then
		source_type = "require"
		source_name = source
	else
		source_type = string.sub(source, type_start, type_end - 1)
		source_name = string.sub(source, type_end + 1)
	end

	return source_type, source_name
end

local function require_module(name)
	return require(name)
end

local function load_lua_file(path)
	local script = loadfile(tostring(path))
	assert(script ~= nil)
	local result = script()
	return result
end

local function load_yaml_file(path)
	return with(path:open("r"), function(file)
		local content = file:read("*all")
		return function()
			return yaml.eval(content)
		end
	end)
end

local FILE_LOADERS = {
	lua = load_lua_file,
	yml = load_yaml_file,
	yaml = load_yaml_file,
	json = load_yaml_file,
}

local function load_file(name)
	local file_path = Path(name)
	local extension = file_path.extension
	local loader = FILE_LOADERS[extension]
	if not loader then
		error("Unable to load file of type " .. extension)
	end

	return loader(file_path)
end

local function load_glob(glob)
	return Path.glob(glob)
		:map(function(path)
			return "file:" .. tostring(path)
		end)
		:to_list()
end

local LOADERS = {
	["require"] = require_module,
	file = load_file,
	glob = load_glob,
}

--- Load a workspace configuration template from a source.
--
-- Parameters
-- ----------
-- source : function | { source } | str
--     Source.
--      * If it's callable (function or class with __call member), will return
--        the source itself.
--      * If it's a table, will return the result of load_templates on each
--        element of the table.
--      * If it's a string, will try to load the pointed ressource.
--        TODO: add documentation about this.
--
-- Returns
-- -------
-- `jlua.iterator[{str=*]`
--      The resulting workspace configuration.
function template.load_templates(root, name, config, source)
	if is_callable(source) then
		return template.load_templates(root, name, config, source(root, name, config) or {})
	elseif is_table(source) then
		for key, import in ipairs(source) do
			assert(import)
			config = template.load_templates(root, name, config, import) or {}
			source[key] = nil
		end

		return Map.update(config, source)
	end

	local source_type, source_name = split_source(source)
	local loader = LOADERS[source_type]
	assert(loader, "Unknown source type " .. source_type)
	return template.load_templates(root, name, config, loader(source_name))
end

return template
