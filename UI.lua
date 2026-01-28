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
                local profiles = addon:GetActiveProfileTable()
                SetupColorSwatch(swatchData.swatch, profiles[currentEditingProfile])
                local profile = profiles[currentEditingProfile]
                swatchData.rainbowIndicator:SetText(profile and profile.rainbowMode and "|cFFFFFF00R|r" or "")
            end
            -- Update active indicator if this is the current zone profile
            if addon.currentZoneProfile == currentEditingProfile and uiControls.activeColorSwatch then
                local profiles = addon:GetActiveProfileTable()
                SetupColorSwatch(uiControls.activeColorSwatch, profiles[currentEditingProfile])
                if uiControls.activeRainbowIndicator then
                    local profile = profiles[currentEditingProfile]
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
            local defaultColor = addon:GetSetting("color") or { 0.0, 1.0, 1.0 }
            swatch:SetColorTexture(unpack(defaultColor))
        end
    end

    local yPos = -100

    -- CHARACTER SELECTOR
    yPos = CreateSection("Character Settings", yPos)

    local charSelectorDesc = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    charSelectorDesc:SetPoint("TOPLEFT", 20, yPos)
    charSelectorDesc:SetText("Manage settings per character or share across all characters")
    yPos = yPos - 25

    -- Account-wide toggle
    local accountWideCB = CreateCheckbox(
        "UseAccountSettings",
        "Use Account-Wide Settings",
        yPos,
        "When enabled: All characters share the same cursor settings\nWhen disabled: This character has unique settings separate from other characters"
    )
    local currentCharKey = addon:GetCharacterKey()
    local charData = UltraCursorFXDB.characters and UltraCursorFXDB.characters[currentCharKey]
    accountWideCB:SetChecked(charData and charData.useAccountSettings)
    accountWideCB:SetScript("OnClick", function(self)
        addon:SetUseAccountSettings(self:GetChecked())
        if settingsPanel.RefreshUI then
            settingsPanel.RefreshUI()
        end
    end)
    uiControls.accountWideCB = accountWideCB
    yPos = yPos - 35

    -- Helper text explaining account-wide setting
    local accountWideHelp = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    accountWideHelp:SetPoint("TOPLEFT", 40, yPos)
    accountWideHelp:SetWidth(520)
    accountWideHelp:SetJustifyH("LEFT")
    if accountWideHelp.SetTextColor then
        accountWideHelp:SetTextColor(0.8, 0.8, 0.8)
    end
    if charData and charData.useAccountSettings then
        accountWideHelp:SetText(
            "|cFF00FF00Enabled:|r All your characters will use the same cursor appearance and behavior."
        )
    else
        accountWideHelp:SetText(
            "|cFFFFAA00Disabled:|r This character has its own unique cursor settings. Changes won't affect other characters."
        )
    end
    uiControls.accountWideHelp = accountWideHelp
    yPos = yPos - 30

    -- Character dropdown
    local charDropdownLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    charDropdownLabel:SetPoint("TOPLEFT", 20, yPos)
    charDropdownLabel:SetText("Viewing Character:")

    local charDropdown = CreateFrame("Frame", "UltraCursorFXCharDropdown", content, "UIDropDownMenuTemplate")
    charDropdown:SetPoint("LEFT", charDropdownLabel, "RIGHT", -10, -3)

    -- Store the currently selected character key for viewing
    settingsPanel.viewingCharKey = currentCharKey

    local function UpdateCharacterDropdown()
        local charList = addon:GetCharacterList()

        UIDropDownMenu_Initialize(charDropdown, function(self, level)
            local info = UIDropDownMenu_CreateInfo()

            -- Current character (this session)
            info.text = currentCharKey .. " |cFF00FF00(Current)|r"
            info.value = currentCharKey
            info.func = function()
                settingsPanel.viewingCharKey = currentCharKey
                UIDropDownMenu_SetSelectedValue(charDropdown, currentCharKey)
                if settingsPanel.RefreshUI then
                    settingsPanel.RefreshUI()
                end
            end
            info.checked = (settingsPanel.viewingCharKey == currentCharKey)
            UIDropDownMenu_AddButton(info)

            -- Other characters
            for _, char in ipairs(charList) do
                if char.key ~= currentCharKey then
                    info = UIDropDownMenu_CreateInfo()
                    info.text = char.key
                    info.value = char.key
                    info.func = function()
                        settingsPanel.viewingCharKey = char.key
                        UIDropDownMenu_SetSelectedValue(charDropdown, char.key)
                        if settingsPanel.RefreshUI then
                            settingsPanel.RefreshUI()
                        end
                    end
                    info.checked = (settingsPanel.viewingCharKey == char.key)
                    UIDropDownMenu_AddButton(info)
                end
            end
        end)

        UIDropDownMenu_SetSelectedValue(charDropdown, settingsPanel.viewingCharKey)
        UIDropDownMenu_SetWidth(charDropdown, 200)
        UIDropDownMenu_SetText(charDropdown, settingsPanel.viewingCharKey)
    end

    UpdateCharacterDropdown()
    uiControls.charDropdown = charDropdown
    uiControls.updateCharacterDropdown = UpdateCharacterDropdown

    yPos = yPos - 45

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
    situationalCB:SetChecked(addon:GetSetting("situationalEnabled"))
    situationalCB:SetScript("OnClick", function(self)
        addon:SetSetting("situationalEnabled", self:GetChecked())
        if addon:GetSetting("situationalEnabled") then
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

    local profiles = addon:GetActiveProfileTable()
    local currentProfile = profiles[addon.currentZoneProfile]
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

        local profilesTable = addon:GetActiveProfileTable()
        local colorSwatch = profileFrame:CreateTexture(nil, "ARTWORK")
        colorSwatch:SetSize(24, 24)
        colorSwatch:SetPoint("LEFT", 4, 0)
        SetupColorSwatch(colorSwatch, profilesTable[profileInfo.key])

        -- Rainbow indicator overlay
        local rainbowIndicator = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        rainbowIndicator:SetPoint("CENTER", colorSwatch, "CENTER", 0, 0)
        local profile = profiles[profileInfo.key]
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
            local profiles = addon:GetActiveProfileTable()
            SetupColorSwatch(uiControls.activeColorSwatch, profiles[profileInfo.key])
            uiControls.activeRainbowIndicator:SetText(
                profiles[profileInfo.key] and profiles[profileInfo.key].rainbowMode and "|cFFFFFF00R|r" or ""
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
    enableCB:SetChecked(addon:GetSetting("enabled"))
    enableCB:SetScript("OnClick", function(self)
        addon:SetSetting("enabled", self:GetChecked())
        addon:UpdateCursorState()
        AutoSaveToProfile()
    end)
    yPos = yPos - 40
    uiControls.enableCB = enableCB

    local flashCB = CreateCheckbox("Flash", "Enable Pulse Flash", yPos, "HDR flash effect synchronized with pulse")
    flashCB:SetChecked(addon:GetSetting("flashEnabled"))
    flashCB:SetScript("OnClick", function(self)
        addon:SetSetting("flashEnabled", self:GetChecked())
        AutoSaveToProfile()
    end)
    yPos = yPos - 40
    uiControls.flashCB = flashCB

    local combatCB = CreateCheckbox("CombatOnly", "Combat Only Mode", yPos, "Only show cursor trail during combat")
    combatCB:SetChecked(addon:GetSetting("combatOnly"))
    combatCB:SetScript("OnClick", function(self)
        addon:SetSetting("combatOnly", self:GetChecked())
        addon:UpdateCursorState()
        AutoSaveToProfile()
    end)
    yPos = yPos - 50
    uiControls.combatCB = combatCB

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
    pointsSlider:SetValue(addon:GetSetting("points") or 48)
    pointsSlider.valueText:SetText(addon:GetSetting("points") or 48)
    pointsSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        addon:SetSetting("points", value)
        self.valueText:SetText(value .. " points")
        addon:BuildTrail()
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.pointsSlider = pointsSlider

    local sizeSlider =
        CreateSlider("Size", "Particle Size", yPos, 10, 100, 1, "Bigger = more visible | Smaller = subtle")
    sizeSlider:SetValue(addon:GetSetting("size") or 34)
    sizeSlider.valueText:SetText(addon:GetSetting("size") or 34)
    sizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        addon:SetSetting("size", value)
        self.valueText:SetText(value .. "px")
        addon:BuildTrail()
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.sizeSlider = sizeSlider

    local glowSlider =
        CreateSlider("GlowSize", "Glow Intensity", yPos, 10, 150, 1, "Larger = brighter glow around particles")
    glowSlider:SetValue(addon:GetSetting("glowSize") or 64)
    glowSlider.valueText:SetText(addon:GetSetting("glowSize") or 64)
    glowSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        addon:SetSetting("glowSize", value)
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
    smoothSlider:SetValue(addon:GetSetting("smoothness") or 0.18)
    smoothSlider.valueText:SetText(string.format("%.2f", addon:GetSetting("smoothness") or 0.18))
    smoothSlider:SetScript("OnValueChanged", function(self, value)
        addon:SetSetting("smoothness", value)
        local desc = value < 0.15 and "(Snappy)" or value > 0.30 and "(Floaty)" or "(Balanced)"
        self.valueText:SetText(string.format("%.2f %s", value, desc))
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.smoothSlider = smoothSlider

    local pulseSlider = CreateSlider("Pulse", "Pulse Speed", yPos, 0.5, 5.0, 0.1, "How fast the trail pulses/breathes")
    pulseSlider:SetValue(addon:GetSetting("pulseSpeed") or 2.5)
    pulseSlider.valueText:SetText(string.format("%.1f", addon:GetSetting("pulseSpeed") or 2.5))
    pulseSlider:SetScript("OnValueChanged", function(self, value)
        addon:SetSetting("pulseSpeed", value)
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
            addon:SetSetting("particleShape", shape.id)
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

        if addon:GetSetting("particleShape") == shape.id then
            bg:SetColorTexture(0.2, 0.6, 0.2, 0.8)
        end
    end
    yPos = yPos - 40

    -- COLOR SETTINGS
    yPos = CreateSection("Color Settings", yPos)

    local rainbowCB = CreateCheckbox("Rainbow", "Rainbow Mode", yPos, "Automatically cycle through rainbow colors")
    rainbowCB:SetChecked(addon:GetSetting("rainbowMode"))
    rainbowCB:SetScript("OnClick", function(self)
        addon:SetSetting("rainbowMode", self:GetChecked())
        AutoSaveToProfile()
    end)
    yPos = yPos - 50
    uiControls.rainbowCB = rainbowCB

    local rainbowSlider = CreateSlider("RainbowSpeed", "Rainbow Speed", yPos, 0.1, 5.0, 0.1, "Speed of color cycling")
    rainbowSlider:SetValue(addon:GetSetting("rainbowSpeed") or 1.0)
    rainbowSlider.valueText:SetText(string.format("%.1f", addon:GetSetting("rainbowSpeed") or 1.0))
    rainbowSlider:SetScript("OnValueChanged", function(self, value)
        addon:SetSetting("rainbowSpeed", value)
        self.valueText:SetText(string.format("%.1f", value))
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.rainbowSlider = rainbowSlider

    local function ShowColorPicker(onChange)
        local r, g, b = addon:GetSetting("color")[1], addon:GetSetting("color")[2], addon:GetSetting("color")[3]
        local info = {
            r = r,
            g = g,
            b = b,
            opacity = 1.0,
            hasOpacity = false,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                addon:SetSetting("color", { nr, ng, nb })
                addon:SetSetting("rainbowMode", false)
                rainbowCB:SetChecked(false)
                addon:BuildTrail()
                AutoSaveToProfile()
                if onChange then
                    onChange(nr, ng, nb)
                end
            end,
            cancelFunc = function()
                addon:SetSetting("color", { r, g, b })
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
    colorBtn.texture:SetColorTexture(unpack(addon:GetSetting("color") or addon.defaults.color or { 0.0, 1.0, 1.0 }))
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
            addon:SetSetting("color", { unpack(preset.color) })
            addon:SetSetting("rainbowMode", false)
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
    clickCB:SetChecked(addon:GetSetting("clickEffects"))
    clickCB:SetScript("OnClick", function(self)
        addon:SetSetting("clickEffects", self:GetChecked())
        AutoSaveToProfile()
    end)
    yPos = yPos - 50
    uiControls.clickCB = clickCB

    local clickParticlesSlider =
        CreateSlider("ClickParticles", "Click Particles", yPos, 4, 24, 1, "Number of particles per click")
    clickParticlesSlider:SetValue(addon:GetSetting("clickParticles") or 12)
    clickParticlesSlider.valueText:SetText(addon:GetSetting("clickParticles") or 12)
    clickParticlesSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        addon:SetSetting("clickParticles", value)
        self.valueText:SetText(value)
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.clickParticlesSlider = clickParticlesSlider

    local clickSizeSlider =
        CreateSlider("ClickSize", "Click Particle Size", yPos, 20, 100, 1, "Size of click particles")
    clickSizeSlider:SetValue(addon:GetSetting("clickSize") or 50)
    clickSizeSlider.valueText:SetText(addon:GetSetting("clickSize") or 50)
    clickSizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        addon:SetSetting("clickSize", value)
        self.valueText:SetText(value)
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.clickSizeSlider = clickSizeSlider

    local clickDurationSlider =
        CreateSlider("ClickDuration", "Click Effect Duration", yPos, 0.2, 2.0, 0.1, "How long click effects last")
    clickDurationSlider:SetValue(addon:GetSetting("clickDuration") or 0.6)
    clickDurationSlider.valueText:SetText(string.format("%.1f", addon:GetSetting("clickDuration") or 0.6))
    clickDurationSlider:SetScript("OnValueChanged", function(self, value)
        addon:SetSetting("clickDuration", value)
        self.valueText:SetText(string.format("%.1f", value))
        AutoSaveToProfile()
    end)
    yPos = yPos - 70
    uiControls.clickDurationSlider = clickDurationSlider

    -- COMET MODE
    yPos = CreateSection("Comet Mode", yPos)

    local cometCB = CreateCheckbox("Comet", "Enable Comet Mode", yPos, "Elongated trailing effect")
    cometCB:SetChecked(addon:GetSetting("cometMode"))
    cometCB:SetScript("OnClick", function(self)
        addon:SetSetting("cometMode", self:GetChecked())
        AutoSaveToProfile()
    end)
    yPos = yPos - 50
    uiControls.cometCB = cometCB

    local cometSlider =
        CreateSlider("CometLength", "Comet Tail Length", yPos, 1.0, 5.0, 0.1, "Length multiplier for comet tail")
    cometSlider:SetValue(addon:GetSetting("cometLength") or 2.0)
    cometSlider.valueText:SetText(string.format("%.1f", addon:GetSetting("cometLength") or 2.0))
    cometSlider:SetScript("OnValueChanged", function(self, value)
        addon:SetSetting("cometLength", value)
        self.valueText:SetText(string.format("%.1f", value))
        addon:BuildTrail()
        AutoSaveToProfile()
    end)
    yPos = yPos - 80
    uiControls.cometSlider = cometSlider

    -- OPACITY & FADE
    yPos = CreateSection("Opacity & Fade", yPos)

    local opacitySlider =
        CreateSlider("Opacity", "Trail Opacity", yPos, 0.1, 1.0, 0.05, "Overall visibility of cursor trail")
    opacitySlider:SetValue(addon:GetSetting("opacity") or 1.0)
    opacitySlider.valueText:SetText(string.format("%d%%", math.floor((addon:GetSetting("opacity") or 1.0) * 100)))
    opacitySlider:SetScript("OnValueChanged", function(self, value)
        addon:SetSetting("opacity", value)
        self.valueText:SetText(string.format("%d%%", math.floor(value * 100)))
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.opacitySlider = opacitySlider

    local fadeCB = CreateCheckbox("Fade", "Enable Fade Mode", yPos, "Gradually fade particles from head to tail")
    fadeCB:SetChecked(addon:GetSetting("fadeEnabled"))
    fadeCB:SetScript("OnClick", function(self)
        addon:SetSetting("fadeEnabled", self:GetChecked())
        AutoSaveToProfile()
    end)
    yPos = yPos - 50
    uiControls.fadeCB = fadeCB

    local fadeStrengthSlider =
        CreateSlider("FadeStrength", "Fade Strength", yPos, 0.0, 1.0, 0.05, "How quickly particles fade along trail")
    fadeStrengthSlider:SetValue(addon:GetSetting("fadeStrength") or 0.5)
    fadeStrengthSlider.valueText:SetText(string.format("%.0f%%", (addon:GetSetting("fadeStrength") or 0.5) * 100))
    fadeStrengthSlider:SetScript("OnValueChanged", function(self, value)
        addon:SetSetting("fadeStrength", value)
        local desc = value < 0.3 and "(Subtle)" or value > 0.7 and "(Aggressive)" or "(Moderate)"
        self.valueText:SetText(string.format("%.0f%% %s", value * 100, desc))
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.fadeStrengthSlider = fadeStrengthSlider

    local combatBoostCB =
        CreateCheckbox("CombatBoost", "Combat Opacity Boost", yPos, "Increase trail visibility by 30% during combat")
    combatBoostCB:SetChecked(addon:GetSetting("combatOpacityBoost"))
    combatBoostCB:SetScript("OnClick", function(self)
        addon:SetSetting("combatOpacityBoost", self:GetChecked())
        AutoSaveToProfile()
    end)
    yPos = yPos - 70
    uiControls.combatBoostCB = combatBoostCB

    -- RETICLE SYSTEM
    yPos = CreateSection("Smart Reticle System", yPos)

    local reticleEnabledCB = CreateCheckbox(
        "ReticleEnabled",
        "Enable Smart Reticle",
        yPos,
        "Dynamic crosshair that changes based on mouseover target"
    )
    reticleEnabledCB:SetChecked(addon:GetSetting("reticleEnabled"))
    reticleEnabledCB:SetScript("OnClick", function(self)
        addon:SetSetting("reticleEnabled", self:GetChecked())
        addon:BuildTrail() -- Rebuild reticle
        AutoSaveToProfile()
    end)
    yPos = yPos - 50
    uiControls.reticleEnabledCB = reticleEnabledCB

    local reticleStyleLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    reticleStyleLabel:SetPoint("TOPLEFT", 20, yPos)
    reticleStyleLabel:SetText("Reticle Style")
    yPos = yPos - 25

    local reticleStyleDD = CreateFrame("Frame", "UltraCursorFXReticleStyleDD", content, "UIDropDownMenuTemplate")
    reticleStyleDD:SetPoint("TOPLEFT", 0, yPos)
    UIDropDownMenu_SetWidth(reticleStyleDD, 150)

    local reticleStyles = {
        { text = "Crosshair (Classic +)", value = "crosshair" },
        { text = "Circle Dot (Red Dot)", value = "circledot" },
        { text = "T-Shape (Rangefinder)", value = "tshape" },
        { text = "Military (Brackets)", value = "military" },
        { text = "Cyberpunk (Neon Ring)", value = "cyberpunk" },
        { text = "Minimal (Corners)", value = "minimal" },
    }

    UIDropDownMenu_Initialize(reticleStyleDD, function(self, level)
        for _, style in ipairs(reticleStyles) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = style.text
            info.value = style.value
            info.func = function()
                addon:SetSetting("reticleStyle", style.value)
                UIDropDownMenu_SetText(reticleStyleDD, style.text)
                addon:BuildTrail() -- Rebuild reticle with new style
                AutoSaveToProfile()
            end
            info.checked = (addon:GetSetting("reticleStyle") == style.value)
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local currentStyleText = "Crosshair (Classic +)"
    for _, style in ipairs(reticleStyles) do
        if style.value == addon:GetSetting("reticleStyle") then
            currentStyleText = style.text
            break
        end
    end
    UIDropDownMenu_SetText(reticleStyleDD, currentStyleText)
    yPos = yPos - 50
    uiControls.reticleStyleDD = reticleStyleDD

    local reticleSizeSlider = CreateSlider("ReticleSize", "Reticle Size", yPos, 40, 150, 5, "Size of the reticle ring")
    reticleSizeSlider:SetValue(addon:GetSetting("reticleSize") or 80)
    reticleSizeSlider.valueText:SetText(math.floor(addon:GetSetting("reticleSize") or 80))
    reticleSizeSlider:SetScript("OnValueChanged", function(self, value)
        addon:SetSetting("reticleSize", value)
        self.valueText:SetText(math.floor(value))
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.reticleSizeSlider = reticleSizeSlider

    local reticleBrightnessSlider =
        CreateSlider("ReticleBrightness", "Brightness", yPos, 0.5, 2.0, 0.1, "Brightness multiplier for reticle glow")
    reticleBrightnessSlider:SetValue(addon:GetSetting("reticleBrightness") or 1.0)
    reticleBrightnessSlider.valueText:SetText(string.format("%.1fx", addon:GetSetting("reticleBrightness") or 1.0))
    reticleBrightnessSlider:SetScript("OnValueChanged", function(self, value)
        addon:SetSetting("reticleBrightness", value)
        self.valueText:SetText(string.format("%.1fx", value))
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.reticleBrightnessSlider = reticleBrightnessSlider

    local reticleOpacitySlider =
        CreateSlider("ReticleOpacity", "Reticle Opacity", yPos, 0.2, 1.0, 0.05, "Overall visibility of reticle")
    reticleOpacitySlider:SetValue(addon:GetSetting("reticleOpacity") or 0.7)
    reticleOpacitySlider.valueText:SetText(
        string.format("%d%%", math.floor((addon:GetSetting("reticleOpacity") or 0.7) * 100))
    )
    reticleOpacitySlider:SetScript("OnValueChanged", function(self, value)
        addon:SetSetting("reticleOpacity", value)
        self.valueText:SetText(string.format("%d%%", math.floor(value * 100)))
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.reticleOpacitySlider = reticleOpacitySlider

    local reticleRotationSlider =
        CreateSlider("ReticleRotation", "Rotation Speed", yPos, 0.0, 3.0, 0.1, "Speed of reticle rotation animation")
    reticleRotationSlider:SetValue(addon:GetSetting("reticleRotationSpeed") or 1.0)
    reticleRotationSlider.valueText:SetText(string.format("%.1fx", addon:GetSetting("reticleRotationSpeed") or 1.0))
    reticleRotationSlider:SetScript("OnValueChanged", function(self, value)
        addon:SetSetting("reticleRotationSpeed", value)
        self.valueText:SetText(string.format("%.1fx", value))
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.reticleRotationSlider = reticleRotationSlider

    local reticleInfoText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    reticleInfoText:SetPoint("TOPLEFT", 20, yPos)
    reticleInfoText:SetWidth(600)
    reticleInfoText:SetJustifyH("LEFT")
    reticleInfoText:SetText(
        "|cFFFFD700Colors adapt to targets:|r Red for enemies, Green for friendlies, Gold for objects/NPCs"
    )
    yPos = yPos - 50

    -- EDGE WARNING SYSTEM
    yPos = CreateSection("Screen Edge Warnings", yPos)

    local edgeDesc = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    edgeDesc:SetPoint("TOPLEFT", 20, yPos)
    edgeDesc:SetWidth(600)
    edgeDesc:SetJustifyH("LEFT")
    edgeDesc:SetText("Shows warning arrows when cursor approaches screen edges - perfect for large monitors!")
    yPos = yPos - 35

    local edgeEnabledCB = CreateCheckbox(
        "EdgeWarningEnabled",
        "Enable Edge Warnings",
        yPos,
        "Show arrows when cursor gets close to screen boundaries"
    )
    edgeEnabledCB:SetChecked(addon:GetSetting("edgeWarningEnabled"))
    edgeEnabledCB:SetScript("OnClick", function(self)
        addon:SetSetting("edgeWarningEnabled", self:GetChecked())
        addon:BuildTrail() -- Rebuild edge warnings
        AutoSaveToProfile()
    end)
    yPos = yPos - 50
    uiControls.edgeEnabledCB = edgeEnabledCB

    local edgeDistanceSlider = CreateSlider(
        "EdgeDistance",
        "Trigger Distance",
        yPos,
        20,
        150,
        5,
        "How close to edge (in pixels) before warning appears"
    )
    edgeDistanceSlider:SetValue(addon:GetSetting("edgeWarningDistance") or 50)
    edgeDistanceSlider.valueText:SetText(
        string.format("%dpx", math.floor(addon:GetSetting("edgeWarningDistance") or 50))
    )
    edgeDistanceSlider:SetScript("OnValueChanged", function(self, value)
        addon:SetSetting("edgeWarningDistance", value)
        self.valueText:SetText(string.format("%dpx", math.floor(value)))
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.edgeDistanceSlider = edgeDistanceSlider

    local edgeSizeSlider = CreateSlider("EdgeSize", "Arrow Size", yPos, 32, 128, 4, "Size of warning arrows")
    edgeSizeSlider:SetValue(addon:GetSetting("edgeWarningSize") or 64)
    edgeSizeSlider.valueText:SetText(math.floor(addon:GetSetting("edgeWarningSize") or 64))
    edgeSizeSlider:SetScript("OnValueChanged", function(self, value)
        addon:SetSetting("edgeWarningSize", value)
        self.valueText:SetText(math.floor(value))
        addon:BuildTrail() -- Rebuild arrows with new size
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.edgeSizeSlider = edgeSizeSlider

    local edgeOpacitySlider =
        CreateSlider("EdgeOpacity", "Arrow Opacity", yPos, 0.3, 1.0, 0.05, "How visible the warning arrows are")
    edgeOpacitySlider:SetValue(addon:GetSetting("edgeWarningOpacity") or 0.8)
    edgeOpacitySlider.valueText:SetText(
        string.format("%d%%", math.floor((addon:GetSetting("edgeWarningOpacity") or 0.8) * 100))
    )
    edgeOpacitySlider:SetScript("OnValueChanged", function(self, value)
        addon:SetSetting("edgeWarningOpacity", value)
        self.valueText:SetText(string.format("%d%%", math.floor(value * 100)))
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.edgeOpacitySlider = edgeOpacitySlider

    local edgePulseSlider = CreateSlider(
        "EdgePulseIntensity",
        "Pulse Intensity",
        yPos,
        0.0,
        1.0,
        0.05,
        "How much the arrows and reticle grow and shrink near edges"
    )
    edgePulseSlider:SetValue(addon:GetSetting("edgeWarningPulseIntensity") or 0.5)
    edgePulseSlider.valueText:SetText(
        string.format("%d%%", math.floor((addon:GetSetting("edgeWarningPulseIntensity") or 0.5) * 100))
    )
    edgePulseSlider:SetScript("OnValueChanged", function(self, value)
        addon:SetSetting("edgeWarningPulseIntensity", value)
        self.valueText:SetText(string.format("%d%%", math.floor(value * 100)))
        AutoSaveToProfile()
    end)
    yPos = yPos - 60
    uiControls.edgePulseSlider = edgePulseSlider

    local edgeNote = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    edgeNote:SetPoint("TOPLEFT", 20, yPos)
    edgeNote:SetWidth(600)
    edgeNote:SetJustifyH("LEFT")
    edgeNote:SetText(
        "|cFF888888Edge warnings pulsate (grow/shrink) to grab attention. Click effects hidden near edges.|r"
    )
    yPos = yPos - 50

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
        -- Determine which character we're viewing
        local viewingChar = settingsPanel.viewingCharKey or addon:GetCharacterKey()
        local isViewingOtherChar = (viewingChar ~= addon:GetCharacterKey())

        -- Helper function to get the appropriate setting value
        local function GetDisplaySetting(key)
            if isViewingOtherChar then
                return addon:GetSettingForCharacter(viewingChar, key)
            else
                return UltraCursorFXDB[key]
            end
        end

        -- Update account-wide checkbox
        if uiControls.accountWideCB then
            local charData = UltraCursorFXDB.characters and UltraCursorFXDB.characters[viewingChar]
            uiControls.accountWideCB:SetChecked(charData and charData.useAccountSettings)
            -- Disable if viewing another character
            if isViewingOtherChar then
                uiControls.accountWideCB:Disable()
            else
                uiControls.accountWideCB:Enable()
            end
        end

        -- Update account-wide helper text
        if uiControls.accountWideHelp then
            local charData = UltraCursorFXDB.characters and UltraCursorFXDB.characters[viewingChar]
            if charData and charData.useAccountSettings then
                uiControls.accountWideHelp:SetText(
                    "|cFF00FF00Enabled:|r All your characters will use the same cursor appearance and behavior."
                )
            else
                uiControls.accountWideHelp:SetText(
                    "|cFFFFAA00Disabled:|r This character has its own unique cursor settings. Changes won't affect other characters."
                )
            end
        end

        -- Show indicator if viewing another character
        if isViewingOtherChar then
            if not uiControls.viewOnlyWarning then
                uiControls.viewOnlyWarning = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                uiControls.viewOnlyWarning:SetPoint("TOP", content, "TOP", 0, -20)
            end
            uiControls.viewOnlyWarning:SetText("|cFFFF8800[View-Only Mode]|r")
            uiControls.viewOnlyWarning:Show()
        elseif uiControls.viewOnlyWarning then
            uiControls.viewOnlyWarning:Hide()
        end

        -- Update checkboxes
        uiControls.enableCB:SetChecked(GetDisplaySetting("enabled"))
        uiControls.flashCB:SetChecked(GetDisplaySetting("flashEnabled"))
        uiControls.combatCB:SetChecked(GetDisplaySetting("combatOnly"))
        uiControls.rainbowCB:SetChecked(GetDisplaySetting("rainbowMode"))
        uiControls.clickCB:SetChecked(GetDisplaySetting("clickEffects"))
        uiControls.cometCB:SetChecked(GetDisplaySetting("cometMode"))
        uiControls.fadeCB:SetChecked(GetDisplaySetting("fadeEnabled"))
        uiControls.combatBoostCB:SetChecked(GetDisplaySetting("combatOpacityBoost"))

        -- Update sliders
        uiControls.pointsSlider:SetValue(GetDisplaySetting("points") or 48)
        uiControls.pointsSlider.valueText:SetText(GetDisplaySetting("points") or 48)

        uiControls.sizeSlider:SetValue(GetDisplaySetting("size") or 34)
        uiControls.sizeSlider.valueText:SetText(GetDisplaySetting("size") or 34)

        uiControls.glowSlider:SetValue(GetDisplaySetting("glowSize") or 64)
        uiControls.glowSlider.valueText:SetText(GetDisplaySetting("glowSize") or 64)

        uiControls.smoothSlider:SetValue(GetDisplaySetting("smoothness") or 0.18)
        uiControls.smoothSlider.valueText:SetText(string.format("%.2f", GetDisplaySetting("smoothness") or 0.18))

        uiControls.pulseSlider:SetValue(GetDisplaySetting("pulseSpeed") or 2.5)
        uiControls.pulseSlider.valueText:SetText(string.format("%.1f", GetDisplaySetting("pulseSpeed") or 2.5))

        uiControls.rainbowSlider:SetValue(GetDisplaySetting("rainbowSpeed") or 1.0)
        uiControls.rainbowSlider.valueText:SetText(string.format("%.1f", GetDisplaySetting("rainbowSpeed") or 1.0))

        uiControls.clickParticlesSlider:SetValue(GetDisplaySetting("clickParticles") or 12)
        uiControls.clickParticlesSlider.valueText:SetText(GetDisplaySetting("clickParticles") or 12)

        uiControls.clickSizeSlider:SetValue(GetDisplaySetting("clickSize") or 50)
        uiControls.clickSizeSlider.valueText:SetText(GetDisplaySetting("clickSize") or 50)

        uiControls.clickDurationSlider:SetValue(GetDisplaySetting("clickDuration") or 0.6)
        uiControls.clickDurationSlider.valueText:SetText(
            string.format("%.1f", GetDisplaySetting("clickDuration") or 0.6)
        )

        uiControls.cometSlider:SetValue(GetDisplaySetting("cometLength") or 2.0)
        uiControls.cometSlider.valueText:SetText(string.format("%.1f", GetDisplaySetting("cometLength") or 2.0))

        uiControls.opacitySlider:SetValue(GetDisplaySetting("opacity") or 1.0)
        uiControls.opacitySlider.valueText:SetText(
            string.format("%d%%", math.floor((GetDisplaySetting("opacity") or 1.0) * 100))
        )

        uiControls.fadeStrengthSlider:SetValue(GetDisplaySetting("fadeStrength") or 0.5)
        uiControls.fadeStrengthSlider.valueText:SetText(
            string.format("%.0f%%", (GetDisplaySetting("fadeStrength") or 0.5) * 100)
        )

        -- Update reticle controls
        if uiControls.reticleEnabledCB then
            uiControls.reticleEnabledCB:SetChecked(GetDisplaySetting("reticleEnabled"))
        end
        if uiControls.reticleSizeSlider then
            uiControls.reticleSizeSlider:SetValue(GetDisplaySetting("reticleSize") or 80)
            uiControls.reticleSizeSlider.valueText:SetText(math.floor(GetDisplaySetting("reticleSize") or 80))
        end
        if uiControls.reticleBrightnessSlider then
            uiControls.reticleBrightnessSlider:SetValue(GetDisplaySetting("reticleBrightness") or 1.0)
            uiControls.reticleBrightnessSlider.valueText:SetText(
                string.format("%.1fx", GetDisplaySetting("reticleBrightness") or 1.0)
            )
        end
        if uiControls.reticleOpacitySlider then
            uiControls.reticleOpacitySlider:SetValue(GetDisplaySetting("reticleOpacity") or 0.7)
            uiControls.reticleOpacitySlider.valueText:SetText(
                string.format("%d%%", math.floor((GetDisplaySetting("reticleOpacity") or 0.7) * 100))
            )
        end
        if uiControls.reticleRotationSlider then
            uiControls.reticleRotationSlider:SetValue(addon:GetSetting("reticleRotationSpeed") or 1.0)
            uiControls.reticleRotationSlider.valueText:SetText(
                string.format("%.1fx", addon:GetSetting("reticleRotationSpeed") or 1.0)
            )
        end

        -- Update edge warning controls
        if uiControls.edgeEnabledCB then
            uiControls.edgeEnabledCB:SetChecked(addon:GetSetting("edgeWarningEnabled"))
        end
        if uiControls.edgeDistanceSlider then
            uiControls.edgeDistanceSlider:SetValue(addon:GetSetting("edgeWarningDistance") or 50)
            uiControls.edgeDistanceSlider.valueText:SetText(
                string.format("%dpx", math.floor(addon:GetSetting("edgeWarningDistance") or 50))
            )
        end
        if uiControls.edgeSizeSlider then
            uiControls.edgeSizeSlider:SetValue(addon:GetSetting("edgeWarningSize") or 64)
            uiControls.edgeSizeSlider.valueText:SetText(math.floor(addon:GetSetting("edgeWarningSize") or 64))
        end
        if uiControls.edgeOpacitySlider then
            uiControls.edgeOpacitySlider:SetValue(addon:GetSetting("edgeWarningOpacity") or 0.8)
            uiControls.edgeOpacitySlider.valueText:SetText(
                string.format("%d%%", math.floor((addon:GetSetting("edgeWarningOpacity") or 0.8) * 100))
            )
        end
        if uiControls.edgePulseSlider then
            uiControls.edgePulseSlider:SetValue(addon:GetSetting("edgeWarningPulseIntensity") or 0.5)
            uiControls.edgePulseSlider.valueText:SetText(
                string.format("%d%%", math.floor((addon:GetSetting("edgeWarningPulseIntensity") or 0.5) * 100))
            )
        end

        -- Update color button
        uiControls.colorBtn.texture:SetColorTexture(
            unpack(addon:GetSetting("color") or addon.defaults.color or { 0.0, 1.0, 1.0 })
        )

        -- Update particle shape button highlights
        for _, s in ipairs(shapes) do
            local b = _G["ShapeBtn" .. s.id]
            if b and b.bg then
                if addon:GetSetting("particleShape") == s.id then
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
    addon:SetSetting("enabled", not addon:GetSetting("enabled"))
    if addon:GetSetting("enabled") then
        addon.frame:SetScript("OnUpdate", function(_, elapsed)
            addon:OnUpdate(elapsed)
        end)
    else
        addon.frame:SetScript("OnUpdate", nil)
    end
    print("UltraCursorFX:", addon:GetSetting("enabled") and "Enabled" or "Disabled")
end

function UltraCursorFX_ToggleFlash()
    addon:SetSetting("flashEnabled", not addon:GetSetting("flashEnabled"))
    print("UltraCursorFX Flash:", addon:GetSetting("flashEnabled") and "Enabled" or "Disabled")
end
