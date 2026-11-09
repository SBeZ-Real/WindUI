local Creator = require("../modules/Creator")
local Capabilities = require("./Capabilities")
local Performance = require("./Performance")
local Schema = require("./Schema")
local WindowManager = {}

function WindowManager.new(WindUI, parent)
    local self = { Windows = {}, Contexts = {}, Order = {}, NextID = 0, Parent = parent, Focused = nil }
    function self:Context(Config)
        self.NextID += 1
        local id = Config.ID or "Window" .. self.NextID
        assert(Schema.Name(id), "Window ID must contain letters, digits, spaces, underscores or hyphens")
        assert(not self.Contexts[id], "Window ID already exists")
        local context = setmetatable({ ID = id, UIScale = Config.UIScale or WindUI.UIScale, Theme = WindUI.Themes[Config.Theme] or WindUI.Theme }, {
            __index = WindUI,
            __newindex = function(object, key, value)
                if key == "CurrentInput" then rawset(object, "_InputToken", value); WindUI.CurrentInput = value else rawset(object, key, value) end
            end,
        })
        context.Scope = Creator.Scope.new(Creator.RootScope, context)
        self.Contexts[id] = context
        context.Performance = Performance.new(context.Scope)
        context.Scope:Give(context, function() self.Contexts[id] = nil; if WindUI.CurrentInput == context._InputToken then WindUI.CurrentInput = nil end end)
        context.Scope:Run(function()
            for _, key in ipairs({ "ScreenGui", "DropdownGui", "TooltipGui" }) do
                context[key] = Creator.New("ScreenGui", { Name = "WindUI/" .. id .. "/" .. key, Parent = self.Parent, IgnoreGuiInset = false })
                Capabilities.Protect(context[key])
            end
            for _, name in ipairs({ "Window", "KeySystem", "Popups", "ToolTips" }) do Creator.New("Folder", { Name = name, Parent = context.ScreenGui }) end
            context.UIScaleObj = Creator.New("UIScale", { Scale = context.UIScale })
        end)
        context.Notify = function(_, config) config = table.clone(config); config.Window = context.Window; return WindUI:Notify(config) end
        context.ToggleAcrylic = function(_, value)
            local window = context.Window
            if window and window.AcrylicPaint and window.AcrylicPaint.Model then
                value = value and window.Acrylic and context.Performance.Quality ~= "Off" and context.Performance.Quality ~= "Low" and not context.Performance.ReducedMotion
                window.AcrylicPaint.Model.Transparency = value and 0.98 or 1
                local Acrylic = require("../utils/Acrylic/Init")
                if value then Acrylic.Enable(window.ID) else Acrylic.Disable(window.ID) end
            end
        end
        return context
    end
    function self:Focus(Window)
        local index = table.find(self.Order, Window)
        if index then table.remove(self.Order, index) end
        table.insert(self.Order, Window)
        self.Focused = Window
        for rank, entry in ipairs(self.Order) do
            entry.Context.ScreenGui.DisplayOrder = rank * 4
            entry.Context.DropdownGui.DisplayOrder = rank * 4 + 1
            entry.Context.TooltipGui.DisplayOrder = rank * 4 + 2
        end
        WindUI.NotificationGui.DisplayOrder = #self.Order * 4 + 4
    end
    function self:Remove(Window)
        self.Windows[Window.ID] = nil
        local index = table.find(self.Order, Window)
        if index then table.remove(self.Order, index) end
        self.Focused = self.Order[#self.Order]
        if WindUI.Window == Window then WindUI.Window = self.Focused end
    end
    function self:Attach(Window, Config)
        local context = Config.WindUI
        context.Window = Window
        Window.Context, Window.Scope, Window.ID = context, context.Scope, context.ID
        self.Windows[Window.ID] = Window
        local main = Window.UIElements.Main
        local saved
        local expanded = Config.SideBarWidth or 200
        local function viewport()
            local size = context.ScreenGui.AbsoluteSize
            return Vector2.new(math.max(1, size.X / context.UIScale), math.max(1, size.Y / context.UIScale))
        end
        local function remember()
            if not saved then saved = { Size = Window.Size, Position = main.Position } end
        end
        Window.Focus = function() self:Focus(Window); return Window end
        function Window:Hide()
            Window:Close()
            if Window.OpenButtonMain then Window.OpenButtonMain:Visible(false) end
            return Window
        end
        function Window:Minimize()
            Window:Close()
            Window.Minimized = true
            if Window.OpenButtonMain then Window.OpenButtonMain:Visible(true) end
            return Window
        end
        function Window:Restore()
            if saved then
                Window.Size = saved.Size
                main.Size, main.Position = saved.Size, saved.Position
                saved = nil
            end
            Window.Minimized, Window.IsFullscreen = false, false
            Window:Open()
            Window:Focus()
            Window:FitViewport()
            return Window
        end
        function Window:Snap(preset)
            local presets = { Left = { 0, 0, 0.5, 1 }, Right = { 0.5, 0, 0.5, 1 }, Center = { 0.15, 0.1, 0.7, 0.8 }, TopLeft = { 0, 0, 0.5, 0.5 }, TopRight = { 0.5, 0, 0.5, 0.5 }, BottomLeft = { 0, 0.5, 0.5, 0.5 }, BottomRight = { 0.5, 0.5, 0.5, 0.5 } }
            local value = presets[preset]
            if not value then return false, "Unknown snap preset" end
            remember()
            local size = viewport()
            Window.Size = UDim2.fromOffset(math.max(100, size.X * value[3] - 16), math.max(100, size.Y * value[4] - 16))
            main.Size = Window.Size
            main.Position = UDim2.fromOffset(size.X * (value[1] + value[3] / 2), size.Y * (value[2] + value[4] / 2))
            Window:Focus()
            return Window
        end
        function Window:Maximize()
            remember()
            local size = viewport()
            Window.Size = UDim2.fromOffset(size.X - 16, size.Y - 16)
            main.Size, main.Position = Window.Size, UDim2.fromScale(0.5, 0.5)
            Window:Focus()
            Window.CanResize = false
            return Window
        end
        function Window:Fullscreen()
            remember()
            Window.IsFullscreen = true
            local size = viewport()
            Window.Size = UDim2.fromOffset(size.X, size.Y)
            main.Size, main.Position = Window.Size, UDim2.fromScale(0.5, 0.5)
            Window.CanResize = false
            if Window.DragModule then Window.DragModule:Set(false) end
            Window:Focus()
            return Window
        end
        function Window:_ApplyFullscreen() if Window.IsFullscreen then Window:Fullscreen() end end
        function Window:SetLayout(layout)
            if layout ~= "Settings" and layout ~= "Compact" and layout ~= "Adaptive" then return false, "Unknown layout" end
            Window.Layout = layout
            local compact = layout == "Compact" or layout == "Adaptive" and viewport().X < 640
            local width = compact and 64 or expanded
            Window.UIElements.SideBarContainer.Size = UDim2.new(0, width, Window.UIElements.SideBarContainer.Size.Y.Scale, Window.UIElements.SideBarContainer.Size.Y.Offset)
            Window.UIElements.MainBar.Size = UDim2.new(1, -width, 1, -Window.Topbar.Height)
            for _, tab in ipairs(Window.TabModule.Tabs) do
                local text = tab.UIElements.Main.Frame.TextLabel
                text.Visible = not compact or tab.UIElements.Icon == nil
                text.Text = compact and tab.UIElements.Icon == nil and tab.Title:sub(1, 2) or tab.Title
            end
            return Window
        end
        function Window:SetEffects(quality)
            if not table.find({ "Off", "Low", "Balanced", "High" }, quality) then return false, "Unknown effects quality" end
            context.Performance.Quality = quality
            if Window.Style then
                local shadow = main:FindFirstChild("Blur")
                Window.ShadowTransparency = quality == "High" and 0.72 or quality == "Low" and 0.94 or Window.Tokens and Window.Tokens.Elevation.Shadow or Config.ShadowTransparency or 0.88
                if shadow then shadow.Visible = quality ~= "Off"; shadow.ImageTransparency = Window.ShadowTransparency end
            end
            context:ToggleAcrylic(not Window.Closed)
            if quality == "Off" or context.Performance.ReducedMotion then
                for object, active in pairs(Creator.ActiveTweens) do
                    local owner = Creator.Scope.Owners[object]
                    if owner and owner.Context == context then
                        for tween, properties in pairs(active) do tween:Cancel(); for key, value in pairs(properties) do object[key] = value end end
                    end
                end
                for _, element in ipairs(Window.AllElements) do
                    if element.__type == "ProgressBar" and element.Indeterminate then element.UIElements.Fill.Position = UDim2.fromScale(0.35, 0) end
                end
            end
            return Window
        end
        function Window:SetReducedMotion(value) context.Performance.ReducedMotion = value == true; return Window:SetEffects(context.Performance.Quality) end
        function Window:GetDiagnostics() return context.Performance:Snapshot() end
        function Window:SetAdaptiveQuality(value)
            context.Performance.Adaptive = value == true
            if context.QualityConnection then context.QualityConnection:Disconnect(); context.Scope:Forget(context.QualityConnection); context.QualityConnection = nil end
            if value then context.QualityConnection = context.Scope:Connect(game:GetService("RunService").Heartbeat, function(delta)
                local quality = context.Performance.Quality
                context.Performance:Sample(delta)
                if quality ~= context.Performance.Quality then Window:SetEffects(context.Performance.Quality) end
            end) end
            return Window
        end
        function Window:SaveWorkspace(name)
            if not Schema.Name(name) then return false, "Invalid workspace name" end
            local position, size = main.Position, Window.Size
            local data = { ID = Window.ID, Position = { position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset }, Size = { size.X.Scale, size.X.Offset, size.Y.Scale, size.Y.Offset }, Layout = Window.Layout, Tab = Window.CurrentTab, Theme = Window:ExportTheme() }
            return Window.ConfigManager.Storage:Write(Window.ConfigManager.BasePath .. "workspaces/" .. name .. ".json", game:GetService("HttpService"):JSONEncode(data))
        end
        function Window:LoadWorkspace(name)
            if not Schema.Name(name) then return false, "Invalid workspace name" end
            local json, message = Window.ConfigManager.Storage:Read(Window.ConfigManager.BasePath .. "workspaces/" .. name .. ".json")
            if not json then return false, message or "Workspace does not exist" end
            local success, data = pcall(function() return game:GetService("HttpService"):JSONDecode(json) end)
            if not success or type(data) ~= "table" or data.ID ~= Window.ID then return false, "Invalid workspace" end
            for _, key in ipairs({ "Position", "Size" }) do
                if type(data[key]) ~= "table" or #data[key] ~= 4 then return false, "Invalid window geometry" end
                for _, value in ipairs(data[key]) do if type(value) ~= "number" or value ~= value or math.abs(value) > 100000 then return false, "Invalid window geometry" end end
            end
            Window:SetSize(UDim2.new(table.unpack(data.Size)))
            main.Position = UDim2.new(table.unpack(data.Position))
            if data.Layout then Window:SetLayout(data.Layout) end
            if data.Theme then Window:ImportTheme(data.Theme) end
            if data.Tab then Window:SelectTab(data.Tab) end
            Window:FitViewport()
            return true
        end
        function Window:FitViewport()
            if Window.Destroyed then return end
            local size = viewport()
            if Window.Layout == "Adaptive" then
                Window:SetLayout("Adaptive")
                Window.Size = UDim2.fromOffset(math.max(100, math.min(Window.Size.X.Scale * size.X + Window.Size.X.Offset, size.X - 16)), math.max(100, math.min(Window.Size.Y.Scale * size.Y + Window.Size.Y.Offset, size.Y - 16)))
                main.Size = Window.Size
            end
            local width, height = math.min(main.AbsoluteSize.X / context.UIScale, size.X), math.min(main.AbsoluteSize.Y / context.UIScale, size.Y)
            local x = main.Position.X.Scale * size.X + main.Position.X.Offset
            local y = main.Position.Y.Scale * size.Y + main.Position.Y.Offset
            main.Position = UDim2.fromOffset(math.clamp(x, width / 2, size.X - width / 2), math.clamp(y, height / 2, size.Y - height / 2))
        end
        context.Scope:Connect(main.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Window:Focus() end
        end)
        context.Scope:Connect(game:GetService("UserInputService").InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Window:FitViewport() end
        end)
        context.Scope:Connect(context.ScreenGui:GetPropertyChangedSignal("AbsoluteSize"), function() Window:FitViewport() end)
        Window:SetEffects(Config.Effects or "Balanced")
        local reduced = false
        pcall(function() reduced = game:GetService("GuiService").ReducedMotionEnabled end)
        Window:SetReducedMotion(Config.ReducedMotion == nil and reduced or Config.ReducedMotion)
        Window:SetAdaptiveQuality(Config.AdaptiveQuality == true)
        if Config.Layout or Config.Style then Window:SetLayout(Config.Layout or "Adaptive"); Window:FitViewport() end
        self:Focus(Window)
        return Window
    end
    return self
end

return WindowManager
