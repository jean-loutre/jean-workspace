--- Template loading templates in the workspace root directory.
return function(root, _)
	return "glob:" .. root .. "/" .. ".workspace.*"
end
