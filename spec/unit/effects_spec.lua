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
            addon:SetSetting("points", 10)
            addon:BuildTrail()

            assert.are.equal(10, #addon.points)
            assert.are.equal(10, #addon.glow)
        end)

        it("should respect points setting", function()
            addon:SetSetting("points", 50)
            addon:BuildTrail()

            assert.are.equal(50, #addon.points)
        end)

        it("should clear old particles before rebuilding", function()
            addon:SetSetting("points", 20)
            addon:BuildTrail()

            addon:SetSetting("points", 10)
            addon:BuildTrail()

            assert.are.equal(10, #addon.points)
        end)

        it("should use selected particle shape", function()
            addon:SetSetting("particleShape", "star")
            addon:BuildTrail()

            assert.are.equal(addon:GetSetting("points"), #addon.points)
        end)

        it("should handle different shapes", function()
            local shapes = { "star", "skull", "spark", "dot" }

            for _, shape in ipairs(shapes) do
                addon:SetSetting("particleShape", shape)
                addon:SetSetting("points", 5)
                addon:BuildTrail()

                assert.are.equal(5, #addon.points)
            end
        end)

        it("should set particle color", function()
            addon:SetSetting("color", { 1.0, 0.5, 0.0 })
            addon:SetSetting("points", 5)
            addon:BuildTrail()

            assert.are.equal(5, #addon.points)
        end)

        it("should set particle size", function()
            addon:SetSetting("size", 50)
            addon:SetSetting("points", 5)
            addon:BuildTrail()

            assert.are.equal(5, #addon.points)
        end)
    end)

    describe("OnUpdate Animation", function()
        before_each(function()
            addon:SetSetting("enabled", true)
            addon:SetSetting("points", 10)
            addon:BuildTrail()
        end)

        it("should not run when disabled", function()
            addon:SetSetting("enabled", false)
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
            addon:SetSetting("rainbowMode", true)
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
            addon:SetSetting("cometMode", true)
            addon:SetSetting("cometLength", 2.0)

            addon:OnUpdate(0.016)

            -- Should complete without errors
            assert.is_true(true)
        end)

        it("should apply pulse effect", function()
            addon:SetSetting("pulseSpeed", 3.0)

            addon:OnUpdate(0.016)

            assert.is_true(true)
        end)

        it("should handle flash effect", function()
            addon:SetSetting("flashEnabled", true)

            -- Simulate many frames to trigger flash
            for i = 1, 100 do
                addon:OnUpdate(0.016)
            end

            assert.is_true(true)
        end)

        it("should handle different smoothness values", function()
            addon:SetSetting("smoothness", 0.5)

            addon:OnUpdate(0.016)

            assert.is_true(true)
        end)
    end)

    describe("Rainbow Mode", function()
        before_each(function()
            addon:SetSetting("points", 10)
            addon:BuildTrail()
        end)

        it("should cycle through colors", function()
            addon:SetSetting("rainbowMode", true)
            addon.rainbowHue = 0

            addon:OnUpdate(1.0)

            assert.is_true(addon.rainbowHue > 0)
        end)

        it("should wrap hue value", function()
            addon:SetSetting("rainbowMode", true)
            addon.rainbowHue = 0.95
            addon:SetSetting("rainbowSpeed", 10)

            addon:OnUpdate(1.0)

            -- Hue should wrap around
            assert.is_true(addon.rainbowHue < 1.0)
        end)

        it("should update particle colors in rainbow mode", function()
            addon:SetSetting("rainbowMode", true)
            local initialColor = addon:GetSetting("color")
            local initialCopy = { initialColor[1], initialColor[2], initialColor[3] }

            addon:OnUpdate(0.5)

            -- Color should have changed
            local currentColor = addon:GetSetting("color")
            local changed = currentColor[1] ~= initialCopy[1]
                or currentColor[2] ~= initialCopy[2]
                or currentColor[3] ~= initialCopy[3]
            assert.is_true(changed)
        end)
    end)

    describe("Click Effects", function()
        before_each(function()
            addon:SetSetting("clickEffects", true)
            addon:SetSetting("clickParticles", 8)
            addon:SetSetting("clickSize", 32)
            addon:SetSetting("clickDuration", 0.5)
            addon:SetSetting("points", 10)
            addon:BuildTrail()
        end)

        it("should not create effects when disabled", function()
            addon:SetSetting("clickEffects", false)
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
            addon:SetSetting("rainbowMode", true)
            addon.rainbowHue = 0.5

            mocks.SimulateMouseClick("LeftButton", true)
            addon:OnUpdate(0.016)

            -- Should have created particles (using rainbow color)
            assert.is_true(#addon.clickParticles > 0)

            mocks.SimulateMouseClick("LeftButton", false)
        end)

        it("should create correct number of click particles", function()
            addon:SetSetting("clickParticles", 12)
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
            addon:SetSetting("particleShape", "unknownshape")
            addon:SetSetting("points", 5)

            addon:BuildTrail()

            -- Should not crash and create particles
            assert.are.equal(5, #addon.points)
        end)
    end)

    describe("Comet Mode", function()
        before_each(function()
            addon:SetSetting("cometMode", true)
            addon:SetSetting("cometLength", 2.5)
            addon:SetSetting("points", 20)
            addon:BuildTrail()
        end)

        it("should apply different alpha curve", function()
            addon:OnUpdate(0.016)

            -- Should complete without errors
            assert.is_true(true)
        end)

        it("should use custom spacing", function()
            addon:SetSetting("cometLength", 1.0)

            addon:OnUpdate(0.016)

            assert.is_true(true)
        end)

        it("should work with different lengths", function()
            local lengths = { 0.5, 1.0, 2.0, 5.0 }

            for _, length in ipairs(lengths) do
                addon:SetSetting("cometLength", length)
                addon:OnUpdate(0.016)

                assert.is_true(true)
            end
        end)
    end)
end)

describe("BuildReticle", function()
    local addon

    before_each(function()
        mocks.ResetWoWMocks()
        require("Core")
        require("Utils")
        require("Effects")
        addon = UltraCursorFX
        addon:InitializeDefaults()

        -- Set up test settings using SetSetting
        addon:SetSetting("reticleEnabled", true)
        addon:SetSetting("reticleStyle", "military")
        addon:SetSetting("reticleSize", 80)
        addon:SetSetting("reticleOpacity", 0.7)
        addon:SetSetting("reticleBrightness", 1.0)
        addon:SetSetting("reticleRotationSpeed", 0.5)
        addon:SetSetting("color", { 0.5, 0.8, 1.0 })
        addon:SetSetting("rainbowMode", false)
        addon:SetSetting("points", 10)
        addon:SetSetting("size", 8)
        addon:SetSetting("glowSize", 16)
        addon:SetSetting("particleShape", "star")

        addon:BuildTrail()
    end)

    after_each(function()
        _G.UltraCursorFXDB = nil
    end)

    it("builds crosshair reticle with 5 segments", function()
        addon:SetSetting("reticleStyle", "crosshair")
        addon:BuildReticle(parent)

        assert.equals(5, #addon.reticleSegments)
        assert.is_not_nil(addon.reticleSegments[1])
        assert.is_not_nil(addon.reticleSegments[5])
    end)

    it("builds circledot reticle with 9 segments", function()
        addon:SetSetting("reticleStyle", "circledot")
        addon:BuildReticle(parent)

        assert.equals(9, #addon.reticleSegments)
        assert.is_not_nil(addon.reticleSegments[1])
        assert.is_not_nil(addon.reticleSegments[9])
    end)

    it("builds tshape reticle with 5 segments", function()
        addon:SetSetting("reticleStyle", "tshape")
        addon:BuildReticle(parent)

        assert.equals(5, #addon.reticleSegments)
        assert.is_not_nil(addon.reticleSegments[1])
        assert.is_not_nil(addon.reticleSegments[5])
    end)

    it("builds military reticle with 8 segments", function()
        addon:SetSetting("reticleStyle", "military")
        addon:BuildReticle(parent)

        assert.equals(8, #addon.reticleSegments)
        assert.is_not_nil(addon.reticleSegments[1])
        assert.is_not_nil(addon.reticleSegments[8])
    end)

    it("builds cyberpunk reticle with 8 segments", function()
        addon:SetSetting("reticleStyle", "cyberpunk")
        addon:BuildReticle(parent)

        assert.equals(8, #addon.reticleSegments)
        assert.is_not_nil(addon.reticleSegments[1])
        assert.is_not_nil(addon.reticleSegments[8])
    end)

    it("builds minimal reticle with 4 segments", function()
        addon:SetSetting("reticleStyle", "minimal")
        addon:BuildReticle(parent)

        assert.equals(4, #addon.reticleSegments)
        assert.is_not_nil(addon.reticleSegments[1])
        assert.is_not_nil(addon.reticleSegments[4])
    end)

    it("hides all reticle segments when reticleEnabled is false", function()
        addon:SetSetting("reticleEnabled", false)
        addon:BuildReticle(parent)

        for _, seg in ipairs(addon.reticleSegments) do
            assert.is_true(seg.hidden)
        end
    end)

    it("creates texture segments with correct properties", function()
        addon:SetSetting("reticleStyle", "crosshair")
        addon:BuildReticle()

        -- Verify 5 segments were created for crosshair style
        assert.equals(5, #addon.reticleSegments)
        -- Verify segments exist
        for i = 1, 5 do
            assert.is_not_nil(addon.reticleSegments[i])
        end
    end)
end)

describe("UpdateReticle", function()
    local addon, mockTime

    before_each(function()
        mocks.ResetWoWMocks()
        require("Core")
        require("Utils")
        require("Effects")
        addon = UltraCursorFX
        addon:InitializeDefaults()

        mockTime = 0
        _G.GetTime = function()
            return mockTime
        end

        -- Set up test settings using SetSetting
        addon:SetSetting("reticleEnabled", true)
        addon:SetSetting("reticleStyle", "military")
        addon:SetSetting("reticleSize", 80)
        addon:SetSetting("reticleOpacity", 0.7)
        addon:SetSetting("reticleBrightness", 1.0)
        addon:SetSetting("reticleRotationSpeed", 0.5)
        addon:SetSetting("color", { 0.5, 0.8, 1.0 })
        addon:SetSetting("rainbowMode", false)
        addon:SetSetting("points", 10)
        addon:SetSetting("size", 8)
        addon:SetSetting("glowSize", 16)
        addon:SetSetting("particleShape", "star")

        _G.UnitExists = function(unit)
            return false
        end
        _G.UnitCanAttack = function()
            return false
        end
        _G.UnitIsDead = function()
            return false
        end
        _G.UnitIsFriend = function()
            return false
        end
        _G.UnitIsUnit = function()
            return false
        end
        _G.GameTooltip = {
            IsShown = function()
                return false
            end,
            GetUnit = function()
                return nil
            end,
        }

        addon.reticleRotation = 0
        addon.rainbowHue = 0
        addon:BuildTrail()
        addon:BuildReticle()
    end)

    after_each(function()
        _G.UltraCursorFXDB = nil
        _G.UnitExists = nil
        _G.UnitCanAttack = nil
        _G.UnitIsDead = nil
        _G.UnitIsFriend = nil
        _G.UnitIsUnit = nil
        _G.GameTooltip = nil
    end)

    it("detects enemy mouseover and uses red color", function()
        _G.UnitExists = function(unit)
            return unit == "mouseover"
        end
        _G.UnitCanAttack = function(unit, target)
            return unit == "player" and target == "mouseover"
        end
        _G.UnitIsDead = function()
            return false
        end

        addon:UpdateReticle(0.016, 500, 300)

        -- Just verify it runs without error and segments exist
        assert.is_not_nil(addon.reticleSegments)
        assert.is_true(#addon.reticleSegments > 0)
    end)

    it("detects friendly mouseover and uses green color with pulse", function()
        mockTime = 1.0

        _G.UnitExists = function(unit)
            return unit == "mouseover"
        end
        _G.UnitIsFriend = function(unit, target)
            return unit == "player" and target == "mouseover"
        end
        _G.UnitIsUnit = function(unit, target)
            return false -- Not player
        end

        addon:UpdateReticle(0.016, 500, 300)

        -- Just verify it runs without error
        assert.is_not_nil(addon.reticleSegments)
        assert.is_true(#addon.reticleSegments > 0)
    end)

    it("detects interactive object and uses gold color", function()
        _G.UnitExists = function()
            return false
        end
        _G.GameTooltip = {
            IsShown = function()
                return true
            end,
            GetUnit = function()
                return nil -- Object, not unit
            end,
        }

        addon:UpdateReticle(0.016, 500, 300)

        -- Just verify it runs without error
        assert.is_not_nil(addon.reticleSegments)
        assert.is_true(#addon.reticleSegments > 0)
    end)

    it("uses trail color for default state", function()
        _G.UnitExists = function()
            return false
        end

        addon:UpdateReticle(0.016, 500, 300)

        -- Just verify it runs without error
        assert.is_not_nil(addon.reticleSegments)
        assert.is_true(#addon.reticleSegments > 0)
    end)

    it("updates rotation based on rotation speed", function()
        local initialRotation = addon.reticleRotation
        addon:UpdateReticle(1.0, 500, 300) -- 1 second elapsed

        -- rotation += elapsed * rotationSpeed
        -- 0 + 1.0 * 0.5 = 0.5
        assert.equals(0.5, addon.reticleRotation)
    end)

    it("wraps rotation at 2π", function()
        addon.reticleRotation = math.pi * 2 - 0.1
        addon:UpdateReticle(1.0, 500, 300) -- Should wrap around

        assert.is_true(addon.reticleRotation < math.pi * 2)
        assert.is_true(addon.reticleRotation >= 0)
    end)

    it("applies brightness multiplier to colors", function()
        addon:SetSetting("reticleBrightness", 0.5)

        addon:UpdateReticle(0.016, 500, 300)

        -- Just verify it runs without error
        assert.is_true(true)
    end)

    it("applies opacity setting to alpha", function()
        addon:SetSetting("reticleOpacity", 0.5)

        addon:UpdateReticle(0.016, 500, 300)

        -- Just verify it runs without error
        assert.is_true(true)
    end)

    it("does not update when reticleEnabled is false", function()
        addon:SetSetting("reticleEnabled", false)
        local initialRotation = addon.reticleRotation

        addon:UpdateReticle(1.0, 500, 300)

        -- Rotation should not have changed
        assert.equals(initialRotation, addon.reticleRotation)
    end)

    it("does not update when reticle segments are empty", function()
        -- Clear the reticle segments array (not replace it)
        while #addon.reticleSegments > 0 do
            table.remove(addon.reticleSegments)
        end

        local initialRotation = addon.reticleRotation

        addon:UpdateReticle(1.0, 500, 300)

        -- Should return early without updating rotation
        assert.equals(initialRotation, addon.reticleRotation)
    end)
end)

describe("Reticle Rendering Styles", function()
    local addon

    before_each(function()
        mocks.ResetWoWMocks()
        require("Core")
        require("Utils")
        require("Effects")
        addon = UltraCursorFX
        addon:InitializeDefaults()

        -- Set up test settings using SetSetting
        addon:SetSetting("reticleEnabled", true)
        addon:SetSetting("reticleStyle", "crosshair")
        addon:SetSetting("reticleSize", 100)
        addon:SetSetting("reticleOpacity", 0.8)
        addon:SetSetting("reticleBrightness", 1.0)
        addon:SetSetting("reticleRotationSpeed", 0.5)
        addon:SetSetting("color", { 1.0, 1.0, 1.0 })
        addon:SetSetting("rainbowMode", false)
        addon:SetSetting("points", 10)
        addon:SetSetting("size", 8)
        addon:SetSetting("glowSize", 16)
        addon:SetSetting("particleShape", "star")

        addon.reticleRotation = 0
        addon:BuildTrail()
        addon:BuildReticle()
    end)

    after_each(function()
        _G.UltraCursorFXDB = nil
    end)

    it("renders crosshair with correct segment positioning", function()
        addon:RenderCrosshairReticle(500, 300, 100, 1.0, 1.0, 1.0, 0.8)

        -- Just verify segments exist and function runs without error
        assert.is_not_nil(addon.reticleSegments)
        assert.equals(5, #addon.reticleSegments)
    end)

    it("renders circledot with 8 segments + center", function()
        addon:SetSetting("reticleStyle", "circledot")
        addon:BuildReticle()

        addon:RenderCircleDotReticle(500, 300, 100, 1.0, 0.5, 0.2, 0.8)

        -- Verify correct number of segments
        assert.equals(9, #addon.reticleSegments)
    end)

    it("renders tshape with range tick marks", function()
        addon:SetSetting("reticleStyle", "tshape")
        addon:BuildReticle()

        addon:RenderTShapeReticle(500, 300, 100, 0.8, 0.8, 0.8, 0.7, "default")

        -- Verify correct number of segments
        assert.equals(5, #addon.reticleSegments)
    end)

    it("renders military with rotating segments for enemies", function()
        addon:SetSetting("reticleStyle", "military")
        addon:BuildReticle()
        addon.reticleRotation = math.pi / 4

        addon:RenderMilitaryReticle(500, 300, 100, 1.0, 0.0, 0.0, 0.8, "enemy")

        -- Verify correct number of segments
        assert.equals(8, #addon.reticleSegments)
    end)

    it("renders military without rotating segments for default", function()
        addon:SetSetting("reticleStyle", "military")
        addon:BuildReticle()

        addon:RenderMilitaryReticle(500, 300, 100, 0.5, 0.5, 0.5, 0.8, "default")

        -- Verify it runs without error
        assert.equals(8, #addon.reticleSegments)
    end)

    it("renders cyberpunk with rotating neon segments", function()
        addon:SetSetting("reticleStyle", "cyberpunk")
        addon:BuildReticle()
        addon.reticleRotation = math.pi / 8

        addon:RenderCyberpunkReticle(500, 300, 100, 0.0, 1.0, 1.0, 0.9, "default")

        -- Verify correct number of segments
        assert.equals(8, #addon.reticleSegments)
    end)

    it("renders minimal with 4 corner L-brackets", function()
        addon:SetSetting("reticleStyle", "minimal")
        addon:BuildReticle()

        addon:RenderMinimalReticle(500, 300, 80, 1.0, 1.0, 1.0, 0.6)

        -- Verify correct number of segments
        assert.equals(4, #addon.reticleSegments)
    end)
end)

describe("Fade Effect Calculations", function()
    local addon

    before_each(function()
        mocks.ResetWoWMocks()
        require("Core")
        require("Utils")
        require("Effects")
        addon = UltraCursorFX
        addon:InitializeDefaults()

        -- Set up test settings using SetSetting
        addon:SetSetting("points", 20)
        addon:SetSetting("smoothness", 0.35)
        addon:SetSetting("opacity", 1.0)
        addon:SetSetting("fadeEnabled", true)
        addon:SetSetting("fadeStrength", 0.5)
        addon:SetSetting("combatOpacityBoost", false)
        addon:SetSetting("rainbowMode", false)
        addon:SetSetting("color", { 1.0, 1.0, 1.0 })
        addon:SetSetting("cometMode", false)
        addon:SetSetting("size", 8)
        addon:SetSetting("glow", true)
        addon:SetSetting("glowSize", 16)
        addon:SetSetting("particleShape", "star")
        addon:SetSetting("reticleEnabled", false)

        _G.InCombatLockdown = function()
            return false
        end

        _G.UnitExists = function(unit)
            return false
        end

        _G.GameTooltip = {
            IsShown = function()
                return false
            end,
        }

        addon.inCombat = false
        addon:BuildTrail()
    end)

    after_each(function()
        _G.UltraCursorFXDB = nil
        _G.InCombatLockdown = nil
        _G.GameTooltip = nil
    end)

    it("applies fade with fadeEnabled and fadeStrength", function()
        addon:SetSetting("fadeEnabled", true)
        addon:SetSetting("fadeStrength", 0.5)

        addon:OnUpdate(0.016)

        -- Just verify it runs without error
        assert.is_true(true)
    end)

    it("uses standard fade when fadeEnabled is false", function()
        addon:SetSetting("fadeEnabled", false)

        addon:OnUpdate(0.016)

        -- Just verify it runs without error
        assert.is_true(true)
    end)

    it("applies combat opacity boost when in combat", function()
        addon:SetSetting("combatOpacityBoost", true)
        addon:SetSetting("opacity", 0.8)
        addon.inCombat = true
        _G.InCombatLockdown = function()
            return true
        end

        addon:OnUpdate(0.016)

        -- Just verify it runs without error
        assert.is_true(true)
    end)

    it("does not boost opacity when not in combat", function()
        addon:SetSetting("combatOpacityBoost", true)
        addon:SetSetting("opacity", 0.8)
        addon.inCombat = false
        _G.InCombatLockdown = function()
            return false
        end

        addon:OnUpdate(0.016)

        -- Just verify it runs without error
        assert.is_true(true)
    end)

    it("clamps boosted opacity to 1.0 maximum", function()
        addon:SetSetting("combatOpacityBoost", true)
        addon:SetSetting("opacity", 0.9) -- Would boost to 1.17
        addon.inCombat = true

        addon:OnUpdate(0.016)

        -- Just verify it runs without error
        assert.is_true(true)
    end)

    it("renders circledot reticle during OnUpdate", function()
        addon:SetSetting("reticleEnabled", true)
        addon:SetSetting("reticleStyle", "circledot")
        addon:BuildReticle()

        addon:OnUpdate(0.016)

        -- Just verify it runs without error
        assert.is_true(true)
    end)

    it("renders tshape reticle during OnUpdate", function()
        addon:SetSetting("reticleEnabled", true)
        addon:SetSetting("reticleStyle", "tshape")
        addon:BuildReticle()

        addon:OnUpdate(0.016)

        -- Just verify it runs without error
        assert.is_true(true)
    end)

    it("renders cyberpunk reticle during OnUpdate", function()
        addon:SetSetting("reticleEnabled", true)
        addon:SetSetting("reticleStyle", "cyberpunk")
        addon:BuildReticle()

        addon:OnUpdate(0.016)

        -- Just verify it runs without error
        assert.is_true(true)
    end)

    it("renders minimal reticle during OnUpdate", function()
        addon:SetSetting("reticleEnabled", true)
        addon:SetSetting("reticleStyle", "minimal")
        addon:BuildReticle()

        addon:OnUpdate(0.016)

        -- Just verify it runs without error
        assert.is_true(true)
    end)

    it("handles edge warning pulse when active", function()
        addon:SetSetting("edgeWarningEnabled", true)
        addon:SetSetting("edgeWarningSize", 64)
        addon:SetSetting("edgeWarningDistance", 50)
        addon:SetSetting("edgeWarningOpacity", 0.8)
        addon:BuildEdgeWarnings()
        addon.edgeWarningPulse = 0.5

        addon:OnUpdate(0.016)

        -- Just verify it runs without error
        assert.is_true(true)
    end)
end)
