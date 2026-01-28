-- ===============================
-- Core Module Tests
-- ===============================

local mocks = require("spec.wow_mocks")

describe("Core Module", function()
    before_each(function()
        mocks.ResetWoWMocks()
        require("Core")
    end)

    describe("Namespace", function()
        it("should create UltraCursorFX global namespace", function()
            assert.is_not_nil(UltraCursorFX)
            assert.is_table(UltraCursorFX)
        end)

        it("should initialize UltraCursorFXDB", function()
            assert.is_not_nil(UltraCursorFXDB)
            assert.is_table(UltraCursorFXDB)
        end)
    end)

    describe("Defaults", function()
        it("should have all required default settings", function()
            local addon = UltraCursorFX
            assert.is_true(addon.defaults.enabled)
            assert.is_true(addon.defaults.flashEnabled)
            assert.are.same({ 0.0, 1.0, 1.0 }, addon.defaults.color)
            assert.are.equal(48, addon.defaults.points)
            assert.are.equal(34, addon.defaults.size)
            assert.are.equal(64, addon.defaults.glowSize)
            assert.are.equal("star", addon.defaults.particleShape)
        end)

        it("should have profile settings in defaults", function()
            local addon = UltraCursorFX
            assert.is_false(addon.defaults.situationalEnabled)
            assert.are.equal("world", addon.defaults.currentProfile)
        end)
    end)

    describe("Profile Defaults", function()
        it("should have all 5 profile defaults defined", function()
            local addon = UltraCursorFX
            assert.is_not_nil(addon.profileDefaults.world)
            assert.is_not_nil(addon.profileDefaults.raid)
            assert.is_not_nil(addon.profileDefaults.dungeon)
            assert.is_not_nil(addon.profileDefaults.arena)
            assert.is_not_nil(addon.profileDefaults.battleground)
        end)

        it("should have unique colors for each profile", function()
            local addon = UltraCursorFX
            local colors = {}
            for _, profile in pairs({ "world", "raid", "dungeon", "arena", "battleground" }) do
                local color = table.concat(addon.profileDefaults[profile].color, ",")
                assert.is_nil(colors[color], "Profile " .. profile .. " has duplicate color")
                colors[color] = profile
            end
        end)

        it("should have valid profile names", function()
            local addon = UltraCursorFX
            assert.are.equal("World", addon.profileDefaults.world.name)
            assert.are.equal("Raid", addon.profileDefaults.raid.name)
            assert.are.equal("Dungeon", addon.profileDefaults.dungeon.name)
            assert.are.equal("Arena", addon.profileDefaults.arena.name)
            assert.are.equal("Battleground", addon.profileDefaults.battleground.name)
        end)
    end)

    describe("Core Variables", function()
        it("should initialize core variables", function()
            local addon = UltraCursorFX
            assert.is_not_nil(addon.parent)
            assert.is_table(addon.points)
            assert.is_table(addon.glow)
            assert.is_table(addon.clickParticles)
            assert.is_not_nil(addon.frame)
            assert.are.equal(0, addon.rainbowHue)
            assert.are.equal("world", addon.currentZoneProfile)
        end)

        it("should have particle texture definitions", function()
            local addon = UltraCursorFX
            assert.is_not_nil(addon.particleTextures.star)
            assert.is_not_nil(addon.particleTextures.skull)
            assert.is_not_nil(addon.particleTextures.spark)
            assert.is_not_nil(addon.particleTextures.dot)
        end)
    end)

    describe("InitializeDefaults", function()
        it("should apply defaults to empty DB", function()
            _G.UltraCursorFXDB = {}
            UltraCursorFX:InitializeDefaults()

            assert.is_true(_G.UltraCursorFXDB.enabled)
            assert.are.equal(48, _G.UltraCursorFXDB.points)
            assert.are.equal("star", _G.UltraCursorFXDB.particleShape)
        end)

        it("should not overwrite existing DB values", function()
            _G.UltraCursorFXDB = { enabled = false, points = 100 }
            UltraCursorFX:InitializeDefaults()

            assert.is_false(_G.UltraCursorFXDB.enabled)
            assert.are.equal(100, _G.UltraCursorFXDB.points)
        end)

        it("should fill in missing DB values", function()
            _G.UltraCursorFXDB = { enabled = false }
            UltraCursorFX:InitializeDefaults()

            assert.is_false(_G.UltraCursorFXDB.enabled)
            assert.are.equal(48, _G.UltraCursorFXDB.points)
        end)
    end)

    describe("SyncSettingsToFlat", function()
        it("should handle missing defaults gracefully", function()
            local addon = UltraCursorFX
            local originalDefaults = addon.defaults
            addon.defaults = nil

            -- Should not crash
            addon:SyncSettingsToFlat()

            -- Restore defaults
            addon.defaults = originalDefaults
        end)
    end)
end)
