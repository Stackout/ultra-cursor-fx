-- ===============================
-- Init Module Tests
-- ===============================

local mocks = require("spec.wow_mocks")

describe("Init Module", function()
    local addon

    before_each(function()
        mocks.ResetWoWMocks()
        require("Core")
        require("Utils")
        require("Profiles")
        require("Effects")
        addon = UltraCursorFX
    end)

    describe("Event Registration", function()
        it("should register ADDON_LOADED event", function()
            require("Init")

            assert.is_true(addon.frame._events["ADDON_LOADED"])
        end)

        it("should register PLAYER_ENTERING_WORLD event", function()
            require("Init")

            assert.is_true(addon.frame._events["PLAYER_ENTERING_WORLD"])
        end)

        it("should register PLAYER_REGEN_DISABLED event", function()
            require("Init")

            assert.is_true(addon.frame._events["PLAYER_REGEN_DISABLED"])
        end)

        it("should register PLAYER_REGEN_ENABLED event", function()
            require("Init")

            assert.is_true(addon.frame._events["PLAYER_REGEN_ENABLED"])
        end)
    end)

    describe("ADDON_LOADED Event", function()
        it("should initialize on addon load", function()
            require("Init")
            mocks.SimulateAddonLoad("UltraCursorFX")

            assert.is_not_nil(UltraCursorFXDB.enabled)
            assert.is_not_nil(UltraCursorFXDB.account)
            assert.is_not_nil(UltraCursorFXDB.account.profiles)
        end)

        it("should build trail on load", function()
            require("Init")
            mocks.SimulateAddonLoad("UltraCursorFX")

            assert.is_true(#addon.points > 0)
        end)

        it("should not initialize for other addons", function()
            local initialDB = _G.UltraCursorFXDB
            require("Init")

            local handler = addon.frame._scripts["OnEvent"]
            handler(addon.frame, "ADDON_LOADED", "SomeOtherAddon")

            -- Should not have initialized
            assert.are.equal(initialDB, _G.UltraCursorFXDB)
        end)

        it("should start OnUpdate when enabled", function()
            UltraCursorFXDB = { enabled = true }
            require("Init")
            mocks.SimulateAddonLoad("UltraCursorFX")

            -- OnUpdate script should be set
            assert.is_function(addon.frame._scripts["OnUpdate"])
        end)

        it("should respect enabled state", function()
            _G.UltraCursorFXDB = { enabled = false }
            require("Init")

            mocks.SimulateAddonLoad("UltraCursorFX")

            -- Should still initialize properly
            assert.is_false(_G.UltraCursorFXDB.enabled)
            assert.is_not_nil(_G.UltraCursorFXDB.account)
            assert.is_not_nil(_G.UltraCursorFXDB.account.profiles)
        end)
    end)

    describe("PLAYER_ENTERING_WORLD Event", function()
        before_each(function()
            require("Init")
            mocks.SimulateAddonLoad("UltraCursorFX")
        end)

        it("should trigger profile switch on zone change", function()
            UltraCursorFXDB.situationalEnabled = true
            UltraCursorFXDB.profiles = {
                world = { name = "World", color = { 0.0, 1.0, 1.0 }, points = 48 },
                raid = { name = "Raid", color = { 1.0, 0.0, 0.0 }, points = 40 },
            }

            mocks.SimulateZoneChange(true, "raid")

            assert.are.equal("raid", addon.currentZoneProfile)
        end)

        it("should handle entering world in non-instance", function()
            mocks.SimulateZoneChange(false, "none")

            assert.are.equal("world", addon.currentZoneProfile)
        end)
    end)

    describe("Combat Events", function()
        before_each(function()
            require("Init")
            mocks.SimulateAddonLoad("UltraCursorFX")
        end)

        it("should set inCombat on PLAYER_REGEN_DISABLED", function()
            addon.inCombat = false
            local handler = addon.frame._scripts["OnEvent"]

            handler(addon.frame, "PLAYER_REGEN_DISABLED")

            assert.is_true(addon.inCombat)
        end)

        it("should clear inCombat on PLAYER_REGEN_ENABLED", function()
            addon.inCombat = true
            local handler = addon.frame._scripts["OnEvent"]

            handler(addon.frame, "PLAYER_REGEN_ENABLED")

            assert.is_false(addon.inCombat)
        end)

        it("should update cursor state on combat enter", function()
            UltraCursorFXDB.combatOnly = true
            UltraCursorFXDB.enabled = true
            addon.inCombat = false

            local handler = addon.frame._scripts["OnEvent"]
            handler(addon.frame, "PLAYER_REGEN_DISABLED")

            -- Cursor should be shown when entering combat with combatOnly mode
            assert.is_function(addon.frame._scripts["OnUpdate"])
        end)

        it("should update cursor state on combat leave", function()
            UltraCursorFXDB.combatOnly = true
            UltraCursorFXDB.enabled = true
            addon.inCombat = true

            local handler = addon.frame._scripts["OnEvent"]
            handler(addon.frame, "PLAYER_REGEN_ENABLED")

            -- Cursor should be hidden when leaving combat with combatOnly mode
            assert.is_nil(addon.frame._scripts["OnUpdate"])
        end)
    end)

    describe("Settings Panel Creation", function()
        it("should create settings panel if function exists", function()
            -- UI.lua defines CreateSettingsPanel
            require("UI")
            require("Init")

            mocks.SimulateAddonLoad("UltraCursorFX")

            assert.is_not_nil(addon.settingsPanel)
        end)

        it("should handle missing CreateSettingsPanel", function()
            addon.CreateSettingsPanel = nil
            require("Init")

            mocks.SimulateAddonLoad("UltraCursorFX")

            -- Should not crash
            assert.is_true(true)
        end)
    end)
end)
