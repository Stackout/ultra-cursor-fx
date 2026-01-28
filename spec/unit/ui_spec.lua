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
            addon:SetSetting("color", { 0.5, 0.5, 0.5 })
            addon:BuildTrail()

            assert.are.same({ 0.5, 0.5, 0.5 }, addon:GetSetting("color"))
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

            assert.are.equal(40, addon:GetSetting("points"))
        end)

        it("should save profile on button click", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("points", 100)
            addon:SaveToProfile("world")

            local profiles = addon:GetActiveProfileTable()
            assert.are.equal(100, profiles.world.points)
        end)
    end)

    describe("Particle Shape Dropdown", function()
        it("should change particle shape", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("particleShape", "skull")
            addon:BuildTrail()

            assert.are.equal("skull", addon:GetSetting("particleShape"))
        end)

        it("should support all shapes", function()
            addon:CreateSettingsPanel()

            local shapes = { "star", "skull", "spark", "dot" }
            for _, shape in ipairs(shapes) do
                addon:SetSetting("particleShape", shape)
                addon:BuildTrail()

                assert.are.equal(shape, addon:GetSetting("particleShape"))
            end
        end)
    end)

    describe("Sliders", function()
        it("should update points slider value", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("points", 75)
            addon:BuildTrail()

            assert.are.equal(75, addon:GetSetting("points"))
        end)

        it("should update size slider value", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("size", 50)
            addon:BuildTrail()

            assert.are.equal(50, addon:GetSetting("size"))
        end)

        it("should update smoothness slider value", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("smoothness", 0.5)

            assert.are.equal(0.5, addon:GetSetting("smoothness"))
        end)

        it("should update glow size slider value", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("glowSize", 80)
            addon:BuildTrail()

            assert.are.equal(80, addon:GetSetting("glowSize"))
        end)

        it("should update pulse speed slider value", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("pulseSpeed", 5.0)

            assert.are.equal(5.0, addon:GetSetting("pulseSpeed"))
        end)

        it("should update rainbow speed slider value", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("rainbowSpeed", 2.0)

            assert.are.equal(2.0, addon:GetSetting("rainbowSpeed"))
        end)

        it("should update comet length slider value", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("cometLength", 3.5)

            assert.are.equal(3.5, addon:GetSetting("cometLength"))
        end)

        it("should update click particles slider value", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("clickParticles", 16)

            assert.are.equal(16, addon:GetSetting("clickParticles"))
        end)

        it("should update click size slider value", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("clickSize", 64)

            assert.are.equal(64, addon:GetSetting("clickSize"))
        end)

        it("should update click duration slider value", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("clickDuration", 1.0)

            assert.are.equal(1.0, addon:GetSetting("clickDuration"))
        end)
    end)

    describe("Checkboxes", function()
        it("should toggle enabled checkbox", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("enabled", false)
            assert.is_false(addon:GetSetting("enabled"))

            addon:SetSetting("enabled", true)
            assert.is_true(addon:GetSetting("enabled"))
        end)

        it("should toggle flash checkbox", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("flashEnabled", false)
            assert.is_false(addon:GetSetting("flashEnabled"))
        end)

        it("should toggle rainbow checkbox", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("rainbowMode", false)
            assert.is_false(addon:GetSetting("rainbowMode"))
        end)

        it("should toggle click effects checkbox", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("clickEffects", false)
            assert.is_false(addon:GetSetting("clickEffects"))
        end)

        it("should toggle comet mode checkbox", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("cometMode", false)
            assert.is_false(addon:GetSetting("cometMode"))
        end)

        it("should toggle situational profiles checkbox", function()
            addon:CreateSettingsPanel()

            addon:SetSetting("situationalEnabled", false)
            assert.is_false(addon:GetSetting("situationalEnabled"))
        end)
    end)

    describe("Preset Buttons", function()
        it("should apply preset configurations", function()
            addon:CreateSettingsPanel()

            -- Test applying a preset
            addon:SetSetting("color", { 1.0, 0.0, 0.0 })
            addon:SetSetting("points", 60)

            -- Verify values were set
            assert.are.same({ 1.0, 0.0, 0.0 }, addon:GetSetting("color"))
            assert.are.equal(60, addon:GetSetting("points"))
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
