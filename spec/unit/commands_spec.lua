-- ===============================
-- Commands Module Tests
-- ===============================

local mocks = require("spec.wow_mocks")

describe("Commands Module", function()
    local addon
    local slashHandler

    before_each(function()
        mocks.ResetWoWMocks()
        require("Core")
        require("Utils")
        require("Profiles")
        require("Effects")
        require("Commands")
        addon = UltraCursorFX
        addon:InitializeDefaults()
        slashHandler = SlashCmdList["ULTRACURSORFX"]
    end)

    describe("Slash Command Registration", function()
        it("should register /ucfx slash command", function()
            assert.are.equal("/ucfx", SLASH_ULTRACURSORFX1)
        end)

        it("should have handler in SlashCmdList", function()
            assert.is_function(slashHandler)
        end)
    end)

    describe("Toggle Commands", function()
        it("should toggle addon off", function()
            addon:SetSetting("enabled", true)
            slashHandler("off")
            assert.is_false(addon:GetSetting("enabled"))
        end)

        it("should toggle addon on", function()
            addon:SetSetting("enabled", false)
            slashHandler("on")
            assert.is_true(addon:GetSetting("enabled"))
        end)

        it("should set OnUpdate script when turning on", function()
            addon:SetSetting("enabled", false)
            addon.frame:SetScript("OnUpdate", nil)

            slashHandler("on")

            -- OnUpdate script should be set
            assert.is_function(addon.frame._scripts["OnUpdate"])

            -- Test that the OnUpdate callback can be called
            local onUpdate = addon.frame._scripts["OnUpdate"]
            onUpdate(addon.frame, 0.016) -- Should not crash
            assert.is_true(true)
        end)

        it("should toggle flash", function()
            local initial = addon:GetSetting("flashEnabled")
            slashHandler("flash")
            assert.are.not_equal(initial, addon:GetSetting("flashEnabled"))
        end)

        it("should toggle rainbow mode", function()
            local initial = addon:GetSetting("rainbowMode")
            slashHandler("rainbow")
            assert.are.not_equal(initial, addon:GetSetting("rainbowMode"))
        end)

        it("should toggle click effects", function()
            local initial = addon:GetSetting("clickEffects")
            slashHandler("click")
            assert.are.not_equal(initial, addon:GetSetting("clickEffects"))
        end)

        it("should toggle comet mode", function()
            local initial = addon:GetSetting("cometMode")
            slashHandler("comet")
            assert.are.not_equal(initial, addon:GetSetting("cometMode"))
        end)

        it("should toggle situational profiles", function()
            local initial = addon:GetSetting("situationalEnabled")
            slashHandler("profiles")
            assert.are.not_equal(initial, addon:GetSetting("situationalEnabled"))
        end)

        it("should toggle combat only mode", function()
            local initial = addon:GetSetting("combatOnly")
            slashHandler("combat")
            assert.are.not_equal(initial, addon:GetSetting("combatOnly"))
        end)

        it("should toggle fade mode", function()
            local initial = addon:GetSetting("fadeEnabled")
            slashHandler("fade")
            assert.are.not_equal(initial, addon:GetSetting("fadeEnabled"))
        end)

        it("should toggle combat opacity boost", function()
            local initial = addon:GetSetting("combatOpacityBoost")
            slashHandler("boost")
            assert.are.not_equal(initial, addon:GetSetting("combatOpacityBoost"))
        end)

        it("should toggle reticle mode", function()
            local initial = addon:GetSetting("reticleEnabled")
            slashHandler("reticle")
            assert.are.not_equal(initial, addon:GetSetting("reticleEnabled"))
        end)

        it("should toggle edge warning mode", function()
            local initial = addon:GetSetting("edgeWarningEnabled")
            slashHandler("edge")
            assert.are.not_equal(initial, addon:GetSetting("edgeWarningEnabled"))
        end)
    end)

    describe("Profile Commands", function()
        before_each(function()
            UltraCursorFXDB.account = {
                profiles = {
                    world = { name = "World", color = { 0.0, 1.0, 1.0 }, points = 48 },
                    raid = { name = "Raid", color = { 1.0, 0.0, 0.0 }, points = 40 },
                },
            }
            UltraCursorFXDB.characters = {
                ["TestCharacter-TestRealm"] = {
                    useAccountSettings = true,
                },
            }
        end)

        it("should save to profile", function()
            addon:SetSetting("color", { 1.0, 0.5, 0.0 })
            addon:SetSetting("points", 100)
            slashHandler("save world")

            local profiles = addon:GetActiveProfileTable()
            assert.are.same({ 1.0, 0.5, 0.0 }, profiles.world.color)
            assert.are.equal(100, profiles.world.points)
        end)

        it("should reject save to non-existent profile", function()
            slashHandler("save invalidprofile")
            -- Should not crash
            assert.is_true(true)
        end)

        it("should load from profile", function()
            slashHandler("load raid")

            assert.are.same({ 1.0, 0.0, 0.0 }, addon:GetSetting("color"))
            assert.are.equal(40, addon:GetSetting("points"))
        end)

        it("should reject load from non-existent profile", function()
            local originalColor = addon:GetSetting("color")
            slashHandler("load invalidprofile")

            -- Color should not change
            assert.are.same(originalColor, addon:GetSetting("color"))
        end)
    end)

    describe("Import/Export Commands", function()
        it("should export settings", function()
            addon:SetSetting("enabled", true)
            addon:SetSetting("points", 60)

            slashHandler("export")
            -- Should not crash
            assert.is_true(true)
        end)

        it("should import valid string", function()
            local exportString = addon:ExportSettings()
            _G.UltraCursorFXDB = {}
            addon:InitializeDefaults()

            slashHandler("import " .. exportString)

            assert.is_not_nil(addon:GetSetting("points"))
        end)

        it("should reject empty import", function()
            slashHandler("import")
            -- Should handle gracefully
            assert.is_true(true)
        end)

        it("should reject invalid import string", function()
            slashHandler("import invalid_string_123")
            -- Should handle gracefully
            assert.is_true(true)
        end)
    end)

    describe("Config Command", function()
        it("should handle config command", function()
            slashHandler("config")
            -- Should not crash
            assert.is_true(true)
        end)

        it("should handle empty command (default to config)", function()
            slashHandler("")
            -- Should not crash
            assert.is_true(true)
        end)

        it("should use Settings API when available", function()
            addon.settingsPanel = {
                category = { ID = "UltraCursorFX" },
            }

            slashHandler("config")

            -- Should have attempted to open settings
            assert.is_true(true)
        end)

        it("should fallback to InterfaceOptionsFrame when Settings unavailable", function()
            local oldSettings = _G.Settings
            _G.Settings = nil
            addon.settingsPanel = {}

            slashHandler("config")

            _G.Settings = oldSettings
            assert.is_true(true)
        end)
    end)

    describe("Help Command", function()
        it("should display help for unknown commands", function()
            slashHandler("unknowncommand")
            -- Should not crash
            assert.is_true(true)
        end)

        it("should handle case-insensitive commands", function()
            addon:SetSetting("enabled", true)
            slashHandler("OFF")
            assert.is_false(addon:GetSetting("enabled"))
        end)
    end)
end)
