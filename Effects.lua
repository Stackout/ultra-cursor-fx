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

    local shape = self:GetSetting("particleShape")
    local texture = particleTextures[shape] or particleTextures.star

    local numPoints = self:GetSetting("points")
    local size = self:GetSetting("size")
    local glowSize = self:GetSetting("glowSize")
    local color = self:GetSetting("color")

    for i = 1, numPoints do
        local p = parent:CreateTexture(nil, "OVERLAY")
        p:SetTexture(texture)
        p:SetBlendMode("ADD")
        p:SetSize(size, size)
        p:SetVertexColor(unpack(color))
        p.x, p.y = 0, 0
        points[i] = p

        local g = parent:CreateTexture(nil, "OVERLAY")
        g:SetTexture("Interface\\SPELLBOOK\\Spellbook-IconGlow")
        g:SetBlendMode("ADD")
        g:SetSize(glowSize, glowSize)
        g:SetVertexColor(unpack(color))
        glow[i] = g
    end

    -- Build reticle segments
    addon:BuildReticle()

    -- Build edge warning arrows
    addon:BuildEdgeWarnings()
end

-- ===============================
-- Reticle Building
-- ===============================
local reticleSegments = addon.reticleSegments

function addon:BuildReticle()
    -- Clear existing segments
    for i = 1, #reticleSegments do
        if reticleSegments[i] then
            reticleSegments[i]:Hide()
        end
    end
    wipe(reticleSegments)

    if not self:GetSetting("reticleEnabled") then
        return
    end

    local style = self:GetSetting("reticleStyle") or "crosshair"

    -- Create different reticle styles
    if style == "crosshair" then
        -- Classic crosshair: 4 lines + center dot (5 segments)
        for i = 1, 5 do
            local seg = parent:CreateTexture(nil, "OVERLAY")
            seg:SetTexture("Interface\\Buttons\\WHITE8X8")
            seg:SetBlendMode("ADD")
            reticleSegments[i] = seg
        end
    elseif style == "circledot" then
        -- Circle with center dot: 8 circle segments + 1 center dot (9 segments)
        for i = 1, 9 do
            local seg = parent:CreateTexture(nil, "OVERLAY")
            seg:SetTexture("Interface\\Buttons\\WHITE8X8")
            seg:SetBlendMode("ADD")
            reticleSegments[i] = seg
        end
    elseif style == "tshape" then
        -- T-shaped rangefinder: 3 lines (top, left, right) + 2 tick marks (5 segments)
        for i = 1, 5 do
            local seg = parent:CreateTexture(nil, "OVERLAY")
            seg:SetTexture("Interface\\Buttons\\WHITE8X8")
            seg:SetBlendMode("ADD")
            reticleSegments[i] = seg
        end
    elseif style == "military" then
        -- 4 corner brackets + 4 rotating segments
        for i = 1, 8 do
            local seg = parent:CreateTexture(nil, "OVERLAY")
            seg:SetTexture("Interface\\Cooldown\\edge-LoC")
            seg:SetBlendMode("ADD")
            reticleSegments[i] = seg
        end
    elseif style == "cyberpunk" then
        -- 8 neon line segments in a circle
        for i = 1, 8 do
            local seg = parent:CreateTexture(nil, "OVERLAY")
            seg:SetTexture("Interface\\Buttons\\WHITE8X8")
            seg:SetBlendMode("ADD")
            reticleSegments[i] = seg
        end
    elseif style == "minimal" then
        -- Simple 4 corner markers
        for i = 1, 4 do
            local seg = parent:CreateTexture(nil, "OVERLAY")
            seg:SetTexture("Interface\\Buttons\\WHITE8X8")
            seg:SetBlendMode("ADD")
            reticleSegments[i] = seg
        end
    end
end

-- ===============================
-- Edge Warning System
-- ===============================
local edgeWarnings = {}
addon.edgeWarnings = edgeWarnings

function addon:BuildEdgeWarnings()
    -- Clear existing warnings
    for _, edge in pairs(edgeWarnings) do
        if edge.arrow then
            edge.arrow:Hide()
        end
        if edge.glow then
            edge.glow:Hide()
        end
    end
    wipe(edgeWarnings)

    if not self:GetSetting("edgeWarningEnabled") then
        return
    end

    local edgeWarningSize = self:GetSetting("edgeWarningSize")

    -- Create arrow textures for each edge
    local edges = { "top", "bottom", "left", "right" }
    for _, edgeName in ipairs(edges) do
        local arrow = parent:CreateTexture(nil, "OVERLAY")
        arrow:SetTexture("Interface\\Buttons\\UI-MicroStream-Yellow")
        arrow:SetBlendMode("ADD")
        arrow:SetSize(edgeWarningSize, edgeWarningSize)
        arrow:Hide()

        local glow = parent:CreateTexture(nil, "OVERLAY")
        glow:SetTexture("Interface\\Buttons\\UI-MicroStream-Yellow")
        glow:SetBlendMode("ADD")
        glow:SetSize(edgeWarningSize * 1.2, edgeWarningSize * 1.2)
        glow:Hide()

        edgeWarnings[edgeName] = {
            arrow = arrow,
            glow = glow,
            pulseTime = 0,
        }
    end
end

function addon:UpdateEdgeWarnings(elapsed, mouseX, mouseY)
    if not self:GetSetting("edgeWarningEnabled") then
        -- Hide all warnings
        for _, edge in pairs(edgeWarnings) do
            if edge.arrow then
                edge.arrow:Hide()
            end
            if edge.glow then
                edge.glow:Hide()
            end
        end
        return false -- Not showing
    end

    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()
    local distance = self:GetSetting("edgeWarningDistance") or 50
    local baseSize = self:GetSetting("edgeWarningSize") or 64
    local opacity = self:GetSetting("edgeWarningOpacity") or 0.8
    local pulseIntensity = self:GetSetting("edgeWarningPulseIntensity") or 0.5

    -- Check each edge
    local showTop = mouseY >= (screenHeight - distance)
    local showBottom = mouseY <= distance
    local showLeft = mouseX <= distance
    local showRight = mouseX >= (screenWidth - distance)

    -- Track if any edge is showing
    local anyEdgeShowing = showTop or showBottom or showLeft or showRight

    -- Top edge
    if edgeWarnings.top then
        edgeWarnings.top.pulseTime = (edgeWarnings.top.pulseTime or 0) + elapsed
        -- Size pulsation: 1.0 + intensity * sin wave
        local pulse = 1.0 + pulseIntensity * math.sin(edgeWarnings.top.pulseTime * 3)
        local size = baseSize * pulse

        if showTop then
            edgeWarnings.top.arrow:SetSize(size, size)
            edgeWarnings.top.arrow:ClearAllPoints()
            edgeWarnings.top.arrow:SetPoint("CENTER", UIParent, "BOTTOMLEFT", mouseX, screenHeight - size / 2)
            edgeWarnings.top.arrow:SetRotation(0) -- Point up
            edgeWarnings.top.arrow:SetAlpha(opacity)
            edgeWarnings.top.arrow:Show()

            edgeWarnings.top.glow:SetSize(size * 1.2, size * 1.2)
            edgeWarnings.top.glow:ClearAllPoints()
            edgeWarnings.top.glow:SetPoint("CENTER", edgeWarnings.top.arrow, "CENTER")
            edgeWarnings.top.glow:SetRotation(0)
            edgeWarnings.top.glow:SetAlpha(opacity * 0.4)
            edgeWarnings.top.glow:Show()
        else
            edgeWarnings.top.arrow:Hide()
            edgeWarnings.top.glow:Hide()
        end
    end

    -- Bottom edge
    if edgeWarnings.bottom then
        edgeWarnings.bottom.pulseTime = (edgeWarnings.bottom.pulseTime or 0) + elapsed
        local pulse = 1.0 + pulseIntensity * math.sin(edgeWarnings.bottom.pulseTime * 3)
        local size = baseSize * pulse

        if showBottom then
            edgeWarnings.bottom.arrow:SetSize(size, size)
            edgeWarnings.bottom.arrow:ClearAllPoints()
            edgeWarnings.bottom.arrow:SetPoint("CENTER", UIParent, "BOTTOMLEFT", mouseX, size / 2)
            edgeWarnings.bottom.arrow:SetRotation(math.rad(180)) -- Point down
            edgeWarnings.bottom.arrow:SetAlpha(opacity)
            edgeWarnings.bottom.arrow:Show()

            edgeWarnings.bottom.glow:SetSize(size * 1.2, size * 1.2)
            edgeWarnings.bottom.glow:ClearAllPoints()
            edgeWarnings.bottom.glow:SetPoint("CENTER", edgeWarnings.bottom.arrow, "CENTER")
            edgeWarnings.bottom.glow:SetRotation(math.rad(180))
            edgeWarnings.bottom.glow:SetAlpha(opacity * 0.4)
            edgeWarnings.bottom.glow:Show()
        else
            edgeWarnings.bottom.arrow:Hide()
            edgeWarnings.bottom.glow:Hide()
        end
    end

    -- Left edge
    if edgeWarnings.left then
        edgeWarnings.left.pulseTime = (edgeWarnings.left.pulseTime or 0) + elapsed
        local pulse = 1.0 + pulseIntensity * math.sin(edgeWarnings.left.pulseTime * 3)
        local size = baseSize * pulse

        if showLeft then
            edgeWarnings.left.arrow:SetSize(size, size)
            edgeWarnings.left.arrow:ClearAllPoints()
            edgeWarnings.left.arrow:SetPoint("CENTER", UIParent, "BOTTOMLEFT", size / 2, mouseY)
            edgeWarnings.left.arrow:SetRotation(math.rad(90)) -- Point right
            edgeWarnings.left.arrow:SetAlpha(opacity)
            edgeWarnings.left.arrow:Show()

            edgeWarnings.left.glow:SetSize(size * 1.2, size * 1.2)
            edgeWarnings.left.glow:ClearAllPoints()
            edgeWarnings.left.glow:SetPoint("CENTER", edgeWarnings.left.arrow, "CENTER")
            edgeWarnings.left.glow:SetRotation(math.rad(90))
            edgeWarnings.left.glow:SetAlpha(opacity * 0.4)
            edgeWarnings.left.glow:Show()
        else
            edgeWarnings.left.arrow:Hide()
            edgeWarnings.left.glow:Hide()
        end
    end

    -- Right edge
    if edgeWarnings.right then
        edgeWarnings.right.pulseTime = (edgeWarnings.right.pulseTime or 0) + elapsed
        local pulse = 1.0 + pulseIntensity * math.sin(edgeWarnings.right.pulseTime * 3)
        local size = baseSize * pulse

        if showRight then
            edgeWarnings.right.arrow:SetSize(size, size)
            edgeWarnings.right.arrow:ClearAllPoints()
            edgeWarnings.right.arrow:SetPoint("CENTER", UIParent, "BOTTOMLEFT", screenWidth - size / 2, mouseY)
            edgeWarnings.right.arrow:SetRotation(math.rad(270)) -- Point left
            edgeWarnings.right.arrow:SetAlpha(opacity)
            edgeWarnings.right.arrow:Show()

            edgeWarnings.right.glow:SetSize(size * 1.2, size * 1.2)
            edgeWarnings.right.glow:ClearAllPoints()
            edgeWarnings.right.glow:SetPoint("CENTER", edgeWarnings.right.arrow, "CENTER")
            edgeWarnings.right.glow:SetRotation(math.rad(270))
            edgeWarnings.right.glow:SetAlpha(opacity * 0.4)
            edgeWarnings.right.glow:Show()
        else
            edgeWarnings.right.arrow:Hide()
            edgeWarnings.right.glow:Hide()
        end
    end

    -- Store the pulse value for reticle coordination
    addon.edgeWarningPulse = 1.0 + pulseIntensity * math.sin((edgeWarnings.top and edgeWarnings.top.pulseTime or 0) * 3)

    return anyEdgeShowing
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
    if not addon:GetSetting("clickEffects") then
        return
    end

    local color = addon:GetSetting("rainbowMode") and { addon.HSVtoRGB(addon.rainbowHue, 1, 1) }
        or addon:GetSetting("color")

    local shape = addon:GetSetting("particleShape")
    local texture = particleTextures[shape] or particleTextures.star
    local clickParticleCount = addon:GetSetting("clickParticles")
    local clickSize = addon:GetSetting("clickSize")
    local clickDuration = addon:GetSetting("clickDuration")

    for i = 1, clickParticleCount do
        local angle = (i / clickParticleCount) * math.pi * 2
        local speed = 200 + math.random(0, 100)

        local p = GetClickParticle()
        p:SetTexture(texture)
        p:SetSize(clickSize, clickSize)
        p:SetVertexColor(unpack(color))
        p:SetPoint("CENTER", parent, "BOTTOMLEFT", x, y)
        p:Show()

        p.velocityX = math.cos(angle) * speed
        p.velocityY = math.sin(angle) * speed
        p.life = 0
        p.maxLife = clickDuration

        table.insert(clickParticles, p)
    end
end

local function UpdateClickParticles(elapsed)
    local clickSize = addon:GetSetting("clickSize")
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

            local size = clickSize * (1 - progress * 0.5)
            p:SetSize(size, size)
            p:SetAlpha(alpha)
        end
    end
end

local function CheckMouseClicks()
    if not addon:GetSetting("clickEffects") then
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
    if not self:GetSetting("enabled") then
        return
    end

    local pulseSpeed = self:GetSetting("pulseSpeed") or 2.5
    local smoothness = self:GetSetting("smoothness") or 0.18
    local flashEnabled = self:GetSetting("flashEnabled")

    if #points == 0 then
        return
    end

    tAccum = tAccum + elapsed
    local pulse = 0.6 + math.sin(tAccum * pulseSpeed) * 0.4

    if flashEnabled and pulse > 0.95 then
        UIParent:SetAlpha(1)
    end

    -- Rainbow Mode
    if self:GetSetting("rainbowMode") then
        self.rainbowHue = (self.rainbowHue + elapsed * self:GetSetting("rainbowSpeed") * 0.1) % 1
        local r, g, b = self.HSVtoRGB(self.rainbowHue, 1, 1)
        self:SetSetting("color", { r, g, b })

        for i = 1, #points do
            points[i]:SetVertexColor(r, g, b)
            glow[i]:SetVertexColor(r, g, b)
        end
    end

    local cx, cy = GetCursorPosition()
    local scale = parent:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale

    -- Check edge warnings first to determine if we should hide particles
    local edgeWarningActive = addon:UpdateEdgeWarnings(elapsed, cx, cy)

    -- Comet Mode - adjust spacing between points
    local cometMode = self:GetSetting("cometMode")
    local spacing = cometMode and (1 / self:GetSetting("cometLength")) or 1

    -- Calculate base opacity with combat boost
    local baseOpacity = self:GetSetting("opacity") or 1.0
    if self:GetSetting("combatOpacityBoost") and addon.inCombat then
        baseOpacity = math.min(1.0, baseOpacity * 1.3) -- 30% boost in combat
    end

    local fadeEnabled = self:GetSetting("fadeEnabled")
    local fadeStrength = self:GetSetting("fadeStrength") or 0.5

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
        if fadeEnabled then
            fadeAlpha = fadeProgress ^ (1 + fadeStrength * 2) -- Stronger fade = faster dropoff
        else
            fadeAlpha = ((#points - i + 1) / #points) ^ (cometMode and 2.5 or 1.5)
        end

        p:SetPoint("CENTER", parent, "BOTTOMLEFT", p.x, p.y)

        -- Hide particles when edge warnings are active
        if edgeWarningActive then
            p:SetAlpha(0)
        else
            p:SetAlpha(fadeAlpha * pulse * baseOpacity)
        end

        local g = glow[i]
        g:SetPoint("CENTER", p)
        if edgeWarningActive then
            g:SetAlpha(0)
        else
            g:SetAlpha(fadeAlpha * 0.75 * pulse * baseOpacity)
        end
    end

    -- Only show click effects if edge warnings are not active
    if not edgeWarningActive then
        CheckMouseClicks()
    end
    UpdateClickParticles(elapsed)
    addon:UpdateReticle(elapsed, cx, cy, edgeWarningActive)
end

-- ===============================
-- Reticle Update & Mouseover Detection
-- ===============================
function addon:UpdateReticle(elapsed, cx, cy, edgeWarningActive)
    if not self:GetSetting("reticleEnabled") or #reticleSegments == 0 then
        return
    end

    -- Update rotation
    addon.reticleRotation = (addon.reticleRotation + elapsed * self:GetSetting("reticleRotationSpeed")) % (math.pi * 2)

    -- Detect mouseover unit type
    local unitType = "default"
    local mouseoverUnit = "mouseover"

    if UnitExists(mouseoverUnit) then
        if UnitCanAttack("player", mouseoverUnit) and not UnitIsDead(mouseoverUnit) then
            unitType = "enemy"
        elseif UnitIsFriend("player", mouseoverUnit) and not UnitIsUnit("player", mouseoverUnit) then
            unitType = "friendly"
        end
    elseif GameTooltip:IsShown() then
        -- Check if tooltip is showing but not a unit (interactive object)
        -- Use pcall to safely handle potential secret/tainted values
        local success, hasUnit = pcall(function()
            local unit = GameTooltip:GetUnit()
            return unit ~= nil
        end)
        if success and not hasUnit then
            unitType = "object"
        end
    end

    -- Set color based on unit type
    local r, g, b, alpha
    local brightness = self:GetSetting("reticleBrightness") or 1.0
    local opacity = self:GetSetting("reticleOpacity") or 0.7

    if unitType == "enemy" then
        r, g, b = 1.0 * brightness, 0.1 * brightness, 0.1 * brightness
        alpha = opacity * 1.2 -- Brighter for enemies
    elseif unitType == "friendly" then
        r, g, b = 0.1 * brightness, 1.0 * brightness, 0.1 * brightness
        alpha = opacity
    elseif unitType == "object" then
        r, g, b = 1.0 * brightness, 0.84 * brightness, 0.0 * brightness
        alpha = opacity
    else
        -- Default - use trail color
        local color = self:GetSetting("rainbowMode") and { addon.HSVtoRGB(addon.rainbowHue, 1, 1) }
            or self:GetSetting("color")
        r, g, b = color[1] * brightness, color[2] * brightness, color[3] * brightness
        alpha = opacity * 0.6
    end

    local baseSize = self:GetSetting("reticleSize") or 80
    local style = self:GetSetting("reticleStyle") or "military"

    -- Pulse effect for friendlies or edge warnings
    local pulse = 1.0
    if edgeWarningActive then
        -- Pulse with edge warnings (already calculated in UpdateEdgeWarnings)
        pulse = addon.edgeWarningPulse or 1.0
    elseif unitType == "friendly" then
        pulse = 0.7 + math.sin(GetTime() * 4) * 0.3
    end

    local size = baseSize * pulse

    -- Render reticle based on style
    if style == "crosshair" then
        addon:RenderCrosshairReticle(cx, cy, size, r, g, b, alpha * pulse, edgeWarningActive)
    elseif style == "circledot" then
        addon:RenderCircleDotReticle(cx, cy, size, r, g, b, alpha * pulse, edgeWarningActive)
    elseif style == "tshape" then
        addon:RenderTShapeReticle(cx, cy, size, r, g, b, alpha * pulse, unitType, edgeWarningActive)
    elseif style == "military" then
        addon:RenderMilitaryReticle(cx, cy, size, r, g, b, alpha * pulse, unitType, edgeWarningActive)
    elseif style == "cyberpunk" then
        addon:RenderCyberpunkReticle(cx, cy, size, r, g, b, alpha * pulse, unitType, edgeWarningActive)
    elseif style == "minimal" then
        addon:RenderMinimalReticle(cx, cy, size, r, g, b, alpha * pulse, edgeWarningActive)
    end
end

-- Crosshair Style: Classic + shape with center dot
function addon:RenderCrosshairReticle(x, y, size, r, g, b, alpha, edgeWarningActive)
    -- Top line
    local seg = reticleSegments[1]
    if seg then
        seg:SetSize(size * 0.04, size * 0.25)
        seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x, y + size * 0.35)
        seg:SetVertexColor(r, g, b)
        seg:SetAlpha(alpha)
        seg:Show()
    end

    -- Bottom line
    seg = reticleSegments[2]
    if seg then
        seg:SetSize(size * 0.04, size * 0.25)
        seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x, y - size * 0.35)
        seg:SetVertexColor(r, g, b)
        seg:SetAlpha(alpha)
        seg:Show()
    end

    -- Left line
    seg = reticleSegments[3]
    if seg then
        seg:SetSize(size * 0.25, size * 0.04)
        seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x - size * 0.35, y)
        seg:SetVertexColor(r, g, b)
        seg:SetAlpha(alpha)
        seg:Show()
    end

    -- Right line
    seg = reticleSegments[4]
    if seg then
        seg:SetSize(size * 0.25, size * 0.04)
        seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x + size * 0.35, y)
        seg:SetVertexColor(r, g, b)
        seg:SetAlpha(alpha)
        seg:Show()
    end

    -- Center dot (hide when edge warnings active)
    seg = reticleSegments[5]
    if seg then
        if edgeWarningActive == true then
            seg:Hide()
        else
            seg:SetSize(size * 0.08, size * 0.08)
            seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x, y)
            seg:SetVertexColor(r, g, b)
            seg:SetAlpha(alpha * 1.2) -- Brighter center
            seg:Show()
        end
    end
end

-- Circle Dot Style: Circle ring with center dot (Red Dot Sight)
function addon:RenderCircleDotReticle(x, y, size, r, g, b, alpha, edgeWarningActive)
    -- 8 segments forming a circle
    for i = 1, 8 do
        local seg = reticleSegments[i]
        if seg then
            local angle = (i - 1) * (math.pi / 4)
            local radius = size * 0.4
            local offsetX = math.cos(angle) * radius
            local offsetY = math.sin(angle) * radius

            seg:SetSize(size * 0.12, size * 0.04)
            seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x + offsetX, y + offsetY)
            seg:SetRotation(angle)
            seg:SetVertexColor(r, g, b)
            seg:SetAlpha(alpha)
            seg:Show()
        end
    end

    -- Center dot (hide when edge warnings active)
    local seg = reticleSegments[9]
    if seg then
        if edgeWarningActive == true then
            seg:Hide()
        else
            seg:SetSize(size * 0.1, size * 0.1)
            seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x, y)
            seg:SetVertexColor(r, g, b)
            seg:SetAlpha(alpha * 1.3) -- Very bright center
            seg:Show()
        end
    end
end

-- T-Shape Style: Rangefinder reticle (sniper scope)
function addon:RenderTShapeReticle(x, y, size, r, g, b, alpha, unitType, edgeWarningActive)
    -- Horizontal top bar
    local seg = reticleSegments[1]
    if seg then
        seg:SetSize(size * 0.6, size * 0.04)
        seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x, y + size * 0.4)
        seg:SetVertexColor(r, g, b)
        seg:SetAlpha(alpha)
        seg:Show()
    end

    -- Vertical center line (from top bar down)
    seg = reticleSegments[2]
    if seg then
        seg:SetSize(size * 0.04, size * 0.5)
        seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x, y + size * 0.15)
        seg:SetVertexColor(r, g, b)
        seg:SetAlpha(alpha)
        seg:Show()
    end

    -- Left tick mark (for range estimation)
    seg = reticleSegments[3]
    if seg then
        seg:SetSize(size * 0.08, size * 0.03)
        seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x - size * 0.15, y)
        seg:SetVertexColor(r, g, b)
        seg:SetAlpha(alpha * 0.8)
        seg:Show()
    end

    -- Right tick mark (for range estimation)
    seg = reticleSegments[4]
    if seg then
        seg:SetSize(size * 0.08, size * 0.03)
        seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x + size * 0.15, y)
        seg:SetVertexColor(r, g, b)
        seg:SetAlpha(alpha * 0.8)
        seg:Show()
    end

    -- Center reference dot (hide when edge warnings active)
    seg = reticleSegments[5]
    if seg then
        if edgeWarningActive == true then
            seg:Hide()
        else
            seg:SetSize(size * 0.06, size * 0.06)
            seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x, y - size * 0.1)
            seg:SetVertexColor(r, g, b)
            seg:SetAlpha(alpha * 1.1)
            seg:Show()
        end
    end
end

-- Military Style: 4 corner brackets + 4 rotating segments (sniper-style)
function addon:RenderMilitaryReticle(x, y, size, r, g, b, alpha, unitType, edgeWarningActive)
    local rotation = addon.reticleRotation
    local rotSpeed = unitType == "enemy" and 2.0 or 1.0

    -- 4 static corner brackets
    for i = 1, 4 do
        local seg = reticleSegments[i]
        if seg then
            local angle = (i - 1) * (math.pi / 2)
            local offsetX = math.cos(angle) * size * 0.35
            local offsetY = math.sin(angle) * size * 0.35

            seg:SetSize(size * 0.25, size * 0.08)
            seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x + offsetX, y + offsetY)
            seg:SetRotation(angle)
            seg:SetVertexColor(r, g, b)
            seg:SetAlpha(alpha)
            seg:Show()
        end
    end

    -- 4 rotating segments (only for enemies or when hovering something)
    local showRotating = unitType ~= "default"
    for i = 5, 8 do
        local seg = reticleSegments[i]
        if seg then
            if showRotating then
                local angle = rotation * rotSpeed + (i - 5) * (math.pi / 2)
                local offsetX = math.cos(angle) * size * 0.5
                local offsetY = math.sin(angle) * size * 0.5

                seg:SetSize(size * 0.2, size * 0.05)
                seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x + offsetX, y + offsetY)
                seg:SetRotation(angle + math.pi / 2)
                seg:SetVertexColor(r, g, b)
                seg:SetAlpha(alpha * 0.8)
                seg:Show()
            else
                seg:Hide()
            end
        end
    end
end

-- Cyberpunk Style: 8 glowing neon segments in a circle
function addon:RenderCyberpunkReticle(x, y, size, r, g, b, alpha, unitType, edgeWarningActive)
    local rotation = addon.reticleRotation

    for i = 1, 8 do
        local seg = reticleSegments[i]
        if seg then
            local angle = rotation + (i - 1) * (math.pi / 4)
            local radius = size * 0.45
            local offsetX = math.cos(angle) * radius
            local offsetY = math.sin(angle) * radius

            -- Alternating segment lengths for cyber effect
            local segLength = (i % 2 == 0) and size * 0.15 or size * 0.25

            seg:SetSize(segLength, size * 0.04)
            seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x + offsetX, y + offsetY)
            seg:SetRotation(angle)
            seg:SetVertexColor(r, g, b)
            seg:SetAlpha(alpha)
            seg:Show()
        end
    end
end

-- Minimal Style: Simple 4 corner L-brackets
function addon:RenderMinimalReticle(x, y, size, r, g, b, alpha, edgeWarningActive)
    for i = 1, 4 do
        local seg = reticleSegments[i]
        if seg then
            local angle = (i - 1) * (math.pi / 2) + (math.pi / 4)
            local offsetX = math.cos(angle) * size * 0.4
            local offsetY = math.sin(angle) * size * 0.4

            seg:SetSize(size * 0.15, size * 0.03)
            seg:SetPoint("CENTER", parent, "BOTTOMLEFT", x + offsetX, y + offsetY)
            seg:SetRotation(angle - math.pi / 4)
            seg:SetVertexColor(r, g, b)
            seg:SetAlpha(alpha)
            seg:Show()
        end
    end
end
