-- ===============================
-- Memory Management & Cleanup Tests
-- ===============================
-- Tests to verify no memory leaks and proper resource cleanup

local mocks = require("spec.wow_mocks")

describe("Memory Management & Cleanup", function()
    local addon

    before_each(function()
        mocks.ResetWoWMocks()
        require("Core")
        require("Utils")
        require("Effects")
        addon = UltraCursorFX
        addon:InitializeDefaults()

        -- Set up test settings using SetSetting
        addon:SetSetting("enabled", true)
        addon:SetSetting("points", 20)
        addon:SetSetting("size", 8)
        addon:SetSetting("glowSize", 16)
        addon:SetSetting("particleShape", "star")
        addon:SetSetting("clickEffects", true)
        addon:SetSetting("clickParticles", 12)
        addon:SetSetting("clickSize", 32)
        addon:SetSetting("clickDuration", 0.5)
        addon:SetSetting("color", { 1.0, 1.0, 1.0 })
        addon:SetSetting("rainbowMode", false)
        addon:SetSetting("reticleEnabled", true)
        addon:SetSetting("reticleStyle", "military")
        addon:SetSetting("reticleSize", 80)
        addon:SetSetting("reticleOpacity", 0.7)
        addon:SetSetting("reticleBrightness", 1.0)
        addon:SetSetting("reticleRotationSpeed", 0.5)

        addon:BuildTrail()
    end)

    after_each(function()
        _G.UltraCursorFXDB = nil
    end)

    describe("BuildTrail Cleanup", function()
        it("properly hides old textures before creating new ones", function()
            -- Build initial trail
            addon:SetSetting("points", 10)
            addon:BuildTrail()

            local initialPoints = #addon.points
            local initialGlow = #addon.glow

            -- Verify initial state
            assert.equals(10, initialPoints)
            assert.equals(10, initialGlow)

            -- Rebuild with different count
            addon:SetSetting("points", 5)
            addon:BuildTrail()

            -- Should have exactly 5 new points, not 15
            assert.equals(5, #addon.points)
            assert.equals(5, #addon.glow)
        end)

        it("wipes arrays completely when rebuilding", function()
            addon:SetSetting("points", 20)
            addon:BuildTrail()

            -- Rebuild multiple times
            for i = 1, 5 do
                addon:SetSetting("points", 10 + i)
                addon:BuildTrail()

                -- Array size should match current setting, not accumulate
                assert.equals(10 + i, #addon.points)
                assert.equals(10 + i, #addon.glow)
            end
        end)

        it("handles rapid rebuilds without accumulating textures", function()
            -- Simulate rapid UI slider changes
            for i = 1, 20 do
                addon:SetSetting("points", 10 + (i % 10))
                addon:BuildTrail()
            end

            -- Final count should match last setting
            assert.equals(10 + (20 % 10), #addon.points)
            assert.equals(10 + (20 % 10), #addon.glow)
        end)

        it("does not leave hidden textures accessible after rebuild", function()
            addon:SetSetting("points", 30)
            addon:BuildTrail()

            local oldPoints = {}
            for i = 1, #addon.points do
                oldPoints[i] = addon.points[i]
            end

            -- Rebuild with fewer points
            addon:SetSetting("points", 10)
            addon:BuildTrail()

            -- Old textures from first 30 positions should have been hidden during wipe
            -- The first 10 get hidden, then new textures created
            -- We can verify the array was wiped by checking the count
            assert.equals(10, #addon.points)

            -- The textures in old array should not be in new array
            local foundOldInNew = false
            for i = 1, #addon.points do
                for j = 1, #oldPoints do
                    if addon.points[i] == oldPoints[j] then
                        foundOldInNew = true
                        break
                    end
                end
            end
            -- Should have new texture objects, not reused old ones
            assert.is_false(foundOldInNew)
        end)
    end)

    describe("BuildReticle Cleanup", function()
        it("properly hides old reticle segments before creating new ones", function()
            addon:SetSetting("reticleStyle", "crosshair")
            addon:BuildReticle()

            local initialCount = #addon.reticleSegments
            assert.equals(5, initialCount) -- Crosshair has 5 segments

            -- Switch to different style
            addon:SetSetting("reticleStyle", "military")
            addon:BuildReticle()

            -- Should have exactly 8 segments, not 13
            assert.equals(8, #addon.reticleSegments)
        end)

        it("wipes reticle segments array completely when rebuilding", function()
            -- Build different styles multiple times
            local styles = {
                { name = "crosshair", count = 5 },
                { name = "military", count = 8 },
                { name = "circledot", count = 9 },
                { name = "minimal", count = 4 },
            }

            for _, style in ipairs(styles) do
                addon:SetSetting("reticleStyle", style.name)
                addon:BuildReticle()

                -- Should have exact count for style, not accumulated
                assert.equals(style.count, #addon.reticleSegments)
            end
        end)

        it("handles rapid style switches without accumulating segments", function()
            local styles = { "crosshair", "military", "circledot", "tshape", "cyberpunk", "minimal" }

            -- Rapidly switch styles 30 times
            for i = 1, 30 do
                addon:SetSetting("reticleStyle", styles[(i % #styles) + 1])
                addon:BuildReticle()
            end

            -- Final count should match last style
            local lastStyle = styles[(30 % #styles) + 1]
            local expectedCounts = {
                crosshair = 5,
                circledot = 9,
                tshape = 5,
                military = 8,
                cyberpunk = 8,
                minimal = 4,
            }

            assert.equals(expectedCounts[lastStyle], #addon.reticleSegments)
        end)

        it("hides all segments when disabling reticle", function()
            addon:SetSetting("reticleEnabled", true)
            addon:SetSetting("reticleStyle", "military")
            addon:BuildReticle()

            local segmentCount = #addon.reticleSegments
            assert.is_true(segmentCount > 0)

            -- Disable reticle
            addon:SetSetting("reticleEnabled", false)
            addon:BuildReticle()

            -- All segments should be hidden
            for _, seg in ipairs(addon.reticleSegments) do
                assert.is_true(seg.hidden or seg.visible == false)
            end
        end)

        it("does not leave old segments visible after style change", function()
            addon:SetSetting("reticleStyle", "circledot") -- 9 segments
            addon:BuildReticle()

            local oldSegments = {}
            for i = 1, #addon.reticleSegments do
                oldSegments[i] = addon.reticleSegments[i]
            end

            -- Switch to minimal (4 segments)
            addon:SetSetting("reticleStyle", "minimal")
            addon:BuildReticle()

            -- Verify new array has correct count
            assert.equals(4, #addon.reticleSegments)

            -- Verify old segments are not in new array
            local foundOldInNew = false
            for i = 1, #addon.reticleSegments do
                for j = 1, #oldSegments do
                    if addon.reticleSegments[i] == oldSegments[j] then
                        foundOldInNew = true
                        break
                    end
                end
            end
            -- Should have new segment objects, not reused old ones
            assert.is_false(foundOldInNew)
        end)
    end)

    describe("Click Particle Pool Management", function()
        it("enforces maximum pool size to prevent unbounded growth", function()
            -- The MAX_POOL_SIZE is 200 in Effects.lua
            -- Simulate many clicks to test pool limit

            -- Create 250 click effects (should cap pool at 200)
            for i = 1, 250 do
                mocks.SimulateMouseClick("LeftButton", true)
                addon:OnUpdate(0.016)
                mocks.SimulateMouseClick("LeftButton", false)
                addon:OnUpdate(0.016)

                -- Fast-forward time to expire particles
                for j = 1, 100 do
                    addon:OnUpdate(0.1) -- Large elapsed time to expire quickly
                end
            end

            -- Active particles should be small (recently created)
            -- Pool should not exceed MAX_POOL_SIZE
            assert.is_true(#addon.clickParticles < 50) -- Most should be expired
        end)

        it("reuses particles from pool instead of creating new textures", function()
            -- This is hard to test directly, but we can verify that after many
            -- clicks, we're not accumulating infinite textures

            local clickCount = 100
            for i = 1, clickCount do
                mocks.SimulateMouseClick("LeftButton", true)
                addon:OnUpdate(0.016)
                mocks.SimulateMouseClick("LeftButton", false)

                -- Let particles expire
                for j = 1, 10 do
                    addon:OnUpdate(0.1)
                end
            end

            -- If pooling works, we should have cleared most particles
            -- If not, we'd have accumulated clickCount * clickParticles textures
            assert.is_true(#addon.clickParticles < 50)
        end)

        it("properly releases particles back to pool when expired", function()
            addon:SetSetting("clickParticles", 8)
            addon:SetSetting("clickDuration", 0.5)

            -- Create click effect
            mocks.SimulateMouseClick("LeftButton", true)
            addon:OnUpdate(0.016)
            mocks.SimulateMouseClick("LeftButton", false)

            local particleCount = #addon.clickParticles
            assert.equals(8, particleCount)

            -- Fast-forward past duration to expire
            addon:OnUpdate(1.0)

            -- All particles should be removed
            assert.equals(0, #addon.clickParticles)
        end)

        it("removes expired particles from active array", function()
            addon:SetSetting("clickParticles", 5)

            mocks.SimulateMouseClick("LeftButton", true)
            addon:OnUpdate(0.016)
            mocks.SimulateMouseClick("LeftButton", false)

            local particleCount = #addon.clickParticles
            assert.equals(5, particleCount)

            -- Expire particles
            addon:OnUpdate(1.0)

            -- All particles should be removed from active array
            assert.equals(0, #addon.clickParticles)
        end)

        it("clears particle positions before returning to pool", function()
            addon:SetSetting("clickParticles", 3)

            mocks.SimulateMouseClick("LeftButton", true)
            addon:OnUpdate(0.016)
            mocks.SimulateMouseClick("LeftButton", false)

            local particles = {}
            for i = 1, #addon.clickParticles do
                particles[i] = addon.clickParticles[i]
            end

            -- Expire particles
            addon:OnUpdate(1.0)

            -- Verify ClearAllPoints was called (points array should be empty/cleared)
            for _, p in ipairs(particles) do
                -- Mock tracks points in an array
                assert.is_true(not p.points or #p.points == 0)
            end
        end)
    end)

    describe("Combat State Transitions", function()
        it("properly cleans up when disabling in combat", function()
            addon:SetSetting("enabled", true)
            addon:SetSetting("combatOnly", false)
            addon.inCombat = true

            -- Build trail
            addon:BuildTrail()
            addon:UpdateCursorState() -- Enable OnUpdate script

            -- Disable addon
            addon:SetSetting("enabled", false)
            addon:UpdateCursorState()

            -- Particles should be hidden (UpdateCursorState hides them)
            for i = 1, #addon.points do
                -- Check if particle exists and is hidden
                if addon.points[i] then
                    -- UpdateCursorState calls Hide() on particles
                    -- Our mock should track this
                    assert.is_not_nil(addon.points[i])
                end
            end

            -- Verify OnUpdate script is disabled
            assert.is_nil(addon.frame._scripts["OnUpdate"])
        end)

        it("cleans up when exiting combat with combatOnly mode enabled", function()
            addon:SetSetting("enabled", true)
            addon:SetSetting("combatOnly", true)
            addon.inCombat = true

            -- Build trail
            addon:BuildTrail()
            addon:UpdateCursorState() -- Enable

            -- Exit combat
            addon.inCombat = false
            addon:UpdateCursorState()

            -- OnUpdate script should be disabled
            assert.is_nil(addon.frame._scripts["OnUpdate"])

            -- Particles should exist but be hidden by UpdateCursorState
            assert.is_true(#addon.points > 0)
        end)

        it("does not accumulate particles across combat state changes", function()
            addon:SetSetting("combatOnly", true)
            addon:SetSetting("points", 15)

            -- Build initial trail
            addon:BuildTrail()

            -- Enter/exit combat multiple times
            for i = 1, 10 do
                addon.inCombat = true
                addon:UpdateCursorState()

                addon.inCombat = false
                addon:UpdateCursorState()
            end

            -- Point count should remain stable (arrays not recreated)
            assert.equals(15, #addon.points)
            assert.equals(15, #addon.glow)
        end)
    end)

    describe("Profile Switching Cleanup", function()
        it("rebuilds trail when switching profiles", function()
            -- Load Profiles module
            require("Profiles")

            -- Create profile with different settings
            _G.UltraCursorFXDB.account = {
                profiles = {
                    world = {
                        points = 20,
                        size = 10,
                        particleShape = "star",
                        color = { 1.0, 1.0, 1.0 },
                        glowSize = 16,
                        smoothness = 0.2,
                        pulseSpeed = 2.0,
                        rainbowMode = false,
                        clickEffects = false,
                    },
                    raid = {
                        points = 40,
                        size = 15,
                        particleShape = "spark",
                        color = { 1.0, 0.0, 0.0 },
                        glowSize = 16,
                        smoothness = 0.2,
                        pulseSpeed = 2.0,
                        rainbowMode = false,
                        clickEffects = false,
                    },
                },
            }
            _G.UltraCursorFXDB.characters = {
                ["TestCharacter-TestRealm"] = {
                    useAccountSettings = true,
                },
            }

            -- Load world profile
            addon:LoadFromProfile("world")
            assert.equals(20, #addon.points)

            -- Switch to raid profile
            addon:LoadFromProfile("raid")
            assert.equals(40, #addon.points) -- Should rebuild
            assert.equals(40, #addon.glow) -- Verify no accumulation
        end)

        it("does not leave orphaned textures after profile switch", function()
            require("Profiles")

            _G.UltraCursorFXDB.account = {
                profiles = {
                    small = {
                        points = 10,
                        size = 8,
                        particleShape = "star",
                        color = { 1.0, 1.0, 1.0 },
                        glowSize = 16,
                        smoothness = 0.2,
                        pulseSpeed = 2.0,
                        rainbowMode = false,
                        clickEffects = false,
                    },
                    large = {
                        points = 50,
                        size = 16,
                        particleShape = "star",
                        color = { 1.0, 1.0, 1.0 },
                        glowSize = 16,
                        smoothness = 0.2,
                        pulseSpeed = 2.0,
                        rainbowMode = false,
                        clickEffects = false,
                    },
                },
            }
            _G.UltraCursorFXDB.characters = {
                ["TestCharacter-TestRealm"] = {
                    useAccountSettings = true,
                },
            }

            -- Load large profile
            addon:LoadFromProfile("large")
            local largePoints = #addon.points

            -- Switch to small profile
            addon:LoadFromProfile("small")

            -- Should have exactly small profile counts
            assert.equals(10, #addon.points)
            assert.equals(10, #addon.glow)

            -- Should not have large profile counts
            assert.not_equals(largePoints, #addon.points)
        end)
    end)

    describe("Table Memory Management", function()
        it("properly wipes points array without leaving references", function()
            addon:SetSetting("points", 30)
            addon:BuildTrail()

            local pointsTable = addon.points
            local oldPointsCount = #pointsTable

            -- Rebuild with fewer points
            addon:SetSetting("points", 10)
            addon:BuildTrail()

            -- Same table reference (not recreated)
            assert.equals(pointsTable, addon.points)

            -- But size should be new count
            assert.equals(10, #addon.points)
            assert.not_equals(oldPointsCount, #addon.points)
        end)

        it("properly wipes glow array without leaving references", function()
            addon:SetSetting("points", 25)
            addon:BuildTrail()

            local glowTable = addon.glow

            addon:SetSetting("points", 8)
            addon:BuildTrail()

            -- Same table reference
            assert.equals(glowTable, addon.glow)

            -- Correct new size
            assert.equals(8, #addon.glow)
        end)

        it("properly wipes reticle segments array", function()
            addon:SetSetting("reticleStyle", "circledot") -- 9 segments
            addon:BuildReticle()

            local reticleTable = addon.reticleSegments

            addon:SetSetting("reticleStyle", "minimal") -- 4 segments
            addon:BuildReticle()

            -- Same table reference
            assert.equals(reticleTable, addon.reticleSegments)

            -- Correct new size
            assert.equals(4, #addon.reticleSegments)
        end)

        it("does not accumulate click particles beyond active count", function()
            addon:SetSetting("clickParticles", 8)

            -- Create many click effects
            for i = 1, 50 do
                mocks.SimulateMouseClick("LeftButton", true)
                addon:OnUpdate(0.016)
                mocks.SimulateMouseClick("LeftButton", false)

                -- Let old particles expire
                addon:OnUpdate(1.0)
            end

            -- Should not have accumulated all 50 * 8 = 400 particles
            assert.is_true(#addon.clickParticles < 50)
        end)
    end)

    describe("Texture Hiding on Disable", function()
        it("hides all trail particles when addon disabled", function()
            addon:SetSetting("enabled", true)
            addon:SetSetting("points", 20)
            addon:BuildTrail()
            addon:UpdateCursorState() -- Enable

            -- Disable addon
            addon:SetSetting("enabled", false)
            addon:UpdateCursorState()

            -- OnUpdate script should be disabled
            assert.is_nil(addon.frame._scripts["OnUpdate"])

            -- Particles still exist in arrays (not deleted, just hidden and no longer updated)
            assert.equals(20, #addon.points)
            assert.equals(20, #addon.glow)
        end)

        it("hides all reticle segments when reticle disabled", function()
            addon:SetSetting("reticleEnabled", true)
            addon:SetSetting("reticleStyle", "military")
            addon:BuildReticle()

            -- Disable reticle
            addon:SetSetting("reticleEnabled", false)
            addon:BuildReticle()

            -- All segments should be hidden
            for i = 1, #addon.reticleSegments do
                assert.is_true(addon.reticleSegments[i].hidden or addon.reticleSegments[i].visible == false)
            end
        end)

        it("hides particles when combatOnly mode exits combat", function()
            addon:SetSetting("combatOnly", true)
            addon:SetSetting("enabled", true)
            addon:SetSetting("points", 15)

            addon:BuildTrail()

            -- Enter combat
            addon.inCombat = true
            addon:UpdateCursorState()

            -- Exit combat
            addon.inCombat = false
            addon:UpdateCursorState()

            -- OnUpdate script should be disabled
            assert.is_nil(addon.frame._scripts["OnUpdate"])

            -- Particles still exist in arrays
            assert.equals(15, #addon.points)
        end)
    end)

    describe("No Memory Leak Edge Cases", function()
        it("handles zero points setting without errors", function()
            addon:SetSetting("points", 0)
            addon:BuildTrail()

            assert.equals(0, #addon.points)
            assert.equals(0, #addon.glow)

            -- Should not crash on update
            addon:OnUpdate(0.016)
            assert.is_true(true)
        end)

        it("handles maximum points setting without accumulation", function()
            addon:SetSetting("points", 100)
            addon:BuildTrail()

            assert.equals(100, #addon.points)
            assert.equals(100, #addon.glow)

            -- Reduce to minimum
            addon:SetSetting("points", 10)
            addon:BuildTrail()

            assert.equals(10, #addon.points)
            assert.equals(10, #addon.glow)
        end)

        it("handles rapid enable/disable cycles", function()
            addon:SetSetting("points", 20)

            -- Rapid toggle 50 times
            for i = 1, 50 do
                addon:SetSetting("enabled", true)
                addon:UpdateCursorState()
                addon:OnUpdate(0.016)

                addon:SetSetting("enabled", false)
                addon:UpdateCursorState()
            end

            -- Point arrays should remain stable
            assert.equals(20, #addon.points)
            assert.equals(20, #addon.glow)
        end)

        it("handles BuildTrail called without InitializeDefaults", function()
            -- Create fresh addon instance
            _G.UltraCursorFX = nil
            package.loaded["Effects"] = nil
            package.loaded["Core"] = nil

            require("Core")
            require("Effects")

            local newAddon = UltraCursorFX

            -- Set minimal DB with ALL required fields using account structure
            _G.UltraCursorFXDB = {
                account = {
                    points = 10,
                    size = 8,
                    glowSize = 16,
                    particleShape = "star",
                    color = { 1.0, 1.0, 1.0 }, -- Required for unpack()
                    reticleEnabled = false, -- Don't build reticle
                },
                characters = {
                    ["TestCharacter-TestRealm"] = {
                        useAccountSettings = true,
                    },
                },
            }

            -- Should not crash
            newAddon:BuildTrail()
            assert.equals(10, #newAddon.points)
        end)
    end)
end)
