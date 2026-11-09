local Creator = require("../modules/Creator")
local Navigation = require("./Navigation")
local Overlay = require("./Overlay")
local VirtualList = require("../components/ui/VirtualList")
local NavigationView = {}
function NavigationView.Attach(Window, Config)
    Window.Navigation = Navigation.new(Window)
    local navigation = Window.Navigation
    function Window:Back() return navigation:Back() end
    function Window:Forward() return navigation:Forward() end
    function Window:Search(query) return navigation:Search(query) end
    function Window:RegisterCommand(command) return navigation:RegisterCommand(command) end
    function Window:UnregisterCommand(id) navigation.Commands[id] = nil end
    function Window:ActivateSearchResult(entry)
        if not navigation:Go(entry.Route) then return false end
        if entry.Kind == "Element" then
            local tab = Window.TabModule.Tabs[entry.Route]
            local index = table.find(tab.Elements, entry.Object)
            if index and entry.Object.ElementFrame then tab:ScrollToTheElement(index) end
        end
        return true
    end
    function Window:OpenCommandPalette(query)
        local popup = Overlay.New(Window, { Width = 480, Height = 410 })
        popup:Build(function(parent)
            local input = Creator.New("TextBox", { Parent = parent, PlaceholderText = "Search pages, controls and commands", Text = query or "", Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 0.9, ThemeTag = { BackgroundColor3 = "Text", TextColor3 = "Text" } })
            local holder = Creator.New("Frame", { Parent = parent, Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 1, -52), BackgroundTransparency = 1 })
            local results = {}
            local function activate(entry)
                popup:Close("selected")
                Window.Scope:Run(function()
                    if entry.Command then
                        local success, message = navigation:RunCommand(entry.Command)
                        if not success then Window.Context:Notify({ Title = "Command failed", Content = tostring(message) }) end
                    else Window:ActivateSearchResult(entry) end
                end)
            end
            local list = VirtualList.New(holder, 44, function(row, entry) row.Button.Text = entry.Title; row.Button.TextXAlignment = Enum.TextXAlignment.Left end, activate)
            local function refresh()
                results = navigation:Search(input.Text)
                for id, command in pairs(navigation.Commands) do
                    if tostring(command.Title or id):lower():find(input.Text:lower(), 1, true) then table.insert(results, { Title = command.Title or id, Command = id }) end
                end
                list:SetItems(results)
            end
            Creator.AddSignal(input:GetPropertyChangedSignal("Text"), refresh)
            Creator.AddSignal(input.FocusLost, function(enter) if enter and results[1] then activate(results[1]) end end)
            refresh()
            input:CaptureFocus()
        end)
        return popup
    end
    function Window:ContextMenu(items, position)
        local popup = Overlay.New(Window, { Position = position, Width = 260, Height = math.min(420, #items * 44 + 24) })
        popup:Build(function(parent)
            local list = VirtualList.New(parent, 44, function(row, item) row.Button.Text = item.Title or "Action"; row.Button.Active = item.Disabled ~= true end, function(item)
                if item.Disabled then return end
                popup:Close("selected")
                Window.Scope:Run(function() Creator.SafeCallback(item.Callback) end)
            end)
            list:SetItems(items)
        end)
        return popup
    end
    function Window:NotificationCenter() return Window.Context.NotificationModule.Center(Window) end
    function Window:SaveNotificationHistory(name)
        if not require("./Schema").Name(name) then return false, "Invalid history name" end
        return Window.ConfigManager.Storage:Write(Window.ConfigManager.BasePath .. "history/" .. name .. ".json", Window.Context.NotificationModule.ExportHistory())
    end
    function Window:LoadNotificationHistory(name)
        if not require("./Schema").Name(name) then return false, "Invalid history name" end
        local data, message = Window.ConfigManager.Storage:Read(Window.ConfigManager.BasePath .. "history/" .. name .. ".json")
        if not data then return false, message or "History unavailable" end
        return Window.Context.NotificationModule.ImportHistory(data)
    end
    local input = game:GetService("UserInputService")
    Creator.AddSignal(input.InputBegan, function(key, processed)
        if processed or input:GetFocusedTextBox() or Window.Context.WindowManager.Focused ~= Window or Window.Closed then return end
        if key.KeyCode == Enum.KeyCode.K and (input:IsKeyDown(Enum.KeyCode.LeftControl) or input:IsKeyDown(Enum.KeyCode.RightControl)) or key.KeyCode == Enum.KeyCode.ButtonY then Window:OpenCommandPalette() end
        if key.KeyCode == Enum.KeyCode.Left and input:IsKeyDown(Enum.KeyCode.LeftAlt) then Window:Back() end
        if key.KeyCode == Enum.KeyCode.Right and input:IsKeyDown(Enum.KeyCode.LeftAlt) then Window:Forward() end
    end)
    if Config.Style or Config.Navigation then
        Window:CreateTopbarButton("Navigation", "menu", function()
            Window:ContextMenu({
                { Title = "Back", Callback = function() Window:Back() end },
                { Title = "Forward", Callback = function() Window:Forward() end },
                { Title = "Search and commands", Callback = function() Window:OpenCommandPalette() end },
                { Title = "Notification center", Callback = function() Window:NotificationCenter() end },
                { Title = "Snap layout", Callback = function()
                    local items = {}
                    for _, preset in ipairs({ "Left", "Right", "Center", "TopLeft", "TopRight", "BottomLeft", "BottomRight" }) do table.insert(items, { Title = preset, Callback = function() Window:Snap(preset) end }) end
                    Window:ContextMenu(items)
                end },
            })
        end, 1)
    end
end
return NavigationView
