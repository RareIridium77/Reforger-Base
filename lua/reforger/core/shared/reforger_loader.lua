local function AddLuaFile(path, realm)
	if realm == "server" then
		if SERVER then
			include(path)
			Reforger.Log("[Server] Included: " .. path)
		end
	elseif realm == "client" then
		if SERVER then
			AddCSLuaFile(path)
			Reforger.Log("[Client] AddCS: " .. path)
		elseif CLIENT then
			include(path)
			Reforger.Log("[Client] Included: " .. path)
		end
	elseif realm == "shared" then
		if SERVER then
			AddCSLuaFile(path)
			include(path)
            
			Reforger.Log("[Shared] AddCS + Include: " .. path)
		elseif CLIENT then
			include(path)
			Reforger.Log("[Shared] Included: " .. path)
		end
	end
end

local function RecursiveLoad(basePath)
	local files, dirs = file.Find(basePath .. "/*", "LUA")

	for _, fileName in ipairs(files) do
		if fileName:EndsWith(".lua") then
			local realm = string.match(basePath, "([^/\\]+)$")
			AddLuaFile(basePath .. "/" .. fileName, realm)
		end
	end

	for _, dir in ipairs(dirs) do
		RecursiveLoad(basePath .. "/" .. dir)
	end
end

return function(basePath)
    RecursiveLoad(basePath)
end