local Creator = require("../modules/Creator")
local ListModel = require("../runtime/ListModel")
local VirtualList = require("../components/ui/VirtualList")
local Element = {}
function Element:New(Config)
    local DataTable = { __type = "DataTable", Title = Config.Title or "Data table", Columns = Config.Columns or {}, Callback = Config.Callback, Elements = {} }
    DataTable.DataTableFrame = require("../components/window/Element")({ Title = DataTable.Title, Parent = Config.Parent, Window = Config.Window, Tab = Config.Tab, Index = Config.Index, ParentConfig = Config, ElementTable = DataTable })
    local holder = Creator.New("Frame", { Parent = DataTable.DataTableFrame.UIElements.Container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Config.Height or 320), LayoutOrder = 100 })
    local search = Creator.New("TextBox", { Parent = holder, Size = UDim2.new(1, 0, 0, 36), PlaceholderText = "Filter rows", Text = "", BackgroundTransparency = 0.92, ThemeTag = { BackgroundColor3 = "Text", TextColor3 = "Text" } })
    local header = Creator.New("Frame", { Parent = holder, Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 })
    local area = Creator.New("Frame", { Parent = holder, Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 1, -80), BackgroundTransparency = 1 })
    local model = ListModel.new(Config.Rows or {})
    DataTable.Model = model
    local list
    list = VirtualList.New(area, Config.RowHeight or 38, function(row, item)
        row.Cells = row.Cells or {}
        row.Button.BackgroundTransparency = model.Selection[item.Index] and 0.78 or 0.96
        for index, column in ipairs(DataTable.Columns) do
            if not row.Cells[index] then row.Cells[index] = Creator.New("TextLabel", { Parent = row.Button, Size = UDim2.new(1 / #DataTable.Columns, -8, 1, 0), Position = UDim2.new((index - 1) / #DataTable.Columns, 4, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ThemeTag = { TextColor3 = "Text" } }) end
            local value = item.Row[column.Key or column]
            row.Cells[index].Text = value == nil and "" or tostring(value)
        end
    end, function(item)
        model:Select(item.Index, Config.Multi == true)
        list:Refresh()
        Creator.SafeCallback(DataTable.Callback, item.Row, item.Index, table.clone(model.Selection))
    end)
    function DataTable:Sort(key, descending) model:Sort(key, descending); list:SetItems(model.Visible); return self end
    function DataTable:Filter(query) model:Filter(query); list:SetItems(model.Visible); return self end
    function DataTable:Set(rows) assert(type(rows) == "table", "Rows must be a table"); model:Set(rows); list:SetItems(model.Visible); return self end
    function DataTable:Select(index) model:Select(index, Config.Multi == true); list:Refresh(); Creator.SafeCallback(DataTable.Callback, model.Rows[index], index, table.clone(model.Selection)); return self end
    function DataTable:GetSelection() return table.clone(model.Selection) end
    function DataTable:GetState()
        local selection = {}
        for index in pairs(model.Selection) do table.insert(selection, index) end
        table.sort(selection)
        return { Query = model.Query, SortKey = model.SortKey, Descending = model.Descending, Selection = selection }
    end
    function DataTable:ApplyState(value)
        model.Selection = {}
        for _, index in ipairs(value.Selection) do if model.Rows[index] then model.Selection[index] = true end end
        model.Query, model.SortKey, model.Descending = value.Query, value.SortKey, value.Descending
        model:Refresh()
        search.Text = model.Query
        list:SetItems(model.Visible)
        return self
    end
    for index, column in ipairs(DataTable.Columns) do
        local key = type(column) == "table" and column.Key or column
        local button = Creator.New("TextButton", { Parent = header, Text = type(column) == "table" and (column.Title or column.Key) or column, Size = UDim2.new(1 / #DataTable.Columns, -2, 1, 0), Position = UDim2.fromScale((index - 1) / #DataTable.Columns, 0), BackgroundTransparency = 0.9, ThemeTag = { BackgroundColor3 = "Text", TextColor3 = "Text" } })
        Creator.AddSignal(button.Activated, function() DataTable:Sort(key, model.SortKey == key and not model.Descending) end)
    end
    Creator.AddSignal(search:GetPropertyChangedSignal("Text"), function() DataTable:Filter(search.Text) end)
    list:SetItems(model.Visible)
    DataTable.List = list
    return DataTable.__type, DataTable
end
return Element
