local blacklist = {
	["reforger/core/shared/reforger_loader.lua"] = true
	["autorun/reforger_init.lua"] = true -- impossible but okay
}

local function AddLuaFile(path, realm)
	if realm == "server" then
		if SERVER then
			include(path)
			print("Reforger [Server] Included: " .. path)
		end
	elseif realm == "client" then
		if SERVER then
			AddCSLuaFile(path)
			print("Reforger [Client] AddCS: " .. path)
		elseif CLIENT then
			include(path)
			print("Reforger [Client] Included: " .. path)
		end
	elseif realm == "shared" then
		if SERVER then
			AddCSLuaFile(path)
			include(path)
			print("Reforger [Shared] AddCS + Include: " .. path)
		elseif CLIENT then
			include(path)
			print("Reforger [Shared] Included: " .. path)
		end
	end
end

local function DetectRealm(basePath, filePath)
	local relative = string.Replace(filePath, basePath .. "/", "")
	local parts = string.Explode("/", relative)

	for _, part in ipairs(parts) do
		if part == "server" or part == "client" or part == "shared" then
			return part
		end
	end

	return nil
end

local function RecursiveLoad(basePath, root)
	root = root or basePath

	local files, dirs = file.Find(basePath .. "/*", "LUA")

	for _, fileName in ipairs(files) do
		if fileName:EndsWith(".lua") then
			local fullPath = basePath .. "/" .. fileName

			if blacklist[fullPath] then
				print("[SKIP] Blacklisted: " .. fullPath)
				continue
			end

			local realm = DetectRealm(root, fullPath)

			if realm then
				AddLuaFile(fullPath, realm)
			else
				print("Reforger [WARN] Cannot find realm for: " .. fullPath)
			end
		end
	end

	for _, dir in ipairs(dirs) do
		RecursiveLoad(basePath .. "/" .. dir, root)
	end
end

return function(basePath)
	RecursiveLoad(basePath)
end
