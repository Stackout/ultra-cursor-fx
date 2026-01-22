-- ===============================
-- UltraCursorFX - Profile Management
-- ===============================

local addon = UltraCursorFX

-- ===============================
-- Profile Functions
-- ===============================

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
    if not UltraCursorFXDB.profiles[profileKey] then
        UltraCursorFXDB.profiles[profileKey] = {}
    end

    local profile = UltraCursorFXDB.profiles[profileKey]
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
    local profile = UltraCursorFXDB.profiles[profileKey]
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

        local profileName = UltraCursorFXDB.profiles[newProfile] and 
            UltraCursorFXDB.profiles[newProfile].name or newProfile
        print("|cFF00FFFFUltraCursorFX:|r Switched to " .. profileName .. " profile")
    end
end

-- ===============================
-- Profile Migration
-- ===============================
function addon:MigrateProfiles()
    -- Initialize profiles structure
    UltraCursorFXDB.profiles = UltraCursorFXDB.profiles or {}

    if UltraCursorFXDB.profilesMigrated == nil then
        UltraCursorFXDB.profilesMigrated = false
    end

    if not UltraCursorFXDB.profilesMigrated then
        -- Check if user has existing customized settings
        local hasCustomSettings = false
        local settingsToMigrate = {
            "color", "points", "size", "glowSize", "smoothness", "pulseSpeed",
            "rainbowMode", "rainbowSpeed", "clickEffects", "clickParticles",
            "clickSize", "clickDuration", "particleShape", "cometMode", "cometLength",
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

        -- If user has custom settings, migrate them to the world profile
        if hasCustomSettings then
            UltraCursorFXDB.profiles.world = UltraCursorFXDB.profiles.world or {}
            local worldProfile = UltraCursorFXDB.profiles.world

            for _, key in ipairs(settingsToMigrate) do
                if UltraCursorFXDB[key] ~= nil then
                    if type(UltraCursorFXDB[key]) == "table" then
                        worldProfile[key] = { unpack(UltraCursorFXDB[key]) }
                    else
                        worldProfile[key] = UltraCursorFXDB[key]
                    end
                end
            end

            worldProfile.name = "World"
            print("|cFF00FFFFUltraCursorFX:|r Migrated your custom settings to the World profile!")
        end

        UltraCursorFXDB.profilesMigrated = true
    end

    -- Initialize all profiles with defaults if they don't exist
    for profileKey, profileData in pairs(self.profileDefaults) do
        if not UltraCursorFXDB.profiles[profileKey] then
            UltraCursorFXDB.profiles[profileKey] = {}
            for k, v in pairs(profileData) do
                if type(v) == "table" then
                    UltraCursorFXDB.profiles[profileKey][k] = { unpack(v) }
                else
                    UltraCursorFXDB.profiles[profileKey][k] = v
                end
            end
        end
    end
end
