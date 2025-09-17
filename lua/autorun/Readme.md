# Reforger Framework Initializationn

`reforger_init.lua` - main initialization file of framework **Reforger**.  

Reforger Base is a shared system for my Garry's Mod addons under the [Reforger] tag.  
Its main purpose is to provide a unified damage and logic framework for different vehicle systems, such as:  
Supports **LVS**, **Simfphys** и **Gmod Glide**.  

---

## Purpose
- Initializes the Reforger framework  
- Ensures compatibility with installed vehicle bases  
- Manages networking, global hooks, and reload logic  

---

## Versioning
- `Reforger.Version` → Current version (e.g. `"0.3"`)  
- `Reforger.VersionType` → Release type (e.g. `"stable"`)  

---

## Networking
- `"Reforger.NotifyDisabled"` → Sent when framework is disabled server-side  
- `"Reforger.InitializeEntity"` → Initializes entity state  

---

## Lifecycle
- **`InitPostEntity()`**
  - Verifies installed vehicle bases  
  - Disables framework if none found (removes hooks, warns server)  
  - Otherwise, schedules `Reforger.Init` after 5 seconds  

- **`EntityCreated(ent)`**
  - Runs on entity creation  
  - Initializes valid entities under Reforger  

- **`GlobalThink()`**
  - Runs every ~1ms  
  - Dispatches `Reforger.GlobalThink` for internal logic  

---

## Hooks
- `OnEntityCreated` → Calls `Reforger:InitializeEntity`  
- `InitPostEntity` → Runs base check and setup  
- `Think` → Executes `Reforger.GlobalThink` with throttling  
- `Reforger.Reload` → Resets framework and reloads loader  

---

## Features
- Automatic disabling if no supported base is installed  
- Disabled status broadcast to clients  
- Developer logging and reload support  