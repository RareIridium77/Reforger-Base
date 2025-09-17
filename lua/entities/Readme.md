# Reforger Entities

These entities provide custom collision and damage handling for vehicles and players inside Reforger systems.  
They extend Garry’s Mod entities with specialized hitboxes, lifecycle logic, and safety features.

---

## Fake Player Collision Entity
Proxy collision hitbox for seated players.  
Enables accurate bullet and trace damage handling, including headshots.

- **Properties**
  - `IsReforgerEntity`, `ReforgerDamageable`  
  - `PhysgunDisabled`, `DoNotDuplicate`, `DisableDuplicator`  
  - `CallDamageHook`  

- **Constants**
  - `COLLISION_UPDATE_INTERVAL` → Hitbox refresh rate  
  - `HEAD_ZONE_RATIO` → Head hitbox proportion  
  - `DAMAGE_REDUCTION_*` → Multipliers for armored/traced damage  
  - `EXTENT_SCALE`, `MARGIN` → Collision bounds scaling  
  - `HEADSHOT_ZONE_*` → Headshot detection region  
  - `TRACE_LENGTH`, `BACK_OFFSET` → OBB intersection tracing  

- **Lifecycle**
  - `InitReforgerEntity()` → Sets defaults  
  - `SetPlayer(ply)` → Assigns target  
  - `SetVehicle(veh)` → Parents to vehicle  
  - `Think()` → Updates collision bounds with animation and bones  
  - `OnTakeDamage(dmginfo)` → Handles scaling, headshots, trace checks, applies player damage  

- **Features**
  - Dynamic collision bounds  
  - Bone-based head alignment  
  - Headshot detection with bonus damage  
  - Prevents invalid shots through armor  
  - Debug overlays in dev mode  

---

## Fake Engine Collision Entity
Custom collision hitbox for Glide and Simfphys engines.  
Allows engine-specific damage simulation.

- **Properties**
  - `IsReforgerEntity`, `ReforgerDamageable`  
  - `PhysgunDisabled`, `DoNotDuplicate`, `DisableDuplicator`  
  - `CallDamageHook`  

- **Constants**
  - `COLLISION_BOUNDS` → Engine hitbox  
  - `ENGINE_HEALTH` → Base HP (Simfphys)  
  - `DAMAGE_REDUCTION` → Simfphys multiplier  
  - `DAMAGE_RAND_MIN/MAX` → Glide random scaling  
  - `STALL_THRESHOLD` → Simfphys stalling chance  
  - `FIRE_THRESHOLD` → Ignition chance  
  - `DEBUG_*` → Overlay settings  

- **Lifecycle**
  - `InitReforgerEntity()` → Sets collision and trigger state  
  - `SetEngineData(data)` → Parents to vehicle  
  - `Think()` → Maintains overlays, validates parent  
  - `OnTakeDamage(dmginfo)`  
    - Glide: Randomized engine damage  
    - Simfphys: Reduced damage, stalling, ignition  

---

## Base Entity
Shared base class for Reforger entities.  
Provides safety and integration with vehicles.

- **Properties**
  - `IsReforgerEntity`, `ReforgerDamageable`  
  - `PhysgunDisabled`, `DoNotDuplicate`, `DisableDuplicator`  
  - `CallDamageHook`  

- **Special Handling**
  - `BaseEntityIgnore["rpg_missile"]` → Fixes collision reset for RPG missiles  

- **Lifecycle**
  - `InitReforgerEntity()` → Custom initializer (override)  
  - `Initialize()` → Enables damage, runs init and hook  
  - `Think()`, `OnTakeDamage(dmg)`, `OnRemove()`  

- **Vehicle Integration**
  - `SetVehicleBase(veh)` → Links entity, adds to Glide trace filter  
  - `RemoveVehicleBase()` → Cleans up from filter  

- **Collision**
  - `StartTouch(e)` → Ignores entities per `BaseEntityIgnore`  
