local Navigation = {}

function Navigation.new(Window)
    local self = { History = {}, Cursor = 0, Index = {}, Commands = {}, Navigating = false, Changed = nil }
    function self:Push(route)
        if not self.Navigating and self.History[self.Cursor] ~= route then
            for index = #self.History, self.Cursor + 1, -1 do table.remove(self.History, index) end
            table.insert(self.History, route)
            if #self.History > 100 then table.remove(self.History, 1) end
            self.Cursor = #self.History
        end
        self.Selected = route
        if self.Changed then self.Changed(route) end
    end
    function self:Go(route)
        local tab = Window.TabModule.Tabs[route]
        if not tab or tab.Locked then return false, "Route is unavailable" end
        Window:SelectTab(route)
        return true
    end
    function self:Back()
        if self.Cursor <= 1 then return false end
        local cursor = self.Cursor - 1
        self.Navigating = true
        local result = self:Go(self.History[cursor])
        self.Navigating = false
        if result then self.Cursor = cursor end
        return result
    end
    function self:Forward()
        if self.Cursor >= #self.History then return false end
        local cursor = self.Cursor + 1
        self.Navigating = true
        local result = self:Go(self.History[cursor])
        self.Navigating = false
        if result then self.Cursor = cursor end
        return result
    end
    function self:Register(key, entry) self.Index[key] = entry end
    function self:Remove(key) self.Index[key] = nil end
    function self:Search(query)
        query = tostring(query or ""):lower()
        local result = {}
        for key, entry in pairs(self.Index) do
            local title = tostring(entry.Object.Title or entry.Title or "")
            local desc = tostring(entry.Object.Desc or "")
            if (title .. " " .. desc):lower():find(query, 1, true) then table.insert(result, { Key = key, Title = title, Route = entry.Route, Object = entry.Object, Kind = entry.Kind }) end
        end
        table.sort(result, function(a, b) return a.Title < b.Title end)
        return result
    end
    function self:RegisterCommand(command)
        if type(command) ~= "table" or type(command.ID) ~= "string" or type(command.Callback) ~= "function" then return false, "Invalid command" end
        if self.Commands[command.ID] then return false, "Command already registered" end
        self.Commands[command.ID] = command
        return true
    end
    function self:RunCommand(id)
        local command = self.Commands[id]
        if not command then return false, "Command is not registered" end
        if command.Enabled and not command.Enabled() then return false, "Command is disabled" end
        return pcall(command.Callback)
    end
    return self
end

return Navigation
