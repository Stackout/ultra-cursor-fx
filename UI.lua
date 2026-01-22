-- ===============================
-- UltraCursorFX - UI Module
-- ===============================

local addon = UltraCursorFX

function addon:CreateSettingsPanel()
    local settingsPanel = CreateFrame("Frame", "UltraCursorFXPanel")
    settingsPanel.name = "UltraCursorFX"

    -- Store UI control references for refreshing
    local uiControls = {}
    local RefreshUI -- Forward declaration
    local SetupColorSwatch -- Forward declaration

    -- Track which profile is currently being edited for auto-save
    local currentEditingProfile = addon.currentZoneProfile or "world"
    local isLoadingProfile = false -- Disable auto-save during profile load

    -- Auto-save function - saves current settings to the active profile
    local function AutoSaveToProfile()
        if isLoadingProfile then
            return -- Don't auto-save while loading a profile
        end
        if currentEditingProfile then
            addon:SaveToProfile(currentEditingProfile)
            -- Update UI indicators immediately
            if uiControls.profileSwatches and uiControls.profileSwatches[currentEditingProfile] then
                local swatchData = uiControls.profileSwatches[currentEditingProfile]
                SetupColorSwatch(swatchData.swatch, UltraCursorFXDB.profiles[currentEditingProfile])
                local profile = UltraCursorFXDB.profiles[currentEditingProfile]
                swatchData.rainbowIndicator:SetText(profile and profile.rainbowMode and "|cFFFFFF00R|r" or "")
            end
            -- Update active indicator if this is the current zone profile
            if addon.currentZoneProfile == currentEditingProfile and uiControls.activeColorSwatch then
                SetupColorSwatch(uiControls.activeColorSwatch, UltraCursorFXDB.profiles[currentEditingProfile])
                if uiControls.activeRainbowIndicator then
                    local profile = UltraCursorFXDB.profiles[currentEditingProfile]
                    uiControls.activeRainbowIndicator:SetText(profile and profile.rainbowMode and "|cFFFFFF00R|r" or "")
                end
            end
        end
    end

    -- Scrollable content
    local scroll = CreateFrame("ScrollFrame", nil, settingsPanel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 3, -4)
    scroll:SetPoint("BOTTOMRIGHT", -27, 4)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    -- Icon
    local iconFrame = CreateFrame("Frame", nil, content)
    iconFrame:SetSize(64, 64)
    iconFrame:SetPoint("TOPLEFT", 16, -16)

    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\AddOns\\UltraCursorFX\\icon.png")

    local iconBorder = iconFrame:CreateTexture(nil, "BACKGROUND")
    iconBorder:SetAllPoints()
    iconBorder:SetColorTexture(0.2, 0.2, 0.2, 0.5)

    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("LEFT", iconFrame, "RIGHT", 10, 8)
    title:SetText("UltraCursorFX Settings")

    local subtitle = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Customize your cursor trail effects")

    -- Helper functions
    local function CreateCheckbox(name, label, yOffset, tooltip)
        local cb = CreateFrame("CheckButton", nil, content, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 20, yOffset)
        cb:SetSize(26, 26) -- Moderate checkbox size
        cb.Text:SetText(label)
        -- Increase font size if GetFont is available (not in tests)
        if cb.Text.GetFont then
            local fontPath, _, fontFlags = cb.Text:GetFont()
            if fontPath then
                cb.Text:SetFont(fontPath, 12, fontFlags)
            end
        end
        cb.tooltipText = tooltip
        return cb
    end

    local function CreateSlider(name, label, yOffset, minVal, maxVal, step, tooltip)
        local slider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 20, yOffset)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        slider:SetWidth(200)

        slider.Text:SetText(label)
        slider.Low:SetText(minVal)
        slider.High:SetText(maxVal)
        slider.tooltipText = tooltip

        local valueText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        valueText:SetPoint("TOP", slider, "BOTTOM", 0, 0)
        slider.valueText = valueText

        return slider
    end

    local function CreateColorPicker(name, label, yOffset)
        local btn = CreateFrame("Button", nil, content)
        btn:SetSize(24, 24)
        btn:SetPoint("TOPLEFT", 20, yOffset)

        local texture = btn:CreateTexture(nil, "BACKGROUND")
        texture:SetAllPoints()
        texture:SetColorTexture(1, 1, 1)
        btn.texture = texture

        local labelText = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        labelText:SetPoint("LEFT", btn, "RIGHT", 8, 0)
        labelText:SetText(label)

        return btn
    end

    local function CreateSection(label, yOffset)
        local section = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        section:SetPoint("TOPLEFT", 16, yOffset)
        section:SetText("|cFFFFD700" .. label .. "|r")

        local line = content:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("TOPLEFT", section, "BOTTOMLEFT", 0, -4)
        line:SetPoint("RIGHT", content, -40, 0)
        line:SetColorTexture(1, 0.82, 0, 0.3)

        return yOffset - 40 -- More spacing after section headers
    end

    -- Helper to setup color swatch (solid or rainbow)
    SetupColorSwatch = function(swatch, profile)
        if not swatch then
            return
        end

        if profile and profile.rainbowMode then
            -- Rainbow mode: use a distinctive magenta/pink to indicate rainbow
            swatch:SetColorTexture(1.0, 0.0, 1.0) -- Bright magenta
        elseif profile and profile.color then
            swatch:SetColorTexture(unpack(profile.color))
        else
            -- Default: use current color or cyan
            local defaultColor = UltraCursorFXDB.color or { 0.0, 1.0, 1.0 }
            swatch:SetColorTexture(unpack(defaultColor))
        end
    end

    local yPos = -100

    -- IMPORT/EXPORT (Top placement for visibility)
    yPos = CreateSection("Share & Import Settings", yPos)

    local shareDesc = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    shareDesc:SetPoint("TOPLEFT", 20, yPos)
    shareDesc:SetText("Share your cursor with friends or import someone else's configuration")
    yPos = yPos - 25

    -- Export row
    local exportBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    exportBtn:SetSize(80, 24)
    exportBtn:SetPoint("TOPLEFT", 20, yPos)
    exportBtn:SetText("Export")

    local exportEditBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    exportEditBox:SetSize(440, 20)
    exportEditBox:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
    exportEditBox:SetAutoFocus(false)
    exportEditBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    exportEditBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    exportEditBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    exportEditBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
    end)

    exportBtn:SetScript("OnClick", function()
        local exportString = addon:ExportSettings()
        exportEditBox:SetText(exportString)
        exportEditBox:HighlightText()
        exportEditBox:SetFocus()
        print("|cFF00FFFFUltraCursorFX:|r Settings exported! Press Ctrl+C to copy.")
    end)
    yPos = yPos - 35

    -- Import row
    local importBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    importBtn:SetSize(80, 24)
    importBtn:SetPoint("TOPLEFT", 20, yPos)
    importBtn:SetText("Import")

    local importEditBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    importEditBox:SetSize(440, 20)
    importEditBox:SetPoint("LEFT", importBtn, "RIGHT", 8, 0)
    importEditBox:SetAutoFocus(false)
    importEditBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    importBtn:SetScript("OnClick", function()
        local importString = importEditBox:GetText()
        local success, message = addon:ImportSettings(importString)
        if success then
            addon:BuildTrail()
            print("|cFF00FFFFUltraCursorFX:|r " .. message)
            -- Refresh UI to show imported values
            if settingsPanel.RefreshUI then
                settingsPanel.RefreshUI()
            end
        else
            print("|cFFFF0000UltraCursorFX Error:|r " .. message)
        end
    end)

    importEditBox:SetScript("OnEnterPressed", function(self)
        importBtn:Click()
        self:ClearFocus()
    end)
    yPos = yPos - 40

    -- SITUATIONAL PROFILES
    yPos = CreateSection("Situational Profiles", yPos)

    local situationalDesc = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    situationalDesc:SetPoint("TOPLEFT", 20, yPos)
    situationalDesc:SetText("Auto-switch cursor effects in raids, dungeons, arenas & battlegrounds")
    yPos = yPos - 30

    local situationalCB = CreateCheckbox(
        "SituationalEnabled",
        "Enable Situational Cursors",
        yPos,
        "Automatically apply different cursor effects based on your location"
    )
    situationalCB:SetChecked(UltraCursorFXDB.situationalEnabled)
    situationalCB:SetScript("OnClick", function(self)
        UltraCursorFXDB.situationalEnabled = self:GetChecked()
        if UltraCursorFXDB.situationalEnabled then
            addon:SwitchToZoneProfile()
        end
    end)
    yPos = yPos - 50

    -- Active Profile Indicator
    local activeProfileFrame = CreateFrame("Frame", nil, content)
    activeProfileFrame:SetSize(400, 30)
    activeProfileFrame:SetPoint("TOPLEFT", 20, yPos)

    local activeProfileBg = activeProfileFrame:CreateTexture(nil, "BACKGROUND")
    activeProfileBg:SetAllPoints()
    activeProfileBg:SetColorTexture(0.1, 0.3, 0.1, 0.5)

    local currentProfile = UltraCursorFXDB.profiles[addon.currentZoneProfile]
    local currentProfileName = currentProfile and currentProfile.name or "World"

    local activeColorSwatch = activeProfileFrame:CreateTexture(nil, "ARTWORK")
    activeColorSwatch:SetSize(20, 20)
    activeColorSwatch:SetPoint("LEFT", 8, 0)
    SetupColorSwatch(activeColorSwatch, currentProfile)
    uiControls.activeColorSwatch = activeColorSwatch

    -- Rainbow indicator for active profile
    local activeRainbowIndicator = activeProfileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    activeRainbowIndicator:SetPoint("CENTER", activeColorSwatch, "CENTER", 0, 0)
    activeRainbowIndicator:SetText(currentProfile and currentProfile.rainbowMode and "|cFFFFFF00R|r" or "")
    uiControls.activeRainbowIndicator = activeRainbowIndicator

    local activeProfileLabel = activeProfileFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    activeProfileLabel:SetPoint("LEFT", activeColorSwatch, "RIGHT", 10, 0)
    activeProfileLabel:SetText("Editing: |cFFFFD700" .. currentProfileName .. "|r |cFF888888(auto-saves)|r")
    uiControls.activeProfileLabel = activeProfileLabel
    yPos = yPos - 45

    -- Profile Management Grid
    local profilesLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    profilesLabel:SetPoint("TOPLEFT", 20, yPos)
    profilesLabel:SetText("Profiles:")
    yPos = yPos - 20

    local colorLegend = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    colorLegend:SetPoint("TOPLEFT", 20, yPos)
    colorLegend:SetText(
        "|cFF888888Click to switch • Changes auto-save • Color = cursor •  |cFFFF00FFR|r = rainbow|r"
    )
    yPos = yPos - 25

    -- Store profile swatches for updates
    uiControls.profileSwatches = {}

    local profileButtons = {
        { key = "world", name = "World", desc = "Default / Open World" },
        { key = "raid", name = "Raid", desc = "Raid Instances" },
        { key = "dungeon", name = "Dungeon", desc = "5-Man Dungeons" },
        { key = "arena", name = "Arena", desc = "PvP Arenas" },
        { key = "battleground", name = "Battleground", desc = "PvP Battlegrounds" },
    }

    for _, profileInfo in ipairs(profileButtons) do
        local xOffset = 20
        local yOffset = yPos

        local profileFrame = CreateFrame("Button", nil, content)
        profileFrame:SetSize(500, 32)
        profileFrame:SetPoint("TOPLEFT", xOffset, yOffset)

        local profileBg = profileFrame:CreateTexture(nil, "BACKGROUND")
        profileBg:SetAllPoints()
        profileBg:SetColorTexture(0.15, 0.15, 0.15, 0.6)

        -- Highlight on hover
        profileFrame:SetScript("OnEnter", function(self)
            profileBg:SetColorTexture(0.2, 0.25, 0.2, 0.8)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Click to edit this profile\nChanges will auto-save")
            GameTooltip:Show()
        end)
        profileFrame:SetScript("OnLeave", function(self)
            profileBg:SetColorTexture(0.15, 0.15, 0.15, 0.6)
            GameTooltip:Hide()
        end)

        local colorSwatch = profileFrame:CreateTexture(nil, "ARTWORK")
        colorSwatch:SetSize(24, 24)
        colorSwatch:SetPoint("LEFT", 4, 0)
        SetupColorSwatch(colorSwatch, UltraCursorFXDB.profiles[profileInfo.key])

        -- Rainbow indicator overlay
        local rainbowIndicator = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        rainbowIndicator:SetPoint("CENTER", colorSwatch, "CENTER", 0, 0)
        local profile = UltraCursorFXDB.profiles[profileInfo.key]
        rainbowIndicator:SetText(profile and profile.rainbowMode and "|cFFFFFF00R|r" or "")

        -- Store for updates
        uiControls.profileSwatches[profileInfo.key] = {
            swatch = colorSwatch,
            rainbowIndicator = rainbowIndicator,
        }

        local nameLabel = profileFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        nameLabel:SetPoint("LEFT", colorSwatch, "RIGHT", 8, 4)
        nameLabel:SetText(profileInfo.name)

        local descLabel = profileFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        descLabel:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -2)
        descLabel:SetText("|cFF888888" .. profileInfo.desc .. "|r")

        -- Click entire frame to switch profiles
        profileFrame:SetScript("OnClick", function()
            isLoadingProfile = true
            currentEditingProfile = profileInfo.key
            addon:LoadFromProfile(profileInfo.key)
            uiControls.activeProfileLabel:SetText(
                "Editing: |cFFFFD700" .. profileInfo.name .. "|r |cFF888888(auto-saves)|r"
            )
            SetupColorSwatch(uiControls.activeColorSwatch, UltraCursorFXDB.profiles[profileInfo.key])
            uiControls.activeRainbowIndicator:SetText(
                UltraCursorFXDB.profiles[profileInfo.key]
                        and UltraCursorFXDB.profiles[profileInfo.key].rainbowMode
                        and "|cFFFFFF00R|r"
                    or ""
            )
            RefreshUI()
            isLoadingProfile = false
        end)

        yPos = yPos - 36
    end
    yPos = yPos - 10

    local profileTip = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    profileTip:SetPoint("TOPLEFT", 20, yPos)
    profileTip:SetText("|cFF88FF88Auto-save enabled:|r Changes are saved to the active profile immediately")
    yPos = yPos - 40

    -- BASIC SETTINGS
    yPos = CreateSection("Basic Settings", yPos)

    local enableCB = CreateCheckbox("Enable", "Enable Cursor Trail", yPos, "Toggle the cursor trail effect on/off")
    enableCB:SetChecked(UltraCursorFXDB.enabled)
    enableCB:SetScript("OnClick", function(self)
        UltraCursorFXDB.enabled = self:GetChecked()
        if UltraCursorFXDB.enabled then
            addon.frame:SetScript("OnUpdate", function(_, elapsed)
                addon:OnUpdate(elapsed)
            end)
        else
            addon.frame:SetScript("OnUpdate", nil)
        end
        AutoSaveToProfile()
    end)
    yPos = yPos - 40
    uiControls.enableCB = enableCB

    local flashCB = CreateCheckbox("Flash", "Enable Pulse Flash", yPos, "HDR flash effect synchronized with pulse")
    flashCB:SetChecked(UltraCursorFXDB.flashEnabled)
    flashCB:SetScript("OnClick", function(self)
        UltraCursorFXDB.flashEnabled = self:GetChecked()
        AutoSaveToProfile()
    end)
    yPos = yPos - 50
    uiControls.flashCB = flashCB

    -- TRAIL SETTINGS
    yPos = CreateSection("Trail Settings", yPos)

    local trailDesc = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    trailDesc:SetPoint("TOPLEFT", 20, yPos)
    trailDesc:SetText("Adjust the appearance and behavior of your cursor trail")
    yPos = yPos - 25

    local pointsSlider = CreateSlider(
        "Points",
        "Trail Length (Points)",
        yPos,
        10,
        100,
        1,
        "More points = longer trail | Fewer = shorter, snappier"
    )
    pointsSlider:SetValue(UltraCursorFXDB.points or 48)
    pointsSlider.valueText:SetText(UltraCursorFXDB.points or 48)
    pointsSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        UltraCursorFXDB.points = value
        self.valueText:SetText(value .. " points")
        addon:BuildTrail()
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.pointsSlider = pointsSlider

    local sizeSlider =
        CreateSlider("Size", "Particle Size", yPos, 10, 100, 1, "Bigger = more visible | Smaller = subtle")
    sizeSlider:SetValue(UltraCursorFXDB.size or 34)
    sizeSlider.valueText:SetText(UltraCursorFXDB.size or 34)
    sizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        UltraCursorFXDB.size = value
        self.valueText:SetText(value .. "px")
        addon:BuildTrail()
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.sizeSlider = sizeSlider

    local glowSlider =
        CreateSlider("GlowSize", "Glow Intensity", yPos, 10, 150, 1, "Larger = brighter glow around particles")
    glowSlider:SetValue(UltraCursorFXDB.glowSize or 64)
    glowSlider.valueText:SetText(UltraCursorFXDB.glowSize or 64)
    glowSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        UltraCursorFXDB.glowSize = value
        self.valueText:SetText(value .. "px")
        addon:BuildTrail()
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.glowSlider = glowSlider

    local smoothSlider = CreateSlider(
        "Smooth",
        "Smoothness",
        yPos,
        0.05,
        0.50,
        0.01,
        "Higher = smoother, floaty | Lower = tight, responsive"
    )
    smoothSlider:SetValue(UltraCursorFXDB.smoothness or 0.18)
    smoothSlider.valueText:SetText(string.format("%.2f", UltraCursorFXDB.smoothness or 0.18))
    smoothSlider:SetScript("OnValueChanged", function(self, value)
        UltraCursorFXDB.smoothness = value
        local desc = value < 0.15 and "(Snappy)" or value > 0.30 and "(Floaty)" or "(Balanced)"
        self.valueText:SetText(string.format("%.2f %s", value, desc))
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.smoothSlider = smoothSlider

    local pulseSlider = CreateSlider("Pulse", "Pulse Speed", yPos, 0.5, 5.0, 0.1, "How fast the trail pulses/breathes")
    pulseSlider:SetValue(UltraCursorFXDB.pulseSpeed or 2.5)
    pulseSlider.valueText:SetText(string.format("%.1f", UltraCursorFXDB.pulseSpeed or 2.5))
    pulseSlider:SetScript("OnValueChanged", function(self, value)
        UltraCursorFXDB.pulseSpeed = value
        local desc = value < 1.5 and "(Slow)" or value > 3.5 and "(Fast)" or "(Medium)"
        self.valueText:SetText(string.format("%.1f %s", value, desc))
        AutoSaveToProfile()
    end)
    yPos = yPos - 70
    uiControls.pulseSlider = pulseSlider

    -- PARTICLE SHAPE
    yPos = CreateSection("Particle Shape", yPos)

    local shapeLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    shapeLabel:SetPoint("TOPLEFT", 20, yPos)
    shapeLabel:SetText("Shape:")

    local shapes = {
        { id = "star", name = "Star", tooltip = "Classic sparkly star" },
        { id = "skull", name = "Skull", tooltip = "Spooky skull marker" },
        { id = "spark", name = "Spark", tooltip = "Bright spark" },
        { id = "dot", name = "Circle", tooltip = "Simple circle" },
    }

    for i, shape in ipairs(shapes) do
        local btn = CreateFrame("Button", nil, content)
        btn:SetSize(70, 24)
        btn:SetPoint("TOPLEFT", 80 + (i - 1) * 75, yPos)
        btn:SetNormalFontObject("GameFontNormal")
        btn:SetHighlightFontObject("GameFontHighlight")
        btn:SetText(shape.name)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        btn.bg = bg

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(shape.tooltip)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        btn:SetScript("OnClick", function()
            UltraCursorFXDB.particleShape = shape.id
            -- Update button highlights first
            for _, s in ipairs(shapes) do
                local b = _G["ShapeBtn" .. s.id]
                if b and b.bg then
                    b.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
                end
            end
            bg:SetColorTexture(0.2, 0.6, 0.2, 0.8)
            -- Then rebuild and save
            addon:BuildTrail()
            AutoSaveToProfile()
        end)

        _G["ShapeBtn" .. shape.id] = btn

        if UltraCursorFXDB.particleShape == shape.id then
            bg:SetColorTexture(0.2, 0.6, 0.2, 0.8)
        end
    end
    yPos = yPos - 40

    -- COLOR SETTINGS
    yPos = CreateSection("Color Settings", yPos)

    local rainbowCB = CreateCheckbox("Rainbow", "Rainbow Mode", yPos, "Automatically cycle through rainbow colors")
    rainbowCB:SetChecked(UltraCursorFXDB.rainbowMode)
    rainbowCB:SetScript("OnClick", function(self)
        UltraCursorFXDB.rainbowMode = self:GetChecked()
        AutoSaveToProfile()
    end)
    yPos = yPos - 50
    uiControls.rainbowCB = rainbowCB

    local rainbowSlider = CreateSlider("RainbowSpeed", "Rainbow Speed", yPos, 0.1, 5.0, 0.1, "Speed of color cycling")
    rainbowSlider:SetValue(UltraCursorFXDB.rainbowSpeed or 1.0)
    rainbowSlider.valueText:SetText(string.format("%.1f", UltraCursorFXDB.rainbowSpeed or 1.0))
    rainbowSlider:SetScript("OnValueChanged", function(self, value)
        UltraCursorFXDB.rainbowSpeed = value
        self.valueText:SetText(string.format("%.1f", value))
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.rainbowSlider = rainbowSlider

    local function ShowColorPicker(onChange)
        local r, g, b = UltraCursorFXDB.color[1], UltraCursorFXDB.color[2], UltraCursorFXDB.color[3]
        local info = {
            r = r,
            g = g,
            b = b,
            opacity = 1.0,
            hasOpacity = false,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                UltraCursorFXDB.color = { nr, ng, nb }
                UltraCursorFXDB.rainbowMode = false
                rainbowCB:SetChecked(false)
                addon:BuildTrail()
                AutoSaveToProfile()
                if onChange then
                    onChange(nr, ng, nb)
                end
            end,
            cancelFunc = function()
                UltraCursorFXDB.color = { r, g, b }
                addon:BuildTrail()
                AutoSaveToProfile()
                if onChange then
                    onChange(r, g, b)
                end
            end,
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end

    local colorBtn = CreateColorPicker("Color", "Custom Color", yPos)
    colorBtn.texture:SetColorTexture(unpack(UltraCursorFXDB.color))
    colorBtn:SetScript("OnClick", function(self)
        ShowColorPicker(function(r, g, b)
            self.texture:SetColorTexture(r, g, b)
        end)
    end)
    yPos = yPos - 40
    uiControls.colorBtn = colorBtn

    local presets = {
        { name = "Cyan", color = { 0.0, 1.0, 1.0 } },
        { name = "Purple", color = { 0.8, 0.2, 1.0 } },
        { name = "Green", color = { 0.0, 1.0, 0.0 } },
        { name = "Red", color = { 1.0, 0.2, 0.2 } },
        { name = "Gold", color = { 1.0, 0.84, 0.0 } },
        { name = "White", color = { 1.0, 1.0, 1.0 } },
    }

    local presetLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    presetLabel:SetPoint("TOPLEFT", 20, yPos)
    presetLabel:SetText("Presets:")

    for i, preset in ipairs(presets) do
        local btn = CreateFrame("Button", nil, content)
        btn:SetSize(60, 22)
        btn:SetPoint("TOPLEFT", 80 + (i - 1) * 65, yPos)
        btn:SetNormalFontObject("GameFontNormal")
        btn:SetHighlightFontObject("GameFontHighlight")
        btn:SetText(preset.name)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

        btn:SetScript("OnClick", function()
            UltraCursorFXDB.color = { unpack(preset.color) }
            UltraCursorFXDB.rainbowMode = false
            rainbowCB:SetChecked(false)
            colorBtn.texture:SetColorTexture(unpack(preset.color))
            addon:BuildTrail()
            AutoSaveToProfile()
        end)
    end
    yPos = yPos - 40

    -- CLICK EFFECTS
    yPos = CreateSection("Click Effects", yPos)

    local clickCB = CreateCheckbox("ClickFX", "Enable Click Effects", yPos, "Particle burst when clicking")
    clickCB:SetChecked(UltraCursorFXDB.clickEffects)
    clickCB:SetScript("OnClick", function(self)
        UltraCursorFXDB.clickEffects = self:GetChecked()
        AutoSaveToProfile()
    end)
    yPos = yPos - 50
    uiControls.clickCB = clickCB

    local clickParticlesSlider =
        CreateSlider("ClickParticles", "Click Particles", yPos, 4, 24, 1, "Number of particles per click")
    clickParticlesSlider:SetValue(UltraCursorFXDB.clickParticles or 12)
    clickParticlesSlider.valueText:SetText(UltraCursorFXDB.clickParticles or 12)
    clickParticlesSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        UltraCursorFXDB.clickParticles = value
        self.valueText:SetText(value)
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.clickParticlesSlider = clickParticlesSlider

    local clickSizeSlider =
        CreateSlider("ClickSize", "Click Particle Size", yPos, 20, 100, 1, "Size of click particles")
    clickSizeSlider:SetValue(UltraCursorFXDB.clickSize or 50)
    clickSizeSlider.valueText:SetText(UltraCursorFXDB.clickSize or 50)
    clickSizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        UltraCursorFXDB.clickSize = value
        self.valueText:SetText(value)
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.clickSizeSlider = clickSizeSlider

    local clickDurationSlider =
        CreateSlider("ClickDuration", "Click Effect Duration", yPos, 0.2, 2.0, 0.1, "How long click effects last")
    clickDurationSlider:SetValue(UltraCursorFXDB.clickDuration or 0.6)
    clickDurationSlider.valueText:SetText(string.format("%.1f", UltraCursorFXDB.clickDuration or 0.6))
    clickDurationSlider:SetScript("OnValueChanged", function(self, value)
        UltraCursorFXDB.clickDuration = value
        self.valueText:SetText(string.format("%.1f", value))
        AutoSaveToProfile()
    end)
    yPos = yPos - 70
    uiControls.clickDurationSlider = clickDurationSlider

    -- COMET MODE
    yPos = CreateSection("Comet Mode", yPos)

    local cometCB = CreateCheckbox("Comet", "Enable Comet Mode", yPos, "Elongated trailing effect")
    cometCB:SetChecked(UltraCursorFXDB.cometMode)
    cometCB:SetScript("OnClick", function(self)
        UltraCursorFXDB.cometMode = self:GetChecked()
        AutoSaveToProfile()
    end)
    yPos = yPos - 50
    uiControls.cometCB = cometCB

    local cometSlider =
        CreateSlider("CometLength", "Comet Tail Length", yPos, 1.0, 5.0, 0.1, "Length multiplier for comet tail")
    cometSlider:SetValue(UltraCursorFXDB.cometLength or 2.0)
    cometSlider.valueText:SetText(string.format("%.1f", UltraCursorFXDB.cometLength or 2.0))
    cometSlider:SetScript("OnValueChanged", function(self, value)
        UltraCursorFXDB.cometLength = value
        self.valueText:SetText(string.format("%.1f", value))
        addon:BuildTrail()
        AutoSaveToProfile()
    end)
    yPos = yPos - 80
    uiControls.cometSlider = cometSlider

    -- KEYBINDINGS REMINDER
    yPos = CreateSection("Quick Toggle", yPos)

    local keybindNote = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    keybindNote:SetPoint("TOPLEFT", 20, yPos)
    keybindNote:SetText("Set a hotkey to quickly toggle the cursor trail on/off!")
    yPos = yPos - 25

    local keybindInstructions = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    keybindInstructions:SetPoint("TOPLEFT", 20, yPos)
    keybindInstructions:SetText("Go to |cFFFFD700ESC > Keybindings > Toggle Cursor Trail|r to assign your hotkey.")
    yPos = yPos - 50

    -- CREDITS
    yPos = CreateSection("Credits", yPos)

    local authorText = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    authorText:SetPoint("TOPLEFT", 20, yPos)
    authorText:SetText("|cFFFFD700Author:|r Ryan Hein")
    yPos = yPos - 25

    local githubLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    githubLabel:SetPoint("TOPLEFT", 20, yPos)
    githubLabel:SetText("|cFFFFD700GitHub:|r |cFF00FFFFhttps://github.com/Stackout/ultra-cursor-fx|r")
    yPos = yPos - 40

    content:SetHeight(math.abs(yPos) + 100)

    -- Function to refresh UI controls from current database values
    RefreshUI = function()
        -- Update checkboxes
        uiControls.enableCB:SetChecked(UltraCursorFXDB.enabled)
        uiControls.flashCB:SetChecked(UltraCursorFXDB.flashEnabled)
        uiControls.rainbowCB:SetChecked(UltraCursorFXDB.rainbowMode)
        uiControls.clickCB:SetChecked(UltraCursorFXDB.clickEffects)
        uiControls.cometCB:SetChecked(UltraCursorFXDB.cometMode)

        -- Update sliders
        uiControls.pointsSlider:SetValue(UltraCursorFXDB.points or 48)
        uiControls.pointsSlider.valueText:SetText(UltraCursorFXDB.points or 48)

        uiControls.sizeSlider:SetValue(UltraCursorFXDB.size or 34)
        uiControls.sizeSlider.valueText:SetText(UltraCursorFXDB.size or 34)

        uiControls.glowSlider:SetValue(UltraCursorFXDB.glowSize or 64)
        uiControls.glowSlider.valueText:SetText(UltraCursorFXDB.glowSize or 64)

        uiControls.smoothSlider:SetValue(UltraCursorFXDB.smoothness or 0.18)
        uiControls.smoothSlider.valueText:SetText(string.format("%.2f", UltraCursorFXDB.smoothness or 0.18))

        uiControls.pulseSlider:SetValue(UltraCursorFXDB.pulseSpeed or 2.5)
        uiControls.pulseSlider.valueText:SetText(string.format("%.1f", UltraCursorFXDB.pulseSpeed or 2.5))

        uiControls.rainbowSlider:SetValue(UltraCursorFXDB.rainbowSpeed or 1.0)
        uiControls.rainbowSlider.valueText:SetText(string.format("%.1f", UltraCursorFXDB.rainbowSpeed or 1.0))

        uiControls.clickParticlesSlider:SetValue(UltraCursorFXDB.clickParticles or 12)
        uiControls.clickParticlesSlider.valueText:SetText(UltraCursorFXDB.clickParticles or 12)

        uiControls.clickSizeSlider:SetValue(UltraCursorFXDB.clickSize or 50)
        uiControls.clickSizeSlider.valueText:SetText(UltraCursorFXDB.clickSize or 50)

        uiControls.clickDurationSlider:SetValue(UltraCursorFXDB.clickDuration or 0.6)
        uiControls.clickDurationSlider.valueText:SetText(string.format("%.1f", UltraCursorFXDB.clickDuration or 0.6))

        uiControls.cometSlider:SetValue(UltraCursorFXDB.cometLength or 2.0)
        uiControls.cometSlider.valueText:SetText(string.format("%.1f", UltraCursorFXDB.cometLength or 2.0))

        -- Update color button
        uiControls.colorBtn.texture:SetColorTexture(unpack(UltraCursorFXDB.color))

        -- Update particle shape button highlights
        for _, s in ipairs(shapes) do
            local b = _G["ShapeBtn" .. s.id]
            if b and b.bg then
                if UltraCursorFXDB.particleShape == s.id then
                    b.bg:SetColorTexture(0.2, 0.6, 0.2, 0.8)
                else
                    b.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
                end
            end
        end
    end

    -- Store refresh function for external use
    settingsPanel.RefreshUI = RefreshUI

    -- Register with Interface Options
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(settingsPanel, settingsPanel.name)
        Settings.RegisterAddOnCategory(category)
        settingsPanel.category = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(settingsPanel)
    end

    addon.settingsPanel = settingsPanel
end

-- ===============================
-- Keybinding Functions
-- ===============================
function UltraCursorFX_Toggle()
    local addon = UltraCursorFX
    UltraCursorFXDB.enabled = not UltraCursorFXDB.enabled
    if UltraCursorFXDB.enabled then
        addon.frame:SetScript("OnUpdate", function(_, elapsed)
            addon:OnUpdate(elapsed)
        end)
    else
        addon.frame:SetScript("OnUpdate", nil)
    end
    print("UltraCursorFX:", UltraCursorFXDB.enabled and "Enabled" or "Disabled")
end

function UltraCursorFX_ToggleFlash()
    UltraCursorFXDB.flashEnabled = not UltraCursorFXDB.flashEnabled
    print("UltraCursorFX Flash:", UltraCursorFXDB.flashEnabled and "Enabled" or "Disabled")
end
