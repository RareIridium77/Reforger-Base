# Reforger Base

**Reforger Base** is a shared system for my Garry's Mod addons under the [Reforger] tag.  
Its main purpose is to provide a unified damage and logic framework for different vehicle systems, such as:

- **[LVS](https://github.com/SpaxscE/lvs_base)**
- **[Simfphys](https://github.com/SpaxscE/simfphys_base)** 
- **[Gmod Glide](https://github.com/StyledStrike/gmod-glide)**

# Shared Hooks

- Reforger.Init -- called when Reforger Inits.
- Reforger.GlobalThink -- Just called by Think. Like general update tick.
- Reforger.EntityFunctionsCalled(ent) -- called every Reforger.CallEntityFunctions

- Reforger.PreEntityDamage(ent, damage, attacker, inflictor, reforgerDamageType, damagePos) -- called every Reforger.ApplyDamageToEnt valid calls
- Reforger.PlayerDirectDamage(player, vehicle, damageInfo) -- called every Reforger.ApplyPlayersDamage valid calls

**LVS**
- Reforger.LVS_BulletFired(bullet) -- Called every LVS bullet fire.

# Possibly Conflicting Addons

- [Damage Players In Seats](https://steamcommunity.com/sharedfiles/filedetails/?id=428278317) (May increase damage to players in vehicle)

## License

You can freely use and modify this base within your GMod projects, but attribution is appreciated.

