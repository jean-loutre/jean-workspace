--- Template loading templates in the workspace root directory.
return function(root, _)
	return root .. "/" .. ".workspace.*"
end
