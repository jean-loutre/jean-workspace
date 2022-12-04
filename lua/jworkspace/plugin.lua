--- The Jean Workspace plugin instance
local List = require("jlua.list")
local BoundContext = require("jnvim.bound-context")
local Path = require("jnvim.path")

local Workspace = require("jworkspace.workspace")

local Plugin = BoundContext:extend()

function Plugin:init(_)
	self:parent("init", "jworkspace#")
	self._workspaces = List({})

	self:bind_user_command("JWLoadWorkspace", "load_workspace", { nargs = "*" })
	self:bind_function("get_workspace_name")
	self:bind_function("get_workspace_root")
	self:enable()
end

--- Create a new workspace
--
-- Parameters
-- ----------
-- name : str
--     Name of the workspace.
-- root: str
--     Root directory of the workspace
function Plugin:load_workspace(args)
	local root = Path(args.fargs[1] or Path.cwd())
	local name = args.fargs[2] or root.basename
	local new_workspace = Workspace(root, name)
	self._workspaces:push(new_workspace)
	local workspace_id = #self._workspaces
	self:execute_user_autocommand("workspace_loaded", { workspace = workspace_id })
end

--- Return the name of the workspace with the given id
--
-- Parameters
-- ----------
-- handle : int, optional
--     Handle of the workspace. If none, will return the name of the active workspace.
function Plugin:get_workspace_name(id)
	assert(self._workspaces[id], "Invalid workspace id")
	return self._workspaces[id].name
end

--- Return the root directory of the workspace with the given id
--
-- Parameters
-- ----------
-- handle : int, optional
--     Handle of the workspace. If none, will return the name of the active workspace.
function Plugin:get_workspace_root(id)
	assert(self._workspaces[id], "Invalid workspace id")
	return tostring(self._workspaces[id].root)
end

return Plugin
