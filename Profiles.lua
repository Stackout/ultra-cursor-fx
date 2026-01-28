-- ===============================
-- UltraCursorFX - Profile Management
-- ===============================

local addon = UltraCursorFX

-- ===============================
-- Profile Functions
-- ===============================

-- Get the active profile table (account or character-specific)
function addon:GetActiveProfileTable()
    -- Ensure structure exists
    if not UltraCursorFXDB.account then
        UltraCursorFXDB.account = {}
    end
    if not UltraCursorFXDB.characters then
        UltraCursorFXDB.characters = {}
    end

    local charKey = self:GetCharacterKey()
    local charData = UltraCursorFXDB.characters[charKey]

    if charData and not charData.useAccountSettings and charData.profiles then
        -- Use character-specific profiles
        return charData.profiles
    else
        -- Use account-wide profiles
        UltraCursorFXDB.account.profiles = UltraCursorFXDB.account.profiles or {}
        return UltraCursorFXDB.account.profiles
    end
end

-- Get list of characters that have used the addon
function addon:GetCharacterList()
    if not UltraCursorFXDB.characters then
        return {}
    end

    local chars = {}
    for charKey, charData in pairs(UltraCursorFXDB.characters) do
        table.insert(chars, {
            key = charKey,
            lastLogin = charData.lastLogin or 0,
            useAccountSettings = charData.useAccountSettings,
        })
    end

    -- Sort by last login (most recent first)
    table.sort(chars, function(a, b)
        return a.lastLogin > b.lastLogin
    end)

    return chars
end

-- Toggle between account-wide and character-specific settings
function addon:SetUseAccountSettings(useAccount)
    if not UltraCursorFXDB.characters then
        UltraCursorFXDB.characters = {}
    end
    if not UltraCursorFXDB.account then
        UltraCursorFXDB.account = {}
    end

    local charKey = self:GetCharacterKey()
    local charData = UltraCursorFXDB.characters[charKey]

    if not charData then
        charData = {}
        UltraCursorFXDB.characters[charKey] = charData
    end

    charData.useAccountSettings = useAccount

    if not useAccount and not charData.profiles then
        -- Initialize character-specific profiles by copying from account
        charData.profiles = {}
        UltraCursorFXDB.account.profiles = UltraCursorFXDB.account.profiles or {}
        for profileKey, profileData in pairs(UltraCursorFXDB.account.profiles) do
            charData.profiles[profileKey] = {}
            for k, v in pairs(profileData) do
                if type(v) == "table" then
                    charData.profiles[profileKey][k] = { unpack(v) }
                else
                    charData.profiles[profileKey][k] = v
                end
            end
        end
        print("|cFF00FFFFUltraCursorFX:|r Created character-specific profiles for " .. charKey)
    end
end

-- Get current zone profile type
function addon:GetCurrentZoneProfile()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        return "world"
    end

    if instanceType == "raid" then
        return "raid"
    elseif instanceType == "party" then
        return "dungeon"
    elseif instanceType == "arena" then
        return "arena"
    elseif instanceType == "pvp" then
        return "battleground"
    end

    return "world"
end

-- Save current settings to a profile
function addon:SaveToProfile(profileKey)
    local profiles = self:GetActiveProfileTable()

    if not profiles[profileKey] then
        profiles[profileKey] = {}
    end

    local profile = profiles[profileKey]
    profile.color = { unpack(UltraCursorFXDB.color) }
    profile.points = UltraCursorFXDB.points
    profile.size = UltraCursorFXDB.size
    profile.glowSize = UltraCursorFXDB.glowSize
    profile.smoothness = UltraCursorFXDB.smoothness
    profile.pulseSpeed = UltraCursorFXDB.pulseSpeed
    profile.rainbowMode = UltraCursorFXDB.rainbowMode
    profile.rainbowSpeed = UltraCursorFXDB.rainbowSpeed
    profile.clickEffects = UltraCursorFXDB.clickEffects
    profile.clickParticles = UltraCursorFXDB.clickParticles
    profile.clickSize = UltraCursorFXDB.clickSize
    profile.clickDuration = UltraCursorFXDB.clickDuration
    profile.particleShape = UltraCursorFXDB.particleShape
    profile.cometMode = UltraCursorFXDB.cometMode
    profile.cometLength = UltraCursorFXDB.cometLength
end

-- Load settings from a profile
function addon:LoadFromProfile(profileKey)
    local profiles = self:GetActiveProfileTable()
    local profile = profiles[profileKey]
    if not profile then
        return false
    end

    UltraCursorFXDB.color = profile.color and { unpack(profile.color) } or { 0.0, 1.0, 1.0 }
    UltraCursorFXDB.points = profile.points or 48
    UltraCursorFXDB.size = profile.size or 34
    UltraCursorFXDB.glowSize = profile.glowSize or 64
    UltraCursorFXDB.smoothness = profile.smoothness or 0.18
    UltraCursorFXDB.pulseSpeed = profile.pulseSpeed or 2.5
    UltraCursorFXDB.rainbowMode = profile.rainbowMode or false
    UltraCursorFXDB.rainbowSpeed = profile.rainbowSpeed or 1.0
    UltraCursorFXDB.clickEffects = profile.clickEffects ~= nil and profile.clickEffects or true
    UltraCursorFXDB.clickParticles = profile.clickParticles or 12
    UltraCursorFXDB.clickSize = profile.clickSize or 50
    UltraCursorFXDB.clickDuration = profile.clickDuration or 0.6
    UltraCursorFXDB.particleShape = profile.particleShape or "star"
    UltraCursorFXDB.cometMode = profile.cometMode or false
    UltraCursorFXDB.cometLength = profile.cometLength or 2.0

    addon:BuildTrail()
    return true
end

-- Switch to appropriate profile based on current zone
function addon:SwitchToZoneProfile()
    if not UltraCursorFXDB.situationalEnabled then
        return
    end

    local newProfile = self:GetCurrentZoneProfile()
    if newProfile ~= self.currentZoneProfile then
        self.currentZoneProfile = newProfile
        self:LoadFromProfile(newProfile)

        local profiles = self:GetActiveProfileTable()
        local profileName = profiles[newProfile] and profiles[newProfile].name or newProfile
        print("|cFF00FFFFUltraCursorFX:|r Switched to " .. profileName .. " profile")
    end
end

-- ===============================
-- Profile Migration
-- ===============================
function addon:MigrateProfiles()
    -- Initialize new structure if needed
    if not UltraCursorFXDB.account then
        -- First time setup or migration needed
        UltraCursorFXDB.account = UltraCursorFXDB.account or {}
        UltraCursorFXDB.characters = UltraCursorFXDB.characters or {}

        -- Get current character
        local charKey = self:GetCharacterKey()
        UltraCursorFXDB.characters[charKey] = UltraCursorFXDB.characters[charKey] or {}

        -- Mark that this character has used the addon
        UltraCursorFXDB.characters[charKey].lastLogin = time()
        UltraCursorFXDB.characters[charKey].useAccountSettings = true
    end

    -- Legacy migration from old flat structure
    if UltraCursorFXDB.profilesMigrated == nil then
        UltraCursorFXDB.profilesMigrated = false
    end

    if not UltraCursorFXDB.profilesMigrated then
        -- Check if user has existing customized settings
        local hasCustomSettings = false
        local settingsToMigrate = {
            "color",
            "points",
            "size",
            "glowSize",
            "smoothness",
            "pulseSpeed",
            "rainbowMode",
            "rainbowSpeed",
            "clickEffects",
            "clickParticles",
            "clickSize",
            "clickDuration",
            "particleShape",
            "cometMode",
            "cometLength",
        }

        -- Check if any user settings differ from defaults
        for _, key in ipairs(settingsToMigrate) do
            if UltraCursorFXDB[key] ~= nil then
                local dbValue = UltraCursorFXDB[key]
                local defaultValue = self.defaults[key]

                local isDifferent = false
                if type(dbValue) == "table" and type(defaultValue) == "table" then
                    if #dbValue ~= #defaultValue then
                        isDifferent = true
                    else
                        for i = 1, #dbValue do
                            if dbValue[i] ~= defaultValue[i] then
                                isDifferent = true
                                break
                            end
                        end
                    end
                elseif dbValue ~= defaultValue then
                    isDifferent = true
                end

                if isDifferent then
                    hasCustomSettings = true
                    break
                end
            end
        end

        -- If user has custom settings, migrate them to account-wide
        if hasCustomSettings then
            -- Migrate to account-wide settings
            for _, key in ipairs(settingsToMigrate) do
                if UltraCursorFXDB[key] ~= nil then
                    if type(UltraCursorFXDB[key]) == "table" then
                        UltraCursorFXDB.account[key] = { unpack(UltraCursorFXDB[key]) }
                    else
                        UltraCursorFXDB.account[key] = UltraCursorFXDB[key]
                    end
                end
            end
            local charKey = self:GetCharacterKey()
            print("|cFF00FFFFUltraCursorFX:|r Migrated custom settings to account-wide for " .. charKey)
            print("|cFFFFD700→|r All your characters will now share these cursor settings!")
        end

        -- Migrate old profiles structure to account.profiles
        if UltraCursorFXDB.profiles and type(UltraCursorFXDB.profiles) == "table" then
            UltraCursorFXDB.account.profiles = UltraCursorFXDB.account.profiles or {}
            local profileCount = 0
            -- Copy valid profiles only
            for profileKey, profileData in pairs(UltraCursorFXDB.profiles) do
                if type(profileData) == "table" then
                    UltraCursorFXDB.account.profiles[profileKey] = profileData
                    profileCount = profileCount + 1
                end
            end
            if profileCount > 0 then
                print("|cFF00FFFFUltraCursorFX:|r Migrated " .. profileCount .. " situational profile(s) to new system")
            end
            UltraCursorFXDB.profiles = nil -- Clean up old structure
        end

        UltraCursorFXDB.profilesMigrated = true
    end

    -- Ensure account has profiles table
    UltraCursorFXDB.account.profiles = UltraCursorFXDB.account.profiles or {}

    -- Initialize all profiles with defaults if they don't exist (in account-wide)
    for profileKey, profileData in pairs(self.profileDefaults) do
        if
            not UltraCursorFXDB.account.profiles[profileKey]
            or type(UltraCursorFXDB.account.profiles[profileKey]) ~= "table"
        then
            UltraCursorFXDB.account.profiles[profileKey] = {}
            for k, v in pairs(profileData) do
                if type(v) == "table" then
                    UltraCursorFXDB.account.profiles[profileKey][k] = { unpack(v) }
                else
                    UltraCursorFXDB.account.profiles[profileKey][k] = v
                end
            end
        end
    end

    -- Update current character's last login
    local charKey = self:GetCharacterKey()
    if UltraCursorFXDB.characters[charKey] then
        UltraCursorFXDB.characters[charKey].lastLogin = time()
    end

    -- Sync current settings to flat structure for backwards compatibility
    if self.SyncSettingsToFlat then
        self:SyncSettingsToFlat()
    end
end
