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
	return script()
end

local function load_yaml_file(path)
	return with(path:open("r"), function(file)
		local content = file:read("*all")
		return yaml.eval(content)
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

local function load_template_source(template_source)
	assert(is_string(template_source))
	local status, result = pcall(function()
		return require(template_source)
	end)

	if status then
		return result
	end

	return Path.glob(template_source):map(load_file):to_list()
end

--- Load a workspace configuration configuration from a template.
--
-- Parameters
-- ----------
-- template : function | { template } | str
--     Source.
--      * If it's callable (function or class with __call member), will return
--        the template itself.
--      * If it's a table, will return the result of load_config on each
--        element of the table.
--      * If it's a string, will try to load the pointed restemplate_source.
--        TODO: add documentation about this.
--
-- Returns
-- -------
-- `jlua.iterator[{str=*]`
--      The resulting workspace configuration.
function template.load_config(root, name, config, template_)
	repeat
		if is_callable(template_) then
			template_ = template_(root, name, config) or {}
		elseif is_string(template_) then
			template_ = load_template_source(template_)
		end
	until is_table(template_)

	for key, import in ipairs(template_) do
		Map.update(config, template.load_config(root, name, config, import) or {})
		template_[key] = nil
	end

	return Map.update(config, template_)
end

return template
