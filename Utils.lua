-- ===============================
-- UltraCursorFX - Utility Functions
-- ===============================

local addon = UltraCursorFX

-- ===============================
-- Math Utilities
-- ===============================
function addon.Lerp(a, b, t)
    return a + (b - a) * t
end

function addon.HSVtoRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6

    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    elseif i == 5 then
        r, g, b = v, p, q
    end

    return r, g, b
end

-- ===============================
-- Base64 Encoding/Decoding
-- ===============================
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local b64lookup = {}
for i = 1, #b64chars do
    b64lookup[b64chars:sub(i, i)] = i - 1
end

function addon.Base64Encode(data)
    return (
        (data:gsub(".", function(x)
            local r, b = "", x:byte()
            for i = 8, 1, -1 do
                r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
            end
            return r
        end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
            if #x < 6 then
                return ""
            end
            local c = 0
            for i = 1, 6 do
                c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
            end
            return b64chars:sub(c + 1, c + 1)
        end) .. ({ "", "==", "=" })[#data % 3 + 1]
    )
end

function addon.Base64Decode(data)
    data = data:gsub("[^" .. b64chars .. "=]", "")
    return (
        data:gsub(".", function(x)
            if x == "=" then
                return ""
            end
            local r, f = "", b64lookup[x]
            for i = 6, 1, -1 do
                r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
            end
            return r
        end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
            if #x ~= 8 then
                return ""
            end
            local c = 0
            for i = 1, 8 do
                c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
            end
            return string.char(c)
        end)
    )
end

-- ===============================
-- Serialization
-- ===============================
function addon.SerializeValue(v)
    local t = type(v)
    if t == "number" then
        return tostring(v)
    elseif t == "boolean" then
        return v and "1" or "0"
    elseif t == "string" then
        return v
    elseif t == "table" then
        local parts = {}
        for _, val in ipairs(v) do
            table.insert(parts, tostring(val))
        end
        return table.concat(parts, ",")
    end
    return ""
end

function addon.DeserializeValue(str, expectedType)
    if expectedType == "number" then
        return tonumber(str) or 0
    elseif expectedType == "boolean" then
        return str == "1" or str == "true"
    elseif expectedType == "string" then
        return str
    elseif expectedType == "table" then
        local tbl = {}
        for val in string.gmatch(str, "[^,]+") do
            table.insert(tbl, tonumber(val) or 0)
        end
        return tbl
    end
    return nil
end

-- ===============================
-- Import/Export
-- ===============================
function addon:ExportSettings()
    local exportData = {}
    local fields = {
        "enabled",
        "flashEnabled",
        "combatOnly",
        "color",
        "points",
        "size",
        "glowSize",
        "smoothness",
        "pulseSpeed",
        "rainbowMode",
        "rainbowSpeed",
        "clickEffects",
        "clickParticles",
        "clickSize",
        "clickDuration",
        "particleShape",
        "cometMode",
        "cometLength",
        "opacity",
        "fadeEnabled",
        "fadeStrength",
        "combatOpacityBoost",
        "reticleEnabled",
        "reticleStyle",
        "reticleSize",
        "reticleBrightness",
        "reticleOpacity",
        "reticleRotationSpeed",
        "edgeWarningEnabled",
        "edgeWarningDistance",
        "edgeWarningSize",
        "edgeWarningOpacity",
        "edgeWarningPulseIntensity",
        "situationalEnabled",
        "currentProfile",
    }

    for _, field in ipairs(fields) do
        -- Use GetSetting to get current effective value (respects account/character settings)
        local value = self:GetSetting(field)
        if value ~= nil then
            table.insert(exportData, field .. "=" .. self.SerializeValue(value))
        end
    end

    local plaintext = table.concat(exportData, ";")
    local encoded = self.Base64Encode(plaintext)
    return "UCFX:" .. encoded
end

function addon:ImportSettings(importString)
    if not importString or importString == "" then
        return false, "Empty import string"
    end

    importString = importString:gsub("%s+", "")
    if not importString:match("^UCFX:") then
        return false, "Invalid import string format. Must start with UCFX:"
    end

    local encoded = importString:sub(6)
    local success, decoded = pcall(self.Base64Decode, encoded)
    if not success or not decoded then
        return false, "Invalid base64 encoding"
    end

    local typeMap = {
        enabled = "boolean",
        flashEnabled = "boolean",
        combatOnly = "boolean",
        color = "table",
        points = "number",
        size = "number",
        glowSize = "number",
        smoothness = "number",
        pulseSpeed = "number",
        rainbowMode = "boolean",
        rainbowSpeed = "number",
        clickEffects = "boolean",
        clickParticles = "number",
        clickSize = "number",
        clickDuration = "number",
        particleShape = "string",
        cometMode = "boolean",
        cometLength = "number",
        opacity = "number",
        fadeEnabled = "boolean",
        fadeStrength = "number",
        combatOpacityBoost = "boolean",
        reticleEnabled = "boolean",
        reticleStyle = "string",
        reticleSize = "number",
        reticleBrightness = "number",
        reticleOpacity = "number",
        reticleRotationSpeed = "number",
        edgeWarningEnabled = "boolean",
        edgeWarningDistance = "number",
        edgeWarningSize = "number",
        edgeWarningOpacity = "number",
        edgeWarningPulseIntensity = "number",
        situationalEnabled = "boolean",
        currentProfile = "string",
    }

    local imported = 0
    for pair in string.gmatch(decoded, "[^;]+") do
        local field, value = pair:match("([^=]+)=(.+)")
        if field and value and typeMap[field] then
            -- Use SetSetting to write to correct location (account or character)
            self:SetSetting(field, self.DeserializeValue(value, typeMap[field]))
            imported = imported + 1
        end
    end

    if imported > 0 then
        -- Trigger visual updates
        if self.BuildTrail then
            self:BuildTrail()
        end
        if self.BuildReticle then
            self:BuildReticle()
        end
        if self.UpdateEdgeWarnings then
            self:UpdateEdgeWarnings()
        end
        if self.UpdateCursorState then
            self:UpdateCursorState()
        end

        -- Warn if importing from older version
        if imported < 20 then
            return true, string.format("Imported %d settings (may be from older addon version)", imported)
        end

        return true, "Successfully imported " .. imported .. " settings"
    else
        return false, "No valid settings found in import string"
    end
end
