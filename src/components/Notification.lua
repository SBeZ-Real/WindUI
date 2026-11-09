local Creator = require("../modules/Creator")
local task = Creator.Tasks
local New = Creator.New
local Tween = Creator.Tween
local NotificationModule = {
    Size = UDim2.new(0, 320, 1, -96), SizeLower = UDim2.new(0, 320, 1, -32), UICorner = 12, UIPadding = 12,
    Holder = nil, NotificationIndex = 0, Notifications = {}, Queue = {}, Active = {}, History = {}, Dedupe = {}, Listeners = {},
    MaxVisible = 3, MaxQueued = 50, MaxHistory = 100,
}
local pumping = false
local function changed()
    for _, callback in pairs(NotificationModule.Listeners) do Creator.SafeCallback(callback) end
end
local function remember(notification)
    table.insert(NotificationModule.History, 1, { ID = notification.ID, WindowID = notification.WindowID, Title = notification.Title, Content = notification.Content, Progress = notification.Progress, Count = notification.Count, Time = os.time(), Status = notification.Status })
    while #NotificationModule.History > NotificationModule.MaxHistory do table.remove(NotificationModule.History) end
    changed()
end
local function render(Notification)
    Notification.ViewScope = Creator.Scope.new(Notification.Scope)
    Notification.ViewScope:Run(function()
        local hasActions = #Notification.Buttons > 0
        local Main = New("Frame", { Parent = Notification.Holder, Size = UDim2.new(1, 0, 0, hasActions and 172 or 124), LayoutOrder = Notification.ID, ThemeTag = { BackgroundColor3 = "Notification" } }, {
            New("UICorner", { CornerRadius = UDim.new(0, NotificationModule.UICorner) }),
            New("UIStroke", { Thickness = 1, Transparency = 0.5, ThemeTag = { Color = "NotificationBorder" } }),
        })
        Notification.UIElements.Main = Main
        if Notification.Background then New("ImageLabel", { Parent = Main, Image = Notification.Background, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ImageTransparency = Notification.BackgroundImageTransparency or 0.7 }) end
        local iconOffset = 0
        if Notification.Icon then
            local icon = Creator.Image(Notification.Icon, Notification.Title, 0, "Temp", "Notification", true, Notification.IconThemed)
            icon.Parent, icon.Position, icon.Size = Main, UDim2.fromOffset(12, 16), UDim2.fromOffset(24, 24)
            iconOffset = 32
        end
        Notification.UIElements.Title = New("TextLabel", { Parent = Main, Text = Notification.Title, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BackgroundTransparency = 1, Position = UDim2.fromOffset(12 + iconOffset, 12), Size = UDim2.new(1, -60 - iconOffset, 0, 28), ThemeTag = { TextColor3 = "NotificationTitle" } })
        Notification.UIElements.Content = New("TextLabel", { Parent = Main, Text = Notification.Content or "", TextWrapped = true, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 46), Size = UDim2.new(1, -24, 0, 54), ThemeTag = { TextColor3 = "NotificationContent" } })
        Notification.UIElements.Progress = New("Frame", { Parent = Main, Position = UDim2.new(0, 12, 1, -10), Size = UDim2.new(0, 0, 0, 3), Visible = Notification.Progress ~= nil, ThemeTag = { BackgroundColor3 = "Primary" } })
        if Notification.CanClose then
            local close = New("TextButton", { Parent = Main, Text = "×", TextSize = 24, Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -44, 0, 4), BackgroundTransparency = 1, ThemeTag = { TextColor3 = "Text" } })
            Creator.AddSignal(close.Activated, function() Notification:Close() end)
        end
        for index, action in ipairs(Notification.Buttons) do
            local button = New("TextButton", { Parent = Main, Text = action.Title or "Action", Size = UDim2.new(1 / #Notification.Buttons, -16, 0, 40), Position = UDim2.new((index - 1) / #Notification.Buttons, 8, 1, -58), BackgroundTransparency = 0.86, ThemeTag = { BackgroundColor3 = "Primary", TextColor3 = "Text" } }, { New("UICorner", { CornerRadius = UDim.new(0, 6) }) })
            Creator.AddSignal(button.Activated, function()
                Creator.SafeCallback(action.Callback, Notification)
                if action.Close ~= false then Notification:Close("action") end
            end)
        end
        Notification:Update({})
        if Notification.Duration ~= false then Notification.Timer = task.delay(Notification.Duration, function() Notification:Close("timeout") end) end
    end)
end
local function pump()
    if pumping then return end
    pumping = true
    local active = 0
    for _ in pairs(NotificationModule.Active) do active += 1 end
    while active < NotificationModule.MaxVisible and #NotificationModule.Queue > 0 do
        local notification = table.remove(NotificationModule.Queue, 1)
        if not notification.Closed and not notification.Scope.Destroyed then
            NotificationModule.Active[notification.ID] = notification
            notification.Status = "visible"
            render(notification)
            active += 1
        end
    end
    pumping = false
end
function NotificationModule.Init(Parent)
    local NotModule = { Lower = false }
    NotModule.Frame = New("Frame", { Parent = Parent, Position = UDim2.new(1, -16, 1, -16), AnchorPoint = Vector2.new(1, 1), Size = NotificationModule.Size, BackgroundTransparency = 1 }, {
        New("UIListLayout", { Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    function NotModule.SetLower(val) NotModule.Lower = val; NotModule.Frame.Size = val and NotificationModule.SizeLower or NotificationModule.Size end
    local function resize()
        NotModule.Frame.Size = UDim2.new(0, math.min(320, math.max(120, Parent.AbsoluteSize.X - 32)), 1, NotModule.Lower and -32 or -96)
        NotificationModule.MaxVisible = math.max(1, math.min(3, math.floor((Parent.AbsoluteSize.Y - 64) / 180)))
        local current = {}
        for _, notification in pairs(NotificationModule.Active) do table.insert(current, notification) end
        table.sort(current, function(a, b) return a.ID < b.ID end)
        for index = #current, NotificationModule.MaxVisible + 1, -1 do
            local notification = current[index]
            notification.ViewScope:Destroy()
            notification.UIElements = {}
            notification.Status = "queued"
            NotificationModule.Active[notification.ID] = nil
            table.insert(NotificationModule.Queue, 1, notification)
        end
        pump()
    end
    Creator.AddSignal(Parent:GetPropertyChangedSignal("AbsoluteSize"), resize)
    resize()
    NotificationModule.Holder = NotModule.Frame
    return NotModule
end
function NotificationModule.New(Config)
    local key = Config.DedupeKey or Config.Group
    if key then key = (Config.Window and Config.Window.ID or "global") .. ":" .. tostring(key) end
    if key and NotificationModule.Dedupe[key] and not NotificationModule.Dedupe[key].Closed then
        local existing = NotificationModule.Dedupe[key]
        existing.Count += 1
        existing:Update(Config)
        return existing
    end
    NotificationModule.NotificationIndex += 1
    local scope = Creator.Scope.new(Config.Window and Config.Window.Scope or Creator.RootScope)
    local Notification = {
        ID = NotificationModule.NotificationIndex, Title = Config.Title or "Notification", Content = Config.Content,
        WindowID = Config.Window and Config.Window.ID,
        Icon = Config.Icon, IconThemed = Config.IconThemed, Background = Config.Background, BackgroundImageTransparency = Config.BackgroundImageTransparency,
        Duration = (Config.Persistent or Config.Progress ~= nil or Config.Duration == false) and false or math.max(0, tonumber(Config.Duration) or 5),
        Buttons = Config.Buttons or Config.Actions or {}, CanClose = Config.CanClose ~= false, UIElements = {}, Closed = false,
        Holder = Config.Holder or NotificationModule.Holder, Scope = scope, Count = 1, Progress = Config.Progress, Status = "queued", DedupeKey = key,
    }
    if Config.Persistent or Config.Progress ~= nil or Config.Duration == false then Notification.Duration = false end
    function Notification:Update(config)
        if Notification.Closed then return false end
        for _, name in ipairs({ "Title", "Content", "Progress" }) do if config[name] ~= nil then Notification[name] = config[name] end end
        if Notification.Progress ~= nil then Notification.Progress = math.clamp(tonumber(Notification.Progress) or 0, 0, 1) end
        if Notification.UIElements.Title then
            Notification.UIElements.Title.Text = Notification.Title .. (Notification.Count > 1 and " ×" .. Notification.Count or "")
            Notification.UIElements.Content.Text = Notification.Content or ""
            Notification.UIElements.Progress.Visible = Notification.Progress ~= nil
            Notification.UIElements.Progress.Size = UDim2.new(Notification.Progress or 0, -24 * (Notification.Progress or 0), 0, 3)
        end
        changed()
        return Notification
    end
    function Notification:SetProgress(value) return Notification:Update({ Progress = value }) end
    function Notification:Close(reason)
        if Notification.Closed then return end
        Notification.Closed, Notification.Status = true, reason or "dismissed"
        NotificationModule.Active[Notification.ID] = nil
        NotificationModule.Notifications[Notification.ID] = nil
        local index = table.find(NotificationModule.Queue, Notification)
        if index then table.remove(NotificationModule.Queue, index) end
        if key and NotificationModule.Dedupe[key] == Notification then NotificationModule.Dedupe[key] = nil end
        remember(Notification)
        Creator.SafeCallback(Config.OnClose, Notification.Status)
        scope:Destroy()
        pump()
    end
    scope:Give(Notification, function() if not Notification.Closed then Notification:Close("destroyed") end end)
    NotificationModule.Notifications[Notification.ID] = Notification
    if key then NotificationModule.Dedupe[key] = Notification end
    if #NotificationModule.Queue >= NotificationModule.MaxQueued then Notification:Close("rate-limited"); return Notification end
    table.insert(NotificationModule.Queue, Notification)
    pump()
    return Notification
end
function NotificationModule.Clear(clearHistory, windowID)
    pumping = true
    local current = table.clone(NotificationModule.Notifications)
    for _, notification in pairs(current) do if not windowID or notification.WindowID == windowID then notification:Close("cleared") end end
    if clearHistory then
        for index = #NotificationModule.History, 1, -1 do
            if not windowID or NotificationModule.History[index].WindowID == windowID then table.remove(NotificationModule.History, index) end
        end
    end
    pumping = false
    pump()
    changed()
end
function NotificationModule.Center(Window)
    local popup = require("../runtime/Overlay").New(Window, { Width = 460, Height = 460 })
    popup:Build(function(parent)
        popup:Button("Clear this window", UDim2.new(), UDim2.new(1, 0, 0, 44), function() NotificationModule.Clear(true, Window.ID) end)
        local holder = New("Frame", { Parent = parent, Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 1, -52), BackgroundTransparency = 1 })
        local list = require("./ui/VirtualList").New(holder, 64, function(row, entry)
            row.Button.Text = entry.Title .. "\n" .. tostring(entry.Content or entry.Status or "")
            row.Button.TextWrapped = true
            row.Button.TextXAlignment = Enum.TextXAlignment.Left
        end, function(entry) if NotificationModule.Notifications[entry.ID] == entry then entry:Close() end end)
        local function refresh()
            local entries = {}
            for _, notification in pairs(NotificationModule.Notifications) do if not notification.WindowID or notification.WindowID == Window.ID then table.insert(entries, notification) end end
            for _, entry in ipairs(NotificationModule.History) do if not entry.WindowID or entry.WindowID == Window.ID then table.insert(entries, entry) end end
            list:SetItems(entries)
        end
        NotificationModule.Listeners[popup] = function() popup.Scope:Run(refresh) end
        popup.Scope:Give(refresh, function() NotificationModule.Listeners[popup] = nil end)
        refresh()
    end)
    return popup
end
function NotificationModule.ExportHistory() return game:GetService("HttpService"):JSONEncode(NotificationModule.History) end
function NotificationModule.ImportHistory(json)
    local success, entries = pcall(function() return game:GetService("HttpService"):JSONDecode(json) end)
    if not success or type(entries) ~= "table" then return false, "Invalid notification history" end
    local valid = {}
    for _, entry in ipairs(entries) do
        if type(entry) ~= "table" or type(entry.Title) ~= "string" then return false, "Invalid notification entry" end
        table.insert(valid, { ID = entry.ID, WindowID = type(entry.WindowID) == "string" and entry.WindowID or nil, Title = entry.Title, Content = tostring(entry.Content or ""), Status = "history", Time = entry.Time })
        if #valid == NotificationModule.MaxHistory then break end
    end
    NotificationModule.History = valid
    changed()
    return true
end
return NotificationModule
