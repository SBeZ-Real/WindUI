local Creator = require("../modules/Creator")
local Element = {}
function Element:New(Config)
    local Breadcrumb = { __type = "Breadcrumb", Title = Config.Title or "Breadcrumb", Items = {} }
    Breadcrumb.BreadcrumbFrame = require("../components/window/Element")({ Title = Breadcrumb.Title, Parent = Config.Parent, Window = Config.Window, Tab = Config.Tab, Index = Config.Index, ParentConfig = Config, ElementTable = Breadcrumb })
    local holder = Creator.New("ScrollingFrame", { Parent = Breadcrumb.BreadcrumbFrame.UIElements.Container, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), LayoutOrder = 100 }, { Creator.New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }) })
    local scope
    function Breadcrumb:Set(items)
        if scope then scope:Destroy() end
        scope = Creator.Scope.new(Breadcrumb.Scope or Creator.Scope.Get() or Config.Window.Scope)
        Breadcrumb.Items = items
        scope:Run(function()
            for index, item in ipairs(items) do
                local button = Creator.New("TextButton", { Parent = holder, Text = (type(item) == "table" and item.Title or tostring(item)) .. (index < #items and "  ›" or ""), AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(24, 40), BackgroundTransparency = 1, TextSize = 14, ThemeTag = { TextColor3 = index == #items and "Text" or "Primary" } })
                Creator.AddSignal(button.Activated, function() Creator.SafeCallback(Config.Callback, item, index) end)
            end
        end)
        return self
    end
    Breadcrumb:Set(Config.Items or {})
    return Breadcrumb.__type, Breadcrumb
end
return Element
