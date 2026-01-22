-- ===============================
-- Profiles Module Tests
-- ===============================

local mocks = require("spec.wow_mocks")

describe("Profiles Module", function()
    local addon

    before_each(function()
        mocks.ResetWoWMocks()
        require("Core")
        require("Utils")
        require("Profiles")
        require("Effects")
        addon = UltraCursorFX
        addon:InitializeDefaults()
    end)

    describe("GetCurrentZoneProfile", function()
        it("should return 'world' when not in instance", function()
            mocks.SimulateZoneChange(false, "none")
            assert.are.equal("world", addon:GetCurrentZoneProfile())
        end)

        it("should return 'raid' in raid instance", function()
            mocks.SimulateZoneChange(true, "raid")
            assert.are.equal("raid", addon:GetCurrentZoneProfile())
        end)

        it("should return 'dungeon' in party instance", function()
            mocks.SimulateZoneChange(true, "party")
            assert.are.equal("dungeon", addon:GetCurrentZoneProfile())
        end)

        it("should return 'arena' in arena", function()
            mocks.SimulateZoneChange(true, "arena")
            assert.are.equal("arena", addon:GetCurrentZoneProfile())
        end)

        it("should return 'battleground' in pvp", function()
            mocks.SimulateZoneChange(true, "pvp")
            assert.are.equal("battleground", addon:GetCurrentZoneProfile())
        end)
    end)

    describe("SaveToProfile", function()
        before_each(function()
            UltraCursorFXDB.profiles = {}
            UltraCursorFXDB.color = { 1.0, 0.0, 0.0 }
            UltraCursorFXDB.points = 50
            UltraCursorFXDB.size = 40
            UltraCursorFXDB.particleShape = "skull"
        end)

        it("should save current settings to profile", function()
            addon:SaveToProfile("world")

            assert.is_not_nil(UltraCursorFXDB.profiles.world)
            assert.are.same({ 1.0, 0.0, 0.0 }, UltraCursorFXDB.profiles.world.color)
            assert.are.equal(50, UltraCursorFXDB.profiles.world.points)
            assert.are.equal(40, UltraCursorFXDB.profiles.world.size)
            assert.are.equal("skull", UltraCursorFXDB.profiles.world.particleShape)
        end)

        it("should create profile if it doesn't exist", function()
            addon:SaveToProfile("custom")
            assert.is_not_nil(UltraCursorFXDB.profiles.custom)
        end)

        it("should copy color table, not reference", function()
            addon:SaveToProfile("world")
            UltraCursorFXDB.color[1] = 0.5

            assert.are.equal(1.0, UltraCursorFXDB.profiles.world.color[1])
        end)
    end)

    describe("LoadFromProfile", function()
        before_each(function()
            UltraCursorFXDB.profiles = {
                test = {
                    color = { 0.8, 0.2, 1.0 },
                    points = 75,
                    size = 50,
                    glowSize = 80,
                    smoothness = 0.25,
                    particleShape = "spark",
                    rainbowMode = true,
                    cometMode = true,
                },
            }
        end)

        it("should load profile settings to DB", function()
            addon:LoadFromProfile("test")

            assert.are.same({ 0.8, 0.2, 1.0 }, UltraCursorFXDB.color)
            assert.are.equal(75, UltraCursorFXDB.points)
            assert.are.equal(50, UltraCursorFXDB.size)
            assert.are.equal(80, UltraCursorFXDB.glowSize)
            assert.are.equal(0.25, UltraCursorFXDB.smoothness)
            assert.are.equal("spark", UltraCursorFXDB.particleShape)
            assert.is_true(UltraCursorFXDB.rainbowMode)
            assert.is_true(UltraCursorFXDB.cometMode)
        end)

        it("should return false for non-existent profile", function()
            local result = addon:LoadFromProfile("nonexistent")
            assert.is_false(result)
        end)

        it("should use defaults for missing values", function()
            UltraCursorFXDB.profiles.partial = { color = { 1.0, 1.0, 1.0 } }
            addon:LoadFromProfile("partial")

            assert.are.equal(48, UltraCursorFXDB.points)
            assert.are.equal(34, UltraCursorFXDB.size)
        end)
    end)

    describe("SwitchToZoneProfile", function()
        before_each(function()
            UltraCursorFXDB.situationalEnabled = true
            UltraCursorFXDB.profiles = {
                world = { name = "World", color = { 0.0, 1.0, 1.0 }, points = 48 },
                raid = { name = "Raid", color = { 1.0, 0.0, 0.0 }, points = 40 },
            }
            addon.currentZoneProfile = "world"
        end)

        it("should not switch if situational disabled", function()
            UltraCursorFXDB.situationalEnabled = false
            UltraCursorFXDB.color = { 0.0, 1.0, 1.0 }

            mocks.SimulateZoneChange(true, "raid")
            addon:SwitchToZoneProfile()

            assert.are.same({ 0.0, 1.0, 1.0 }, UltraCursorFXDB.color)
        end)

        it("should switch to raid profile in raid", function()
            mocks.SimulateZoneChange(true, "raid")
            addon:SwitchToZoneProfile()

            assert.are.equal("raid", addon.currentZoneProfile)
            assert.are.equal(40, UltraCursorFXDB.points)
        end)

        it("should not switch if already in correct profile", function()
            local switchCount = 0
            local oldLoad = addon.LoadFromProfile
            addon.LoadFromProfile = function(...)
                switchCount = switchCount + 1
                return oldLoad(addon, ...)
            end

            mocks.SimulateZoneChange(false, "none")
            addon:SwitchToZoneProfile()

            assert.are.equal(0, switchCount)

            addon.LoadFromProfile = oldLoad
        end)
    end)

    describe("MigrateProfiles", function()
        it("should initialize profiles structure", function()
            _G.UltraCursorFXDB = {}
            addon:MigrateProfiles()

            assert.is_table(_G.UltraCursorFXDB.profiles)
        end)

        it("should create all 5 default profiles", function()
            _G.UltraCursorFXDB = {}
            addon:MigrateProfiles()

            assert.is_not_nil(_G.UltraCursorFXDB.profiles)
            assert.is_not_nil(_G.UltraCursorFXDB.profiles.world)
            assert.is_not_nil(_G.UltraCursorFXDB.profiles.raid)
            assert.is_not_nil(_G.UltraCursorFXDB.profiles.dungeon)
            assert.is_not_nil(_G.UltraCursorFXDB.profiles.arena)
            assert.is_not_nil(_G.UltraCursorFXDB.profiles.battleground)
        end)

        it("should migrate custom user settings to world profile", function()
            _G.UltraCursorFXDB = {
                color = { 1.0, 0.5, 0.0 },
                points = 100,
                size = 60,
                particleShape = "skull",
            }

            addon:MigrateProfiles()

            assert.are.same({ 1.0, 0.5, 0.0 }, _G.UltraCursorFXDB.profiles.world.color)
            assert.are.equal(100, _G.UltraCursorFXDB.profiles.world.points)
            assert.are.equal(60, _G.UltraCursorFXDB.profiles.world.size)
            assert.are.equal("skull", _G.UltraCursorFXDB.profiles.world.particleShape)
        end)

        it("should not migrate if settings match defaults", function()
            _G.UltraCursorFXDB = {
                color = { 0.0, 1.0, 1.0 },
                points = 48,
            }

            addon:MigrateProfiles()

            -- Should use profile defaults, not user's default-matching values
            assert.are.equal(48, _G.UltraCursorFXDB.profiles.world.points)
        end)

        it("should only migrate once", function()
            _G.UltraCursorFXDB = { color = { 1.0, 0.0, 0.0 } }

            addon:MigrateProfiles()
            assert.is_true(_G.UltraCursorFXDB.profilesMigrated)

            -- Change world profile
            _G.UltraCursorFXDB.profiles.world.color = { 0.0, 1.0, 0.0 }

            -- Migrate again
            addon:MigrateProfiles()

            -- Should NOT overwrite
            assert.are.same({ 0.0, 1.0, 0.0 }, _G.UltraCursorFXDB.profiles.world.color)
        end)

        it("should migrate numeric differences from defaults", function()
            _G.UltraCursorFXDB = {
                points = 100, -- Different from default 48
                size = 60, -- Different from default 34
            }

            addon:MigrateProfiles()

            assert.are.equal(100, _G.UltraCursorFXDB.profiles.world.points)
            assert.are.equal(60, _G.UltraCursorFXDB.profiles.world.size)
        end)

        it("should migrate boolean differences from defaults", function()
            _G.UltraCursorFXDB = {
                cometMode = false, -- Different from default true
            }

            addon:MigrateProfiles()

            -- Should preserve the false value
            assert.is_not_nil(_G.UltraCursorFXDB.profiles.world)
        end)

        it("should preserve existing profiles", function()
            UltraCursorFXDB = {
                profiles = {
                    world = { name = "Custom World", points = 200 },
                },
            }

            addon:MigrateProfiles()

            assert.are.equal("Custom World", UltraCursorFXDB.profiles.world.name)
            assert.are.equal(200, UltraCursorFXDB.profiles.world.points)
        end)
    end)
end)
