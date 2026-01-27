-- ===============================
-- WoW API Mocks for Testing
-- ===============================
-- This file mocks the WoW API functions used by UltraCursorFX
-- so we can run tests without the actual WoW client

-- Global WoW-provided variables
_G.UIParent = {
    GetEffectiveScale = function()
        return 1.0
    end,
    GetWidth = function()
        return 1920
    end,
    GetHeight = function()
        return 1080
    end,
    SetAlpha = function() end,
    CreateTexture = function(self, name, layer)
        local texture = {
            SetTexture = function() end,
            SetBlendMode = function() end,
            SetSize = function() end,
            SetWidth = function() end,
            SetHeight = function() end,
            SetVertexColor = function() end,
            SetPoint = function() end,
            SetAllPoints = function() end,
            ClearAllPoints = function() end,
            SetColorTexture = function() end,
            SetAlpha = function(self, alpha)
                self.alpha = alpha
            end,
            SetRotation = function(self, rotation)
                self.rotation = rotation
            end,
            Hide = function(self)
                self.hidden = true
                self.visible = false
            end,
            Show = function(self)
                self.hidden = false
                self.visible = true
            end,
            GetCenter = function()
                return 0, 0
            end,
            x = 0,
            y = 0,
            hidden = false,
            visible = true,
            alpha = 1.0,
        }
        return texture
    end,
}

-- Frame creation mock
local mockFrameId = 0
local function CreateMockFrame(frameType, name, parent, template)
    mockFrameId = mockFrameId + 1

    local frame = {
        _id = mockFrameId,
        _type = frameType or "Frame",
        _events = {},
        _scripts = {},
        _children = {},
        _textures = {},

        -- Event methods
        RegisterEvent = function(self, event)
            self._events[event] = true
        end,
        UnregisterEvent = function(self, event)
            self._events[event] = nil
        end,
        SetScript = function(self, script, handler)
            self._scripts[script] = handler
        end,

        -- Texture creation
        CreateTexture = function(self, name, layer)
            local texture = {
                SetTexture = function(self, tex)
                    self.texture = tex
                end,
                SetBlendMode = function(self, mode)
                    self.blendMode = mode
                end,
                SetSize = function(self, width, height)
                    self.width = width
                    self.height = height or width
                end,
                SetWidth = function(self, width)
                    self.width = width
                end,
                SetHeight = function(self, height)
                    self.height = height
                end,
                SetVertexColor = function(self, r, g, b, a)
                    self.r = r
                    self.g = g
                    self.b = b
                    self.a = a or 1.0
                end,
                SetPoint = function(self, ...)
                    self.points = self.points or {}
                    table.insert(self.points, { ... })
                end,
                SetAllPoints = function() end,
                ClearAllPoints = function(self)
                    self.points = {}
                end,
                SetColorTexture = function() end,
                SetAlpha = function(self, alpha)
                    self.alpha = alpha
                end,
                SetRotation = function(self, rotation)
                    self.rotation = rotation
                end,
                Hide = function(self)
                    self.hidden = true
                    self.visible = false
                end,
                Show = function(self)
                    self.hidden = false
                    self.visible = true
                end,
                GetCenter = function()
                    return 0, 0
                end,
                x = 0,
                y = 0,
                r = 1.0,
                g = 1.0,
                b = 1.0,
                a = 1.0,
                alpha = 1.0,
                width = 0,
                height = 0,
                visible = true,
                hidden = false,
                drawLayer = layer,
            }
            table.insert(self._textures, texture)
            return texture
        end,

        -- Font string creation
        CreateFontString = function(self, name, layer, template)
            return {
                SetText = function() end,
                SetPoint = function() end,
                SetWidth = function() end,
                SetJustifyH = function() end,
                GetText = function()
                    return ""
                end,
            }
        end,

        -- Frame methods
        SetSize = function() end,
        SetPoint = function() end,
        SetWidth = function() end,
        SetHeight = function() end,
        Hide = function() end,
        Show = function() end,
        SetMinMaxValues = function() end,
        SetValueStep = function() end,
        SetObeyStepOnDrag = function() end,
        SetValue = function() end,
        GetValue = function()
            return 0
        end,
        SetChecked = function() end,
        GetChecked = function()
            return false
        end,
        SetAutoFocus = function() end,
        SetFocus = function() end,
        ClearFocus = function() end,
        HighlightText = function() end,
        SetText = function() end,
        GetText = function()
            return ""
        end,
        SetNormalFontObject = function() end,
        SetHighlightFontObject = function() end,
        SetScrollChild = function() end,
        Click = function() end,
    }

    -- Add special properties for CheckButton
    if template and template:match("CheckButton") then
        frame.Text = {
            SetText = function() end,
            SetPoint = function() end,
            GetText = function()
                return ""
            end,
        }
        frame.tooltipText = ""
    end

    -- Add special properties for Slider
    if template and template:match("Slider") then
        frame.Text = {
            SetText = function() end,
            SetPoint = function() end,
            GetText = function()
                return ""
            end,
        }
        frame.Low = {
            SetText = function() end,
        }
        frame.High = {
            SetText = function() end,
        }
        frame.tooltipText = ""
    end

    if parent then
        table.insert(parent._children, frame)
    end

    return frame
end

_G.CreateFrame = CreateMockFrame

-- Color picker mock
_G.ColorPickerFrame = {
    SetupColorPickerAndShow = function(info)
        -- Simulate immediate color selection
        if info.swatchFunc then
            info.swatchFunc()
        end
    end,
    GetColorRGB = function()
        return 1.0, 0.5, 0.5
    end,
}

-- Game functions
_G.IsInInstance = function()
    return false, "none"
end

_G.GetCursorPosition = function()
    return 500, 500
end

-- Mouse button state tracking for tests
local mouseButtonState = {
    LeftButton = false,
    RightButton = false,
}

_G.IsMouseButtonDown = function(button)
    return mouseButtonState[button] or false
end

function SimulateMouseClick(button, pressed)
    mouseButtonState[button] = pressed
end

_G.GameTooltip = {
    SetOwner = function() end,
    SetText = function() end,
    Show = function() end,
    Hide = function() end,
    IsShown = function()
        return false
    end,
    GetUnit = function()
        return nil
    end,
}

-- Unit functions for reticle system
_G.UnitExists = function(unit)
    return false -- Default: no mouseover unit
end

_G.UnitCanAttack = function(unit, target)
    return false
end

_G.UnitIsFriend = function(unit, target)
    return false
end

_G.UnitIsDead = function(unit)
    return false
end

_G.UnitIsUnit = function(unit1, unit2)
    return unit1 == unit2
end

_G.GetTime = function()
    return os.clock()
end

-- Settings API (modern)
_G.Settings = {
    RegisterCanvasLayoutCategory = function(panel, name)
        return { ID = name }
    end,
    RegisterAddOnCategory = function() end,
    OpenToCategory = function() end,
}

-- Timer API
_G.C_Timer = {
    After = function(delay, callback)
        -- Execute immediately in tests
        if callback then
            callback()
        end
    end,
}

-- Interface Options (legacy)
_G.InterfaceOptions_AddCategory = function() end
_G.InterfaceOptionsFrame_OpenToCategory = function() end

-- UIDropDownMenu API (for reticle style dropdown)
_G.UIDropDownMenu_SetWidth = function(frame, width) end
_G.UIDropDownMenu_Initialize = function(frame, initFunc, level) end
_G.UIDropDownMenu_CreateInfo = function()
    return {
        text = "",
        value = nil,
        func = nil,
        checked = false,
    }
end
_G.UIDropDownMenu_AddButton = function(info, level) end
_G.UIDropDownMenu_SetText = function(frame, text) end

-- Slash commands
_G.SlashCmdList = {}
_G.SLASH_ULTRACURSORFX1 = "/ucfx"

-- String functions
_G.string = string
_G.table = table
_G.math = math
_G.pairs = pairs
_G.ipairs = ipairs
_G.unpack = unpack or table.unpack
_G.wipe = function(tbl)
    for k in pairs(tbl) do
        tbl[k] = nil
    end
    return tbl
end

-- Print function
_G.print = print

-- Addon loading simulation
function SimulateAddonLoad(addonName)
    if UltraCursorFX and UltraCursorFX.frame then
        local handler = UltraCursorFX.frame._scripts["OnEvent"]
        if handler then
            handler(UltraCursorFX.frame, "ADDON_LOADED", addonName)
        end
    end
end

function SimulateZoneChange(inInstance, instanceType)
    _G.IsInInstance = function()
        return inInstance, instanceType
    end

    if UltraCursorFX and UltraCursorFX.frame then
        local handler = UltraCursorFX.frame._scripts["OnEvent"]
        if handler then
            handler(UltraCursorFX.frame, "PLAYER_ENTERING_WORLD")
        end
    end
end

-- Reset state between tests
function ResetWoWMocks()
    mockFrameId = 0
    _G.UltraCursorFXDB = nil
    _G.UltraCursorFX = nil
    package.loaded["Core"] = nil
    package.loaded["Utils"] = nil
    package.loaded["Profiles"] = nil
    package.loaded["Effects"] = nil
    package.loaded["UI"] = nil
    package.loaded["Commands"] = nil
    package.loaded["Init"] = nil
end

return {
    SimulateAddonLoad = SimulateAddonLoad,
    SimulateZoneChange = SimulateZoneChange,
    SimulateMouseClick = SimulateMouseClick,
    ResetWoWMocks = ResetWoWMocks,
}
