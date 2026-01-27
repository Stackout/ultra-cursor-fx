-- ===============================
-- UltraCursorFX - Spell Tracker Module
-- ===============================
-- Displays tracked spell cooldowns near cursor
-- Perfect for healers and DPS tracking key abilities

local addon = UltraCursorFX

-- Spell tracker state
addon.spellIcons = addon.spellIcons or {}
addon.cachedMaxCharges = addon.cachedMaxCharges or {}

-- ===============================
-- Helper Functions
-- ===============================

-- Check if player knows a spell
local function IsSpellKnownByPlayer(spellID)
    if not spellID then
        return false
    end

    -- Check various spell knowledge APIs
    if IsSpellKnown(spellID) then
        return true
    end
    if IsPlayerSpell(spellID) then
        return true
    end
    if IsSpellKnown(spellID, true) then
        return true
    end

    return false
end

-- ===============================
-- Icon Management
-- ===============================

-- Clear all spell icons
function addon:ClearSpellIcons()
    for i, icon in ipairs(self.spellIcons) do
        icon:Hide()
        icon:SetScript("OnUpdate", nil)
    end
    wipe(self.spellIcons)
end

-- Build spell tracker icons
function addon:BuildSpellIcons()
    self:ClearSpellIcons()

    if not UltraCursorFXDB.spellTrackerEnabled then
        return
    end

    local trackedSpells = UltraCursorFXDB.trackedSpells or {}

    for i, spellID in ipairs(trackedSpells) do
        local icon = CreateFrame("Frame", "UltraCursorFX_SpellIcon" .. i, UIParent)
        icon:SetFrameStrata("TOOLTIP")
        icon:SetFrameLevel(1000)
        icon:EnableMouse(false)
        icon:Hide()

        -- Icon texture
        icon.texture = icon:CreateTexture(nil, "BACKGROUND")
        icon.texture:SetAllPoints()
        icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- Crop edges like default UI

        -- Cooldown spiral
        icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
        icon.cooldown:SetAllPoints()
        icon.cooldown:SetDrawEdge(true)
        icon.cooldown:SetDrawSwipe(true)
        icon.cooldown:SetHideCountdownNumbers(false)
        icon.cooldown:SetReverse(false)

        -- Stack/charge text
        icon.stackText = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        icon.stackText:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 2)
        icon.stackText:SetJustifyH("RIGHT")
        icon.stackText:SetTextColor(1, 1, 1, 1)

        -- Ready indicator (glow when off cooldown)
        icon.readyGlow = icon:CreateTexture(nil, "OVERLAY")
        icon.readyGlow:SetTexture("Interface\\COOLDOWN\\star4")
        icon.readyGlow:SetBlendMode("ADD")
        icon.readyGlow:SetAllPoints()
        icon.readyGlow:SetVertexColor(0, 1, 0, 0) -- Start hidden
        icon.readyGlow.alpha = 0

        -- Border for better visibility
        icon.border = icon:CreateTexture(nil, "BORDER")
        icon.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        icon.border:SetBlendMode("BLEND")
        icon.border:SetAllPoints()
        icon.border:SetVertexColor(0.7, 0.7, 0.7, 1)

        icon.spellID = spellID
        self.spellIcons[i] = icon
    end
end

-- ===============================
-- Update Functions
-- ===============================

-- Update single spell icon
function addon:UpdateSpellIcon(icon)
    if not icon or not icon.spellID then
        return
    end

    local spellID = icon.spellID

    -- Hide if spell tracker is disabled
    if not UltraCursorFXDB.spellTrackerEnabled then
        icon:Hide()
        return
    end

    -- Hide if combat only mode and not in combat
    if UltraCursorFXDB.spellTrackerCombatOnly and not self.inCombat then
        icon:Hide()
        return
    end

    -- Hide if player doesn't know the spell
    if not IsSpellKnownByPlayer(spellID) then
        icon:Hide()
        return
    end

    -- Get spell info
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if not spellInfo or not spellInfo.iconID then
        icon:Hide()
        return
    end

    -- Show and set texture
    icon:Show()
    icon.texture:SetTexture(spellInfo.iconID)

    -- Update cooldown
    local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
    if cooldownInfo and cooldownInfo.startTime and cooldownInfo.duration then
        local duration = cooldownInfo.duration
        local startTime = cooldownInfo.startTime

        -- Only show cooldown spiral for cooldowns > 1.5s (GCD)
        if duration > 1.5 then
            icon.cooldown:SetCooldown(startTime, duration)
            icon.readyGlow.alpha = 0 -- Hide glow during cooldown
        else
            -- Spell is ready - show glow
            icon.cooldown:Clear()
            if not icon.glowAnimating then
                icon.readyGlow.alpha = 0.7
            end
        end
    end

    -- Update charges
    local chargeInfo = C_Spell.GetSpellCharges(spellID)
    if chargeInfo then
        local currentCharges = chargeInfo.currentCharges or 0
        local maxCharges = self.cachedMaxCharges[spellID]

        -- Cache max charges outside of combat
        if not self.inCombat then
            local maxChargesNum = tonumber(chargeInfo.maxCharges) or 1
            self.cachedMaxCharges[spellID] = maxChargesNum
            maxCharges = maxChargesNum
        end

        maxCharges = maxCharges or 1

        -- Show stack text if spell has multiple charges
        if maxCharges >= 2 then
            icon.stackText:SetText(currentCharges)
            icon.stackText:Show()

            -- Color coding: red if 0, yellow if partial, green if full
            if currentCharges == 0 then
                icon.stackText:SetTextColor(1, 0, 0, 1)
            elseif currentCharges < maxCharges then
                icon.stackText:SetTextColor(1, 1, 0, 1)
            else
                icon.stackText:SetTextColor(0, 1, 0, 1)
            end
        else
            icon.stackText:Hide()
        end
    else
        icon.stackText:Hide()
    end

    -- Pulsing glow animation when ready
    if icon.readyGlow.alpha > 0 then
        if not icon.glowAnimating then
            icon.glowAnimating = true
            icon.glowTime = 0
        end
        icon.glowTime = icon.glowTime + 0.016 -- ~60fps
        local pulse = (math.sin(icon.glowTime * 3) + 1) / 2 -- 0 to 1
        icon.readyGlow:SetVertexColor(0, 1, 0, 0.3 + pulse * 0.4)
    else
        icon.glowAnimating = false
        icon.readyGlow:SetVertexColor(0, 1, 0, 0)
    end
end

-- Update all spell icons
function addon:UpdateAllSpellIcons()
    for _, icon in ipairs(self.spellIcons) do
        self:UpdateSpellIcon(icon)
    end
end

-- Position spell icons near cursor
function addon:PositionSpellIcons()
    if not UltraCursorFXDB.spellTrackerEnabled then
        return
    end

    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    local iconSize = UltraCursorFXDB.spellTrackerIconSize or 32
    local spacing = UltraCursorFXDB.spellTrackerSpacing or 2
    local offsetX = UltraCursorFXDB.spellTrackerOffsetX or 10
    local offsetY = UltraCursorFXDB.spellTrackerOffsetY or 30

    local visibleIndex = 0

    for i, icon in ipairs(self.spellIcons) do
        if icon:IsShown() then
            icon:SetSize(iconSize, iconSize)
            icon:ClearAllPoints()
            icon:SetPoint(
                "BOTTOMLEFT",
                UIParent,
                "BOTTOMLEFT",
                (x / scale) + offsetX + (visibleIndex * (iconSize + spacing)),
                (y / scale) + offsetY
            )
            visibleIndex = visibleIndex + 1
        end
    end
end

-- ===============================
-- Event Handlers
-- ===============================

-- Initialize spell tracker
function addon:InitSpellTracker()
    -- Build icons on load
    self:BuildSpellIcons()
    self:UpdateAllSpellIcons()

    -- Register for spell events
    self.parent:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    self.parent:RegisterEvent("SPELL_UPDATE_CHARGES")
    self.parent:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

    -- Set up update ticker
    if not self.spellTrackerTicker then
        self.spellTrackerTicker = C_Timer.NewTicker(0.1, function()
            addon:UpdateAllSpellIcons()
        end)
    end
end

-- Handle spell tracker events
function addon:OnSpellTrackerEvent(event, ...)
    if event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" then
        self:UpdateAllSpellIcons()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit = ...
        if unit == "player" then
            self:UpdateAllSpellIcons()
        end
    end
end

-- Rebuild spell icons (called when settings change)
function addon:RefreshSpellTracker()
    self:BuildSpellIcons()
    self:UpdateAllSpellIcons()
end

-- Toggle spell tracker on/off
function addon:ToggleSpellTracker()
    UltraCursorFXDB.spellTrackerEnabled = not UltraCursorFXDB.spellTrackerEnabled
    if UltraCursorFXDB.spellTrackerEnabled then
        self:BuildSpellIcons()
        self:UpdateAllSpellIcons()
        print("|cff00ffffUltraCursorFX:|r Spell Tracker |cff00ff00enabled|r")
    else
        self:ClearSpellIcons()
        print("|cff00ffffUltraCursorFX:|r Spell Tracker |cffff0000disabled|r")
    end
end

-- Add a spell to tracker
function addon:AddTrackedSpell(spellID)
    UltraCursorFXDB.trackedSpells = UltraCursorFXDB.trackedSpells or {}

    -- Check if already tracked
    for _, id in ipairs(UltraCursorFXDB.trackedSpells) do
        if id == spellID then
            print("|cff00ffffUltraCursorFX:|r Spell " .. spellID .. " is already tracked")
            return
        end
    end

    -- Add to tracked list
    table.insert(UltraCursorFXDB.trackedSpells, spellID)
    self:RefreshSpellTracker()

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local spellName = spellInfo and spellInfo.name or "Unknown"
    print("|cff00ffffUltraCursorFX:|r Added spell: |cff00ff00" .. spellName .. "|r (" .. spellID .. ")")
end

-- Remove a spell from tracker
function addon:RemoveTrackedSpell(spellID)
    UltraCursorFXDB.trackedSpells = UltraCursorFXDB.trackedSpells or {}

    for i, id in ipairs(UltraCursorFXDB.trackedSpells) do
        if id == spellID then
            table.remove(UltraCursorFXDB.trackedSpells, i)
            self:RefreshSpellTracker()

            local spellInfo = C_Spell.GetSpellInfo(spellID)
            local spellName = spellInfo and spellInfo.name or "Unknown"
            print("|cff00ffffUltraCursorFX:|r Removed spell: |cffff0000" .. spellName .. "|r (" .. spellID .. ")")
            return
        end
    end

    print("|cff00ffffUltraCursorFX:|r Spell " .. spellID .. " is not tracked")
end

-- List all tracked spells
function addon:ListTrackedSpells()
    UltraCursorFXDB.trackedSpells = UltraCursorFXDB.trackedSpells or {}

    if #UltraCursorFXDB.trackedSpells == 0 then
        print("|cff00ffffUltraCursorFX:|r No spells are currently tracked")
        return
    end

    print("|cff00ffffUltraCursorFX:|r Tracked Spells:")
    for i, spellID in ipairs(UltraCursorFXDB.trackedSpells) do
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        local spellName = spellInfo and spellInfo.name or "Unknown"
        local known = IsSpellKnownByPlayer(spellID) and "|cff00ff00✓|r" or "|cffff0000✗|r"
        print("  " .. i .. ". " .. known .. " " .. spellName .. " (" .. spellID .. ")")
    end
end
