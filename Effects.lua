-- ===============================
-- UltraCursorFX - Visual Effects
-- ===============================

local addon = UltraCursorFX

-- Local references for performance
local points, glow, clickParticles = addon.points, addon.glow, addon.clickParticles
local parent = addon.parent
local particleTextures = addon.particleTextures

-- ===============================
-- Trail Building
-- ===============================
function addon:BuildTrail()
    for i = 1, #points do
        if points[i] then
            points[i]:Hide()
        end
        if glow[i] then
            glow[i]:Hide()
        end
    end
    wipe(points)
    wipe(glow)

    local shape = UltraCursorFXDB.particleShape
    local texture = particleTextures[shape] or particleTextures.star

    for i = 1, UltraCursorFXDB.points do
        local p = parent:CreateTexture(nil, "OVERLAY")
        p:SetTexture(texture)
        p:SetBlendMode("ADD")
        p:SetSize(UltraCursorFXDB.size, UltraCursorFXDB.size)
        p:SetVertexColor(unpack(UltraCursorFXDB.color))
        p.x, p.y = 0, 0
        points[i] = p

        local g = parent:CreateTexture(nil, "OVERLAY")
        g:SetTexture("Interface\\SPELLBOOK\\Spellbook-IconGlow")
        g:SetBlendMode("ADD")
        g:SetSize(UltraCursorFXDB.glowSize, UltraCursorFXDB.glowSize)
        g:SetVertexColor(unpack(UltraCursorFXDB.color))
        glow[i] = g
    end
end

-- ===============================
-- Click Effects
-- ===============================
local lastMouseState = { false, false }
local clickParticlePool = {}
local MAX_POOL_SIZE = 200

local function GetClickParticle()
    local p = table.remove(clickParticlePool)
    if not p then
        p = parent:CreateTexture(nil, "OVERLAY")
        p:SetBlendMode("ADD")
    end
    return p
end

local function ReleaseClickParticle(p)
    p:Hide()
    p:ClearAllPoints()
    if #clickParticlePool < MAX_POOL_SIZE then
        table.insert(clickParticlePool, p)
    end
end

local function CreateClickEffect(x, y)
    if not UltraCursorFXDB.clickEffects then
        return
    end

    local color = UltraCursorFXDB.rainbowMode and { addon.HSVtoRGB(addon.rainbowHue, 1, 1) } or UltraCursorFXDB.color

    local shape = UltraCursorFXDB.particleShape
    local texture = particleTextures[shape] or particleTextures.star

    for i = 1, UltraCursorFXDB.clickParticles do
        local angle = (i / UltraCursorFXDB.clickParticles) * math.pi * 2
        local speed = 200 + math.random(0, 100)

        local p = GetClickParticle()
        p:SetTexture(texture)
        p:SetSize(UltraCursorFXDB.clickSize, UltraCursorFXDB.clickSize)
        p:SetVertexColor(unpack(color))
        p:SetPoint("CENTER", parent, "BOTTOMLEFT", x, y)
        p:Show()

        p.velocityX = math.cos(angle) * speed
        p.velocityY = math.sin(angle) * speed
        p.life = 0
        p.maxLife = UltraCursorFXDB.clickDuration

        table.insert(clickParticles, p)
    end
end

local function UpdateClickParticles(elapsed)
    for i = #clickParticles, 1, -1 do
        local p = clickParticles[i]
        p.life = p.life + elapsed

        if p.life >= p.maxLife then
            ReleaseClickParticle(p)
            table.remove(clickParticles, i)
        else
            local progress = p.life / p.maxLife
            local alpha = 1 - progress

            local x, y = p:GetCenter()
            if x and y then
                x = x + p.velocityX * elapsed
                y = y + p.velocityY * elapsed
                p:SetPoint("CENTER", parent, "BOTTOMLEFT", x, y)
            end

            local size = UltraCursorFXDB.clickSize * (1 - progress * 0.5)
            p:SetSize(size, size)
            p:SetAlpha(alpha)
        end
    end
end

local function CheckMouseClicks()
    if not UltraCursorFXDB.clickEffects then
        return
    end

    local leftDown = IsMouseButtonDown("LeftButton")
    local rightDown = IsMouseButtonDown("RightButton")

    if leftDown and not lastMouseState[1] then
        local cx, cy = GetCursorPosition()
        local scale = parent:GetEffectiveScale()
        CreateClickEffect(cx / scale, cy / scale)
    end

    if rightDown and not lastMouseState[2] then
        local cx, cy = GetCursorPosition()
        local scale = parent:GetEffectiveScale()
        CreateClickEffect(cx / scale, cy / scale)
    end

    lastMouseState[1] = leftDown
    lastMouseState[2] = rightDown
end

-- ===============================
-- Animation Loop
-- ===============================
local tAccum = 0

function addon:OnUpdate(elapsed)
    if not UltraCursorFXDB.enabled then
        return
    end

    local pulseSpeed = UltraCursorFXDB.pulseSpeed or 2.5
    local smoothness = UltraCursorFXDB.smoothness or 0.18
    local flashEnabled = UltraCursorFXDB.flashEnabled

    if #points == 0 then
        return
    end

    tAccum = tAccum + elapsed
    local pulse = 0.6 + math.sin(tAccum * pulseSpeed) * 0.4

    if flashEnabled and pulse > 0.95 then
        UIParent:SetAlpha(1)
    end

    -- Rainbow Mode
    if UltraCursorFXDB.rainbowMode then
        self.rainbowHue = (self.rainbowHue + elapsed * UltraCursorFXDB.rainbowSpeed * 0.1) % 1
        local r, g, b = self.HSVtoRGB(self.rainbowHue, 1, 1)
        UltraCursorFXDB.color = { r, g, b }

        for i = 1, #points do
            points[i]:SetVertexColor(r, g, b)
            glow[i]:SetVertexColor(r, g, b)
        end
    end

    local cx, cy = GetCursorPosition()
    local scale = parent:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale

    -- Comet Mode - adjust spacing between points
    local spacing = UltraCursorFXDB.cometMode and (1 / UltraCursorFXDB.cometLength) or 1

    -- Calculate base opacity with combat boost
    local baseOpacity = UltraCursorFXDB.opacity or 1.0
    if UltraCursorFXDB.combatOpacityBoost and addon.inCombat then
        baseOpacity = math.min(1.0, baseOpacity * 1.3) -- 30% boost in combat
    end

    for i = 1, #points do
        local p = points[i]
        if i == 1 then
            p.x = self.Lerp(p.x, cx, smoothness)
            p.y = self.Lerp(p.y, cy, smoothness)
        else
            local prev = points[i - 1]
            p.x = self.Lerp(p.x, prev.x, smoothness * spacing)
            p.y = self.Lerp(p.y, prev.y, smoothness * spacing)
        end

        -- Calculate fade with optional fade mode
        local fadeProgress = (1 - (i - 1) / #points)
        local fadeAlpha
        if UltraCursorFXDB.fadeEnabled then
            local fadeStrength = UltraCursorFXDB.fadeStrength or 0.5
            fadeAlpha = fadeProgress ^ (1 + fadeStrength * 2) -- Stronger fade = faster dropoff
        else
            fadeAlpha = ((#points - i + 1) / #points) ^ (UltraCursorFXDB.cometMode and 2.5 or 1.5)
        end

        p:SetPoint("CENTER", parent, "BOTTOMLEFT", p.x, p.y)
        p:SetAlpha(fadeAlpha * pulse * baseOpacity)

        local g = glow[i]
        g:SetPoint("CENTER", p)
        g:SetAlpha(fadeAlpha * 0.75 * pulse * baseOpacity)
    end

    CheckMouseClicks()
    UpdateClickParticles(elapsed)
end
