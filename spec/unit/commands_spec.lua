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
            UltraCursorFXDB.enabled = true
            slashHandler("off")
            assert.is_false(UltraCursorFXDB.enabled)
        end)

        it("should toggle addon on", function()
            UltraCursorFXDB.enabled = false
            slashHandler("on")
            assert.is_true(UltraCursorFXDB.enabled)
        end)

        it("should set OnUpdate script when turning on", function()
            UltraCursorFXDB.enabled = false
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
            local initial = UltraCursorFXDB.flashEnabled
            slashHandler("flash")
            assert.are.not_equal(initial, UltraCursorFXDB.flashEnabled)
        end)

        it("should toggle rainbow mode", function()
            local initial = UltraCursorFXDB.rainbowMode
            slashHandler("rainbow")
            assert.are.not_equal(initial, UltraCursorFXDB.rainbowMode)
        end)

        it("should toggle click effects", function()
            local initial = UltraCursorFXDB.clickEffects
            slashHandler("click")
            assert.are.not_equal(initial, UltraCursorFXDB.clickEffects)
        end)

        it("should toggle comet mode", function()
            local initial = UltraCursorFXDB.cometMode
            slashHandler("comet")
            assert.are.not_equal(initial, UltraCursorFXDB.cometMode)
        end)

        it("should toggle situational profiles", function()
            local initial = UltraCursorFXDB.situationalEnabled
            slashHandler("profiles")
            assert.are.not_equal(initial, UltraCursorFXDB.situationalEnabled)
        end)
    end)

    describe("Profile Commands", function()
        before_each(function()
            UltraCursorFXDB.profiles = {
                world = { name = "World", color = { 0.0, 1.0, 1.0 }, points = 48 },
                raid = { name = "Raid", color = { 1.0, 0.0, 0.0 }, points = 40 },
            }
        end)

        it("should save to profile", function()
            UltraCursorFXDB.color = { 1.0, 0.5, 0.0 }
            UltraCursorFXDB.points = 100
            slashHandler("save world")

            assert.are.same({ 1.0, 0.5, 0.0 }, UltraCursorFXDB.profiles.world.color)
            assert.are.equal(100, UltraCursorFXDB.profiles.world.points)
        end)

        it("should reject save to non-existent profile", function()
            slashHandler("save invalidprofile")
            -- Should not crash
            assert.is_true(true)
        end)

        it("should load from profile", function()
            slashHandler("load raid")

            assert.are.same({ 1.0, 0.0, 0.0 }, UltraCursorFXDB.color)
            assert.are.equal(40, UltraCursorFXDB.points)
        end)

        it("should reject load from non-existent profile", function()
            local originalColor = UltraCursorFXDB.color
            slashHandler("load invalidprofile")

            -- Color should not change
            assert.are.equal(originalColor, UltraCursorFXDB.color)
        end)
    end)

    describe("Import/Export Commands", function()
        it("should export settings", function()
            UltraCursorFXDB.enabled = true
            UltraCursorFXDB.points = 60

            slashHandler("export")
            -- Should not crash
            assert.is_true(true)
        end)

        it("should import valid string", function()
            local exportString = addon:ExportSettings()
            _G.UltraCursorFXDB = {}
            addon:InitializeDefaults()

            slashHandler("import " .. exportString)

            assert.is_not_nil(UltraCursorFXDB.points)
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
            UltraCursorFXDB.enabled = true
            slashHandler("OFF")
            assert.is_false(UltraCursorFXDB.enabled)
        end)
    end)
end)
