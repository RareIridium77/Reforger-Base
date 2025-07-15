Reforger = Reforger or {}

function Reforger.Export(name, modl, force)
    assert(isstring(name), "Export name must be a string!")
    assert(istable(modl), "Module must be a table!")

    if Reforger[name] ~= nil and not force then
        ErrorNoHaltWithStack(
            string.format(
                "[Reforger.Export] Export '%s' already exists in Reforger. Use unique names or nested tables. Example: Reforger.Export('LogicSystem', {...})",
                name
            )
        )
        return
    end

    Reforger[name] = modl
end
