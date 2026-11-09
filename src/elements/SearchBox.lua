local Creator = require("../modules/Creator")
local VirtualList = require("../components/ui/VirtualList")
local Element = {}
function Element:New(Config)
    local list
    local config = table.clone(Config)
    config.Title = config.Title or "Search"
    config.Callback = function(query)
        if list then list:SetItems(Config.Window:Search(query)) end
        Creator.SafeCallback(Config.Callback, query)
    end
    local _, result = require("./Input"):New(config)
    result.__type = "SearchBox"
    local holder = Creator.New("Frame", { Parent = result.InputFrame.UIElements.Container, Size = UDim2.new(1, 0, 0, Config.Height or 176), BackgroundTransparency = 1, LayoutOrder = 100 })
    list = VirtualList.New(holder, 44, function(row, entry) row.Button.Text = entry.Title end, function(entry) Config.Window:ActivateSearchResult(entry) end)
    list:SetItems(Config.Window:Search(result.Value))
    return result.__type, result
end
return Element
