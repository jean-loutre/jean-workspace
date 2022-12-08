#!/usr/bin/lua

local function run()
	package.path = package.path
		.. ";"
		.. table.concat({
			"./lua/?.lua",
			"./tests/?.lua",
			"./third-party/?.lua",
			"./third-party/jean-nvim/lua/?.lua",
			"./third-party/jean-nvim/third-party/jean-lua/lua/?.lua",
			"./third-party/lua-yaml/?.lua",
		}, ";")

	pcall(function()
		require("luacov")
	end)

	local suites = { "plugin-tests", "template-tests", "builtin-common-tests" }

	-- To make assert functions globally accessible
	for key, value in pairs(require("luaunit")) do
		_G[key] = value
	end

	for _, suite in ipairs(suites) do
		_G[suite] = require(suite)
	end

	function LuaUnit.isMethodTestName(method_name)
		return method_name ~= "setup" and method_name ~= "teardown"
	end

	function LuaUnit.isTestName(name)
		for _, suite in ipairs(suites) do
			if suite == name then
				return true
			end
		end
		return false
	end

	return LuaUnit.run("-v")
end

local status, result = pcall(run)

if not status then
	print(result)
	os.exit(-1)
end

os.exit(result)
