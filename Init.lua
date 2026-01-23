-- ===============================
-- UltraCursorFX - Main Initialization
-- ===============================

local addon = UltraCursorFX

-- ===============================
-- Event Handler
-- ===============================
addon.frame:RegisterEvent("ADDON_LOADED")
addon.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
addon.frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat
addon.frame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Leaving combat

addon.frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "UltraCursorFX" then
        self:UnregisterEvent("ADDON_LOADED")

        -- Initialize defaults
        addon:InitializeDefaults()

        -- Migrate and initialize profiles
        addon:MigrateProfiles()

        -- Build initial trail
        addon:BuildTrail()

        -- Create settings panel (defined in UI.lua)
        if addon.CreateSettingsPanel then
            addon:CreateSettingsPanel()
        end

        -- Start animation loop if enabled
        if UltraCursorFXDB.enabled then
            addon:UpdateCursorState()
        end

        print("|cFF00FFFFUltraCursorFX|r loaded! Type |cFFFFD700/ucfx|r for settings")
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Auto-switch profiles when entering new zones
        addon:SwitchToZoneProfile()
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat
        addon.inCombat = true
        addon:UpdateCursorState()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat
        addon.inCombat = false
        addon:UpdateCursorState()
    end
end)
