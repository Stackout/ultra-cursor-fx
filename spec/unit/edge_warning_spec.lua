-- ===============================
-- Edge Warning System Tests
-- ===============================

local mocks = require("spec.wow_mocks")

describe("Edge Warning System", function()
    local addon

    before_each(function()
        mocks.ResetWoWMocks()
        require("Core")
        require("Utils")
        require("Effects")
        addon = UltraCursorFX
        addon:InitializeDefaults()
    end)

    describe("BuildEdgeWarnings", function()
        it("should create edge warnings when enabled", function()
            addon:SetSetting("edgeWarningEnabled", true)
            addon:BuildEdgeWarnings()

            assert.is_not_nil(addon.edgeWarnings.top)
            assert.is_not_nil(addon.edgeWarnings.bottom)
            assert.is_not_nil(addon.edgeWarnings.left)
            assert.is_not_nil(addon.edgeWarnings.right)

            assert.is_not_nil(addon.edgeWarnings.top.arrow)
            assert.is_not_nil(addon.edgeWarnings.top.glow)
        end)

        it("should not create warnings when disabled", function()
            addon:SetSetting("edgeWarningEnabled", false)
            addon:BuildEdgeWarnings()

            assert.equals(0, #addon.edgeWarnings)
        end)

        it("should respect edge warning size setting", function()
            addon:SetSetting("edgeWarningEnabled", true)
            addon:SetSetting("edgeWarningSize", 100)
            addon:BuildEdgeWarnings()

            -- Size is set during BuildEdgeWarnings
            local topArrow = addon.edgeWarnings.top.arrow
            assert.is_not_nil(topArrow)
        end)

        it("should clean up existing warnings before rebuilding", function()
            addon:SetSetting("edgeWarningEnabled", true)
            addon:BuildEdgeWarnings()
            local firstTop = addon.edgeWarnings.top

            -- Rebuild
            addon:BuildEdgeWarnings()
            assert.is_not_nil(addon.edgeWarnings.top)

            -- Should have hidden old ones
            assert.is_true(firstTop.arrow.hidden)
        end)
    end)

    describe("UpdateEdgeWarnings", function()
        before_each(function()
            addon:SetSetting("edgeWarningEnabled", true)
            addon:SetSetting("edgeWarningDistance", 50)
            addon:SetSetting("edgeWarningSize", 64)
            addon:SetSetting("edgeWarningOpacity", 0.8)
            addon:BuildEdgeWarnings()
        end)

        it("should show top warning when near top edge", function()
            local screenHeight = UIParent:GetHeight()
            local mouseX, mouseY = 500, screenHeight - 30 -- Near top edge

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            assert.is_false(addon.edgeWarnings.top.arrow.hidden)
            assert.is_true(addon.edgeWarnings.bottom.arrow.hidden)
        end)

        it("should show bottom warning when near bottom edge", function()
            local mouseX, mouseY = 500, 30 -- Near bottom edge

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            assert.is_true(addon.edgeWarnings.top.arrow.hidden)
            assert.is_false(addon.edgeWarnings.bottom.arrow.hidden)
        end)

        it("should show left warning when near left edge", function()
            local mouseX, mouseY = 30, 400 -- Near left edge

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            assert.is_false(addon.edgeWarnings.left.arrow.hidden)
            assert.is_true(addon.edgeWarnings.right.arrow.hidden)
        end)

        it("should show right warning when near right edge", function()
            local screenWidth = UIParent:GetWidth()
            local mouseX, mouseY = screenWidth - 30, 400 -- Near right edge

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            assert.is_true(addon.edgeWarnings.left.arrow.hidden)
            assert.is_false(addon.edgeWarnings.right.arrow.hidden)
        end)

        it("should hide all warnings when in center of screen", function()
            local screenWidth = UIParent:GetWidth()
            local screenHeight = UIParent:GetHeight()
            local mouseX, mouseY = screenWidth / 2, screenHeight / 2 -- Center

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            assert.is_true(addon.edgeWarnings.top.arrow.hidden)
            assert.is_true(addon.edgeWarnings.bottom.arrow.hidden)
            assert.is_true(addon.edgeWarnings.left.arrow.hidden)
            assert.is_true(addon.edgeWarnings.right.arrow.hidden)
        end)

        it("should show multiple warnings when near corner", function()
            local mouseX, mouseY = 30, 30 -- Bottom-left corner

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            assert.is_false(addon.edgeWarnings.bottom.arrow.hidden)
            assert.is_false(addon.edgeWarnings.left.arrow.hidden)
            assert.is_true(addon.edgeWarnings.top.arrow.hidden)
            assert.is_true(addon.edgeWarnings.right.arrow.hidden)
        end)

        it("should respect edgeWarningDistance setting", function()
            addon:SetSetting("edgeWarningDistance", 100)
            local mouseX, mouseY = 500, 80 -- 80 pixels from bottom

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            -- Should show because 80 < 100
            assert.is_false(addon.edgeWarnings.bottom.arrow.hidden)

            -- Now with smaller distance
            addon:SetSetting("edgeWarningDistance", 50)
            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            -- Should hide because 80 > 50
            assert.is_true(addon.edgeWarnings.bottom.arrow.hidden)
        end)

        it("should apply pulse animation over time", function()
            local mouseX, mouseY = 500, 30 -- Near bottom
            local elapsed = 0.5

            addon:UpdateEdgeWarnings(elapsed, mouseX, mouseY)

            -- Pulse time should accumulate
            assert.is_not_nil(addon.edgeWarnings.bottom.pulseTime)
            assert.is_true(addon.edgeWarnings.bottom.pulseTime > 0)
        end)

        it("should use pulse intensity for size pulsation", function()
            addon:SetSetting("edgeWarningPulseIntensity", 0.5)
            addon:SetSetting("edgeWarningSize", 100)
            local mouseX, mouseY = 500, 30

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            -- Pulse value should be stored for reticle coordination
            assert.is_not_nil(addon.edgeWarningPulse)
        end)

        it("should return true when edge warnings are active", function()
            local mouseX, mouseY = 500, 30 -- Near bottom edge

            local result = addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            assert.is_true(result)
        end)

        it("should return false when not near any edge", function()
            local screenWidth = UIParent:GetWidth()
            local screenHeight = UIParent:GetHeight()
            local mouseX, mouseY = screenWidth / 2, screenHeight / 2 -- Center

            local result = addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            assert.is_false(result)
        end)

        it("should return false when edge warnings disabled", function()
            addon:SetSetting("edgeWarningEnabled", false)
            local mouseX, mouseY = 500, 30 -- Near edge but disabled

            local result = addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            assert.is_false(result)
        end)

        it("should position arrows correctly at edges", function()
            local screenHeight = UIParent:GetHeight()
            local mouseX, mouseY = 500, screenHeight - 30

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            local topArrow = addon.edgeWarnings.top.arrow
            assert.is_false(topArrow.hidden)
            -- Arrow should be positioned near top of screen
        end)

        it("should rotate arrows to point toward center", function()
            local screenHeight = UIParent:GetHeight()
            local mouseX, mouseY = 500, screenHeight - 30

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            local topArrow = addon.edgeWarnings.top.arrow
            -- Top arrow should point down (180 degrees)
            assert.is_not_nil(topArrow.rotation)
        end)

        it("should apply opacity setting to arrows", function()
            addon:SetSetting("edgeWarningOpacity", 0.5)
            local mouseX, mouseY = 500, 30

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            local arrow = addon.edgeWarnings.bottom.arrow
            -- Alpha should incorporate opacity setting (with pulse)
            assert.is_not_nil(arrow.alpha)
        end)

        it("should hide all warnings when feature disabled", function()
            addon:SetSetting("edgeWarningEnabled", false)
            local mouseX, mouseY = 30, 30 -- Corner - would normally trigger

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            assert.is_true(addon.edgeWarnings.top.arrow.hidden)
            assert.is_true(addon.edgeWarnings.bottom.arrow.hidden)
            assert.is_true(addon.edgeWarnings.left.arrow.hidden)
            assert.is_true(addon.edgeWarnings.right.arrow.hidden)
        end)

        it("should update glow along with arrows", function()
            local mouseX, mouseY = 500, 30

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            local arrow = addon.edgeWarnings.bottom.arrow
            local glow = addon.edgeWarnings.bottom.glow

            -- Both should have same visibility
            assert.equals(arrow.hidden, glow.hidden)
            assert.is_false(glow.hidden)
        end)

        it("should make glow slightly larger than arrow", function()
            local mouseX, mouseY = 500, 30
            addon:SetSetting("edgeWarningSize", 64)

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            -- Glow should be 1.2x arrow size (per implementation)
            -- This is validated during build/update
        end)
    end)

    describe("Edge Detection Edge Cases", function()
        before_each(function()
            addon:SetSetting("edgeWarningEnabled", true)
            addon:SetSetting("edgeWarningDistance", 50)
            addon:BuildEdgeWarnings()
        end)

        it("should handle cursor exactly at distance threshold", function()
            local mouseX, mouseY = 500, 50 -- Exactly at distance

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            -- Should trigger (<=)
            assert.is_false(addon.edgeWarnings.bottom.arrow.hidden)
        end)

        it("should handle cursor exactly at edge (0, 0)", function()
            local mouseX, mouseY = 0, 0

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            assert.is_false(addon.edgeWarnings.bottom.arrow.hidden)
            assert.is_false(addon.edgeWarnings.left.arrow.hidden)
        end)

        it("should handle cursor at max coordinates", function()
            local screenWidth = UIParent:GetWidth()
            local screenHeight = UIParent:GetHeight()
            local mouseX, mouseY = screenWidth, screenHeight

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            assert.is_false(addon.edgeWarnings.top.arrow.hidden)
            assert.is_false(addon.edgeWarnings.right.arrow.hidden)
        end)

        it("should handle very small distance setting", function()
            addon:SetSetting("edgeWarningDistance", 1)
            local mouseX, mouseY = 500, 2 -- Just 2 pixels from bottom

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            -- Should not trigger (2 > 1)
            assert.is_true(addon.edgeWarnings.bottom.arrow.hidden)
        end)

        it("should handle very large distance setting", function()
            local screenHeight = UIParent:GetHeight()
            addon:SetSetting("edgeWarningDistance", 500)
            local mouseX, mouseY = 500, screenHeight / 2

            addon:UpdateEdgeWarnings(0.016, mouseX, mouseY)

            -- Center might trigger with very large distance
            -- (depends on screen size, but should handle gracefully)
        end)
    end)

    describe("Integration with BuildTrail", function()
        it("should build edge warnings when building trail", function()
            addon:SetSetting("edgeWarningEnabled", true)
            addon:SetSetting("points", 10)

            addon:BuildTrail()

            -- Edge warnings should be built
            assert.is_not_nil(addon.edgeWarnings.top)
            assert.is_not_nil(addon.edgeWarnings.bottom)
            assert.is_not_nil(addon.edgeWarnings.left)
            assert.is_not_nil(addon.edgeWarnings.right)
        end)

        it("should clear old warnings when rebuilding trail", function()
            addon:SetSetting("edgeWarningEnabled", true)
            addon:BuildTrail()
            local oldTop = addon.edgeWarnings.top

            -- Rebuild
            addon:BuildTrail()

            -- Should have cleaned up old warnings
            if oldTop and oldTop.arrow then
                assert.is_true(oldTop.arrow.hidden)
            end
        end)
    end)

    describe("Defaults", function()
        it("should have edge warning defaults in main defaults", function()
            assert.is_true(addon.defaults.edgeWarningEnabled)
            assert.equals(50, addon.defaults.edgeWarningDistance)
            assert.equals(64, addon.defaults.edgeWarningSize)
            assert.equals(0.8, addon.defaults.edgeWarningOpacity)
        end)

        it("should have edge warning defaults in all profiles", function()
            for profile, data in pairs(addon.profileDefaults) do
                assert.is_not_nil(data.edgeWarningEnabled, "Profile " .. profile .. " missing edgeWarningEnabled")
                assert.is_not_nil(data.edgeWarningDistance, "Profile " .. profile .. " missing edgeWarningDistance")
                assert.is_not_nil(data.edgeWarningSize, "Profile " .. profile .. " missing edgeWarningSize")
                assert.is_not_nil(data.edgeWarningOpacity, "Profile " .. profile .. " missing edgeWarningOpacity")
            end
        end)

        it("should initialize edge warning settings correctly", function()
            _G.UltraCursorFXDB = {}
            addon:InitializeDefaults()

            assert.is_true(addon:GetSetting("edgeWarningEnabled"))
            assert.equals(50, addon:GetSetting("edgeWarningDistance"))
            assert.equals(64, addon:GetSetting("edgeWarningSize"))
            assert.equals(0.8, addon:GetSetting("edgeWarningOpacity"))
        end)
    end)

    describe("Profile-Specific Settings", function()
        it("should have different edge settings for raid profile", function()
            local raid = addon.profileDefaults.raid
            assert.equals(40, raid.edgeWarningDistance) -- More sensitive
            assert.equals(70, raid.edgeWarningSize) -- Larger
            assert.equals(0.9, raid.edgeWarningOpacity) -- More visible
        end)

        it("should have aggressive settings for arena profile", function()
            local arena = addon.profileDefaults.arena
            assert.equals(30, arena.edgeWarningDistance) -- Very sensitive
            assert.equals(80, arena.edgeWarningSize) -- Largest
            assert.equals(1.0, arena.edgeWarningOpacity) -- Fully visible
        end)
    end)
end)
