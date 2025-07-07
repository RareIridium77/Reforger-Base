local blacklist = {
	["reforger/core/shared/reforger_loader.lua"] = true
}

local function AddLuaFile(path, realm)
	if realm == "server" then
		if SERVER then
			include(path)
			print("[Server] Included: " .. path)
		end
	elseif realm == "client" then
		if SERVER then
			AddCSLuaFile(path)
			print("[Client] AddCS: " .. path)
		elseif CLIENT then
			include(path)
			print("[Client] Included: " .. path)
		end
	elseif realm == "shared" then
		if SERVER then
			AddCSLuaFile(path)
			include(path)
			print("[Shared] AddCS + Include: " .. path)
		elseif CLIENT then
			include(path)
			print("[Shared] Included: " .. path)
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
				print("[WARN] Не удалось определить realm для: " .. fullPath)
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
