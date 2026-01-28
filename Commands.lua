-- ===============================
-- UltraCursorFX - Commands Module
-- ===============================

local addon = UltraCursorFX

-- ===============================
-- Slash Commands
-- ===============================
SLASH_ULTRACURSORFX1 = "/ucfx"
SlashCmdList["ULTRACURSORFX"] = function(msg)
    local cmd = msg:match("%S+") or ""
    cmd = cmd:lower()

    if cmd == "off" then
        addon:SetSetting("enabled", false)
        addon:UpdateCursorState()
        print("UltraCursorFX disabled")
    elseif cmd == "on" then
        addon:SetSetting("enabled", true)
        addon:UpdateCursorState()
        print("UltraCursorFX enabled")
    elseif cmd == "flash" then
        local newVal = not addon:GetSetting("flashEnabled")
        addon:SetSetting("flashEnabled", newVal)
        print("Flash:", newVal)
    elseif cmd == "rainbow" then
        local newVal = not addon:GetSetting("rainbowMode")
        addon:SetSetting("rainbowMode", newVal)
        print("Rainbow Mode:", newVal)
    elseif cmd == "click" then
        local newVal = not addon:GetSetting("clickEffects")
        addon:SetSetting("clickEffects", newVal)
        print("Click Effects:", newVal)
    elseif cmd == "comet" then
        local newVal = not addon:GetSetting("cometMode")
        addon:SetSetting("cometMode", newVal)
        print("Comet Mode:", newVal)
    elseif cmd == "combat" then
        local newVal = not addon:GetSetting("combatOnly")
        addon:SetSetting("combatOnly", newVal)
        print("Combat Only Mode:", newVal and "Enabled" or "Disabled")
        addon:UpdateCursorState()
    elseif cmd == "fade" then
        local newVal = not addon:GetSetting("fadeEnabled")
        addon:SetSetting("fadeEnabled", newVal)
        print("Fade Mode:", newVal and "Enabled" or "Disabled")
    elseif cmd == "boost" then
        local newVal = not addon:GetSetting("combatOpacityBoost")
        addon:SetSetting("combatOpacityBoost", newVal)
        print("Combat Opacity Boost:", newVal and "Enabled" or "Disabled")
    elseif cmd == "reticle" then
        local newVal = not addon:GetSetting("reticleEnabled")
        addon:SetSetting("reticleEnabled", newVal)
        addon:BuildTrail() -- Rebuild reticle
        print("Smart Reticle:", newVal and "Enabled" or "Disabled")
    elseif cmd == "edge" then
        local newVal = not addon:GetSetting("edgeWarningEnabled")
        addon:SetSetting("edgeWarningEnabled", newVal)
        addon:BuildTrail() -- Rebuild edge warnings
        print("Screen Edge Warnings:", newVal and "Enabled" or "Disabled")
    elseif cmd == "profiles" then
        local newVal = not addon:GetSetting("situationalEnabled")
        addon:SetSetting("situationalEnabled", newVal)
        print("Situational Profiles:", newVal and "Enabled" or "Disabled")
        if newVal then
            addon:SwitchToZoneProfile()
        end
    elseif cmd == "save" then
        local profile = msg:match("%S+%s+(%S+)")
        local profiles = addon:GetActiveProfileTable()
        if profile and profiles[profile] then
            addon:SaveToProfile(profile)
            local profileName = profiles[profile].name or profile
            local charKey = addon:GetCharacterKey()
            local charData = UltraCursorFXDB.characters and UltraCursorFXDB.characters[charKey]
            local scope = (charData and charData.useAccountSettings) and "account-wide" or charKey
            print(
                "|cFF00FFFFUltraCursorFX:|r Saved current settings to " .. profileName .. " profile (" .. scope .. ")"
            )
        else
            print("|cFFFF0000UltraCursorFX:|r Usage: /ucfx save <world|raid|dungeon|arena|battleground>")
        end
    elseif cmd == "load" then
        local profile = msg:match("%S+%s+(%S+)")
        local profiles = addon:GetActiveProfileTable()
        if profile and profiles[profile] then
            addon:LoadFromProfile(profile)
            local profileName = profiles[profile].name or profile
            local charKey = addon:GetCharacterKey()
            local charData = UltraCursorFXDB.characters and UltraCursorFXDB.characters[charKey]
            local scope = (charData and charData.useAccountSettings) and "account-wide" or charKey
            print("|cFF00FFFFUltraCursorFX:|r Loaded " .. profileName .. " profile (" .. scope .. ")")
        else
            print("|cFFFF0000UltraCursorFX:|r Usage: /ucfx load <world|raid|dungeon|arena|battleground>")
        end
    elseif cmd == "export" then
        local exportString = addon:ExportSettings()
        local charKey = addon:GetCharacterKey()
        local charData = UltraCursorFXDB.characters and UltraCursorFXDB.characters[charKey]
        local scope = (charData and not charData.useAccountSettings) and "character-specific" or "account-wide"
        print("|cFF00FFFFUltraCursorFX Export String:|r " .. charKey .. " (" .. scope .. ")")
        print(exportString)
        print("|cFFFFD700Copy the string above to share your settings!|r")
    elseif cmd == "import" then
        local importString = msg:sub(8) -- Remove "import " prefix
        if importString and importString ~= "" then
            local success, message = addon:ImportSettings(importString)
            if success then
                addon:BuildTrail()
                print("|cFF00FFFFUltraCursorFX:|r " .. message)
            else
                print("|cFFFF0000UltraCursorFX Error:|r " .. message)
            end
        else
            print("|cFFFF0000UltraCursorFX:|r Usage: /ucfx import <import string>")
        end
    elseif cmd == "config" or cmd == "" then
        if addon.settingsPanel then
            if Settings and addon.settingsPanel.category then
                Settings.OpenToCategory(addon.settingsPanel.category.ID)
            elseif InterfaceOptionsFrame_OpenToCategory then
                InterfaceOptionsFrame_OpenToCategory(addon.settingsPanel)
                InterfaceOptionsFrame_OpenToCategory(addon.settingsPanel)
            end
        end
    else
        print("UltraCursorFX commands:")
        print("/ucfx - Open settings")
        print("/ucfx on | off | flash | rainbow | click | comet | combat")
        print("/ucfx fade - Toggle fade mode | boost - Toggle combat opacity boost")
        print("/ucfx reticle - Toggle smart reticle system")
        print("/ucfx edge - Toggle screen edge warnings")
        print("/ucfx profiles - Toggle situational profiles")
        print("/ucfx save <profile> - Save current settings to profile")
        print("/ucfx load <profile> - Load profile settings")
        print("   Profiles: world, raid, dungeon, arena, battleground")
        print("/ucfx export - Export settings to chat")
        print("/ucfx import <string> - Import settings from string")
    end
end
