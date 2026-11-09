local Creator = require("../../modules/Creator")
local Calendar = require("../../runtime/Calendar")
local Overlay = require("../../runtime/Overlay")
local VirtualList = require("./VirtualList")
local Picker = {}
function Picker.New(Config, kind)
    local value
    if kind == "DatePicker" then
        local now = os.date("!*t")
        value = Config.Value or { Year = now.year, Month = now.month, Day = now.day }
        assert(Calendar.Valid(value), "Invalid date")
        assert(not Config.Min or Calendar.Valid(Config.Min), "Invalid minimum date")
        assert(not Config.Max or Calendar.Valid(Config.Max), "Invalid maximum date")
        assert(not Config.Min or not Config.Max or Calendar.Compare(Config.Min, Config.Max) <= 0, "Invalid date range")
        assert(not Config.Min or Calendar.Compare(value, Config.Min) >= 0, "Date below minimum")
        assert(not Config.Max or Calendar.Compare(value, Config.Max) <= 0, "Date above maximum")
    else
        value = Config.Value or { Hour = 12, Minute = 0 }
        assert(Calendar.Time(value), "Invalid time")
    end
    local control
    local config = table.clone(Config)
    config.Icon = kind == "DatePicker" and "calendar" or "clock"
    config.Callback = function() control:Open() end
    local _, result = require("../../elements/Button"):New(config)
    control = result
    control.__type = kind
    control.Value = table.clone(value)
    local function label()
        if kind == "DatePicker" then return string.format("%04d-%02d-%02d", control.Value.Year, control.Value.Month, control.Value.Day) end
        return string.format("%02d:%02d", control.Value.Hour, control.Value.Minute)
    end
    function control:Set(nextValue)
        if kind == "DatePicker" then
            if not Calendar.Valid(nextValue) then return false, "Invalid date" end
            if Config.Min and Calendar.Compare(nextValue, Config.Min) < 0 or Config.Max and Calendar.Compare(nextValue, Config.Max) > 0 then return false, "Date outside permitted range" end
        elseif not Calendar.Time(nextValue) then return false, "Invalid time" end
        control.Value = table.clone(nextValue)
        control.ButtonFrame:SetDesc(label())
        Creator.SafeCallback(Config.Callback, table.clone(control.Value))
        return control
    end
    function control:Open()
        if control.Locked then return end
        local pending = table.clone(control.Value)
        local popup = Overlay.New(Config.Window, { Width = 356, Height = 394 })
        popup:Build(function(parent)
            local title = Creator.New("TextLabel", { Parent = parent, Text = label(), Size = UDim2.new(1, -88, 0, 40), Position = UDim2.fromOffset(44, 0), BackgroundTransparency = 1, TextSize = 18, ThemeTag = { TextColor3 = "Text" } })
            if kind == "DatePicker" then
                local calendar = Creator.New("ScrollingFrame", { Parent = parent, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 1, -44), CanvasSize = UDim2.fromOffset(0, 292), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.Y })
                local days = {}
                local function refresh()
                    title.Text = string.format("%04d · %02d", pending.Year, pending.Month)
                    local offset = Calendar.Weekday(pending.Year, pending.Month, 1)
                    for index, button in ipairs(days) do
                        local day = index - offset
                        button.Visible = day > 0 and day <= Calendar.Days(pending.Year, pending.Month)
                        button.Text = tostring(day)
                        button:SetAttribute("Day", day)
                        local candidate = { Year = pending.Year, Month = pending.Month, Day = day }
                        local enabled = button.Visible and (not Config.Min or Calendar.Compare(candidate, Config.Min) >= 0) and (not Config.Max or Calendar.Compare(candidate, Config.Max) <= 0)
                        button.Active, button.Selectable, button.TextTransparency = enabled, enabled, enabled and 0 or 0.6
                        button.BackgroundTransparency = day == control.Value.Day and pending.Month == control.Value.Month and pending.Year == control.Value.Year and 0.65 or 0.92
                    end
                end
                popup:Button("‹", UDim2.fromOffset(0, 0), UDim2.fromOffset(40, 40), function()
                    if pending.Year == 1900 and pending.Month == 1 then return end
                    pending.Month -= 1
                    if pending.Month == 0 then pending.Month = 12; pending.Year -= 1 end
                    refresh()
                end)
                popup:Button("›", UDim2.new(1, -40, 0, 0), UDim2.fromOffset(40, 40), function()
                    if pending.Year == 9999 and pending.Month == 12 then return end
                    pending.Month += 1
                    if pending.Month == 13 then pending.Month = 1; pending.Year += 1 end
                    refresh()
                end)
                for index, name in ipairs({ "S", "M", "T", "W", "T", "F", "S" }) do Creator.New("TextLabel", { Parent = calendar, Text = name, Size = UDim2.new(1 / 7, 0, 0, 24), Position = UDim2.new((index - 1) / 7, 0, 0, 0), BackgroundTransparency = 1, ThemeTag = { TextColor3 = "Text" } }) end
                for index = 1, 42 do
                    local button
                    button = popup:Button("", UDim2.new((index - 1) % 7 / 7, 1, 0, 28 + math.floor((index - 1) / 7) * 44), UDim2.new(1 / 7, -2, 0, 42), function()
                        pending.Day = button:GetAttribute("Day")
                        local accepted = control:Set(pending)
                        if accepted ~= false then popup:Close("selected") end
                    end)
                    button.Parent = calendar
                    table.insert(days, button)
                end
                refresh()
            else
                for index, key in ipairs({ "Hour", "Minute" }) do
                    local holder = Creator.New("Frame", { Parent = parent, Position = UDim2.new((index - 1) / 2, 0, 0, 48), Size = UDim2.new(0.5, -4, 1, -100), BackgroundTransparency = 1 })
                    local list
                    list = VirtualList.New(holder, 44, function(row, item)
                        row.Button.Text = string.format("%02d", item.Value)
                        row.Button.TextSize = 22
                        row.Button.BackgroundTransparency = pending[key] == item.Value and 0.65 or 0.96
                    end, function(item)
                        pending[key] = item.Value
                        title.Text = string.format("%02d:%02d", pending.Hour, pending.Minute)
                        list:Refresh()
                    end)
                    local items = {}
                    for number = 0, key == "Hour" and 23 or 59 do table.insert(items, { Value = number }) end
                    list:SetItems(items)
                    list.Frame.CanvasPosition = Vector2.new(0, math.max(0, pending[key] - 2) * 44)
                end
                popup:Button("Apply", UDim2.new(0, 0, 1, -44), UDim2.new(1, 0, 0, 44), function() control:Set(pending); popup:Close("selected") end)
            end
        end)
        return popup
    end
    control.ButtonFrame:SetDesc(label())
    return kind, control
end
return Picker
