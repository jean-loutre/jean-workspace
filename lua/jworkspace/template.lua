--- Templates allow to define skeletons for workspaces
local Map = require("jlua.map")
local is_callable = require("jlua.type").is_callable
local is_string = require("jlua.type").is_string
local is_table = require("jlua.type").is_table
local with = require("jlua.context").with

local yaml = require("yaml")

local Path = require("jnvim.path")

local template = {}

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

local function load_file(path)
	local extension = path.extension
	local loader = FILE_LOADERS[extension]
	if not loader then
		error("Unable to load file of type " .. extension)
	end

	return loader(path)
end

local function load_source(source)
	assert(is_string(source))
	local status, result = pcall(function()
		return require(source)
	end)

	if status then
		return result
	end

	return Path.glob(source):map(load_file):to_list()
end

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
	repeat
		if is_callable(source) then
			source = source(root, name, config) or {}
		elseif is_string(source) then
			source = load_source(source)
		end
	until is_table(source)

	for key, import in ipairs(source) do
		assert(import)
		config = template.load_templates(root, name, config, import) or {}
		source[key] = nil
	end

	return Map.update(config, source)
end

return template
