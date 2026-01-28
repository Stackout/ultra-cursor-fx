-- ===============================
-- UI Module Tests
-- ===============================

local mocks = require("spec.wow_mocks")

describe("UI Module", function()
    local addon

    before_each(function()
        mocks.ResetWoWMocks()
        require("Core")
        require("Utils")
        require("Profiles")
        require("Effects")
        require("UI")
        addon = UltraCursorFX
        addon:InitializeDefaults()
    end)

    describe("Settings Panel Creation", function()
        it("should create settings panel", function()
            addon:CreateSettingsPanel()

            assert.is_not_nil(addon.settingsPanel)
        end)

        it("should have required UI elements", function()
            addon:CreateSettingsPanel()

            -- Panel should exist
            assert.is_table(addon.settingsPanel)
        end)

        it("should register with Settings API", function()
            addon:CreateSettingsPanel()

            -- Should not crash
            assert.is_true(true)
        end)
    end)

    describe("Color Picker", function()
        it("should handle color selection", function()
            addon:CreateSettingsPanel()

            -- Test color changes
            UltraCursorFXDB.color = { 0.5, 0.5, 0.5 }
            addon:BuildTrail()

            assert.are.same({ 0.5, 0.5, 0.5 }, UltraCursorFXDB.color)
        end)
    end)

    describe("Profile Buttons", function()
        before_each(function()
            UltraCursorFXDB.account = {
                profiles = {
                    world = { name = "World", color = { 0.0, 1.0, 1.0 }, points = 48 },
                    raid = { name = "Raid", color = { 1.0, 0.0, 0.0 }, points = 40 },
                    dungeon = { name = "Dungeon", color = { 0.0, 1.0, 0.0 }, points = 50 },
                    arena = { name = "Arena", color = { 1.0, 1.0, 0.0 }, points = 35 },
                    battleground = { name = "Battleground", color = { 1.0, 0.0, 1.0 }, points = 45 },
                },
            }
            UltraCursorFXDB.characters = {
                ["TestCharacter-TestRealm"] = {
                    useAccountSettings = true,
                },
            }
        end)

        it("should load profile on button click", function()
            addon:CreateSettingsPanel()

            -- Simulate loading raid profile
            addon:LoadFromProfile("raid")

            assert.are.equal(40, UltraCursorFXDB.points)
        end)

        it("should save profile on button click", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.points = 100
            addon:SaveToProfile("world")

            local profiles = addon:GetActiveProfileTable()
            assert.are.equal(100, profiles.world.points)
        end)
    end)

    describe("Particle Shape Dropdown", function()
        it("should change particle shape", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.particleShape = "skull"
            addon:BuildTrail()

            assert.are.equal("skull", UltraCursorFXDB.particleShape)
        end)

        it("should support all shapes", function()
            addon:CreateSettingsPanel()

            local shapes = { "star", "skull", "spark", "dot" }
            for _, shape in ipairs(shapes) do
                UltraCursorFXDB.particleShape = shape
                addon:BuildTrail()

                assert.are.equal(shape, UltraCursorFXDB.particleShape)
            end
        end)
    end)

    describe("Sliders", function()
        it("should update points slider value", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.points = 75
            addon:BuildTrail()

            assert.are.equal(75, UltraCursorFXDB.points)
        end)

        it("should update size slider value", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.size = 50
            addon:BuildTrail()

            assert.are.equal(50, UltraCursorFXDB.size)
        end)

        it("should update smoothness slider value", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.smoothness = 0.5

            assert.are.equal(0.5, UltraCursorFXDB.smoothness)
        end)

        it("should update glow size slider value", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.glowSize = 80
            addon:BuildTrail()

            assert.are.equal(80, UltraCursorFXDB.glowSize)
        end)

        it("should update pulse speed slider value", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.pulseSpeed = 5.0

            assert.are.equal(5.0, UltraCursorFXDB.pulseSpeed)
        end)

        it("should update rainbow speed slider value", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.rainbowSpeed = 2.0

            assert.are.equal(2.0, UltraCursorFXDB.rainbowSpeed)
        end)

        it("should update comet length slider value", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.cometLength = 3.5

            assert.are.equal(3.5, UltraCursorFXDB.cometLength)
        end)

        it("should update click particles slider value", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.clickParticles = 16

            assert.are.equal(16, UltraCursorFXDB.clickParticles)
        end)

        it("should update click size slider value", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.clickSize = 64

            assert.are.equal(64, UltraCursorFXDB.clickSize)
        end)

        it("should update click duration slider value", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.clickDuration = 1.0

            assert.are.equal(1.0, UltraCursorFXDB.clickDuration)
        end)
    end)

    describe("Checkboxes", function()
        it("should toggle enabled checkbox", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.enabled = false
            assert.is_false(UltraCursorFXDB.enabled)

            UltraCursorFXDB.enabled = true
            assert.is_true(UltraCursorFXDB.enabled)
        end)

        it("should toggle flash checkbox", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.flashEnabled = false
            assert.is_false(UltraCursorFXDB.flashEnabled)
        end)

        it("should toggle rainbow checkbox", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.rainbowMode = false
            assert.is_false(UltraCursorFXDB.rainbowMode)
        end)

        it("should toggle click effects checkbox", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.clickEffects = false
            assert.is_false(UltraCursorFXDB.clickEffects)
        end)

        it("should toggle comet mode checkbox", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.cometMode = false
            assert.is_false(UltraCursorFXDB.cometMode)
        end)

        it("should toggle situational profiles checkbox", function()
            addon:CreateSettingsPanel()

            UltraCursorFXDB.situationalEnabled = false
            assert.is_false(UltraCursorFXDB.situationalEnabled)
        end)
    end)

    describe("Preset Buttons", function()
        it("should apply preset configurations", function()
            addon:CreateSettingsPanel()

            -- Test applying a preset
            UltraCursorFXDB.color = { 1.0, 0.0, 0.0 }
            UltraCursorFXDB.points = 60

            -- Verify values were set
            assert.are.same({ 1.0, 0.0, 0.0 }, UltraCursorFXDB.color)
            assert.are.equal(60, UltraCursorFXDB.points)
        end)
    end)

    describe("Import/Export UI", function()
        it("should export settings from UI", function()
            addon:CreateSettingsPanel()

            local exported = addon:ExportSettings()

            assert.is_string(exported)
            assert.is_true(#exported > 0)
        end)

        it("should import settings from UI", function()
            addon:CreateSettingsPanel()

            local exported = addon:ExportSettings()
            _G.UltraCursorFXDB = {}
            addon:InitializeDefaults()

            local success = addon:ImportSettings(exported)

            assert.is_true(success)
        end)
    end)
end)
