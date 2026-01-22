-- Luacheck configuration
std = "lua51"

-- Global variables provided by WoW
globals = {
    "UltraCursorFXDB",
    "UltraCursorFX",
    "UIParent",
    "CreateFrame",
    "IsInInstance",
    "GetInstanceInfo",
    "GetCursorPosition",
    "IsMouseButtonDown",
    "Settings",
    "InterfaceOptions_AddCategory",
    "InterfaceOptionsFrame_OpenToCategory",
    "ColorPickerFrame",
    "GameTooltip",
    "wipe",
    "print",
    -- Slash commands and keybinding globals
    "UltraCursorFX_Toggle",
    "UltraCursorFX_ToggleFlash",
    "SLASH_ULTRACURSORFX1",
    "SlashCmdList",
    -- Localization binding strings
    "BINDING_HEADER_ULTRACURSORFX",
    "BINDING_NAME_ULTRACURSORFX_TOGGLE",
    "BINDING_NAME_ULTRACURSORFX_FLASH",
}

-- Exclude generated or vendored files
exclude_files = {
    "spec/",
    ".luacheckrc",
    "UltraCursorFX.lua.old",
}

-- Warnings to ignore
ignore = {
    "212", -- Unused argument (common in WoW callbacks)
    "611", -- Line contains only whitespace (formatting preference)
    "612", -- Line contains trailing whitespace (will fix separately)
    "431", -- Shadowing upvalue (common pattern in WoW UI callbacks)
}

-- Files with special rules
files["Bindings.xml"] = {
    ignore = {".*"}
}

-- UI.lua uses self parameter in nested callbacks (common WoW pattern)
files["UI.lua"] = {
    ignore = {"432"} -- Shadowing upvalue argument 'self'
}
