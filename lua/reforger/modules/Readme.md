# Reforger Modules

This folder provides modular extensions for vehicles, damage, and entity systems.  
Each module integrates with Garry’s Mod bases (LVS, Simfphys, Glide) and extends functionality with hooks and utilities.

---

## LVS Integration
Extends LVS entities with projectiles, weapons, bullet system, and explosions.

- **Bullet System**
  - Hooks into `LVS.FireBullet`  
  - Adds filters, callbacks, and collision handling  

- **Projectiles**
  - Adds hooks for bombs and missiles (activation, collision, detonation, touch)  
  - `IsProjectile(ent)` → Checks if entity is projectile  
  - `IsBomb(ent)` / `IsMissile(ent)`  

- **Weapons**
  - `IsWeaponed(veh)` → Checks if vehicle has weapons  
  - `Get(veh)` → Returns weapon groups  
  - `GetActive(veh)` → Returns selected weapon  

- **Hooks**
  - `LVS_BulletFired`, `LVS_BulletOnCollide`, `LVS_BulletCallback`  
  - `LVS_Exploded`  
  - `LVS_BombTouch / Activated / Collide / Detonated`  
  - `LVS_MissileTouch / Activated / Collide / Detonated`  
  - `LVS_WeaponInit / StartAttack / CanAttack / Attack / FinishAttack`  
  - `LVS_ProjectileTouch / Activated / Collide / Detonated`  

---

## Armored
Handles ammorack logic for armored vehicles.

- **Functions**
  - `DamageAmmoracks(veh, dmginfo)` → Applies damage to ammoracks  
  - `GetAmmoracks(veh)` → Returns cached ammoracks  
  - `IsAmmorackDestroyed(veh)` → Checks destruction state  
  - `_internal:CacheAmmorack(veh)` → Scans and caches  

---

## Damage
Provides utilities for applying and handling damage.

- **Functions**
  - Type detection: `HasDamageType`, `HasAnyType`, `IsMeleeDamageType`, `IsSmallDamageType`, `IsCollisionDamageType`, `IsFireDamageType`  
  - `FixDamageForce(dmginfo, attacker, victim)`  
  - `ApplyDamageToEnt(ent, ...)` → Direct damage  
  - `ApplyPlayerDamage(ply, ...)` / `ApplyPlayersDamage(veh, dmginfo)`  
  - `DamageParts(veh, damage)` → Reduces part HP  
  - `HandleCollisionDamage(veh, dmginfo)` → Fire/explosion chance  
  - `HandleRayDamage(veh, dmginfo)` → Traced damage with falloff  
  - Ignition: `IgniteLimited(ent, size, repeatCount)` / `StopLimitedFire(ent)`  

- **Hooks**
  - `EntityTakeDamage` → Routes into Reforger  

---

## Engines
Handles Simfphys & Glide engine entities.

- **Functions**
  - `_internal:CacheEngine(veh)` → Refreshes engine entity  
  - `SpawnEngine(veh, offset)` → Creates and attaches engine  

---

## Pods
Manages collision pods for players inside vehicles.

- **Hooks**
  - `PlayerEnteredVehicle` → Creates pod  
  - `PlayerLeaveVehicle` → Removes pod  

---

## Rotors
Manages rotor entities for helicopters and planes.

- **Functions**
  - `RotorsGetDamage(veh, dmginfo)` → Handles rotor damage  
  - `DestroyRotor(rotor)` → Marks destroyed  
  - `IsRotorSpinning(rotor)` → Status check  
  - `FindRotorAlongRay(veh, dmginfo)` → Traced hit detection  
  - `FindRotors(veh)` / `GetRotors(veh)` → Cache access  
  - `RepairRotors(veh)` → Repairs  
  - `_internal:CacheRotors(veh)` → Scans and caches  

- **Config (ConVars, `reforger.`)**
  - `rotor.chance.damage` → Normal damage chance  
  - `rotor.chance.damage.critical` → Critical damage chance  
  - `rotor.chance.ignite` → Ignition chance  
  - `rotor.time.ignite` → Ignition duration  

- **Hooks**
  - `PreRotorDamage`, `PostRotorDamage`  
  - `RotorGotCriticalDamage`  
  - `RotorIgnited`  
  - `RotorDestroyed`  
  - `RotorsCached`  

---

## Scanners
Utility functions for entity and player scanning.

- **Functions**
  - `PairEntity(parent, className)` → First child entity by class  
  - `PairEntityAll(parent, className)` → All children by class  
  - `FindClosestByClass(veh, dmginfo, className)` → Finds closest child via ray  
  - `GetEveryone(veh)` → All players inside a vehicle  
