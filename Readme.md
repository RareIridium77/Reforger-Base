# Reforger Base  
**Reforger Base** is a shared system for my Garry's Mod addons under the [Reforger] tag.  
Its main purpose is to provide a unified damage and logic framework for different vehicle systems, such as:

- **[LVS](https://github.com/SpaxscE/lvs_base)**
- **[Simfphys](https://github.com/SpaxscE/simfphys_base)** 
- **[Gmod Glide](https://github.com/StyledStrike/gmod-glide)**

**For getting Reforger table write console command: `dev.reforger.framework.table`**

**Reforger can also automatically load your modules from your addons folder.**

**Example**:  
`my_addon/lua/reforger/m/server/reforger_my_module.lua`
```lua
-- /reforger/m/server/reforger_my_module.lua
if Reforger then
    for i = 0, 10 do
        Reforger.Log("You loaded the test file")
    end
end
```  
**Example output:**  
<img width="277" height="122" alt="output console." src="https://github.com/user-attachments/assets/7d81278f-bc11-4919-944f-b199345c5f3e" />

## Potentially Conflicting Addons  
These addons may interfere with Reforger's damage logic and cause unintended behavior:  
- [Damage Players In Seats](https://steamcommunity.com/sharedfiles/filedetails/?id=428278317)  
  _May apply additional damage to players inside vehicles._  
- [[LVS & Simfphys] Derby and more crash damage](https://steamcommunity.com/sharedfiles/filedetails/?id=3327523626)  
  _May override or conflict with Reforger's collision damage system._

## License  
You can freely use and modify this base within your GMod projects, but attribution is appreciated.