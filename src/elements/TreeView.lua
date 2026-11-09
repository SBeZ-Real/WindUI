local Creator = require("../modules/Creator")
local VirtualList = require("../components/ui/VirtualList")
local Element = {}
function Element:New(Config)
    local TreeView = { __type = "TreeView", Title = Config.Title or "Tree", Nodes = Config.Nodes or {}, Expanded = {}, Value = nil }
    TreeView.TreeViewFrame = require("../components/window/Element")({ Title = TreeView.Title, Parent = Config.Parent, Window = Config.Window, Tab = Config.Tab, Index = Config.Index, ParentConfig = Config, ElementTable = TreeView })
    local holder = Creator.New("Frame", { Parent = TreeView.TreeViewFrame.UIElements.Container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Config.Height or 260), LayoutOrder = 100 })
    local list
    local function flatten()
        local rows, seen = {}, {}
        local function visit(nodes, depth, path)
            assert(depth < 64, "Tree depth exceeds 63")
            for index, node in ipairs(nodes) do
                assert(not seen[node], "Tree contains a cycle or duplicate node")
                seen[node] = true
                local key = node.ID or path .. "/" .. index
                table.insert(rows, { Node = node, Key = key, Depth = depth })
                if node.Children and TreeView.Expanded[key] then visit(node.Children, depth + 1, key) end
            end
        end
        visit(TreeView.Nodes, 0, "")
        list:SetItems(rows)
    end
    list = VirtualList.New(holder, 38, function(row, item)
        row.Button.TextXAlignment = Enum.TextXAlignment.Left
        row.Button.Text = string.rep("   ", item.Depth) .. (item.Node.Children and (TreeView.Expanded[item.Key] and "▾  " or "▸  ") or "   ") .. tostring(item.Node.Title or item.Key)
        row.Button.BackgroundTransparency = TreeView.Value == item.Key and 0.75 or 0.96
    end, function(item)
        TreeView:Select(item.Key)
        if item.Node.Children then TreeView:Expand(item.Key, not TreeView.Expanded[item.Key]) end
        Creator.SafeCallback(Config.Callback, item.Node, item.Key)
    end)
    function TreeView:Expand(key, value) TreeView.Expanded[key] = value ~= false; flatten(); return self end
    function TreeView:Select(key) TreeView.Value = key; list:Refresh(); return self end
    function TreeView:Set(nodes) TreeView.Nodes = nodes; TreeView.Expanded = {}; flatten(); return self end
    function TreeView:GetState() return { Expanded = table.clone(TreeView.Expanded), Value = TreeView.Value } end
    function TreeView:ApplyState(value) TreeView.Expanded = table.clone(value.Expanded); TreeView.Value = value.Value; flatten(); return self end
    flatten()
    return TreeView.__type, TreeView
end
return Element
