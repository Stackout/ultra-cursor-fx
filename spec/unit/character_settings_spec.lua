-- ===============================
-- Character Settings Tests
-- Tests for account-wide vs character-specific settings
-- ===============================

describe("Character Settings (Account-Wide vs Character-Specific)", function()
    local addon
    local mocks

    before_each(function()
        mocks = require("spec.wow_mocks")
        mocks.ResetWoWMocks()
    end)

    describe("GetSetting and SetSetting", function()
        it("should read from account when useAccountSettings is true", function()
            _G.UltraCursorFXDB = {
                account = {
                    color = { 1.0, 0.5, 0.2 },
                    points = 100,
                    rainbowMode = true,
                },
                characters = {
                    ["TestCharacter-TestRealm"] = {
                        useAccountSettings = true,
                        lastLogin = os.time(),
                    },
                },
            }

            require("Core")
            addon = UltraCursorFX

            -- Should read from account
            assert.are.same({ 1.0, 0.5, 0.2 }, addon:GetSetting("color"))
            assert.are.equal(100, addon:GetSetting("points"))
            assert.is_true(addon:GetSetting("rainbowMode"))
        end)

        it("should read from character when useAccountSettings is false", function()
            _G.UltraCursorFXDB = {
                account = {
                    color = { 1.0, 0.5, 0.2 },
                    points = 100,
                },
                characters = {
                    ["TestCharacter-TestRealm"] = {
                        useAccountSettings = false,
                        color = { 0.0, 1.0, 0.0 }, -- Character-specific green
                        points = 200, -- Character-specific
                        lastLogin = os.time(),
                    },
                },
            }

            require("Core")
            addon = UltraCursorFX

            -- Should read from character, not account
            assert.are.same({ 0.0, 1.0, 0.0 }, addon:GetSetting("color"))
            assert.are.equal(200, addon:GetSetting("points"))
        end)

        it("should write to account when useAccountSettings is true", function()
            _G.UltraCursorFXDB = {
                account = {},
                characters = {
                    ["TestCharacter-TestRealm"] = {
                        useAccountSettings = true,
                        lastLogin = os.time(),
                    },
                },
            }

            require("Core")
            addon = UltraCursorFX

            addon:SetSetting("color", { 1.0, 0.0, 1.0 })
            addon:SetSetting("points", 150)

            -- Should be written to account
            assert.are.same({ 1.0, 0.0, 1.0 }, UltraCursorFXDB.account.color)
            assert.are.equal(150, UltraCursorFXDB.account.points)
        end)

        it("should write to character when useAccountSettings is false", function()
            _G.UltraCursorFXDB = {
                account = {},
                characters = {
                    ["TestCharacter-TestRealm"] = {
                        useAccountSettings = false,
                        lastLogin = os.time(),
                    },
                },
            }

            require("Core")
            addon = UltraCursorFX

            addon:SetSetting("color", { 0.5, 0.5, 1.0 })
            addon:SetSetting("points", 250)

            local charKey = addon:GetCharacterKey()

            -- Should be written to character, not account
            assert.are.same({ 0.5, 0.5, 1.0 }, UltraCursorFXDB.characters[charKey].color)
            assert.are.equal(250, UltraCursorFXDB.characters[charKey].points)

            -- Account should be empty
            assert.is_nil(UltraCursorFXDB.account.color)
            assert.is_nil(UltraCursorFXDB.account.points)
        end)

        it("should fall back to defaults when setting not found", function()
            _G.UltraCursorFXDB = {
                account = {},
                characters = {
                    ["TestCharacter-TestRealm"] = {
                        useAccountSettings = true,
                        lastLogin = os.time(),
                    },
                },
            }

            require("Core")
            addon = UltraCursorFX

            -- Should get defaults
            assert.are.same({ 0.0, 1.0, 1.0 }, addon:GetSetting("color"))
            assert.are.equal(48, addon:GetSetting("points"))
            assert.are.equal(34, addon:GetSetting("size"))
        end)
    end)

    describe("Switching Between Account and Character Settings", function()
        it("should create character profiles when switching from account to character-specific", function()
            _G.UltraCursorFXDB = {
                account = {
                    color = { 1.0, 0.0, 0.0 },
                    points = 60,
                    profiles = {
                        world = {
                            name = "World",
                            color = { 0.0, 1.0, 1.0 },
                            points = 48,
                        },
                        raid = {
                            name = "Raid",
                            color = { 1.0, 0.0, 0.0 },
                            points = 40,
                        },
                    },
                },
                characters = {
                    ["TestCharacter-TestRealm"] = {
                        useAccountSettings = true,
                        lastLogin = os.time(),
                    },
                },
                profilesMigrated = true,
            }

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            local charKey = addon:GetCharacterKey()

            -- Switch to character-specific
            addon:SetUseAccountSettings(false)

            -- Should have copied profiles
            assert.is_not_nil(UltraCursorFXDB.characters[charKey].profiles)
            assert.is_not_nil(UltraCursorFXDB.characters[charKey].profiles.world)
            assert.is_not_nil(UltraCursorFXDB.characters[charKey].profiles.raid)

            -- Should be deep copies
            assert.are.same({ 0.0, 1.0, 1.0 }, UltraCursorFXDB.characters[charKey].profiles.world.color)
            assert.are.equal(48, UltraCursorFXDB.characters[charKey].profiles.world.points)

            -- Modifying character profile shouldn't affect account
            UltraCursorFXDB.characters[charKey].profiles.world.color[1] = 0.5
            assert.are.equal(0.0, UltraCursorFXDB.account.profiles.world.color[1])
        end)

        it("should switch back to account settings without losing character data", function()
            _G.UltraCursorFXDB = {
                account = {
                    color = { 1.0, 0.0, 0.0 },
                    points = 60,
                },
                characters = {
                    ["TestCharacter-TestRealm"] = {
                        useAccountSettings = false,
                        color = { 0.0, 1.0, 0.0 }, -- Character's unique green
                        points = 200,
                        lastLogin = os.time(),
                    },
                },
                profilesMigrated = true,
            }

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            local charKey = addon:GetCharacterKey()

            -- Initially using character settings
            assert.are.same({ 0.0, 1.0, 0.0 }, addon:GetSetting("color"))
            assert.are.equal(200, addon:GetSetting("points"))

            -- Switch to account
            addon:SetUseAccountSettings(true)

            -- Should now read from account
            assert.are.same({ 1.0, 0.0, 0.0 }, addon:GetSetting("color"))
            assert.are.equal(60, addon:GetSetting("points"))

            -- Character data should still exist
            assert.are.same({ 0.0, 1.0, 0.0 }, UltraCursorFXDB.characters[charKey].color)
            assert.are.equal(200, UltraCursorFXDB.characters[charKey].points)
        end)

        it("should handle toggling back and forth multiple times", function()
            _G.UltraCursorFXDB = {
                account = {
                    color = { 1.0, 0.0, 0.0 },
                },
                characters = {
                    ["TestCharacter-TestRealm"] = {
                        useAccountSettings = true,
                        lastLogin = os.time(),
                    },
                },
            }

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            -- Start with account
            assert.are.same({ 1.0, 0.0, 0.0 }, addon:GetSetting("color"))

            -- Toggle to character
            addon:SetUseAccountSettings(false)
            addon:SetSetting("color", { 0.0, 1.0, 0.0 })
            assert.are.same({ 0.0, 1.0, 0.0 }, addon:GetSetting("color"))

            -- Toggle back to account
            addon:SetUseAccountSettings(true)
            assert.are.same({ 1.0, 0.0, 0.0 }, addon:GetSetting("color"))

            -- Toggle to character again
            addon:SetUseAccountSettings(false)
            assert.are.same({ 0.0, 1.0, 0.0 }, addon:GetSetting("color")) -- Preserved!
        end)
    end)

    describe("Multiple Characters with Different Settings", function()
        it("should isolate settings between characters using GetSettingForCharacter", function()
            _G.UltraCursorFXDB = {
                account = {
                    color = { 1.0, 1.0, 1.0 }, -- White (account default)
                    points = 48,
                },
                characters = {
                    ["Warrior-Stormrage"] = {
                        useAccountSettings = true, -- Uses account
                        lastLogin = os.time(),
                    },
                    ["Mage-Stormrage"] = {
                        useAccountSettings = false, -- Has own settings
                        color = { 1.0, 0.0, 1.0 }, -- Pink
                        points = 200,
                        lastLogin = os.time(),
                    },
                },
            }

            require("Core")
            addon = UltraCursorFX

            -- Warrior uses account (white, 48)
            assert.are.same({ 1.0, 1.0, 1.0 }, addon:GetSettingForCharacter("Warrior-Stormrage", "color"))
            assert.are.equal(48, addon:GetSettingForCharacter("Warrior-Stormrage", "points"))

            -- Mage uses character-specific (pink, 200)
            assert.are.same({ 1.0, 0.0, 1.0 }, addon:GetSettingForCharacter("Mage-Stormrage", "color"))
            assert.are.equal(200, addon:GetSettingForCharacter("Mage-Stormrage", "points"))
        end)

        it("should share account settings between opted-in characters", function()
            _G.UltraCursorFXDB = {
                account = {
                    color = { 0.5, 0.5, 0.5 },
                    points = 75,
                },
                characters = {
                    ["Warrior-Stormrage"] = {
                        useAccountSettings = true,
                        lastLogin = os.time(),
                    },
                    ["Rogue-Stormrage"] = {
                        useAccountSettings = true,
                        lastLogin = os.time(),
                    },
                },
            }

            require("Core")
            addon = UltraCursorFX

            -- Both characters should read the same account values
            local warriorColor = addon:GetSettingForCharacter("Warrior-Stormrage", "color")
            local warriorPoints = addon:GetSettingForCharacter("Warrior-Stormrage", "points")

            local rogueColor = addon:GetSettingForCharacter("Rogue-Stormrage", "color")
            local roguePoints = addon:GetSettingForCharacter("Rogue-Stormrage", "points")

            assert.are.same(warriorColor, rogueColor)
            assert.are.equal(warriorPoints, roguePoints)
        end)
    end)

    describe("GetSettingForCharacter (Viewing Other Characters)", function()
        it("should get account settings for character using account-wide", function()
            _G.UltraCursorFXDB = {
                account = {
                    color = { 1.0, 0.0, 0.0 },
                    points = 100,
                },
                characters = {
                    ["Warrior-Stormrage"] = {
                        useAccountSettings = true,
                        lastLogin = os.time(),
                    },
                },
            }

            require("Core")
            addon = UltraCursorFX

            -- View Warrior's settings
            assert.are.same({ 1.0, 0.0, 0.0 }, addon:GetSettingForCharacter("Warrior-Stormrage", "color"))
            assert.are.equal(100, addon:GetSettingForCharacter("Warrior-Stormrage", "points"))
        end)

        it("should get character-specific settings when available", function()
            _G.UltraCursorFXDB = {
                account = {
                    color = { 1.0, 0.0, 0.0 },
                    points = 100,
                },
                characters = {
                    ["Mage-Stormrage"] = {
                        useAccountSettings = false,
                        color = { 0.0, 0.0, 1.0 }, -- Blue
                        points = 300,
                        lastLogin = os.time(),
                    },
                },
            }

            require("Core")
            addon = UltraCursorFX

            -- View Mage's settings (should be character-specific, not account)
            assert.are.same({ 0.0, 0.0, 1.0 }, addon:GetSettingForCharacter("Mage-Stormrage", "color"))
            assert.are.equal(300, addon:GetSettingForCharacter("Mage-Stormrage", "points"))
        end)

        it("should return account or defaults for non-existent character", function()
            _G.UltraCursorFXDB = {
                account = {
                    color = { 1.0, 0.0, 0.0 },
                },
                characters = {},
            }

            require("Core")
            addon = UltraCursorFX

            -- Non-existent character should get account values
            assert.are.same({ 1.0, 0.0, 0.0 }, addon:GetSettingForCharacter("NonExistent-Realm", "color"))
        end)

        it("should return defaults for non-existent character when account has no value", function()
            _G.UltraCursorFXDB = {
                account = {},
                characters = {},
            }

            require("Core")
            addon = UltraCursorFX

            -- Non-existent character with no account value should get defaults
            assert.are.same(addon.defaults.color, addon:GetSettingForCharacter("NonExistent-Realm", "color"))
            assert.are.equal(addon.defaults.points, addon:GetSettingForCharacter("NonExistent-Realm", "points"))
        end)
    end)

    describe("Profile System with Character-Specific Settings", function()
        it("should use character profiles when not using account settings", function()
            _G.UltraCursorFXDB = {
                account = {
                    profiles = {
                        raid = {
                            color = { 1.0, 0.0, 0.0 },
                            points = 40,
                        },
                    },
                },
                characters = {
                    ["TestCharacter-TestRealm"] = {
                        useAccountSettings = false,
                        profiles = {
                            raid = {
                                color = { 0.0, 1.0, 1.0 }, -- Character's unique raid profile
                                points = 100,
                            },
                        },
                        lastLogin = os.time(),
                    },
                },
                profilesMigrated = true,
            }

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            -- Should return character's profiles
            local profiles = addon:GetActiveProfileTable()
            assert.are.same({ 0.0, 1.0, 1.0 }, profiles.raid.color)
            assert.are.equal(100, profiles.raid.points)
        end)

        it("should use account profiles when using account settings", function()
            _G.UltraCursorFXDB = {
                account = {
                    profiles = {
                        raid = {
                            color = { 1.0, 0.0, 0.0 },
                            points = 40,
                        },
                    },
                },
                characters = {
                    ["TestCharacter-TestRealm"] = {
                        useAccountSettings = true,
                        lastLogin = os.time(),
                    },
                },
                profilesMigrated = true,
            }

            require("Core")
            require("Profiles")
            addon = UltraCursorFX

            -- Should return account profiles
            local profiles = addon:GetActiveProfileTable()
            assert.are.same({ 1.0, 0.0, 0.0 }, profiles.raid.color)
            assert.are.equal(40, profiles.raid.points)
        end)
    end)

    describe("Edge Cases and State Isolation", function()
        it("should handle missing characters table gracefully", function()
            _G.UltraCursorFXDB = {
                account = {
                    color = { 1.0, 0.0, 0.0 },
                },
                -- No characters table
            }

            require("Core")
            addon = UltraCursorFX

            -- Should still work, falling back to account
            assert.are.same({ 1.0, 0.0, 0.0 }, addon:GetSetting("color"))
        end)

        it("should handle missing account table gracefully", function()
            _G.UltraCursorFXDB = {
                characters = {
                    ["TestCharacter-TestRealm"] = {
                        useAccountSettings = true,
                        lastLogin = os.time(),
                    },
                },
                -- No account table
            }

            require("Core")
            addon = UltraCursorFX

            -- Should fall back to defaults
            assert.are.same({ 0.0, 1.0, 1.0 }, addon:GetSetting("color"))
        end)

        it("should NOT use flat structure - only account/character storage", function()
            _G.UltraCursorFXDB = {
                account = {
                    color = { 1.0, 0.5, 0.2 },
                    points = 100,
                },
                characters = {
                    ["TestCharacter-TestRealm"] = {
                        useAccountSettings = true,
                        lastLogin = os.time(),
                    },
                },
            }

            require("Core")
            addon = UltraCursorFX

            -- Set a value
            addon:SetSetting("rainbowMode", true)

            -- Should be ONLY in account structure, NOT in flat structure
            assert.is_true(UltraCursorFXDB.account.rainbowMode)
            assert.is_nil(UltraCursorFXDB.rainbowMode) -- Flat structure should NOT exist
        end)
    end)
end)
