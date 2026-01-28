-- ===============================
-- Migration Tests - Critical for User Data Safety
-- ===============================

describe("Profile Migration (User Data Safety)", function()
    local addon
    local mocks

    before_each(function()
        -- Reset state
        _G.UltraCursorFXDB = nil
        _G.UltraCursorFX = nil
        package.loaded["Core"] = nil
        package.loaded["Profiles"] = nil

        mocks = require("spec/wow_mocks")
        mocks.ResetWoWMocks()
    end)

    describe("First Character Login with Old Data", function()
        it("should migrate old flat settings to account-wide on first login", function()
            -- Simulate user who has been using the addon with the old structure
            _G.UltraCursorFXDB = {
                enabled = true,
                flashEnabled = false,
                color = { 1.0, 0.5, 0.2 }, -- Custom color
                points = 64, -- Custom
                size = 45, -- Custom
                glowSize = 80, -- Custom
                rainbowMode = true, -- Custom
                clickEffects = false, -- Custom
                particleShape = "skull", -- Custom
                cometMode = true, -- Custom
                -- Old profile system
                profiles = {
                    world = {
                        color = { 0.8, 0.3, 0.1 },
                        points = 72,
                    },
                    raid = {
                        color = { 1.0, 0.0, 0.0 },
                        points = 40,
                    },
                },
                situationalEnabled = true,
            }

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            -- Simulate first character login
            addon:InitializeDefaults()
            addon:MigrateProfiles()

            -- Verify account-wide settings were created
            assert.is_not_nil(UltraCursorFXDB.account)
            assert.is_not_nil(UltraCursorFXDB.characters)

            -- Verify custom settings migrated to account
            assert.are.same({ 1.0, 0.5, 0.2 }, UltraCursorFXDB.account.color)
            assert.are.equal(64, UltraCursorFXDB.account.points)
            assert.are.equal(45, UltraCursorFXDB.account.size)
            assert.are.equal(80, UltraCursorFXDB.account.glowSize)
            assert.is_true(UltraCursorFXDB.account.rainbowMode)
            assert.is_false(UltraCursorFXDB.account.clickEffects)
            assert.are.equal("skull", UltraCursorFXDB.account.particleShape)
            assert.is_true(UltraCursorFXDB.account.cometMode)

            -- Verify old profiles migrated to account.profiles
            assert.is_not_nil(UltraCursorFXDB.account.profiles.world)
            assert.are.same({ 0.8, 0.3, 0.1 }, UltraCursorFXDB.account.profiles.world.color)
            assert.are.equal(72, UltraCursorFXDB.account.profiles.world.points)

            assert.is_not_nil(UltraCursorFXDB.account.profiles.raid)
            assert.are.same({ 1.0, 0.0, 0.0 }, UltraCursorFXDB.account.profiles.raid.color)
            assert.are.equal(40, UltraCursorFXDB.account.profiles.raid.points)

            -- Verify character was created with account-wide flag
            local charKey = addon:GetCharacterKey()
            assert.is_not_nil(UltraCursorFXDB.characters[charKey])
            assert.is_true(UltraCursorFXDB.characters[charKey].useAccountSettings)

            -- Verify old structure was cleaned up
            assert.is_nil(UltraCursorFXDB.profiles)

            -- Verify migration flag was set
            assert.is_true(UltraCursorFXDB.profilesMigrated)
        end)

        it("should migrate VERY OLD data (before situational profiles existed)", function()
            -- Simulate user from the very first version (no profiles at all, only flat settings)
            _G.UltraCursorFXDB = {
                enabled = true,
                flashEnabled = true,
                color = { 0.5, 0.8, 0.3 }, -- Custom color
                points = 72, -- Custom
                size = 50, -- Custom
                glowSize = 90, -- Custom
                smoothness = 0.25,
                pulseSpeed = 3.0,
                rainbowMode = false,
                rainbowSpeed = 1.5,
                clickEffects = true,
                clickParticles = 15,
                clickSize = 60,
                clickDuration = 0.8,
                particleShape = "circle",
                cometMode = false,
                cometLength = 3.0,
                -- NO profiles key at all - user never enabled situational profiles
            }

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            addon:InitializeDefaults()
            addon:MigrateProfiles()

            -- Verify all custom settings migrated to account
            assert.are.same({ 0.5, 0.8, 0.3 }, UltraCursorFXDB.account.color)
            assert.are.equal(72, UltraCursorFXDB.account.points)
            assert.are.equal(50, UltraCursorFXDB.account.size)
            assert.are.equal(90, UltraCursorFXDB.account.glowSize)
            assert.are.equal(0.25, UltraCursorFXDB.account.smoothness)
            assert.are.equal(3.0, UltraCursorFXDB.account.pulseSpeed)
            assert.is_false(UltraCursorFXDB.account.rainbowMode)
            assert.are.equal(1.5, UltraCursorFXDB.account.rainbowSpeed)
            assert.is_true(UltraCursorFXDB.account.clickEffects)
            assert.are.equal(15, UltraCursorFXDB.account.clickParticles)
            assert.are.equal(60, UltraCursorFXDB.account.clickSize)
            assert.are.equal(0.8, UltraCursorFXDB.account.clickDuration)
            assert.are.equal("circle", UltraCursorFXDB.account.particleShape)
            assert.is_false(UltraCursorFXDB.account.cometMode)
            assert.are.equal(3.0, UltraCursorFXDB.account.cometLength)

            -- Verify default profiles were created (even though user never had profiles)
            assert.is_not_nil(UltraCursorFXDB.account.profiles.world)
            assert.is_not_nil(UltraCursorFXDB.account.profiles.raid)
            assert.is_not_nil(UltraCursorFXDB.account.profiles.dungeon)
            assert.is_not_nil(UltraCursorFXDB.account.profiles.arena)
            assert.is_not_nil(UltraCursorFXDB.account.profiles.battleground)

            -- Verify character tracking works
            local charKey = addon:GetCharacterKey()
            assert.is_not_nil(UltraCursorFXDB.characters[charKey])
            assert.is_true(UltraCursorFXDB.characters[charKey].useAccountSettings)
            assert.is_number(UltraCursorFXDB.characters[charKey].lastLogin)

            -- Verify migration flag was set
            assert.is_true(UltraCursorFXDB.profilesMigrated)

            -- Verify backward compatibility - flat structure should be synced
            assert.are.same({ 0.5, 0.8, 0.3 }, UltraCursorFXDB.color)
            assert.are.equal(72, UltraCursorFXDB.points)
        end)

        it("should preserve all default profiles after migration", function()
            _G.UltraCursorFXDB = {
                color = { 1.0, 0.0, 0.0 },
                points = 100,
            }

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            addon:InitializeDefaults()
            addon:MigrateProfiles()

            -- All 5 default profiles should exist
            assert.is_not_nil(UltraCursorFXDB.account.profiles.world)
            assert.is_not_nil(UltraCursorFXDB.account.profiles.raid)
            assert.is_not_nil(UltraCursorFXDB.account.profiles.dungeon)
            assert.is_not_nil(UltraCursorFXDB.account.profiles.arena)
            assert.is_not_nil(UltraCursorFXDB.account.profiles.battleground)
        end)

        it("should handle migration with no custom settings (fresh defaults)", function()
            -- User who never customized anything
            _G.UltraCursorFXDB = {}

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            addon:InitializeDefaults()
            addon:MigrateProfiles()

            -- Should create account structure
            assert.is_not_nil(UltraCursorFXDB.account)
            assert.is_not_nil(UltraCursorFXDB.characters)

            -- Should have default values in account
            assert.is_true(UltraCursorFXDB.account.enabled)
            assert.are.same({ 0.0, 1.0, 1.0 }, UltraCursorFXDB.account.color)
            assert.are.equal(48, UltraCursorFXDB.account.points)

            -- Should create default profiles
            assert.is_not_nil(UltraCursorFXDB.account.profiles.world)
        end)
    end)

    describe("Second Character Login", function()
        it("should use account-wide settings on second character login", function()
            -- Simulate first character already migrated
            _G.UltraCursorFXDB = {
                account = {
                    enabled = true,
                    color = { 1.0, 0.5, 0.2 },
                    points = 64,
                    size = 45,
                    profiles = {
                        world = {
                            color = { 0.8, 0.3, 0.1 },
                            points = 72,
                        },
                    },
                },
                characters = {
                    ["FirstChar-TestRealm"] = {
                        useAccountSettings = true,
                        lastLogin = os.time() - 3600, -- 1 hour ago
                    },
                },
                profilesMigrated = true,
            }

            -- Mock second character
            _G.UnitName = function(unit)
                if unit == "player" then
                    return "SecondChar"
                end
                return "Unknown"
            end

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            addon:InitializeDefaults()
            addon:MigrateProfiles()

            -- Second character should be created
            local charKey = addon:GetCharacterKey()
            assert.are.equal("SecondChar-TestRealm", charKey)
            assert.is_not_nil(UltraCursorFXDB.characters[charKey])

            -- Should default to account-wide settings
            assert.is_true(UltraCursorFXDB.characters[charKey].useAccountSettings)

            -- Should NOT have character-specific profiles
            assert.is_nil(UltraCursorFXDB.characters[charKey].profiles)

            -- GetSetting should return account values
            assert.are.equal(64, addon:GetSetting("points"))
            assert.are.same({ 1.0, 0.5, 0.2 }, addon:GetSetting("color"))

            -- GetActiveProfileTable should return account profiles
            local profiles = addon:GetActiveProfileTable()
            assert.are.same({ 0.8, 0.3, 0.1 }, profiles.world.color)
            assert.are.equal(72, profiles.world.points)
        end)

        it("should track login time for multiple characters", function()
            local now = os.time()

            _G.UltraCursorFXDB = {
                account = { enabled = true },
                characters = {
                    ["FirstChar-TestRealm"] = {
                        useAccountSettings = true,
                        lastLogin = now - 86400, -- 1 day ago
                    },
                },
                profilesMigrated = true,
            }

            _G.UnitName = function(unit)
                if unit == "player" then
                    return "SecondChar"
                end
                return "Unknown"
            end

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            addon:InitializeDefaults()
            addon:MigrateProfiles()

            local charList = addon:GetCharacterList()

            -- Should have 2 characters
            assert.are.equal(2, #charList)

            -- Most recent should be first (sorted by lastLogin)
            assert.are.equal("SecondChar-TestRealm", charList[1].key)
            assert.are.equal("FirstChar-TestRealm", charList[2].key)
        end)
    end)

    describe("Migration Edge Cases", function()
        it("should handle partial old data structure", function()
            _G.UltraCursorFXDB = {
                color = { 1.0, 0.0, 0.0 },
                -- Missing most other settings
            }

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            addon:InitializeDefaults()
            addon:MigrateProfiles()

            -- Should migrate the one custom setting
            assert.are.same({ 1.0, 0.0, 0.0 }, UltraCursorFXDB.account.color)

            -- Should fill in defaults for missing settings
            assert.are.equal(48, addon:GetSetting("points"))
            assert.is_true(addon:GetSetting("enabled"))
        end)

        it("should not re-migrate if already migrated", function()
            _G.UltraCursorFXDB = {
                account = {
                    color = { 0.5, 0.5, 0.5 }, -- Already migrated value
                    points = 80,
                },
                characters = {
                    ["TestCharacter-TestRealm"] = {
                        useAccountSettings = true,
                        lastLogin = os.time(),
                    },
                },
                profilesMigrated = true, -- Already migrated
                -- Old data still present (shouldn't be used)
                color = { 1.0, 0.0, 0.0 },
                points = 100,
            }

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            addon:MigrateProfiles()

            -- Should keep migrated account values, not re-migrate
            assert.are.same({ 0.5, 0.5, 0.5 }, UltraCursorFXDB.account.color)
            assert.are.equal(80, UltraCursorFXDB.account.points)
        end)

        it("should handle corrupted old profiles gracefully", function()
            _G.UltraCursorFXDB = {
                profiles = {
                    world = nil, -- Corrupted
                    raid = "not a table", -- Corrupted
                    dungeon = {}, -- Empty
                },
            }

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            addon:InitializeDefaults()
            addon:MigrateProfiles()

            -- Should still create valid default profiles
            assert.is_table(UltraCursorFXDB.account.profiles.world)
            assert.is_table(UltraCursorFXDB.account.profiles.raid)
            assert.is_table(UltraCursorFXDB.account.profiles.dungeon)
            assert.is_table(UltraCursorFXDB.account.profiles.arena)
            assert.is_table(UltraCursorFXDB.account.profiles.battleground)
        end)
    end)

    describe("Backwards Compatibility", function()
        it("should maintain flat structure for existing code", function()
            _G.UltraCursorFXDB = {
                color = { 1.0, 0.5, 0.0 },
                points = 75,
            }

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            addon:InitializeDefaults()
            addon:MigrateProfiles()

            -- Flat structure should still be accessible
            assert.are.same({ 1.0, 0.5, 0.0 }, UltraCursorFXDB.color)
            assert.are.equal(75, UltraCursorFXDB.points)

            -- And should match account settings
            assert.are.same(UltraCursorFXDB.color, UltraCursorFXDB.account.color)
            assert.are.equal(UltraCursorFXDB.points, UltraCursorFXDB.account.points)
        end)

        it("should keep flat structure in sync when using SetSetting", function()
            _G.UltraCursorFXDB = {}

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            addon:InitializeDefaults()
            addon:MigrateProfiles()

            -- Change via SetSetting
            addon:SetSetting("points", 120)

            -- Both should be updated
            assert.are.equal(120, UltraCursorFXDB.account.points)
            assert.are.equal(120, UltraCursorFXDB.points)
        end)
    end)

    describe("Character-Specific Profile Creation", function()
        it("should copy account profiles when switching to character-specific", function()
            _G.UltraCursorFXDB = {
                account = {
                    enabled = true,
                    profiles = {
                        world = {
                            color = { 1.0, 0.0, 0.0 },
                            points = 60,
                        },
                        raid = {
                            color = { 0.0, 1.0, 0.0 },
                            points = 40,
                        },
                    },
                },
                characters = {
                    ["TestCharacter-TestRealm"] = {
                        useAccountSettings = true,
                    },
                },
                profilesMigrated = true,
            }

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            -- Switch to character-specific
            addon:SetUseAccountSettings(false)

            local charKey = addon:GetCharacterKey()

            -- Should have created character profiles
            assert.is_not_nil(UltraCursorFXDB.characters[charKey].profiles)
            assert.is_not_nil(UltraCursorFXDB.characters[charKey].profiles.world)
            assert.is_not_nil(UltraCursorFXDB.characters[charKey].profiles.raid)

            -- Should be a copy, not reference
            assert.are.same({ 1.0, 0.0, 0.0 }, UltraCursorFXDB.characters[charKey].profiles.world.color)

            -- Modify character profile
            UltraCursorFXDB.characters[charKey].profiles.world.color[1] = 0.5

            -- Account profile should be unchanged
            assert.are.equal(1.0, UltraCursorFXDB.account.profiles.world.color[1])
        end)
    end)
end)
