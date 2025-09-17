# Reforger Core

Reforger Core provides a modular foundation for Garry’s Mod Lua development.  
It standardizes logging, configuration variables, networking, entity management, and vehicle handling with safety and extensibility in mind.

---

## Constants
Defines enums and constants used across Reforger modules.

- **Logging**
  - `LogLevels`: INFO, WARN, DEV, ERROR  
  - `LogColors`: Console color mapping
- **Networking**
  - `NetworkTypes`: Allowed NWVar types  
- **Vehicles**
  - `VehicleTypes`: LIGHT, ARMORED, PLANE, HELICOPTER, UNDEFINED  
  - `VehicleBases`: Glide, LVS, Simfphys  
  - `ValidClasslist`: Whitelisted vehicle classes  

---

## ConVar System
Unified API for creating and accessing server/client convars.

- **Prefixes**
  - Server: `reforger.*`  
  - Client: `cl_reforger.*`  

- **Functions**
  - `CreateConvar(name, value, helptext, min, max)` → Creates a prefixed convar  
  - `Convar(name)` → Returns reference if exists  
  - `SafeCvar(name, mode, fallback)` → Retrieves value safely (`int`, `float`, `bool`, `string`)  
  - `SafeInt(name, fallback)` / `SafeFloat(name, fallback)` → Numeric shorthand  

- **Safety**
  - Prevents duplicates  
  - Validates input types  
  - Provides fallback values  

---

## Entity Initialization & Networking
Compact system for syncing entity parameters.

- **Features**
  - Default values with typed read/write  
  - Indexed mappings for compact transmission  
  - Entity module system with hooks  
  - Delayed server-side initialization (armor, engines, rotors)  

- **Functions**
  - `WriteEntityNetData(ent)` / `ReadEntityNetData(ent)`  
  - `AddEntityModule(idf, func, force)`  
  - `InitializeEntity(ent)`  

- **Networking**
  - `"Reforger.InitializeEntity"` → Syncs entity state  

- **Hooks**
  - `EntityInitialized` → Fired after setup  

- **Safety**
  - Duplicate prevention unless forced  
  - Protected calls (`pcall`) for stability  

---

## AutoLoader
Recursive loader for Lua files by realm.

- **Features**
  - **Blacklist**: Skips forbidden files  
  - **PriorityList**: Ensures critical files load first  
  - **PriorityKeywords**: Keywords like `util`, `base`, `logger` load earlier  
  - Realm detection: `server`, `client`, `shared`  

- **Functions**
  - `AddLuaFile(path, realm)`  
  - `DetectRealm(basePath, filePath)`  
  - `RecursiveLoad(basePath, root)`  

- **Notes**
  - Blacklist overrides all  
  - Warnings on unknown realm  
  - Logs every action  

---

## Logging System
Structured logging with levels and developer-only debug tracing.

- **Functions**
  - `IsDeveloper()`  
  - `SLog(level, ...)` → Core logging with color and tracing  
  - `Log(...)` → INFO  
  - `WarnLog(...)` → WARN  
  - `DevLog(...)` → DEV (dev mode only)  
  - `ErrorLog(...)` → ERROR  

- **Notes**
  - Colors from `LogColors`  
  - Levels from `LogLevels`  
  - DEV logs include caller trace  

---

## Network System
Abstraction layer for safe NWVar operations.

- **Functions**
  - `SetNetworkValue(ent, nType, nName, nValue)` → Server-only, cached  
  - `GetNetworkValue(ent, nType, nName, fallback)` → Safe retrieval  

- **Notes**
  - Keys prefixed with `"Reforger."`  
  - Uses `Reforger.NetworkTypes` for supported types  

---

## Core Utilities
Helper functions for validation and developer execution.

- **Functions**
  - `SafeEntity(ent)` → Valid or world  
  - `IsValidReforger(ent)` → Checks compatibility  
  - `DoInDev(func)` → Executes only in dev mode  

---

## Vehicle Utilities
Unified vehicle detection and handling.

- **Functions**
  - `GetVehicleBase(ent)` → Detects base (lvs, glide, simfphys)  
  - `GetVehicleType(ent)` → Resolves type (LIGHT, PLANE, etc.)  
  - `GetHealth(ent)` → Returns health by base  

- **Notes**
  - Internal `_ResolveVehicleType(ent)` handles type resolution  
  - All functions validate entities first  
