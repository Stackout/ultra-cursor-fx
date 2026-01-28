-- ===============================
-- Integration Tests
-- ===============================
-- Full addon lifecycle testing

local mocks = require("spec.wow_mocks")

describe("Full Addon Integration", function()
    before_each(function()
        mocks.ResetWoWMocks()
    end)

    describe("Addon Loading", function()
        it("should load all modules without errors", function()
            assert.has_no.errors(function()
                require("Core")
                require("Utils")
                require("Profiles")
                require("Effects")
                require("UI")
                require("Commands")
                require("Init")
            end)
        end)

        it("should initialize addon on ADDON_LOADED event", function()
            require("Core")
            require("Utils")
            require("Profiles")
            require("Effects")
            require("UI")
            require("Commands")
            require("Init")

            mocks.SimulateAddonLoad("UltraCursorFX")

            assert.is_not_nil(UltraCursorFXDB)
            assert.is_true(UltraCursorFXDB.enabled)
            assert.is_not_nil(UltraCursorFXDB.account)
            assert.is_not_nil(UltraCursorFXDB.account.profiles)
        end)
    end)

    describe("Profile Workflow", function()
        before_each(function()
            require("Core")
            require("Utils")
            require("Profiles")
            require("Effects")
            require("Init")
            mocks.SimulateAddonLoad("UltraCursorFX")
        end)

        it("should complete save-load-switch workflow", function()
            local addon = UltraCursorFX

            -- 1. Modify settings
            UltraCursorFXDB.color = { 1.0, 0.0, 1.0 }
            UltraCursorFXDB.points = 99

            -- 2. Save to raid profile
            addon:SaveToProfile("raid")

            -- 3. Load different profile
            addon:LoadFromProfile("world")

            -- 4. Verify world settings
            assert.are.same({ 0.0, 1.0, 1.0 }, UltraCursorFXDB.color)

            -- 5. Load back raid profile
            addon:LoadFromProfile("raid")

            -- 6. Verify raid settings were saved
            assert.are.same({ 1.0, 0.0, 1.0 }, UltraCursorFXDB.color)
            assert.are.equal(99, UltraCursorFXDB.points)
        end)

        it("should auto-switch profiles on zone change", function()
            local addon = UltraCursorFX
            UltraCursorFXDB.situationalEnabled = true

            -- Start in world
            mocks.SimulateZoneChange(false, "none")
            addon:SwitchToZoneProfile()
            local worldColor = { unpack(UltraCursorFXDB.color) }

            -- Enter raid
            mocks.SimulateZoneChange(true, "raid")
            mocks.SimulateZoneChange(true, "raid")
            addon:SwitchToZoneProfile()

            -- Color should have changed
            assert.is_not.same(worldColor, UltraCursorFXDB.color)
        end)
    end)

    describe("Import/Export Workflow", function()
        before_each(function()
            require("Core")
            require("Utils")
            require("Profiles")
            require("Effects")
            require("Init")
            mocks.SimulateAddonLoad("UltraCursorFX")
        end)

        it("should export and import complete settings", function()
            local addon = UltraCursorFX

            -- Set custom values using SetSetting to work with profile system
            addon:SetSetting("enabled", false)
            addon:SetSetting("rainbowMode", true)
            addon:SetSetting("points", 77)
            addon:SetSetting("size", 55)
            addon:SetSetting("color", { 0.5, 0.5, 0.5 })
            addon:SetSetting("particleShape", "skull")
            addon:SetSetting("cometMode", true)
            addon:SetSetting("cometLength", 3.5)

            -- Export
            local exported = addon:ExportSettings()

            -- Reset to defaults
            _G.UltraCursorFXDB = {}
            addon:InitializeDefaults()

            -- Import
            local success = addon:ImportSettings(exported)
            assert.is_true(success)

            -- Verify all values using GetSetting to work with profile system
            assert.is_false(addon:GetSetting("enabled"))
            assert.is_true(addon:GetSetting("rainbowMode"))
            assert.are.equal(77, addon:GetSetting("points"))
            assert.are.equal(55, addon:GetSetting("size"))
            assert.are.same({ 0.5, 0.5, 0.5 }, addon:GetSetting("color"))
            assert.are.equal("skull", addon:GetSetting("particleShape"))
            assert.is_true(addon:GetSetting("cometMode"))
            assert.are.equal(3.5, addon:GetSetting("cometLength"))
        end)
    end)

    describe("Migration Scenarios", function()
        it("should migrate from pre-profiles version", function()
            -- Simulate old addon version with custom settings
            _G.UltraCursorFXDB = {
                enabled = true,
                color = { 1.0, 0.5, 0.0 },
                points = 120,
                size = 75,
                particleShape = "skull",
                cometMode = true,
            }

            require("Core")
            require("Profiles")
            local addon = UltraCursorFX

            addon:MigrateProfiles()

            -- Should preserve custom settings in account
            assert.are.same({ 1.0, 0.5, 0.0 }, UltraCursorFXDB.account.color)
            assert.are.equal(120, UltraCursorFXDB.account.points)
            assert.are.equal(75, UltraCursorFXDB.account.size)
            assert.are.equal("skull", UltraCursorFXDB.account.particleShape)
            assert.is_true(UltraCursorFXDB.account.cometMode)

            -- Should create profiles with defaults
            assert.are.equal(40, UltraCursorFXDB.account.profiles.raid.points)
            assert.are.equal(50, UltraCursorFXDB.account.profiles.dungeon.points)
        end)

        it("should handle fresh install", function()
            _G.UltraCursorFXDB = {}

            require("Core")
            require("Profiles")
            local addon = UltraCursorFX

            addon:InitializeDefaults()
            addon:MigrateProfiles()

            -- All profiles should exist with defaults
            assert.is_not_nil(_G.UltraCursorFXDB.account.profiles.world)
            assert.is_not_nil(UltraCursorFXDB.account.profiles.raid)
            assert.are.equal(48, UltraCursorFXDB.account.profiles.world.points)
            assert.are.equal(40, UltraCursorFXDB.account.profiles.raid.points)
        end)
    end)

    describe("Error Handling", function()
        before_each(function()
            require("Core")
            require("Utils")
        end)

        it("should handle corrupted import strings gracefully", function()
            local addon = UltraCursorFX
            local success, message = addon:ImportSettings("UCFX:@#$%^&*()")

            assert.is_false(success)
            assert.is_string(message)
        end)

        it("should handle missing profile gracefully", function()
            require("Profiles")
            local addon = UltraCursorFX
            UltraCursorFXDB.profiles = {}

            local result = addon:LoadFromProfile("nonexistent")
            assert.is_false(result)
        end)
    end)
end)
