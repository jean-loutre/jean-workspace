-- Third party path initialization
local is_win = package.config:sub(1, 1) == "\\"
local path_separator = "/"
local script_path = debug.getinfo(1, "S").source:sub(2)

if is_win then
	path_separator = "\\"
	script_path = script_path:gsub("/", "\\")
end

local script_dir = script_path:match("(.*" .. path_separator .. ")")

local function add_third_party_path(path)
	package.path = package.path .. ";" .. script_dir .. "/../third-party/" .. path
end

add_third_party_path("?.lua")
add_third_party_path("./jean-vim/lua/?.lua")
add_third_party_path("./jean-vim/third-party/jean-lua/lua/?.lua")
add_third_party_path("./lua-yaml/?.lua")

return {
	setup = function(_) end,
}
