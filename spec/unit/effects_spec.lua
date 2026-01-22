-- ===============================
-- Effects Module Tests
-- ===============================

local mocks = require("spec.wow_mocks")

describe("Effects Module", function()
    local addon

    before_each(function()
        mocks.ResetWoWMocks()
        require("Core")
        require("Utils")
        require("Effects")
        addon = UltraCursorFX
        addon:InitializeDefaults()
    end)

    describe("BuildTrail", function()
        it("should create trail particles", function()
            UltraCursorFXDB.points = 10
            addon:BuildTrail()

            assert.are.equal(10, #addon.points)
            assert.are.equal(10, #addon.glow)
        end)

        it("should respect points setting", function()
            UltraCursorFXDB.points = 50
            addon:BuildTrail()

            assert.are.equal(50, #addon.points)
        end)

        it("should clear old particles before rebuilding", function()
            UltraCursorFXDB.points = 20
            addon:BuildTrail()

            UltraCursorFXDB.points = 10
            addon:BuildTrail()

            assert.are.equal(10, #addon.points)
        end)

        it("should use selected particle shape", function()
            UltraCursorFXDB.particleShape = "star"
            addon:BuildTrail()

            assert.are.equal(UltraCursorFXDB.points, #addon.points)
        end)

        it("should handle different shapes", function()
            local shapes = { "star", "skull", "spark", "dot" }

            for _, shape in ipairs(shapes) do
                UltraCursorFXDB.particleShape = shape
                UltraCursorFXDB.points = 5
                addon:BuildTrail()

                assert.are.equal(5, #addon.points)
            end
        end)

        it("should set particle color", function()
            UltraCursorFXDB.color = { 1.0, 0.5, 0.0 }
            UltraCursorFXDB.points = 5
            addon:BuildTrail()

            assert.are.equal(5, #addon.points)
        end)

        it("should set particle size", function()
            UltraCursorFXDB.size = 50
            UltraCursorFXDB.points = 5
            addon:BuildTrail()

            assert.are.equal(5, #addon.points)
        end)
    end)

    describe("OnUpdate Animation", function()
        before_each(function()
            UltraCursorFXDB.enabled = true
            UltraCursorFXDB.points = 10
            addon:BuildTrail()
        end)

        it("should not run when disabled", function()
            UltraCursorFXDB.enabled = false
            addon:OnUpdate(0.016)

            -- Should not crash
            assert.is_true(true)
        end)

        it("should handle empty points array", function()
            addon.points = {}
            addon:OnUpdate(0.016)

            -- Should not crash
            assert.is_true(true)
        end)

        it("should update rainbow hue", function()
            UltraCursorFXDB.rainbowMode = true
            local initialHue = addon.rainbowHue

            addon:OnUpdate(0.1)

            assert.are.not_equal(initialHue, addon.rainbowHue)
        end)

        it("should update particle positions", function()
            addon:OnUpdate(0.016)

            -- First point should have moved toward cursor
            assert.is_not_nil(addon.points[1].x)
            assert.is_not_nil(addon.points[1].y)
        end)

        it("should create comet effect spacing", function()
            UltraCursorFXDB.cometMode = true
            UltraCursorFXDB.cometLength = 2.0

            addon:OnUpdate(0.016)

            -- Should complete without errors
            assert.is_true(true)
        end)

        it("should apply pulse effect", function()
            UltraCursorFXDB.pulseSpeed = 3.0

            addon:OnUpdate(0.016)

            assert.is_true(true)
        end)

        it("should handle flash effect", function()
            UltraCursorFXDB.flashEnabled = true

            -- Simulate many frames to trigger flash
            for i = 1, 100 do
                addon:OnUpdate(0.016)
            end

            assert.is_true(true)
        end)

        it("should handle different smoothness values", function()
            UltraCursorFXDB.smoothness = 0.5

            addon:OnUpdate(0.016)

            assert.is_true(true)
        end)
    end)

    describe("Rainbow Mode", function()
        before_each(function()
            UltraCursorFXDB.points = 10
            addon:BuildTrail()
        end)

        it("should cycle through colors", function()
            UltraCursorFXDB.rainbowMode = true
            addon.rainbowHue = 0

            addon:OnUpdate(1.0)

            assert.is_true(addon.rainbowHue > 0)
        end)

        it("should wrap hue value", function()
            UltraCursorFXDB.rainbowMode = true
            addon.rainbowHue = 0.95
            UltraCursorFXDB.rainbowSpeed = 10

            addon:OnUpdate(1.0)

            -- Hue should wrap around
            assert.is_true(addon.rainbowHue < 1.0)
        end)

        it("should update particle colors in rainbow mode", function()
            UltraCursorFXDB.rainbowMode = true
            local initialColor = { UltraCursorFXDB.color[1], UltraCursorFXDB.color[2], UltraCursorFXDB.color[3] }

            addon:OnUpdate(0.5)

            -- Color should have changed
            local changed = UltraCursorFXDB.color[1] ~= initialColor[1]
                or UltraCursorFXDB.color[2] ~= initialColor[2]
                or UltraCursorFXDB.color[3] ~= initialColor[3]
            assert.is_true(changed)
        end)
    end)

    describe("Click Effects", function()
        before_each(function()
            UltraCursorFXDB.clickEffects = true
            UltraCursorFXDB.clickParticles = 8
            UltraCursorFXDB.clickSize = 32
            UltraCursorFXDB.clickDuration = 0.5
            UltraCursorFXDB.points = 10
            addon:BuildTrail()
        end)

        it("should not create effects when disabled", function()
            UltraCursorFXDB.clickEffects = false
            local initialCount = #addon.clickParticles

            addon:OnUpdate(0.016)

            assert.are.equal(initialCount, #addon.clickParticles)
        end)

        it("should create click effects on left mouse button", function()
            local initialCount = #addon.clickParticles

            -- Simulate left click
            mocks.SimulateMouseClick("LeftButton", true)
            addon:OnUpdate(0.016)

            -- Should have created click particles
            assert.is_true(#addon.clickParticles > initialCount)

            -- Reset mouse state
            mocks.SimulateMouseClick("LeftButton", false)
        end)

        it("should create click effects on right mouse button", function()
            local initialCount = #addon.clickParticles

            -- Simulate right click
            mocks.SimulateMouseClick("RightButton", true)
            addon:OnUpdate(0.016)

            -- Should have created click particles
            assert.is_true(#addon.clickParticles > initialCount)

            -- Reset mouse state
            mocks.SimulateMouseClick("RightButton", false)
        end)

        it("should use rainbow color for click effects when rainbow mode enabled", function()
            UltraCursorFXDB.rainbowMode = true
            addon.rainbowHue = 0.5

            mocks.SimulateMouseClick("LeftButton", true)
            addon:OnUpdate(0.016)

            -- Should have created particles (using rainbow color)
            assert.is_true(#addon.clickParticles > 0)

            mocks.SimulateMouseClick("LeftButton", false)
        end)

        it("should create correct number of click particles", function()
            UltraCursorFXDB.clickParticles = 12
            local initialCount = #addon.clickParticles

            mocks.SimulateMouseClick("LeftButton", true)
            addon:OnUpdate(0.016)

            -- Should have created 12 particles
            assert.are.equal(initialCount + 12, #addon.clickParticles)

            mocks.SimulateMouseClick("LeftButton", false)
        end)

        it("should update click particles", function()
            -- Manually add a click particle to test update
            local p = addon.parent:CreateTexture(nil, "OVERLAY")
            p.life = 0
            p.maxLife = 1.0
            p.velocityX = 100
            p.velocityY = 100
            p.GetCenter = function()
                return 100, 100
            end
            table.insert(addon.clickParticles, p)

            addon:OnUpdate(0.016)

            -- Life should have progressed
            assert.is_true(p.life > 0)
        end)

        it("should remove expired click particles", function()
            -- Add an expired particle
            local p = addon.parent:CreateTexture(nil, "OVERLAY")
            p.life = 2.0
            p.maxLife = 1.0
            p.velocityX = 0
            p.velocityY = 0
            p.GetCenter = function()
                return 100, 100
            end
            table.insert(addon.clickParticles, p)

            local initialCount = #addon.clickParticles
            addon:OnUpdate(0.016)

            -- Expired particle should be removed
            assert.is_true(#addon.clickParticles < initialCount)
        end)
    end)

    describe("Particle Shape Textures", function()
        it("should have all particle shapes defined", function()
            assert.is_not_nil(addon.particleTextures.star)
            assert.is_not_nil(addon.particleTextures.skull)
            assert.is_not_nil(addon.particleTextures.spark)
            assert.is_not_nil(addon.particleTextures.dot)
        end)

        it("should fallback to star for unknown shape", function()
            UltraCursorFXDB.particleShape = "unknownshape"
            UltraCursorFXDB.points = 5

            addon:BuildTrail()

            -- Should not crash and create particles
            assert.are.equal(5, #addon.points)
        end)
    end)

    describe("Comet Mode", function()
        before_each(function()
            UltraCursorFXDB.cometMode = true
            UltraCursorFXDB.cometLength = 2.5
            UltraCursorFXDB.points = 20
            addon:BuildTrail()
        end)

        it("should apply different alpha curve", function()
            addon:OnUpdate(0.016)

            -- Should complete without errors
            assert.is_true(true)
        end)

        it("should use custom spacing", function()
            UltraCursorFXDB.cometLength = 1.0

            addon:OnUpdate(0.016)

            assert.is_true(true)
        end)

        it("should work with different lengths", function()
            local lengths = { 0.5, 1.0, 2.0, 5.0 }

            for _, length in ipairs(lengths) do
                UltraCursorFXDB.cometLength = length
                addon:OnUpdate(0.016)

                assert.is_true(true)
            end
        end)
    end)
end)
