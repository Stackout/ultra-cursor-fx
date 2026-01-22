-- ===============================
-- UltraCursorFX - Core Module
-- ===============================

-- Namespace
UltraCursorFX = UltraCursorFX or {}
local addon = UltraCursorFX

-- ===============================
-- Saved Variables / Defaults
-- ===============================
UltraCursorFXDB = UltraCursorFXDB or {}

addon.defaults = {
    enabled = true,
    flashEnabled = true,
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
    },
}

-- ===============================
-- Core Variables
-- ===============================
addon.parent = UIParent
addon.points = {}
addon.glow = {}
addon.clickParticles = {}
addon.frame = CreateFrame("Frame")
addon.rainbowHue = 0
addon.currentZoneProfile = "world"

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
    -- Initialize profiles structure first
    UltraCursorFXDB.profiles = UltraCursorFXDB.profiles or {}

    for k, v in pairs(self.defaults) do
        if UltraCursorFXDB[k] == nil then
            UltraCursorFXDB[k] = v
        end
    end
end
