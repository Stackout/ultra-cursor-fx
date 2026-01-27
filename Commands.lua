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
        addon:UpdateCursorState()
        print("UltraCursorFX disabled")
    elseif cmd == "on" then
        UltraCursorFXDB.enabled = true
        addon:UpdateCursorState()
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
    elseif cmd == "combat" then
        UltraCursorFXDB.combatOnly = not UltraCursorFXDB.combatOnly
        print("Combat Only Mode:", UltraCursorFXDB.combatOnly and "Enabled" or "Disabled")
        addon:UpdateCursorState()
    elseif cmd == "fade" then
        UltraCursorFXDB.fadeEnabled = not UltraCursorFXDB.fadeEnabled
        print("Fade Mode:", UltraCursorFXDB.fadeEnabled and "Enabled" or "Disabled")
    elseif cmd == "boost" then
        UltraCursorFXDB.combatOpacityBoost = not UltraCursorFXDB.combatOpacityBoost
        print("Combat Opacity Boost:", UltraCursorFXDB.combatOpacityBoost and "Enabled" or "Disabled")
    elseif cmd == "reticle" then
        UltraCursorFXDB.reticleEnabled = not UltraCursorFXDB.reticleEnabled
        addon:BuildTrail() -- Rebuild reticle
        print("Smart Reticle:", UltraCursorFXDB.reticleEnabled and "Enabled" or "Disabled")
    elseif cmd == "edge" then
        UltraCursorFXDB.edgeWarningEnabled = not UltraCursorFXDB.edgeWarningEnabled
        addon:BuildTrail() -- Rebuild edge warnings
        print("Screen Edge Warnings:", UltraCursorFXDB.edgeWarningEnabled and "Enabled" or "Disabled")
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
    elseif cmd == "spell" then
        local subCmd, arg = msg:match("%S+%s+(%S+)%s*(%S*)")
        if not subCmd then
            print("|cFFFF0000UltraCursorFX:|r Spell Tracker Commands:")
            print("  /ucfx spell toggle - Toggle spell tracker on/off")
            print("  /ucfx spell add <spellID> - Add spell to tracker")
            print("  /ucfx spell remove <spellID> - Remove spell from tracker")
            print("  /ucfx spell list - List all tracked spells")
            print("  /ucfx spell combat - Toggle combat-only mode")
        elseif subCmd == "toggle" then
            addon:ToggleSpellTracker()
        elseif subCmd == "add" then
            local spellID = tonumber(arg)
            if spellID then
                addon:AddTrackedSpell(spellID)
            else
                print("|cFFFF0000UltraCursorFX:|r Usage: /ucfx spell add <spellID>")
                print("|cFFFFD700Tip:|r Shift-click a spell in your spellbook to link it in chat, then copy the ID")
            end
        elseif subCmd == "remove" then
            local spellID = tonumber(arg)
            if spellID then
                addon:RemoveTrackedSpell(spellID)
            else
                print("|cFFFF0000UltraCursorFX:|r Usage: /ucfx spell remove <spellID>")
            end
        elseif subCmd == "list" then
            addon:ListTrackedSpells()
        elseif subCmd == "combat" then
            UltraCursorFXDB.spellTrackerCombatOnly = not UltraCursorFXDB.spellTrackerCombatOnly
            addon:RefreshSpellTracker()
            print("|cff00ffffUltraCursorFX:|r Spell Tracker Combat-Only Mode: " .. (UltraCursorFXDB.spellTrackerCombatOnly and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"))
        else
            print("|cFFFF0000UltraCursorFX:|r Unknown spell command. Type /ucfx spell for help.")
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
        print("/ucfx spell - Spell tracker commands (add/remove/list spells)")
        print("/ucfx profiles - Toggle situational profiles")
        print("/ucfx save <profile> - Save current settings to profile")
        print("/ucfx load <profile> - Load profile settings")
        print("   Profiles: world, raid, dungeon, arena, battleground")
        print("/ucfx export - Export settings to chat")
        print("/ucfx import <string> - Import settings from string")
    end
end
