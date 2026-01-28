-- ===============================
-- UltraCursorFX - Core Module
-- ===============================

-- Namespace
UltraCursorFX = UltraCursorFX or {}
local addon = UltraCursorFX

-- Combat state tracking
addon.inCombat = false

-- ===============================
-- Saved Variables / Defaults
-- ===============================
UltraCursorFXDB = UltraCursorFXDB or {}

-- Forward declarations
function addon:UpdateCursorState() end

-- Helper to get character key
function addon:GetCharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. "-" .. realm
end

addon.defaults = {
    enabled = true,
    flashEnabled = true,
    combatOnly = false,
    color = { 0.0, 1.0, 1.0 },
    points = 48,
    size = 34,
    glowSize = 64,
    smoothness = 0.18,
    pulseSpeed = 2.5,

    -- Rainbow Mode
    rainbowMode = false,
    rainbowSpeed = 1.0,

    -- Click Effects
    clickEffects = true,
    clickParticles = 12,
    clickSize = 50,
    clickDuration = 0.6,

    -- Particle Shape
    particleShape = "star",

    -- Comet Mode
    cometMode = false,
    cometLength = 2.0,

    -- Opacity & Fade
    opacity = 1.0,
    fadeEnabled = false,
    fadeStrength = 0.5,
    combatOpacityBoost = false,

    -- Reticle System
    reticleEnabled = true,
    reticleStyle = "crosshair", -- crosshair, circledot, tshape, military, cyberpunk, minimal
    reticleSize = 80,
    reticleBrightness = 1.0,
    reticleOpacity = 0.7,
    reticleRotationSpeed = 1.0,

    -- Edge Warning System
    edgeWarningEnabled = false,
    edgeWarningDistance = 50,
    edgeWarningSize = 64,
    edgeWarningOpacity = 0.8,
    edgeWarningPulseIntensity = 0.5,

    -- Situational Profiles
    situationalEnabled = false,
    currentProfile = "world",
}

-- Profile defaults for different situations
addon.profileDefaults = {
    world = {
        name = "World",
        color = { 0.0, 1.0, 1.0 },
        points = 48,
        size = 34,
        glowSize = 64,
        smoothness = 0.18,
        pulseSpeed = 2.5,
        rainbowMode = false,
        rainbowSpeed = 1.0,
        clickEffects = true,
        clickParticles = 12,
        clickSize = 50,
        clickDuration = 0.6,
        particleShape = "star",
        cometMode = false,
        cometLength = 2.0,
        opacity = 1.0,
        fadeEnabled = false,
        fadeStrength = 0.5,
        combatOpacityBoost = false,
        reticleEnabled = true,
        reticleStyle = "crosshair",
        reticleSize = 80,
        reticleBrightness = 1.0,
        reticleOpacity = 0.7,
        reticleRotationSpeed = 1.0,
        edgeWarningEnabled = false,
        edgeWarningDistance = 50,
        edgeWarningSize = 64,
        edgeWarningOpacity = 0.8,
    },
    raid = {
        name = "Raid",
        color = { 1.0, 0.2, 0.2 },
        points = 40,
        size = 30,
        glowSize = 50,
        smoothness = 0.20,
        pulseSpeed = 2.0,
        rainbowMode = false,
        rainbowSpeed = 1.0,
        clickEffects = true,
        clickParticles = 16,
        clickSize = 60,
        clickDuration = 0.5,
        particleShape = "star",
        cometMode = true,
        cometLength = 2.5,
        opacity = 1.0,
        fadeEnabled = true,
        fadeStrength = 0.6,
        combatOpacityBoost = true,
        reticleEnabled = true,
        reticleStyle = "military",
        reticleSize = 90,
        reticleBrightness = 1.2,
        reticleOpacity = 0.8,
        reticleRotationSpeed = 1.5,
        edgeWarningEnabled = false,
        edgeWarningDistance = 40,
        edgeWarningSize = 70,
        edgeWarningOpacity = 0.9,
        edgeWarningPulseIntensity = 0.6,
    },
    dungeon = {
        name = "Dungeon",
        color = { 0.8, 0.2, 1.0 },
        points = 50,
        size = 32,
        glowSize = 60,
        smoothness = 0.15,
        pulseSpeed = 2.5,
        rainbowMode = false,
        rainbowSpeed = 1.0,
        clickEffects = true,
        clickParticles = 12,
        clickSize = 55,
        clickDuration = 0.6,
        particleShape = "star",
        cometMode = false,
        cometLength = 2.0,
        opacity = 1.0,
        fadeEnabled = false,
        fadeStrength = 0.5,
        combatOpacityBoost = false,
        reticleEnabled = true,
        reticleStyle = "circledot",
        reticleSize = 75,
        reticleBrightness = 1.0,
        reticleOpacity = 0.7,
        reticleRotationSpeed = 0.8,
        edgeWarningEnabled = false,
        edgeWarningDistance = 50,
        edgeWarningSize = 64,
        edgeWarningOpacity = 0.8,
        edgeWarningPulseIntensity = 0.5,
    },
    arena = {
        name = "Arena",
        color = { 1.0, 0.5, 0.0 },
        points = 60,
        size = 40,
        glowSize = 70,
        smoothness = 0.12,
        pulseSpeed = 3.0,
        rainbowMode = false,
        rainbowSpeed = 1.0,
        clickEffects = true,
        clickParticles = 20,
        clickSize = 70,
        clickDuration = 0.4,
        particleShape = "spark",
        cometMode = true,
        cometLength = 3.0,
        opacity = 1.0,
        fadeEnabled = true,
        fadeStrength = 0.7,
        combatOpacityBoost = true,
        reticleEnabled = true,
        reticleStyle = "tshape",
        reticleSize = 100,
        reticleBrightness = 1.3,
        reticleOpacity = 0.9,
        reticleRotationSpeed = 2.0,
        edgeWarningEnabled = false,
        edgeWarningDistance = 30,
        edgeWarningSize = 80,
        edgeWarningOpacity = 1.0,
        edgeWarningPulseIntensity = 0.7,
    },
    battleground = {
        name = "Battleground",
        color = { 1.0, 0.84, 0.0 },
        points = 55,
        size = 36,
        glowSize = 65,
        smoothness = 0.15,
        pulseSpeed = 2.8,
        rainbowMode = false,
        rainbowSpeed = 1.0,
        clickEffects = true,
        clickParticles = 18,
        clickSize = 65,
        clickDuration = 0.5,
        particleShape = "star",
        cometMode = false,
        cometLength = 2.0,
        opacity = 1.0,
        fadeEnabled = true,
        fadeStrength = 0.5,
        combatOpacityBoost = false,
        reticleEnabled = true,
        reticleStyle = "military",
        reticleSize = 85,
        reticleBrightness = 1.1,
        reticleOpacity = 0.75,
        reticleRotationSpeed = 1.2,
        edgeWarningEnabled = false,
        edgeWarningDistance = 50,
        edgeWarningSize = 64,
        edgeWarningOpacity = 0.8,
        edgeWarningPulseIntensity = 0.5,
    },
}

-- ===============================
-- Core Variables
-- ===============================
addon.parent = UIParent
addon.points = {}
addon.glow = {}
addon.clickParticles = {}
addon.reticleSegments = {}
addon.frame = CreateFrame("Frame")
addon.rainbowHue = 0
addon.currentZoneProfile = "world"
addon.reticleRotation = 0

addon.particleTextures = {
    star = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1",
    skull = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_8",
    spark = "Interface\\Cooldown\\star4",
    dot = "Interface\\CastingBar\\UI-CastingBar-Spark",
}

-- ===============================
-- Initialization
-- ===============================
function addon:InitializeDefaults()
    -- Initialize new database structure
    UltraCursorFXDB.account = UltraCursorFXDB.account or {}
    UltraCursorFXDB.characters = UltraCursorFXDB.characters or {}

    local charKey = self:GetCharacterKey()
    UltraCursorFXDB.characters[charKey] = UltraCursorFXDB.characters[charKey] or {}

    -- Default to account-wide settings for new characters
    if UltraCursorFXDB.characters[charKey].useAccountSettings == nil then
        UltraCursorFXDB.characters[charKey].useAccountSettings = true
    end

    -- Apply defaults for any missing values in account
    for k, v in pairs(addon.defaults) do
        if UltraCursorFXDB.account[k] == nil then
            UltraCursorFXDB.account[k] = v
        end
    end
end

-- Get effective setting value (supports account/character hierarchy)
function addon:GetSetting(key)
    local charKey = self:GetCharacterKey()
    local charData = UltraCursorFXDB.characters and UltraCursorFXDB.characters[charKey]

    -- If character uses their own settings and has this setting defined
    if charData and not charData.useAccountSettings and charData[key] ~= nil then
        return charData[key]
    end

    -- Check account-wide
    if UltraCursorFXDB.account and UltraCursorFXDB.account[key] ~= nil then
        return UltraCursorFXDB.account[key]
    end

    -- Fall back to defaults (with safety check)
    if self.defaults then
        return self.defaults[key]
    end
    return nil
end

-- Get a setting value for a specific character (for viewing other characters' settings)
function addon:GetSettingForCharacter(charKey, key)
    if not UltraCursorFXDB.characters or not UltraCursorFXDB.characters[charKey] then
        -- Character not found, return account or default
        if UltraCursorFXDB.account and UltraCursorFXDB.account[key] ~= nil then
            return UltraCursorFXDB.account[key]
        end
        return self.defaults[key]
    end

    local charData = UltraCursorFXDB.characters[charKey]

    -- If character uses their own settings and has this setting defined
    if charData and not charData.useAccountSettings and charData[key] ~= nil then
        return charData[key]
    end

    -- Check account-wide
    if UltraCursorFXDB.account and UltraCursorFXDB.account[key] ~= nil then
        return UltraCursorFXDB.account[key]
    end

    -- Fall back to defaults
    return self.defaults[key]
end

-- Set a setting value (writes to appropriate location)
function addon:SetSetting(key, value)
    local charKey = self:GetCharacterKey()
    local charData = UltraCursorFXDB.characters and UltraCursorFXDB.characters[charKey]

    if charData and not charData.useAccountSettings then
        -- Write to character-specific
        charData[key] = value
    else
        -- Write to account-wide (ensure account table exists)
        UltraCursorFXDB.account = UltraCursorFXDB.account or {}
        UltraCursorFXDB.account[key] = value
    end
end

-- ===============================
-- Combat State Management
-- ===============================
function addon:UpdateCursorState()
    local shouldShow = self:GetSetting("enabled")

    -- If combat-only mode is enabled, only show in combat
    if self:GetSetting("combatOnly") then
        shouldShow = shouldShow and addon.inCombat
    end

    if shouldShow then
        -- Enable cursor trail
        addon.frame:SetScript("OnUpdate", function(_, elapsed)
            addon:OnUpdate(elapsed)
        end)
    else
        -- Disable cursor trail
        addon.frame:SetScript("OnUpdate", nil)

        -- Hide all particles when disabling
        for i = 1, #addon.points do
            if addon.points[i] then
                addon.points[i]:Hide()
            end
            if addon.glow[i] then
                addon.glow[i]:Hide()
            end
        end
    end
end
