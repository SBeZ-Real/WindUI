local Creator = require("../../modules/Creator")
local task = Creator.Tasks
local New = Creator.New
local Tween = Creator.Tween

-- local Window
-- local WindUI

local DialogModule = {
	Holder = nil,
	--Window = nil,
	Parent = nil,
}

function DialogModule.Create(Key, Type, Window, WindUI, Parent)
	local Dialog = {
		UICorner = 28,
		UIPadding = 12,

		Window = Window,
		WindUI = WindUI,

		UIElements = {},
	}

	if Key then
		Dialog.UIPadding = 0
	end -- 16
	if Key then
		Dialog.UICorner = 26
	end

	Type = Type or "Dialog"

	if not Key then
		Dialog.UIElements.FullScreen = New("Frame", {
			ZIndex = 999,
			BackgroundTransparency = 1, -- 0.65
			BackgroundColor3 = Color3.fromHex("#000000"),
			Size = UDim2.new(1, 0, 1, 0),
			Active = false, -- true
			Visible = false, -- true
			Parent = DialogModule.Parent
				or (Window and Window.UIElements and Window.UIElements.Main and Window.UIElements.Main.Main),
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Window.UICorner),
			}),
		})
	end

	local Blur = New("ImageLabel", { -- Shadow
		Image = "rbxassetid://8992230677",
		ThemeTag = {
			ImageColor3 = "WindowShadow",
			--ImageTransparency = "WindowShadowTransparency",
		},
		ImageTransparency = 1, -- .7
		Size = UDim2.new(1, 100, 1, 100),
		Position = UDim2.new(0, -100 / 2, 0, -100 / 2),
		ScaleType = "Slice",
		SliceCenter = Rect.new(99, 99, 99, 99),
		BackgroundTransparency = 1,
		ZIndex = -999999999999999,
		Name = "Blur",
	})

	Dialog.UIElements.Main = New("Frame", {
		Size = UDim2.new(0, 280, 0, 0),
		ThemeTag = {
			BackgroundColor3 = Type .. "Background",
		},
		AutomaticSize = "Y",
		BackgroundTransparency = 1, -- .7
		Visible = false,
		ZIndex = 99999,
	}, {
		New("UIPadding", {
			PaddingTop = UDim.new(0, Dialog.UIPadding),
			PaddingLeft = UDim.new(0, Dialog.UIPadding),
			PaddingRight = UDim.new(0, Dialog.UIPadding),
			PaddingBottom = UDim.new(0, Dialog.UIPadding),
		}),
	})

	Dialog.UIElements.MainContainer = Creator.NewRoundFrame(Dialog.UICorner, "Squircle", {
		Visible = false, -- true
		--GroupTransparency = 1, -- 0
		ImageTransparency = Key and 0.15 or 0,
		Parent = Parent or Dialog.UIElements.FullScreen,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutomaticSize = "XY",
		ThemeTag = {
			ImageColor3 = Type .. "Background",
			ImageTransparency = Type .. "BackgroundTransparency",
		},
		ZIndex = 9999,
	}, {
		--[[Creator.NewRoundFrame(Dialog.UICorner, "SquircleGlass", {
			ImageTransparency = 0.92,
			Size = UDim2.new(1, 2, 1, 2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
		}),]]
		Dialog.UIElements.Main,

		-- New("UIScale", {
		--     Scale = .9
		-- }),
		-- Creator.NewRoundFrame(Dialog.UICorner, "SquircleOutline2", {
		--     Size = UDim2.new(1,0,1,0),
		--     ImageTransparency = 1,
		--     ThemeTag = {
		--         ImageColor3 = "Outline",
		--     },
		-- }, {
		--     New("UIGradient", {
		--         Rotation = 45,
		--         Transparency = NumberSequence.new({
		--             NumberSequenceKeypoint.new(0, 0.55),
		--             NumberSequenceKeypoint.new(0.5, 0.8),
		--             NumberSequenceKeypoint.new(1, 0.6)
		--         })
		--     })
		-- })
	})

    local GuiService = game:GetService("GuiService")
    local previous
    function Dialog:Open()
        if Dialog.Closed then return end
        if not Key and Window then
            if Window.Popup and Window.Popup ~= Dialog then Window.Popup:Close("replaced") end
            Window.Popup = Dialog
            previous = GuiService.SelectedObject
            Dialog.UIElements.FullScreen.Visible = true
            Dialog.UIElements.FullScreen.Active = true
            Dialog.UIElements.FullScreen.BackgroundTransparency = 0.45
        end
        Dialog.UIElements.MainContainer.Visible = true
        Dialog.UIElements.Main.Visible = true
        Dialog.UIElements.MainContainer.ImageTransparency = 0
        local viewport = WindUI.ScreenGui.AbsoluteSize
        local scale = WindUI.UIScale or 1
        local available = math.max(120, viewport.X / scale - 48)
        local width = Dialog.UIElements.Main.Size.X.Scale * available + Dialog.UIElements.Main.Size.X.Offset
        Dialog.UIElements.Main.Size = UDim2.new(0, math.min(math.max(120, width), available), 0, Dialog.UIElements.Main.Size.Y.Offset)
        for _, object in ipairs(Dialog.UIElements.Main:GetDescendants()) do
            if object:IsA("GuiButton") then GuiService.SelectedObject = object; break end
        end
    end
    function Dialog:Close(result)
        if Dialog.Closed then return function() end end
        Dialog.Closed = true
        Dialog.Result = result or Dialog.Result or "cancelled"
        if Window and Window.Popup == Dialog then Window.Popup = nil end
        if previous and previous.Parent then GuiService.SelectedObject = previous else GuiService.SelectedObject = nil end
        Creator.SafeCallback(Dialog.OnResult, Dialog.Result)
        if Dialog.Scope then
            Dialog.Scope:Destroy()
        else
            if Dialog.UIElements.FullScreen then Dialog.UIElements.FullScreen:Destroy() end
            Dialog.UIElements.MainContainer:Destroy()
        end
        return function() end
    end
    if not Key then
        Creator.AddSignal(game:GetService("UserInputService").InputBegan, function(input)
            if Window.Popup == Dialog and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then Dialog:Close("cancelled") end
        end)
    end

	--Dialog:Open()
	return Dialog
end

return DialogModule
