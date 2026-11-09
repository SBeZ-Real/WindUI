local Creator = require("../modules/Creator")
local task = Creator.Tasks
local Interaction = require("../runtime/Interaction")

local function Lazy(factory)
    local module
    return { New = function(_, config)
        module = module or factory()
        return module:New(config)
    end }
end

local Registry = {
	Elements = {
        DataTable = Lazy(function() return require("./DataTable") end),
        TreeView = Lazy(function() return require("./TreeView") end),
        DatePicker = Lazy(function() return require("./DatePicker") end),
        TimePicker = Lazy(function() return require("./TimePicker") end),
        Breadcrumb = Lazy(function() return require("./Breadcrumb") end),
        ContextMenu = Lazy(function() return require("./ContextMenu") end),
        CommandPalette = Lazy(function() return require("./CommandPalette") end),
        SearchBox = Lazy(function() return require("./SearchBox") end),

		Paragraph = Lazy(function() return require("./Paragraph") end),
		Button = Lazy(function() return require("./Button") end),
		Toggle = Lazy(function() return require("./Toggle") end),
		Slider = Lazy(function() return require("./Slider") end),
		ProgressBar = Lazy(function() return require("./ProgressBar") end),
		Keybind = Lazy(function() return require("./Keybind") end),
		Input = Lazy(function() return require("./Input") end),
		Dropdown = Lazy(function() return require("./Dropdown") end),
		Code = Lazy(function() return require("./Code") end),
		Colorpicker = Lazy(function() return require("./Colorpicker") end),
		Section = Lazy(function() return require("./Section") end),
		Divider = Lazy(function() return require("./Divider") end),
		Space = Lazy(function() return require("./Space") end),
		Image = Lazy(function() return require("./Image") end),
		Group = Lazy(function() return require("./Group") end),
		HStack = Lazy(function() return require("./HStack") end),
		VStack = Lazy(function() return require("./VStack") end),
		Viewport = Lazy(function() return require("./Viewport") end),
		--Video       = require("./Video"),
	},
	Load = function(tbl, Container, Elements, Window, WindUI, OnElementCreateFunction, ElementsModule, UIScale, Tab)
		for name, module in next, Elements do
			tbl[name] = function(self, config)
				config = table.clone(config or {})
                local scope = Creator.Scope.new(Creator.Scope.Get() or Window.Scope)
                local callback = config.Callback
                if callback or name ~= "Dropdown" then config.Callback = function(...)
                    local result = callback and table.pack(callback(...)) or { n = 0 }
                    if Window.CurrentConfig then Window.CurrentConfig:MarkDirty() end
                    return table.unpack(result, 1, result.n)
                end end
				config.Tab = Tab or tbl
				config.ParentType = tbl.__type
				config.ParentTable = tbl
				config.Index = #tbl.Elements + 1
				config.GlobalIndex = #Window.AllElements + 1
				config.Parent = Container
				config.Window = Window
				config.WindUI = WindUI
				config.UIScale = UIScale
				config.ElementsModule = ElementsModule

				local success, _elementInstance, content = pcall(function() return scope:Run(module.New, module, config) end)
                if not success then scope:Destroy(); error(_elementInstance, 0) end
                content.Scope = scope
                content.Tab = config.Tab

				if config.Flag and typeof(config.Flag) == "string" then
					if Window.CurrentConfig then
						Window.CurrentConfig:Register(config.Flag, content)

						if Window.PendingConfigData and Window.PendingConfigData[config.Flag] then
							local data = Window.PendingConfigData[config.Flag]

							local ConfigManager = Window.ConfigManager
                            if ConfigManager.Parser[data.__type] and data.__type == content.__type then
								task.defer(function()
									local success, err = pcall(function()
										ConfigManager.Parser[data.__type].Load(content, data)
									end)

									if success then
										Window.PendingConfigData[config.Flag] = nil
									else
										warn(
											"[ WindUI ] Failed to apply pending config for '"
												.. config.Flag
												.. "': "
												.. tostring(err)
										)
									end
								end)
							end
						end
					else
						Window.PendingFlags = Window.PendingFlags or {}
						Window.PendingFlags[config.Flag] = content
					end
				end

				local frame
				for key, value in next, content do
					if typeof(value) == "table" and key ~= "ElementFrame" and key:match("Frame$") then
						frame = value
						break
					end
				end

				if frame then
					content.ElementFrame = frame.UIElements.Main
					function content:SetTitle(title)
						content.Title = title
                        return frame.SetTitle and frame:SetTitle(title)
					end
					function content:SetDesc(desc)
						content.Desc = desc
                        return frame.SetDesc and frame:SetDesc(desc)
					end
					function content:SetImage(image, size)
						return frame.SetImage and frame:SetImage(image, size)
					end
					function content:SetThumbnail(image, size)
						return frame.SetThumbnail and frame:SetThumbnail(image, size)
					end
					function content:Highlight()
						frame:Highlight()
					end

				end

                local destroy = content.Destroy
                function content:Destroy()
                    if content.Destroyed then return end
                    content.Destroyed = true
                    if content.Elements then
                        local children = table.clone(content.Elements)
                        for _, child in ipairs(children) do if child.Destroy then child:Destroy() end end
                    end
                    if destroy then destroy(content) elseif frame and frame.Destroy then frame:Destroy() end
                    local function remove(list)
                        local index = table.find(list, content)
                        if index then table.remove(list, index) end
                    end
                    remove(Window.AllElements)
                    remove(tbl.Elements)
                    if Tab and Tab ~= tbl then remove(Tab.Elements) end
                    if config.Flag then
                        if Window.PendingFlags then Window.PendingFlags[config.Flag] = nil end
                        if Window.CurrentConfig then Window.CurrentConfig.Elements[config.Flag] = nil end
                    end
                    if Window.Navigation then Window.Navigation:Remove(content) end
                    scope:Destroy()
                    if Window.NewElements then tbl:UpdateAllElementShapes(tbl) end
                end
                table.insert(Window.AllElements, content)
                table.insert(tbl.Elements, content)
                if Tab and Tab ~= tbl then table.insert(Tab.Elements, content) end
                if Window.Navigation then Window.Navigation:Register(content, { Object = content, Route = config.Tab.Index, Kind = "Element" }) end
                scope:Run(Interaction.Attach, content, config, scope)
                if config.Flag then
                    for _, name in ipairs({ "Set", "Update", "Select", "Expand", "Filter", "Sort", "ApplyState" }) do
                        local method = content[name]
                        if type(method) == "function" then
                            content[name] = function(...)
                                local result = table.pack(method(...))
                                if result[1] ~= false and Window.CurrentConfig then Window.CurrentConfig:MarkDirty() end
                                return table.unpack(result, 1, result.n)
                            end
                        end
                    end
                end
                scope:Bind(content)

				if Window.NewElements then
					tbl:UpdateAllElementShapes(tbl)
				end

				if OnElementCreateFunction then
					OnElementCreateFunction(content, tbl.Elements)
				end
				return content
			end
		end
		function tbl:UpdateAllElementShapes(bbb)
			for i, element in next, bbb.Elements do
				local frame
				for key, value in pairs(element) do
					if typeof(value) == "table" and key:match("Frame$") then
						frame = value
						break
					end
				end

				if not frame and element.UpdateShape then
					frame = element
				end

				if frame then
					--print("idx changed : " .. i .. " " .. (element.Title or "not found"))
					frame.Index = i
					if frame.UpdateShape then
						--print(" .changed: " .. i)
						frame.UpdateShape(bbb)
					end
				end
			end
		end
	end,
}

function Registry.Register(name, factory)
    if type(name) ~= "string" or not name:match("^[%a_][%w_]*$") or type(factory) ~= "function" then return false, "Invalid component registration" end
    if Registry.Elements[name] then return false, "Component already registered" end
    Registry.Elements[name] = Lazy(factory)
    return true
end
return Registry
