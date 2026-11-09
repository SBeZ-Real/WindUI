local Creator = require("../modules/Creator")
local Overlay = {}

function Overlay.New(Window, options)
    options = options or {}
    if Window.Popup then Window.Popup:Close("replaced") end
    local scope = Creator.Scope.new(Window.Scope)
    local self = { Scope = scope, Closed = false, Result = nil, Controls = {}, Modal = options.Modal == true }
    local GuiService = game:GetService("GuiService")
    local previous = GuiService.SelectedObject
    scope:Run(function()
        self.Shield = Creator.New("TextButton", { Name = "Overlay", Parent = Window.Context.DropdownGui, Text = "", Size = UDim2.fromScale(1, 1), BackgroundTransparency = self.Modal and 0.4 or 1, BackgroundColor3 = Color3.new(), AutoButtonColor = false, Selectable = false, Active = true })
        local viewport = Window.Context.DropdownGui.AbsoluteSize
        local width, height = math.min(options.Width or 360, math.max(120, viewport.X - 24)), math.min(options.Height or 320, math.max(100, viewport.Y - 24))
        local x, y = (viewport.X - width) / 2, (viewport.Y - height) / 2
        if options.Position then x, y = options.Position.X, options.Position.Y end
        self.Frame = Creator.New("Frame", { Name = "Panel", Parent = self.Shield, Size = UDim2.fromOffset(width, height), Position = UDim2.fromOffset(math.clamp(x, 8, math.max(8, viewport.X - width - 8)), math.clamp(y, 8, math.max(8, viewport.Y - height - 8))), ThemeTag = { BackgroundColor3 = "DialogBackground" }, ClipsDescendants = true }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 12) }),
            Creator.New("UIStroke", { Thickness = 1, Transparency = 0.4, ThemeTag = { Color = "Outline" } }),
        })
        self.Blocker = Creator.New("TextButton", { Parent = self.Frame, Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Selectable = false, Active = true })
        self.Content = Creator.New("Frame", { Parent = self.Blocker, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 1, -24), Position = UDim2.fromOffset(12, 12) })
        Creator.AddSignal(self.Shield.Activated, function() if options.Dismissable ~= false then self:Close("cancelled") end end)
        Creator.AddSignal(game:GetService("UserInputService").InputBegan, function(input, processed)
            if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
                if options.Dismissable ~= false then self:Close("cancelled") end
            elseif not processed and input.KeyCode == Enum.KeyCode.Tab and #self.Controls > 0 then
                local index = table.find(self.Controls, GuiService.SelectedObject) or 0
                GuiService.SelectedObject = self.Controls[index % #self.Controls + 1]
            end
        end)
        Creator.AddSignal(Window.Context.DropdownGui:GetPropertyChangedSignal("AbsoluteSize"), function()
            local size = Window.Context.DropdownGui.AbsoluteSize
            self.Frame.Size = UDim2.fromOffset(math.min(width, math.max(100, size.X - 16)), math.min(height, math.max(80, size.Y - 16)))
            self.Frame.Position = UDim2.fromOffset(math.clamp(self.Frame.Position.X.Offset, 8, math.max(8, size.X - self.Frame.Size.X.Offset - 8)), math.clamp(self.Frame.Position.Y.Offset, 8, math.max(8, size.Y - self.Frame.Size.Y.Offset - 8)))
        end)
    end)
    function self:Build(callback) return scope:Run(callback, self.Content, self) end
    function self:Button(text, position, size, callback)
        local button = Creator.New("TextButton", { Parent = self.Content, Text = text, Size = size, Position = position, TextSize = 14, Selectable = true, BackgroundTransparency = 0.9, ThemeTag = { BackgroundColor3 = "Text", TextColor3 = "Text" } }, { Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }) })
        table.insert(self.Controls, button)
        Creator.AddSignal(button.Activated, callback)
        return button
    end
    function self:Close(result)
        if self.Closed then return end
        self.Closed, self.Result = true, result or "closed"
        if Window.Popup == self then Window.Popup = nil end
        if previous and previous.Parent then GuiService.SelectedObject = previous else GuiService.SelectedObject = nil end
        Creator.SafeCallback(options.OnClose, self.Result)
        scope:Destroy()
    end
    scope:Give(self, function()
        if not self.Closed then self.Closed = true; self.Result = "destroyed"; Creator.SafeCallback(options.OnClose, self.Result) end
        if Window.Popup == self then Window.Popup = nil end
    end)
    Window.Popup = self
    Window:Focus()
    return self
end

return Overlay
