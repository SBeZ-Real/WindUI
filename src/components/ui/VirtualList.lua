local Creator = require("../../modules/Creator")
local VirtualList = {}
function VirtualList.New(parent, height, draw, activate)
    local self = { Items = {}, Pool = {}, RowHeight = height or 36 }
    self.Frame = Creator.New("ScrollingFrame", { Parent = parent, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.None })
    function self:Refresh()
        local first = math.max(1, math.floor(self.Frame.CanvasPosition.Y / self.RowHeight) + 1)
        local count = math.min(#self.Items, math.ceil(math.max(self.Frame.AbsoluteSize.Y, self.RowHeight) / self.RowHeight) + 2)
        for index = 1, count do
            local row = self.Pool[index]
            if not row then
                row = { Button = Creator.New("TextButton", { Parent = self.Frame, Text = "", Size = UDim2.new(1, -6, 0, self.RowHeight - 2), BackgroundTransparency = 0.96, Selectable = true, ThemeTag = { BackgroundColor3 = "Text", TextColor3 = "Text" } }) }
                self.Pool[index] = row
                Creator.AddSignal(row.Button.Activated, function() if row.Item and activate then activate(row.Item) end end)
            end
            local position = first + index - 1
            row.Item = self.Items[position]
            row.Button.Visible = row.Item ~= nil
            row.Button.Position = UDim2.fromOffset(0, (position - 1) * self.RowHeight)
            if row.Item then draw(row, row.Item, position) end
        end
        for index = count + 1, #self.Pool do self.Pool[index].Button.Visible = false; self.Pool[index].Item = nil end
    end
    function self:SetItems(items)
        self.Items = items
        self.Frame.CanvasSize = UDim2.fromOffset(0, #items * self.RowHeight)
        self.Frame.CanvasPosition = Vector2.new(0, math.clamp(self.Frame.CanvasPosition.Y, 0, math.max(0, #items * self.RowHeight - self.Frame.AbsoluteSize.Y)))
        self:Refresh()
    end
    Creator.AddSignal(self.Frame:GetPropertyChangedSignal("CanvasPosition"), function() self:Refresh() end)
    Creator.AddSignal(self.Frame:GetPropertyChangedSignal("AbsoluteSize"), function() self:Refresh() end)
    local scope = Creator.Scope.Get()
    return scope and scope:Bind(self) or self
end
return VirtualList
