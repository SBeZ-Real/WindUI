local Creator = require("../modules/Creator")
local Tokens = require("./Tokens")
local ThemeEngine = {}

function ThemeEngine.Attach(Window, Config, WindUI)
    local context = Config.WindUI
    local state = { Style = Config.Style, Mode = Config.Mode or "Dark", Accent = Config.Accent, Tokens = Config.Tokens or {}, Theme = Config.Theme, FollowGlobal = Config.Theme == nil }
    local previous
    local function apply()
        local started = os.clock()
        if state.Style then
            Window.Tokens = Tokens.Resolve(state.Style, state.Mode, state.Accent, state.Tokens)
            context.Theme = Tokens.Theme(Window.Tokens, state.Style .. state.Mode)
            Window.ElementConfig.UIPadding = Window.Tokens.Spacing.Control
            Window.ElementConfig.UICorner = Window.Tokens.Radius.Control
            Window.Radius, Window.UICorner = Window.Tokens.Radius.Window, Window.Tokens.Radius.Window
            for object, shape in pairs(Creator.ShapeObjects) do
                local owner = Creator.Scope.Owners[object]
                if owner and owner.Context == context and shape:GetRadius() > 0 and shape:GetRadius() <= 24 then
                    shape:SetRadius(object == Window.UIElements.Main.Background and Window.Tokens.Radius.Window or Window.Tokens.Radius.Control)
                end
            end
            Window.ShadowTransparency = Window.Tokens.Elevation.Shadow
            Window.Transparent = state.Style == "Glass"
            context.TransparencyValue = Window.Tokens.Opacity.Surface
            Window.UIElements.Main.Background.ImageTransparency = context.TransparencyValue
            for _, tab in ipairs(Window.TabModule.Tabs) do tab.UIElements.ContainerFrame.UIListLayout.Padding = UDim.new(0, Window.Tokens.Spacing.Gap) end
            for _, element in ipairs(Window.AllElements) do if element.RefreshStyle then element:RefreshStyle() end end
        else
            Window.Tokens = nil
            context.Theme = WindUI.Themes[state.Theme] or WindUI.Theme
        end
        Window.Style, Window.Mode = state.Style, state.Mode
        if Window.SetEffects then Window:SetEffects(context.Performance.Quality) end
        for object in pairs(Creator.Objects) do
            local owner = Creator.Scope.Owners[object]
            if owner and owner.Context == context then Creator.UpdateTheme(object, false) end
        end
        context.Performance:Record("Theme", os.clock() - started)
        return Window
    end
    function Window:SetStyle(style)
        if not Tokens.Styles[style] then return false, "Unknown Fluent style" end
        state.Style = style
        return apply()
    end
    function Window:SetTheme(theme)
        if not WindUI.Themes[theme] then return false, "Unknown theme" end
        state.Theme, state.FollowGlobal, state.Style = theme, false, nil
        return apply()
    end
    function Window:SetMode(mode)
        if not Tokens.Modes[mode] then return false, "Unknown theme mode" end
        state.Mode = mode
        state.Style = state.Style or "Premium"
        return apply()
    end
    function Window:SetAccent(accent)
        if typeof(accent) == "Color3" then accent = "#" .. accent:ToHex() end
        if type(accent) ~= "string" or not accent:match("^#%x%x%x%x%x%x$") then return false, "Accent must be a hex color" end
        state.Accent = accent
        state.Style = state.Style or "Premium"
        return apply()
    end
    function Window:SetTokens(overrides)
        if type(overrides) ~= "table" then return false, "Tokens must be a table" end
        local valid, result = pcall(Tokens.Resolve, state.Style or "Premium", state.Mode, state.Accent, overrides)
        if not valid then return false, tostring(result) end
        state.Tokens = Tokens.Merge(overrides, {})
        state.Style = state.Style or "Premium"
        return apply()
    end
    function Window:ExportTheme()
        return game:GetService("HttpService"):JSONEncode({ Style = state.Style, Theme = not state.Style and (state.Theme or WindUI.Theme.Name) or nil, Mode = state.Mode, Accent = state.Accent, Tokens = state.Tokens })
    end
    function Window:ImportTheme(json)
        local valid, value = pcall(function() return game:GetService("HttpService"):JSONDecode(json) end)
        if not valid or type(value) ~= "table" or not (Tokens.Styles[value.Style] or value.Style == nil and WindUI.Themes[value.Theme]) or not Tokens.Modes[value.Mode] then return false, "Invalid theme schema" end
        if value.Accent and (type(value.Accent) ~= "string" or not value.Accent:match("^#%x%x%x%x%x%x$")) then return false, "Invalid accent" end
        if value.Tokens and type(value.Tokens) ~= "table" then return false, "Invalid tokens" end
        local resolved, reason = pcall(Tokens.Resolve, value.Style or "Premium", value.Mode, value.Accent, value.Tokens)
        if not resolved then return false, tostring(reason) end
        previous = Tokens.Merge(state, {})
        state.Style, state.Mode, state.Accent, state.Tokens, state.Theme, state.FollowGlobal = value.Style, value.Mode, value.Accent, value.Tokens or {}, value.Theme, false
        local success, result = pcall(apply)
        if not success then state = previous; apply(); return false, tostring(result) end
        return result
    end
    function Window:RollbackTheme()
        if not previous then return false, "No theme checkpoint" end
        state, previous = previous, nil
        return apply()
    end
    function Window:SaveThemePreset(name)
        if not require("./Schema").Name(name) then return false, "Invalid preset name" end
        return Window.ConfigManager.Storage:Write(Window.ConfigManager.BasePath .. "themes/" .. name .. ".json", Window:ExportTheme())
    end
    function Window:LoadThemePreset(name)
        if not require("./Schema").Name(name) then return false, "Invalid preset name" end
        local json, message = Window.ConfigManager.Storage:Read(Window.ConfigManager.BasePath .. "themes/" .. name .. ".json")
        if not json then return false, message or "Theme preset does not exist" end
        return Window:ImportTheme(json)
    end
    local adaptiveConnection
    local adaptiveViewport
    function Window:SetAdaptiveTheme(resolver)
        if resolver ~= false and type(resolver) ~= "function" then return false, "Adaptive theme requires a resolver function or false" end
        if adaptiveConnection then adaptiveConnection:Disconnect(); Window.Scope:Forget(adaptiveConnection); adaptiveConnection = nil end
        if adaptiveViewport then adaptiveViewport:Disconnect(); Window.Scope:Forget(adaptiveViewport); adaptiveViewport = nil end
        Window.AdaptiveTheme = resolver
        if resolver == false then return Window end
        local function refresh()
            local valid, value = pcall(resolver, require("./Capabilities").Detect(), context.ScreenGui.AbsoluteSize)
            if not valid or type(value) ~= "table" then return false, "Adaptive theme resolver must return a table" end
            local style, mode, accent = value.Style or state.Style or "Premium", value.Mode or state.Mode, value.Accent or state.Accent
            local success, reason = pcall(Tokens.Resolve, style, mode, accent, state.Tokens)
            if not success then return false, tostring(reason) end
            state.Style, state.Mode, state.Accent = style, mode, accent
            return apply()
        end
        local accepted, message = refresh()
        if accepted == false then Window.AdaptiveTheme = false; return false, message end
        adaptiveConnection = Window.Scope:Connect(game:GetService("UserInputService").LastInputTypeChanged, function()
            local result, reason = refresh()
            if result == false then warn("[WindUI adaptive theme] " .. tostring(reason)) end
        end)
        adaptiveViewport = Window.Scope:Connect(context.ScreenGui:GetPropertyChangedSignal("AbsoluteSize"), function()
            local result, reason = refresh()
            if result == false then warn("[WindUI adaptive theme] " .. tostring(reason)) end
        end)
        return Window
    end
    function Window:ThemeStudio()
        previous = Tokens.Merge(state, {})
        local tab = Window:Tab({ Title = "Theme Studio", Icon = "palette" })
        tab:Dropdown({ Title = "Style", Values = { "Classic", "Premium", "Glass" }, Value = state.Style or "Premium", Callback = function(value) Window:SetStyle(value) end })
        tab:Dropdown({ Title = "Mode", Values = { "Dark", "Light" }, Value = state.Mode, Callback = function(value) Window:SetMode(value) end })
        tab:Colorpicker({ Title = "Accent", Default = Color3.fromHex(state.Accent or Tokens.Modes[state.Mode].Accent), Callback = function(value) Window:SetAccent(value) end })
        tab:Dropdown({ Title = "Effects", Values = { "Off", "Low", "Balanced", "High" }, Value = context.Performance.Quality, Callback = function(value) Window:SetEffects(value) end })
        tab:Toggle({ Title = "Reduced motion", Value = context.Performance.ReducedMotion, Callback = function(value) Window:SetReducedMotion(value) end })
        tab:Toggle({ Title = "Adaptive quality", Value = context.Performance.Adaptive, Callback = function(value) Window:SetAdaptiveQuality(value) end })
        tab:Button({ Title = "Restore preview checkpoint", Callback = function() Window:RollbackTheme() end })
        local input = tab:Input({ Title = "Theme JSON", Type = "Textarea", Value = Window:ExportTheme(), Callback = function() end })
        tab:Button({ Title = "Export current theme", Callback = function() input:Set(Window:ExportTheme()) end })
        tab:Button({ Title = "Import theme", Callback = function()
            local result, message = Window:ImportTheme(input.Value)
            if result == false then Window:Dialog({ Title = "Invalid theme", Content = message }) end
        end })
        local preset = tab:Input({ Title = "Preset name", Value = "My theme", Callback = function() end })
        local function report(result, message) if result == false then Window:Dialog({ Title = "Theme preset", Content = message }) end end
        tab:Button({ Title = "Save preset", Callback = function() report(Window:SaveThemePreset(preset.Value)) end })
        tab:Button({ Title = "Load preset", Callback = function() report(Window:LoadThemePreset(preset.Value)) end })
        return tab
    end
    Window._GlobalTheme = function()
        if state.FollowGlobal and not state.Style then context.Theme = WindUI.Theme; apply() end
    end
    if Config.AdaptiveTheme then Window:SetAdaptiveTheme(Config.AdaptiveTheme) end
    return apply()
end

return ThemeEngine
