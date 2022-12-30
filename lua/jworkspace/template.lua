--- Templates allow to define skeletons for workspaces
local Map = require("jlua.map")
local get_logger = require("jlua.logging").get_logger
local is_callable = require("jlua.type").is_callable
local is_string = require("jlua.type").is_string
local is_table = require("jlua.type").is_table
local with = require("jlua.context").with

local yaml = require("yaml")

local Path = require("jnvim.path")

local log = get_logger(...)
local template = {}

local function load_lua_file(path)
	log:debug("Loading lua file {}", tostring(path))
	local script, error = loadfile(tostring(path))
	if script == nil then
		log:error("Error loading lua file {} : {}", tostring(path), error)
		return nil
	end

	return script()
end

local function load_yaml_file(path)
	log:debug("Loading yaml file {}", tostring(path))
	return with(path:open("r"), function(file)
		local content = file:read("*all")
		local status, result = pcall(function()
			return yaml.eval(content)
		end)

		if not status then
			log:error("Error loading yaml file {} : {}", tostring(path), result)
			return nil
		end

		return result
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
		log:error("Unable to load file of type {}", extension)
		return nil
	end

	return loader(path)
end

local function load_template_source(template_source)
	local paths = Path.glob(template_source):map(load_file):to_list()
	if #paths ~= 0 then
		return paths
	end

	assert(is_string(template_source))
	local status, result = pcall(function()
		return require(template_source)
	end)

	if not status then
		log:error("Unable to load template source {} : {}", template_source, result)
		return nil
	end

	return result
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
	assert(Map:is_class_of(config))

	repeat
		if is_callable(template_) then
			template_ = template_(root, name, config) or {}
		elseif is_string(template_) then
			template_ = load_template_source(template_) or {}
		end
	until is_table(template_)

	for _, import in ipairs(template_) do
		config:update(template.load_config(root, name, config, import) or {})
	end

	return config:update(template_)
end

return template
