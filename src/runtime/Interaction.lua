local Creator = require("../modules/Creator")
local Interaction = {}
function Interaction.Attach(content, config, scope)
    local root = content.ElementFrame
    if not root or not root:IsA("GuiObject") then return end
    local state = "idle"
    local selectable = setmetatable({}, { __mode = "k" })
    local shield = Creator.New("TextButton", { Name = "FluentDisabled", Text = "", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, AutoButtonColor = false, Active = true, Selectable = false, Visible = false, ZIndex = 39, Parent = root })
    local stroke = Creator.New("UIStroke", { Name = "FluentFocus", Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = root, ThemeTag = { Color = "Primary" } })
    local status = Creator.New("TextLabel", { Name = "FluentStatus", BackgroundTransparency = 0.1, BackgroundColor3 = Color3.fromRGB(25, 25, 25), TextColor3 = Color3.new(1, 1, 1), TextSize = 12, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 1, -24), Visible = false, ZIndex = 40, Parent = root })
    function content:SetState(value, message)
        if not table.find({ "idle", "hover", "pressed", "focused", "disabled", "loading", "invalid" }, value) then return false end
        local wasLocked = content.Locked
        if value == "disabled" or value == "loading" then
            if state ~= "disabled" and state ~= "loading" then content.PreviousLocked = wasLocked end
            if content.Lock then content:Lock() end
        elseif state == "disabled" or state == "loading" then
            if not content.PreviousLocked and content.Unlock then content:Unlock() end
        end
        state, content.State = value, value
        local blocked = value == "disabled" or value == "loading"
        shield.Visible = blocked
        for _, object in ipairs(root:GetDescendants()) do
            if object:IsA("GuiButton") and object ~= shield then
                if blocked then
                    if selectable[object] == nil then selectable[object] = object.Selectable end
                    object.Selectable = false
                elseif selectable[object] ~= nil then object.Selectable = selectable[object]; selectable[object] = nil end
            end
        end
        stroke.Transparency = (value == "focused" or value == "invalid") and 0 or 1
        if value == "focused" then stroke.Transparency = 0 end
        Creator.SetThemeTag(stroke, { Color = value == "invalid" and "Error" or "Primary" })
        status.Visible = value == "invalid" or value == "loading"
        status.Text = message or (value == "loading" and "Loading…" or "Invalid value")
        return content
    end
    function content:SetLoading(value) return content:SetState(value and "loading" or "idle") end
    function content:SetDisabled(value) return content:SetState(value and "disabled" or "idle") end
    function content:RefreshStyle()
        local tokens = config.Window.Tokens
        if not tokens then return end
        local controls = root:GetDescendants()
        table.insert(controls, root)
        for _, object in ipairs(controls) do
            if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                if object.TextSize >= 14 and object.TextSize <= 18 then object.TextSize = tokens.Typography.Body end
                object.FontFace = Font.new(tokens.Typography.Font, object.FontFace.Weight, object.FontFace.Style)
            end
            if object:IsA("UICorner") and object.CornerRadius.Offset > 0 and object.CornerRadius.Offset < 24 then object.CornerRadius = UDim.new(0, tokens.Radius.Control) end
            if object:IsA("GuiButton") and object ~= shield then object.Selectable = state ~= "disabled" and state ~= "loading" end
        end
        local constraint = root:FindFirstChild("FluentMinimum")
        if not constraint then constraint = Creator.New("UISizeConstraint", { Name = "FluentMinimum", Parent = root }) end
        constraint.MinSize = Vector2.new(0, game:GetService("UserInputService").TouchEnabled and tokens.Density.Touch or tokens.Density.Comfortable)
    end
    scope:Connect(root.SelectionGained, function() if not content.Locked then content:SetState("focused") end end)
    scope:Connect(root.SelectionLost, function() if state == "focused" then content:SetState("idle") end end)
    scope:Connect(root.MouseEnter, function() if state == "idle" then content:SetState("hover") end end)
    scope:Connect(root.MouseLeave, function() if state == "hover" or state == "pressed" then content:SetState("idle") end end)
    scope:Connect(root.InputBegan, function(input)
        if not content.Locked and state ~= "disabled" and state ~= "loading" and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then content:SetState("pressed") end
    end)
    scope:Connect(root.InputEnded, function() if state == "pressed" then content:SetState("idle") end end)
    content:RefreshStyle()
end
return Interaction
