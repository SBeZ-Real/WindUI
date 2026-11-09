local Capabilities = require("./runtime/Capabilities")
local WindowManager = require("./runtime/WindowManager")
local ThemeEngine = require("./runtime/ThemeEngine")

local WindUI = {
	Window = nil,
	Theme = nil,
	Creator = require("./modules/Creator"),
	LocalizationModule = require("./modules/Localization"),
	NotificationModule = require("./components/Notification"),
	Themes = nil,
	Transparent = false,

	TransparencyValue = 0.15,

	UIScale = 1,

	ConfigManager = nil,
	Version = "0.0.0",

	Services = require("./utils/services/Init"),

	OnThemeChangeFunction = nil,

	cloneref = nil,
	UIScaleObj = nil,

	CreateWindow = nil,

	CurrentInput = nil,
}

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

WindUI.cloneref = cloneref

local HttpService = cloneref(game:GetService("HttpService"))
local Players = cloneref(game:GetService("Players"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

function WindUI.GenerateGUID()
	return HttpService:GenerateGUID(false)
end

local CurInput = WindUI.GenerateGUID()

WindUI.Creator.AddSignal(UserInputService.InputBegan, function(Input, GameProcessed)
	--[[if GameProcessed then
		return
	end]]

	WindUI.Creator.Tasks.defer(function()
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			if WindUI.CurrentInput and WindUI.CurrentInput ~= CurInput then
				return
			end

			WindUI.CurrentInput = CurInput
			--print(CurInput)
			--WindUI.InputStartedOnUI = false
		end
	end)
end)
WindUI.Creator.AddSignal(UserInputService.InputEnded, function(Input, GameProcessed)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
		if WindUI.CurrentInput and WindUI.CurrentInput ~= CurInput then
			return
		end

		WindUI.CurrentInput = nil
	end
end)

local LocalPlayer = Players.LocalPlayer or nil

local Package = HttpService:JSONDecode(require("../build/package"))
if Package then
	WindUI.Version = Package.version
end

local KeySystem = require("./components/KeySystem")

local Creator = WindUI.Creator
local task = Creator.Tasks

local New = Creator.New

--local Tween = Creator.Tween
--local ServicesModule = WindUI.Services

local Acrylic = require("./utils/Acrylic/Init")

local ProtectGui = Capabilities.Protect

local GUIParent = Capabilities.Parent()

local UIScaleObj = New("UIScale", {
	Scale = WindUI.UIScale,
})

WindUI.UIScaleObj = UIScaleObj

WindUI.ScreenGui = New("ScreenGui", {
	Name = "WindUI",
	Parent = GUIParent,
	IgnoreGuiInset = true,
	ScreenInsets = "None",
	DisplayOrder = -99999,
}, {

	New("Folder", {
		Name = "Window",
	}),
	-- New("Folder", {
	--     Name = "Notifications"
	-- }),
	-- New("Folder", {
	--     Name = "Dropdowns"
	-- }),
	New("Folder", {
		Name = "KeySystem",
	}),
	New("Folder", {
		Name = "Popups",
	}),
	New("Folder", {
		Name = "ToolTips",
	}),
})

WindUI.NotificationGui = New("ScreenGui", {
	Name = "WindUI/Notifications",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
WindUI.DropdownGui = New("ScreenGui", {
	Name = "WindUI/Dropdowns",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
WindUI.TooltipGui = New("ScreenGui", {
	Name = "WindUI/Tooltips",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
ProtectGui(WindUI.ScreenGui)
ProtectGui(WindUI.NotificationGui)
ProtectGui(WindUI.DropdownGui)
ProtectGui(WindUI.TooltipGui)

Creator.Init(WindUI)
WindUI.Capabilities = Capabilities.Detect()
WindUI.WindowManager = WindowManager.new(WindUI, GUIParent)
WindUI.Windows = WindUI.WindowManager.Windows

function WindUI:SetParent(parent)
    WindUI.WindowManager.Parent = parent
    for _, window in pairs(WindUI.Windows) do
        for _, key in ipairs({"ScreenGui", "DropdownGui", "TooltipGui"}) do window.Context[key].Parent = parent end
    end
	if WindUI.ScreenGui then
		WindUI.ScreenGui.Parent = parent
	end
	if WindUI.NotificationGui then
		WindUI.NotificationGui.Parent = parent
	end
	if WindUI.DropdownGui then
		WindUI.DropdownGui.Parent = parent
	end
	if WindUI.TooltipGui then
		WindUI.TooltipGui.Parent = parent
	end
end
math.clamp(WindUI.TransparencyValue, 0, 1)

local Holder = WindUI.NotificationModule.Init(WindUI.NotificationGui)

function WindUI:Notify(Config)
	Config.Holder = Holder.Frame
	Config.Window = Config.Window or WindUI.Window
	--Config.WindUI = WindUI
	return WindUI.NotificationModule.New(Config)
end

function WindUI:SetNotificationLower(Val)
	Holder.SetLower(Val)
end

function WindUI:SetFont(FontId)
	Creator.UpdateFont(FontId)
end

function WindUI:OnThemeChange(func)
	WindUI.OnThemeChangeFunction = func
end

function WindUI:AddTheme(LTheme)
	WindUI.Themes[LTheme.Name] = LTheme
	return LTheme
end

function WindUI:SetTheme(Value)
	if WindUI.Themes[Value] then
		WindUI.Theme = WindUI.Themes[Value]
		Creator.SetTheme(WindUI.Themes[Value])
        for _, window in pairs(WindUI.Windows) do if window._GlobalTheme then window._GlobalTheme() end end

		if WindUI.OnThemeChangeFunction then
			WindUI.OnThemeChangeFunction(Value)
		end

		return WindUI.Themes[Value]
	end
	return nil
end

function WindUI:GetThemes()
	return WindUI.Themes
end
function WindUI:GetCurrentTheme()
	return WindUI.Theme.Name
end
function WindUI:GetTransparency()
	return WindUI.Transparent or false
end
function WindUI:GetWindowSize()
	return WindUI.Window.UIElements.Main.Size
end
function WindUI:Localization(LocalizationConfig)
	return WindUI.LocalizationModule:New(LocalizationConfig, Creator)
end

function WindUI:SetLanguage(Value)
	if Creator.Localization then
		return Creator.SetLanguage(Value)
	end
	return false
end

function WindUI:ToggleAcrylic(Value)
	if WindUI.Window and WindUI.Window.AcrylicPaint and WindUI.Window.AcrylicPaint.Model then
		WindUI.Window.Acrylic = Value
		WindUI.Window.AcrylicPaint.Model.Transparency = Value and 0.98 or 1
		if Value then
			Acrylic.Enable(WindUI.Window.ID)
		else
			Acrylic.Disable(WindUI.Window.ID)
		end
	end
end

function WindUI:Gradient(stops, props)
	local colorSequence = {}
	local transparencySequence = {}

	for posStr, stop in next, stops do
		local position = tonumber(posStr)
		if position then
			position = math.clamp(position / 100, 0, 1)

			local color = stop.Color
			if typeof(color) == "string" and string.sub(color, 1, 1) == "#" then
				color = Color3.fromHex(color)
			end

			local transparency = stop.Transparency or 0

			table.insert(colorSequence, ColorSequenceKeypoint.new(position, color))
			table.insert(transparencySequence, NumberSequenceKeypoint.new(position, transparency))
		end
	end

	table.sort(colorSequence, function(a, b)
		return a.Time < b.Time
	end)
	table.sort(transparencySequence, function(a, b)
		return a.Time < b.Time
	end)

	if #colorSequence < 2 then
		table.insert(colorSequence, ColorSequenceKeypoint.new(1, colorSequence[1].Value))
		table.insert(transparencySequence, NumberSequenceKeypoint.new(1, transparencySequence[1].Value))
	end

	local gradientData = {
		Color = ColorSequence.new(colorSequence),
		Transparency = NumberSequence.new(transparencySequence),
	}

	if props then
		for k, v in pairs(props) do
			gradientData[k] = v
		end
	end

	return gradientData
end

function WindUI:Popup(PopupConfig)
    PopupConfig = table.clone(PopupConfig)
	PopupConfig.WindUI = WindUI
    local scope = Creator.Scope.new(Creator.RootScope)
    local success, popup = pcall(function() return scope:Run(require("./components/popup/Init").new, PopupConfig, WindUI.ScreenGui.Popups) end)
    if not success then scope:Destroy(); error(popup, 0) end
    return scope:Bind(popup)
end

WindUI.Themes = require("./themes/Init")(WindUI, Creator)

Creator.Themes = WindUI.Themes

WindUI:SetTheme("Dark")
WindUI:SetLanguage(Creator.Language)

function WindUI:CreateWindow(Config)
	local CreateWindow = require("./components/window/Init")

    Config = table.clone(Config or {})
    if Config.Folder then assert(Capabilities.ValidPath(Config.Folder), "Invalid window folder") end
    if Config.Style then
        local tokens = require("./runtime/Tokens").Resolve(Config.Style, Config.Mode or "Dark", Config.Accent, Config.Tokens)
        Config.Radius = Config.Radius or tokens.Radius.Window
        Config.ElementsRadius = Config.ElementsRadius or tokens.Radius.Control
        Config.ShadowTransparency = Config.ShadowTransparency or tokens.Elevation.Shadow
        if Config.Layout == nil then Config.Layout = "Adaptive" end
    end
    local context = WindUI.WindowManager:Context(Config)
    Config.WindUI = context
    Config.Window = WindUI.Window
    Config.Parent = context.ScreenGui.Window
    if WindUI.Capabilities.File then
        Capabilities.MakeFolder("WindUI")
        Capabilities.MakeFolder(Config.Folder or Config.Title or "Temp")
    end

	local CanLoadWindow = true

	local Theme = WindUI.Themes[Config.Theme or "Dark"]

	--WindUI.Theme = Theme
	context.Theme = Theme or WindUI.Theme

	local hwid = gethwid or function()
		return Players.LocalPlayer.UserId
	end

	local Filename = hwid()

	if Config.KeySystem then
		CanLoadWindow = false

		local keyScope = Creator.Scope.new(context.Scope)
        local function loadKeysystem()
            local success, message = pcall(function() keyScope:Run(KeySystem.new, Config, Filename, function(c)
				CanLoadWindow = c
			end) end)
            if not success then context.Scope:Destroy(); error(message, 0) end
		end

		local keyPath = (Config.Folder or "Temp") .. "/" .. Filename .. ".key"

		if Config.KeySystem.KeyValidator then
			if Config.KeySystem.SaveKey and (type(isfile) == "function" and type(readfile) == "function" and isfile(keyPath)) then
				local savedKey = readfile(keyPath)
				local isValid = Config.KeySystem.KeyValidator(savedKey)

				if isValid then
					CanLoadWindow = true
				else
					loadKeysystem()
				end
			else
				loadKeysystem()
			end
		elseif not Config.KeySystem.API then
			if Config.KeySystem.SaveKey and (type(isfile) == "function" and type(readfile) == "function" and isfile(keyPath)) then
				local savedKey = readfile(keyPath)
				local isKey = (type(Config.KeySystem.Key) == "table") and table.find(Config.KeySystem.Key, savedKey)
					or tostring(Config.KeySystem.Key) == tostring(savedKey)

				if isKey then
					CanLoadWindow = true
				else
					loadKeysystem()
				end
			else
				loadKeysystem()
			end
		else
			if (type(isfile) == "function" and type(readfile) == "function" and isfile(keyPath)) then
				local fileKey = readfile(keyPath)
				local isSuccess = false

				for _, i in next, Config.KeySystem.API do
					local serviceData = WindUI.Services[i.Type]
					if serviceData then
						local args = {}
						for _, argName in next, serviceData.Args do
							table.insert(args, i[argName])
						end

						local service = serviceData.New(table.unpack(args))
						local success = service.Verify(fileKey)
						if success then
							isSuccess = true
							break
						end
					end
				end

				CanLoadWindow = isSuccess
				if not isSuccess then
					loadKeysystem()
				end
			else
				loadKeysystem()
			end
		end

		repeat
			task.wait()
		until CanLoadWindow or context.Cancelled or context.Scope.Destroyed
        keyScope:Destroy()
        if context.Cancelled or context.Scope.Destroyed then context.Scope:Destroy(); return nil, "Window creation cancelled" end
	end

	local started = os.clock()
    if Config.Acrylic then Acrylic.init() end
    local success, Window = pcall(function() return context.Scope:Run(function()
        local Window = CreateWindow(Config)
        WindUI.WindowManager:Attach(Window, Config)
        ThemeEngine.Attach(Window, Config, WindUI)
        require("./runtime/NavigationView").Attach(Window, Config)
        return Window
    end) end)
    if not success then
        local failed = WindUI.Windows[context.ID]
        if failed then WindUI.WindowManager:Remove(failed) end
        context.Scope:Destroy(); error(Window, 0)
    end
    context.Performance:Record("CreateWindow", os.clock() - started)
    context.Scope:Bind(Window)

	WindUI.Transparent = Config.Transparent
	WindUI.Window = Window


	-- function Window:ToggleTransparency(Value)
	--     WindUI.Transparent = Value
	--     WindUI.Window.Transparent = Value

	--     Window.UIElements.Main.Background.BackgroundTransparency = Value and WindUI.TransparencyValue or 0
	--     Window.UIElements.Main.Background.ImageLabel.ImageTransparency = Value and WindUI.TransparencyValue or 0
	--     Window.UIElements.Main.Gradient.UIGradient.Transparency = NumberSequence.new{
	--         NumberSequenceKeypoint.new(0, 1),
	--         NumberSequenceKeypoint.new(1, Value and 0.85 or 0.7),
	--     }
	-- end

	return Window
end

function WindUI:RegisterComponent(name, factory) return require("./elements/Init").Register(name, factory) end

function WindUI:GetWindow(id) return WindUI.Windows[id] end
function WindUI:GetWindows() return table.clone(WindUI.Windows) end
function WindUI:Destroy()
    local windows = WindUI:GetWindows()
    for _, window in pairs(windows) do window:Destroy() end
    Creator.RootScope:Destroy()
end

return WindUI
