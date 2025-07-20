local blacklist = {
	["reforger/core/shared/reforger_loader.lua"] = true,
	["autorun/reforger_init.lua"] = true -- impossible but okay
}

local priorityList = {
	--- Client
	"reforger/core/server/reforger_logger.lua",
	"reforger/core/server/reforger_network.lua",

	--- Shared
	"reforger/core/shared/reforger_convars.lua",
}

local priorityKeywords = {
	"util", "base", "log", "logger"
}

local function StringHasKeyword(path, keywords)
	for _, keyword in ipairs(keywords) do
		if string.find(path, keyword, 1, true) then
			return true
		end
	end
	return false
end

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

	local priorityFiles = {}
	local normalFiles = {}

	for _, fileName in ipairs(files) do
		if not fileName:EndsWith(".lua") then continue end

		local fullPath = basePath .. "/" .. fileName
		if blacklist[fullPath] then
			print("[SKIP] Blacklisted: " .. fullPath)
			continue
		end

		if StringHasKeyword(fullPath, priorityKeywords) then
			table.insert(priorityFiles, fullPath)
		else
			table.insert(normalFiles, fullPath)
		end
	end

	for _, fullPath in ipairs(priorityFiles) do
		local realm = DetectRealm(root, fullPath)
		if realm then
			AddLuaFile(fullPath, realm)
		else
			print("Reforger [WARN] Cannot find realm (priority): " .. fullPath)
		end
	end

	for _, fullPath in ipairs(normalFiles) do
		local realm = DetectRealm(root, fullPath)
		if realm then
			AddLuaFile(fullPath, realm)
		else
			print("Reforger [WARN] Cannot find realm: " .. fullPath)
		end
	end

	for _, dir in ipairs(dirs) do
		RecursiveLoad(basePath .. "/" .. dir, root)
	end
end

return function(basePath)
	local visited = {}

	for _, path in ipairs(priorityList) do
		if blacklist[path] then -- :D
			print("[SKIP] Blacklisted (priority): " .. path)
			continue
		end

		local realm = DetectRealm(basePath, path)
		if realm then
			AddLuaFile(path, realm)
			visited[path] = true
		else
			print("Reforger [WARN] Cannot find realm for priority file: " .. path)
		end
	end

	RecursiveLoad(basePath)
end
