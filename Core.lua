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
    color = { 0.765, 0.0, 1.0 }, -- Purple/Magenta
    points = 39,
    size = 40,
    glowSize = 150,
    smoothness = 0.5,
    pulseSpeed = 3.0,

    -- Rainbow Mode
    rainbowMode = true,
    rainbowSpeed = 5.0,

    -- Click Effects
    clickEffects = true,
    clickParticles = 9,
    clickSize = 25,
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
    reticleSize = 105,
    reticleBrightness = 2.0,
    reticleOpacity = 1.0,
    reticleRotationSpeed = 1.6,

    -- Edge Warning System
    edgeWarningEnabled = true,
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
        color = { 0.765, 0.0, 1.0 },
        points = 39,
        size = 40,
        glowSize = 150,
        smoothness = 0.5,
        pulseSpeed = 3.0,
        rainbowMode = true,
        rainbowSpeed = 5.0,
        clickEffects = true,
        clickParticles = 9,
        clickSize = 25,
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
        reticleSize = 105,
        reticleBrightness = 2.0,
        reticleOpacity = 1.0,
        reticleRotationSpeed = 1.6,
        edgeWarningEnabled = true,
        edgeWarningDistance = 50,
        edgeWarningSize = 64,
        edgeWarningOpacity = 0.8,
    },
    raid = {
        name = "Raid",
        color = { 1.0, 0.2, 0.2 },
        points = 35,
        size = 35,
        glowSize = 120,
        smoothness = 0.4,
        pulseSpeed = 2.5,
        rainbowMode = false,
        rainbowSpeed = 3.0,
        clickEffects = true,
        clickParticles = 12,
        clickSize = 30,
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
        reticleBrightness = 1.5,
        reticleOpacity = 0.9,
        reticleRotationSpeed = 1.2,
        edgeWarningEnabled = true,
        edgeWarningDistance = 40,
        edgeWarningSize = 70,
        edgeWarningOpacity = 0.9,
        edgeWarningPulseIntensity = 0.6,
    },
    dungeon = {
        name = "Dungeon",
        color = { 0.8, 0.2, 1.0 },
        points = 38,
        size = 38,
        glowSize = 140,
        smoothness = 0.45,
        pulseSpeed = 2.8,
        rainbowMode = false,
        rainbowSpeed = 4.0,
        clickEffects = true,
        clickParticles = 10,
        clickSize = 28,
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
        reticleSize = 100,
        reticleBrightness = 1.8,
        reticleOpacity = 0.9,
        reticleRotationSpeed = 1.4,
        edgeWarningEnabled = true,
        edgeWarningDistance = 50,
        edgeWarningSize = 64,
        edgeWarningOpacity = 0.8,
        edgeWarningPulseIntensity = 0.5,
    },
    arena = {
        name = "Arena",
        color = { 1.0, 0.5, 0.0 },
        points = 45,
        size = 42,
        glowSize = 130,
        smoothness = 0.35,
        pulseSpeed = 3.5,
        rainbowMode = false,
        rainbowSpeed = 4.0,
        clickEffects = true,
        clickParticles = 15,
        clickSize = 35,
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
        reticleSize = 95,
        reticleBrightness = 1.8,
        reticleOpacity = 0.95,
        reticleRotationSpeed = 1.8,
        edgeWarningEnabled = true,
        edgeWarningDistance = 30,
        edgeWarningSize = 80,
        edgeWarningOpacity = 1.0,
        edgeWarningPulseIntensity = 0.7,
    },
    battleground = {
        name = "Battleground",
        color = { 1.0, 0.84, 0.0 },
        points = 40,
        size = 38,
        glowSize = 135,
        smoothness = 0.42,
        pulseSpeed = 3.0,
        rainbowMode = false,
        rainbowSpeed = 4.0,
        clickEffects = true,
        clickParticles = 12,
        clickSize = 32,
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
        reticleSize = 95,
        reticleBrightness = 1.6,
        reticleOpacity = 0.85,
        reticleRotationSpeed = 1.4,
        edgeWarningEnabled = true,
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

-- Reset all settings to defaults
function addon:ResetSettings()
    -- Reset all default settings
    for key, value in pairs(self.defaults) do
        if type(value) == "table" then
            self:SetSetting(key, { unpack(value) })
        else
            self:SetSetting(key, value)
        end
    end

    -- Rebuild visual elements
    if self.BuildTrail then
        self:BuildTrail()
    end
    if self.BuildReticle then
        self:BuildReticle()
    end
    if self.UpdateCursorState then
        self:UpdateCursorState()
    end

    return true
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
