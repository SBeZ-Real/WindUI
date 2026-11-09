local Tokens = {}
Tokens.Styles = {
    Classic = { Radius = { Window = 12, Control = 6 }, Spacing = { Control = 12, Gap = 6 }, Elevation = { Shadow = 0.82 }, Opacity = { Surface = 0 } },
    Premium = { Radius = { Window = 16, Control = 8 }, Spacing = { Control = 14, Gap = 8 }, Elevation = { Shadow = 0.88 }, Opacity = { Surface = 0 } },
    Glass = { Radius = { Window = 16, Control = 8 }, Spacing = { Control = 12, Gap = 8 }, Elevation = { Shadow = 0.9 }, Opacity = { Surface = 0.18 } },
}
Tokens.Modes = {
    Dark = { Surface = "#202020", Panel = "#292929", Control = "#323232", Text = "#f3f3f3", Secondary = "#b6b6b6", Border = "#4a4a4a", Accent = "#60cdff", Success = "#6ccb5f", Warning = "#fce100", Error = "#ff99a4" },
    Light = { Surface = "#f3f3f3", Panel = "#fafafa", Control = "#ffffff", Text = "#1a1a1a", Secondary = "#5d5d5d", Border = "#d7d7d7", Accent = "#005fb8", Success = "#0f7b0f", Warning = "#9d5d00", Error = "#c42b1c" },
}

function Tokens.Merge(base, overrides)
    local result = {}
    for key, value in pairs(base) do result[key] = type(value) == "table" and Tokens.Merge(value, {}) or value end
    for key, value in pairs(overrides or {}) do
        result[key] = type(value) == "table" and Tokens.Merge(type(result[key]) == "table" and result[key] or {}, value) or value
    end
    return result
end

function Tokens.Resolve(style, mode, accent, overrides)
    assert(Tokens.Styles[style], "Unknown Fluent style")
    assert(Tokens.Modes[mode], "Unknown Fluent mode")
    local result = Tokens.Merge(Tokens.Styles[style], {
        Color = Tokens.Modes[mode], Typography = { Body = 14, Caption = 12, Title = 20, Font = "rbxassetid://12187365364" },
        Motion = { Fast = 0.1, Normal = 0.18 }, Density = { Touch = 44, Compact = 32, Comfortable = 38 },
        InteractionState = { Hover = 0.92, Pressed = 0.84, Disabled = 0.55, Focus = 0 },
    })
    if accent then result.Color.Accent = accent end
    local function validate(source, base, group)
        assert(type(source) == "table", "Tokens must be an object")
        for key, value in pairs(source) do
            local expected = base[key]
            assert(expected ~= nil, "Unknown token: " .. tostring(key))
            assert(type(value) == type(expected), "Invalid token type: " .. tostring(key))
            if type(value) == "table" then
                validate(value, expected, key)
            elseif type(value) == "number" then
                local limit = (group == "Opacity" or group == "Elevation" or group == "InteractionState") and 1 or group == "Motion" and 2 or 128
                assert(value == value and value >= 0 and value <= limit, "Token outside range: " .. key)
                if group == "Typography" or group == "Density" then assert(value >= 8, "Token too small: " .. key) end
            elseif group == "Color" then
                assert(value:match("^#%x%x%x%x%x%x$"), "Invalid token color: " .. key)
            elseif key == "Font" then
                assert(value:match("^rbxassetid://%d+$"), "Invalid font asset")
            end
        end
    end
    validate(overrides or {}, result)
    if accent then assert(type(accent) == "string" and accent:match("^#%x%x%x%x%x%x$"), "Invalid accent") end
    return Tokens.Merge(result, overrides)
end

function Tokens.Theme(tokens, name)
    local color = tokens.Color
    return {
        Name = name or "Fluent", Accent = color.Surface, Background = color.Surface, WindowBackground = color.Surface,
        Text = color.Text, Icon = color.Text, Primary = color.Accent, Button = color.Accent, Outline = color.Border,
        Dialog = color.Panel, DialogBackground = color.Panel, PopupBackground = color.Panel, DropdownBackground = color.Panel,
        PanelBackground = color.Panel, PanelBackgroundTransparency = 0,
        ElementBackground = color.Control, ElementBackgroundTransparency = 0, ElementBackgroundHover = color.Panel,
        ElementDesc = color.Secondary, WindowTopbarAuthor = color.Secondary,
        TabBackgroundActive = color.Accent, TabBackgroundActiveTransparency = 0.86, TabBorder = color.Border,
        Notification = color.Panel, NotificationBorder = color.Border, NotificationContent = color.Secondary,
        Success = color.Success, Warning = color.Warning, Error = color.Error, Border = color.Border,
        BackgroundTransparency = tokens.Opacity.Surface,
    }
end

return Tokens
