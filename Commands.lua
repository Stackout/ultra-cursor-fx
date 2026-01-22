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
        UltraCursorFXDB.enabled = false
        addon.frame:SetScript("OnUpdate", nil)
        print("UltraCursorFX disabled")
    elseif cmd == "on" then
        UltraCursorFXDB.enabled = true
        addon.frame:SetScript("OnUpdate", function(self, elapsed) 
            addon:OnUpdate(elapsed) 
        end)
        print("UltraCursorFX enabled")
    elseif cmd == "flash" then
        UltraCursorFXDB.flashEnabled = not UltraCursorFXDB.flashEnabled
        print("Flash:", UltraCursorFXDB.flashEnabled)
    elseif cmd == "rainbow" then
        UltraCursorFXDB.rainbowMode = not UltraCursorFXDB.rainbowMode
        print("Rainbow Mode:", UltraCursorFXDB.rainbowMode)
    elseif cmd == "click" then
        UltraCursorFXDB.clickEffects = not UltraCursorFXDB.clickEffects
        print("Click Effects:", UltraCursorFXDB.clickEffects)
    elseif cmd == "comet" then
        UltraCursorFXDB.cometMode = not UltraCursorFXDB.cometMode
        print("Comet Mode:", UltraCursorFXDB.cometMode)
    elseif cmd == "profiles" then
        UltraCursorFXDB.situationalEnabled = not UltraCursorFXDB.situationalEnabled
        print("Situational Profiles:", UltraCursorFXDB.situationalEnabled and "Enabled" or "Disabled")
        if UltraCursorFXDB.situationalEnabled then
            addon:SwitchToZoneProfile()
        end
    elseif cmd == "save" then
        local profile = msg:match("%S+%s+(%S+)")
        if profile and UltraCursorFXDB.profiles[profile] then
            addon:SaveToProfile(profile)
            local profileName = UltraCursorFXDB.profiles[profile].name or profile
            print("|cFF00FFFFUltraCursorFX:|r Saved current settings to " .. profileName .. " profile")
        else
            print("|cFFFF0000UltraCursorFX:|r Usage: /ucfx save <world|raid|dungeon|arena|battleground>")
        end
    elseif cmd == "load" then
        local profile = msg:match("%S+%s+(%S+)")
        if profile and UltraCursorFXDB.profiles[profile] then
            addon:LoadFromProfile(profile)
            local profileName = UltraCursorFXDB.profiles[profile].name or profile
            print("|cFF00FFFFUltraCursorFX:|r Loaded " .. profileName .. " profile")
        else
            print("|cFFFF0000UltraCursorFX:|r Usage: /ucfx load <world|raid|dungeon|arena|battleground>")
        end
    elseif cmd == "export" then
        local exportString = addon:ExportSettings()
        print("|cFF00FFFFUltraCursorFX Export String:|r")
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
        print("/ucfx on | off | flash | rainbow | click | comet")
        print("/ucfx profiles - Toggle situational profiles")
        print("/ucfx save <profile> - Save current settings to profile")
        print("/ucfx load <profile> - Load profile settings")
        print("   Profiles: world, raid, dungeon, arena, battleground")
        print("/ucfx export - Export settings to chat")
        print("/ucfx import <string> - Import settings from string")
    end
end
