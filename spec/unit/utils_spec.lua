-- ===============================
-- Utils Module Tests
-- ===============================

local mocks = require("spec.wow_mocks")

describe("Utils Module", function()
    local addon

    before_each(function()
        mocks.ResetWoWMocks()
        require("Core")
        require("Utils")
        addon = UltraCursorFX
    end)

    describe("Lerp", function()
        it("should interpolate between two numbers", function()
            assert.are.equal(0, addon.Lerp(0, 10, 0))
            assert.are.equal(10, addon.Lerp(0, 10, 1))
            assert.are.equal(5, addon.Lerp(0, 10, 0.5))
            assert.are.equal(7.5, addon.Lerp(0, 10, 0.75))
        end)

        it("should work with negative numbers", function()
            assert.are.equal(-5, addon.Lerp(-10, 0, 0.5))
            assert.are.equal(0, addon.Lerp(-10, 10, 0.5))
        end)
    end)

    describe("HSVtoRGB", function()
        it("should convert red (H=0)", function()
            local r, g, b = addon.HSVtoRGB(0, 1, 1)
            assert.are.equal(1, r)
            assert.are.equal(0, g)
            assert.are.equal(0, b)
        end)

        it("should convert cyan (H=0.5)", function()
            local r, g, b = addon.HSVtoRGB(0.5, 1, 1)
            assert.are.equal(0, r)
            assert.are.equal(1, g)
            assert.are.equal(1, b)
        end)

        it("should handle saturation", function()
            local r, g, b = addon.HSVtoRGB(0, 0, 1)
            assert.are.equal(1, r)
            assert.are.equal(1, g)
            assert.are.equal(1, b)
        end)

        it("should handle value/brightness", function()
            local r, g, b = addon.HSVtoRGB(0, 1, 0.5)
            assert.are.equal(0.5, r)
            assert.are.equal(0, g)
            assert.are.equal(0, b)
        end)

        it("should convert yellow (H=0.16)", function()
            local r, g, b = addon.HSVtoRGB(0.16, 1, 1)
            -- Should be in yellow range (i=0 or i=1)
            assert.is_true(r > 0.5)
            assert.is_true(g > 0.5)
        end)

        it("should convert green (H=0.33)", function()
            local r, g, b = addon.HSVtoRGB(0.33, 1, 1)
            -- Should be in green range (i=2)
            assert.is_true(g > 0.8)
        end)

        it("should convert blue (H=0.66)", function()
            local r, g, b = addon.HSVtoRGB(0.66, 1, 1)
            -- Should be in blue range (i=4)
            assert.is_true(b > 0.5)
        end)

        it("should convert magenta (H=0.83)", function()
            local r, g, b = addon.HSVtoRGB(0.83, 1, 1)
            -- Should be in magenta range (i=5)
            assert.is_true(r > 0.5)
            assert.is_true(b > 0.5)
        end)

        it("should handle full color wheel", function()
            -- Test all 6 segments of the color wheel
            for i = 0, 5 do
                local h = i / 6
                local r, g, b = addon.HSVtoRGB(h, 1, 1)
                -- All should return valid RGB values
                assert.is_true(r >= 0 and r <= 1)
                assert.is_true(g >= 0 and g <= 1)
                assert.is_true(b >= 0 and b <= 1)
            end
        end)
    end)

    describe("Base64", function()
        it("should encode simple strings", function()
            local encoded = addon.Base64Encode("hello")
            assert.is_string(encoded)
            assert.is_true(#encoded > 0)
        end)

        it("should decode encoded strings", function()
            local original = "test123"
            local encoded = addon.Base64Encode(original)
            local decoded = addon.Base64Decode(encoded)
            assert.are.equal(original, decoded)
        end)

        it("should handle complex data", function()
            local original = "color=1.0,0.5,0.0;points=50;enabled=true"
            local encoded = addon.Base64Encode(original)
            local decoded = addon.Base64Decode(encoded)
            assert.are.equal(original, decoded)
        end)
        it("should handle invalid base64 strings", function()
            local decoded = addon.Base64Decode("!!!invalid!!!")
            -- Should handle gracefully
            assert.is_not_nil(decoded)
        end)

        it("should handle empty base64 string", function()
            local decoded = addon.Base64Decode("")
            assert.are.equal("", decoded)
        end)
    end)

    describe("SerializeValue", function()
        it("should serialize numbers", function()
            assert.are.equal("42", addon.SerializeValue(42))
            assert.are.equal("3.14", addon.SerializeValue(3.14))
        end)

        it("should serialize booleans", function()
            assert.are.equal("1", addon.SerializeValue(true))
            assert.are.equal("0", addon.SerializeValue(false))
        end)

        it("should serialize strings", function()
            assert.are.equal("test", addon.SerializeValue("test"))
        end)

        it("should serialize tables as comma-separated values", function()
            assert.are.equal("1,2,3", addon.SerializeValue({ 1, 2, 3 }))
            assert.are.equal("1,0.5,0", addon.SerializeValue({ 1.0, 0.5, 0.0 }))
        end)

        it("should return empty string for nil", function()
            assert.are.equal("", addon.SerializeValue(nil))
        end)

        it("should handle empty tables", function()
            assert.are.equal("", addon.SerializeValue({}))
        end)
    end)

    describe("DeserializeValue", function()
        it("should deserialize numbers", function()
            assert.are.equal(42, addon.DeserializeValue("42", "number"))
            assert.are.equal(3.14, addon.DeserializeValue("3.14", "number"))
        end)

        it("should deserialize booleans", function()
            assert.is_true(addon.DeserializeValue("1", "boolean"))
            assert.is_true(addon.DeserializeValue("true", "boolean"))
            assert.is_false(addon.DeserializeValue("0", "boolean"))
            assert.is_false(addon.DeserializeValue("false", "boolean"))
        end)

        it("should deserialize strings", function()
            assert.are.equal("test", addon.DeserializeValue("test", "string"))
        end)

        it("should deserialize tables", function()
            local result = addon.DeserializeValue("1,2,3", "table")
            assert.are.same({ 1, 2, 3 }, result)
        end)

        it("should return nil for unknown types", function()
            local result = addon.DeserializeValue("test", "unknowntype")
            assert.is_nil(result)
        end)
    end)

    describe("Export/Import Settings", function()
        before_each(function()
            _G.UltraCursorFXDB = {
                enabled = true,
                flashEnabled = false,
                points = 60,
                size = 40,
                color = { 1.0, 0.5, 0.0 },
                particleShape = "spark",
                rainbowMode = true,
            }
        end)

        it("should export settings as valid string", function()
            local exported = addon:ExportSettings()
            assert.is_string(exported)
            assert.is_not_nil(exported:match("^UCFX:"))
            assert.is_true(#exported > 5) -- More than just "UCFX:"
        end)

        it("should export and import settings correctly", function()
            local exported = addon:ExportSettings()

            -- Clear DB
            _G.UltraCursorFXDB = {}

            -- Import
            local success, message = addon:ImportSettings(exported)
            assert.is_true(success)
            assert.is_string(message)

            -- Verify values
            assert.is_true(_G.UltraCursorFXDB.enabled)
            assert.is_false(_G.UltraCursorFXDB.flashEnabled)
            assert.are.equal(60, _G.UltraCursorFXDB.points)
            assert.are.equal(40, _G.UltraCursorFXDB.size)
            assert.are.same({ 1, 0.5, 0 }, _G.UltraCursorFXDB.color)
            assert.are.equal("spark", _G.UltraCursorFXDB.particleShape)
            assert.is_true(_G.UltraCursorFXDB.rainbowMode)
        end)

        it("should reject invalid import strings", function()
            local success, message = addon:ImportSettings("")
            assert.is_false(success)
            assert.is_string(message)
        end)

        it("should reject malformed import strings", function()
            local success, message = addon:ImportSettings("invalid")
            assert.is_false(success)
            assert.is_string(message)
        end)

        it("should handle import string without UCFX: prefix", function()
            local success, message = addon:ImportSettings("SGVsbG8gV29ybGQ=")
            assert.is_false(success)
            assert.is_not_nil(message:find("UCFX:"))
        end)

        it("should handle corrupted base64 in import string", function()
            local success, message = addon:ImportSettings("UCFX:!!!invalid!!!")
            assert.is_false(success)
            assert.is_string(message)
        end)

        it("should handle partial settings import", function()
            -- Export minimal settings
            _G.UltraCursorFXDB = {
                enabled = true,
                points = 50,
                -- Missing most other settings
            }
            
            local exported = addon:ExportSettings()
            _G.UltraCursorFXDB = {}
            
            local success, message = addon:ImportSettings(exported)
            
            -- Should succeed and note may be from older version
            assert.is_true(success)
            assert.is_string(message)
        end)
    end)
end)
