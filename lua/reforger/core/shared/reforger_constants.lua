--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

--[[
    Reforger Core Constants
    - Defines enums and constants used across Reforger modules
    - Sections:
        * Logging
            - LogLevels → INFO, WARN, DEV, ERROR
            - LogColors → Color mapping for log types
        * Networking
            - NetworkTypes → Allowed networked data types
        * Vehicles
            - VehicleTypes → LIGHT, ARMORED, PLANE, HELICOPTER, UNDEFINED
            - VehicleBases → Glide, LVS, Simfphys
            - ValidClasslist → Whitelisted vehicle-related classnames
]]

Reforger = Reforger or {}

-- // SECTION Logging

Reforger.LogLevels = {
    INFO = "INFO",
    WARN = "WARN",
    DEV  = "DEV",
    ERROR = "ERROR"
}

Reforger.LogColors = {
    INFO  = Color(146, 236, 104),
    WARN  = Color(238, 105, 52),
    DEV   = Color(128, 104, 236),
    ERROR = Color(255, 0, 0),
    TEXT  = Color(100, 178, 241),
    LOC   = Color(200, 200, 200)
}

-- // !SECTION

-- // SECTION Networking

Reforger.NetworkTypes = {
    Bool = true,
    Float = true,
    String = true,
    Int = true,
    Vector = true,
    Angle = true,
    Entity = true
}

-- // !SECTION

-- // SECTION Reforger Vehicles

Reforger.VehicleTypes = {
    LIGHT = "light",
    ARMORED = "armored",
    PLANE = "plane",
    HELICOPTER = "helicopter",
    UNDEFINED = "undefined"
}

Reforger.VehicleBases = {
    Glide = "glide",
    LVS = "lvs",
    Simfphys = "simfphys"
}

Reforger.ValidClasslist = {
    ["gmod_sent_vehicle_fphysics_gib"] = true,
    ["gmod_sent_vehicle_fphysics_base"] = true,
    ["simfphys_tankprojectile"] = true,
    ["glide_gib"] = true,
}

-- // !SECTION