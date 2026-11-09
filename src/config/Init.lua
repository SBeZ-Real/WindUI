local HttpService = game:GetService("HttpService")
local Creator = require("../modules/Creator")
local task = Creator.Tasks
local Storage = require("../runtime/Storage")
local Schema = require("../runtime/Schema")
local Capabilities = require("../runtime/Capabilities")

local function CreateModule(Window)
local ConfigManager = {
    Configs = {},
    Parser = {
        Colorpicker = {
            Save = function(obj)
                return {
                    __type = obj.__type,
                    value = obj.Default:ToHex(),
                    transparency = obj.Transparency or nil,
                }
            end,
            Load = function(element, data)
                if element and element.Update then
                    return element:Update(Color3.fromHex(data.value), data.transparency or nil)
                end
            end
        },
        Dropdown = {
            Save = function(obj)
                return {
                    __type = obj.__type,
                    value = obj.Value,
                }
            end,
            Load = function(element, data)
                if element and element.Select then
                    return element:Select(data.value)
                end
            end
        },
        Input = {
            Save = function(obj)
                return {
                    __type = obj.__type,
                    value = obj.Value,
                }
            end,
            Load = function(element, data)
                if element and element.Set then
                    return element:Set(data.value)
                end
            end
        },
        Keybind = {
            Save = function(obj)
                return {
                    __type = obj.__type,
                    value = obj.Value,
                }
            end,
            Load = function(element, data)
                if element and element.Set then
                    return element:Set(data.value)
                end
            end
        },
        Slider = {
            Save = function(obj)
                return {
                    __type = obj.__type,
                    value = obj.Value.Default,
                }
            end,
            Load = function(element, data)
                if element and element.Set then
                    return element:Set(tonumber(data.value))
                end
            end
        },
        Toggle = {
            Save = function(obj)
                return {
                    __type = obj.__type,
                    value = obj.Value,
                }
            end,
            Load = function(element, data)
                if element and element.Set then
                    return element:Set(data.value)
                end
            end
        },
    }
}

for _, name in ipairs({ "DatePicker", "TimePicker", "SearchBox" }) do ConfigManager.Parser[name] = ConfigManager.Parser.Input end
ConfigManager.Parser.ProgressBar = ConfigManager.Parser.Slider
for _, name in ipairs({ "DataTable", "TreeView" }) do
    ConfigManager.Parser[name] = {
        Save = function(obj) return { __type = obj.__type, value = obj:GetState() } end,
        Load = function(element, data) return element:ApplyState(data.value) end,
    }
end

function ConfigManager:Init(WindowTable)
    local ConfigManager = CreateModule(WindowTable)
    ConfigManager.Folder = WindowTable.Folder or WindowTable.ID or "Session"
    assert(Capabilities.ValidPath(ConfigManager.Folder), "Invalid configuration folder")
    ConfigManager.Path = "WindUI/" .. ConfigManager.Folder .. "/config/"
    if WindowTable.ConfigNamespace then ConfigManager.Path ..= WindowTable.ConfigNamespace .. "/" end
    ConfigManager.Storage = Storage.Resolve(WindowTable.Storage)
    ConfigManager.Persistent = ConfigManager.Storage.Persistent == true
    ConfigManager.Profile = "default"
    ConfigManager.BasePath = ConfigManager.Path
    return ConfigManager
end

function ConfigManager:SetPath(customPath)
    if not Capabilities.ValidPath(customPath) then return false, "Invalid configuration path" end
    ConfigManager.Path = customPath:sub(-1) == "/" and customPath or customPath .. "/"
    ConfigManager.BasePath = ConfigManager.Path
    return true
end

function ConfigManager:SetProfile(name)
    if not Schema.Name(name) then return false, "Invalid profile name" end
    if Window.CurrentConfig and Window.CurrentConfig.StopAutoSave then Window.CurrentConfig:StopAutoSave() end
    ConfigManager.Profile = name
    ConfigManager.Path = ConfigManager.BasePath .. (name == "default" and "" or "profiles/" .. name .. "/")
    ConfigManager.Configs = {}
    Window.CurrentConfig = nil
    return true
end

function ConfigManager:CreateConfig(configFilename, autoload)
    if not Schema.Name(configFilename) then return false, "Invalid configuration filename" end
    local ConfigModule = {
        Path = ConfigManager.Path .. configFilename .. ".json",
        Elements = {}, CustomData = {}, AutoLoad = autoload or false, Version = 1.2,
        Persistent = ConfigManager.Persistent, AutoSave = false, Loading = false,
    }
        local pending
    local blocked = false
    function ConfigModule:SetAsCurrent() Window:SetCurrentConfig(ConfigModule) end
    function ConfigModule:Register(Name, Element) ConfigModule.Elements[Name] = Element end
    function ConfigModule:Set(key, value) ConfigModule.CustomData[key] = value; ConfigModule:MarkDirty() end
    function ConfigModule:Get(key) return ConfigModule.CustomData[key] end
    function ConfigModule:SetAutoLoad(Value) ConfigModule.AutoLoad = Value == true end
    function ConfigModule:GetData() return { elements = ConfigModule.Elements, custom = ConfigModule.CustomData, autoload = ConfigModule.AutoLoad } end
    local function snapshot()
        for flag, element in pairs(Window.PendingFlags or {}) do ConfigModule:Register(flag, element) end
        local data = { __version = ConfigModule.Version, __elements = {}, __autoload = ConfigModule.AutoLoad, __custom = ConfigModule.CustomData }
        for name, element in pairs(ConfigModule.Elements) do
            if not element.Destroyed and ConfigManager.Parser[element.__type] then data.__elements[tostring(name)] = ConfigManager.Parser[element.__type].Save(element) end
        end
        return data
    end
    function ConfigModule:Export()
        local success, result = pcall(function() return HttpService:JSONEncode(snapshot()) end)
        if not success then return false, tostring(result) end
        return result
    end
    function ConfigModule:Save()
        if blocked then return false, "Configuration is corrupt; recover or select another filename before saving" end
        local existing, readError = ConfigManager.Storage:Read(ConfigModule.Path)
        if readError then return false, readError end
        if existing then
            local success, data = pcall(function() return HttpService:JSONDecode(existing) end)
            if not success or not Schema.Config(data) then blocked = true; return false, "Existing configuration is corrupt; preserved without overwrite" end
        end
        local success, data = pcall(snapshot)
        if not success then return false, tostring(data) end
        local valid, message = Schema.Config(data)
        if not valid then return false, message end
        local encoded, json = pcall(function() return HttpService:JSONEncode(data) end)
        if not encoded then return false, tostring(json) end
        local written, reason = ConfigManager.Storage:Write(ConfigModule.Path, json)
        if not written then return false, reason end
        ConfigModule.LastSave = { Persistent = ConfigModule.Persistent, Storage = ConfigManager.Storage.Name, Atomic = ConfigManager.Storage.Atomic == true }
        return data, ConfigModule.LastSave
    end
    function ConfigModule:Import(json)
        if type(json) ~= "string" or #json > 2 * 1024 * 1024 then return false, "Invalid JSON input" end
        local success, loadData = pcall(function() return HttpService:JSONDecode(json) end)
        if not success then return false, "Failed to parse config file" end
        local data, message = Schema.Config(loadData)
        if not data then return false, message end
        for flag, element in pairs(Window.PendingFlags or {}) do ConfigModule:Register(flag, element) end
        ConfigModule.Loading = true
        Window.PendingConfigData = {}
        for name, entry in pairs(data.__elements) do
            local element = ConfigModule.Elements[name]
            local parser = ConfigManager.Parser[entry.__type]
            if element and parser and element.__type == entry.__type then
                local applied, reason, detail = pcall(parser.Load, element, entry)
                if not applied or reason == false then ConfigModule.Loading = false; return false, "Failed to load " .. name .. ": " .. tostring(detail or reason) end
            else
                Window.PendingConfigData[name] = entry
            end
        end
        ConfigModule.CustomData = data.__custom or {}
        ConfigModule.AutoLoad = data.__autoload == true
        ConfigModule.Loading = false
        return ConfigModule.CustomData
    end
    function ConfigModule:Load()
        local data, message = ConfigManager.Storage:Read(ConfigModule.Path)
        if not data then return false, message or "Config file does not exist" end
        local result, reason = ConfigModule:Import(data)
        if result == false then blocked = true end
        return result, reason
    end
    function ConfigModule:RecoverBackup()
        local data, message = ConfigManager.Storage:Read(ConfigModule.Path .. ".bak")
        if not data then return false, message or "Backup does not exist" end
        local result, reason = ConfigModule:Import(data)
        if result == false then return false, reason end
        local saved, saveError = ConfigManager.Storage:Write(ConfigModule.Path, data)
        if saved then blocked = false end
        return saved, saveError
    end
    function ConfigModule:StartAutoSave(delay)
        ConfigModule.AutoSave = true
        ConfigModule.AutoSaveDelay = math.clamp(tonumber(delay) or 0.5, 0.1, 60)
        return ConfigModule
    end
    function ConfigModule:StopAutoSave()
        ConfigModule.AutoSave = false
        if pending then task.cancel(pending); pending = nil end
    end
    function ConfigModule:MarkDirty()
        if not ConfigModule.AutoSave or ConfigModule.Loading or Window.Destroyed then return end
        if pending then task.cancel(pending) end
        pending = task.delay(ConfigModule.AutoSaveDelay, function()
            pending = nil
            local result, message = ConfigModule:Save()
            if result == false then warn("[WindUI autosave] " .. tostring(message)) end
        end)
    end
    function ConfigModule:Delete()
        ConfigModule:StopAutoSave()
        local success, message = ConfigManager.Storage:Delete(ConfigModule.Path)
        if not success then return false, message end
        ConfigManager.Configs[configFilename] = nil
        if Window.CurrentConfig == ConfigModule then Window.CurrentConfig = nil end
        return true, "Config deleted successfully"
    end
    ConfigModule:SetAsCurrent()
    ConfigManager.Configs[configFilename] = ConfigModule
    local stored = ConfigManager.Storage:Read(ConfigModule.Path)
    if stored then
        local success, data = pcall(function() return HttpService:JSONDecode(stored) end)
        if success and Schema.Config(data) then
            if data.__autoload then ConfigModule.AutoLoad = true; ConfigModule:Load() end
        else blocked = true end
    end
    return Window.Scope and Window.Scope:Bind(ConfigModule) or ConfigModule
end

function ConfigManager:Config(configFilename, autoload) return ConfigManager:CreateConfig(configFilename, autoload) end
function ConfigManager:GetConfig(configName) return ConfigManager.Configs[configName] end
function ConfigManager:GetAutoLoadConfigs()
    local result = {}
    for name, value in pairs(ConfigManager.Configs) do if value.AutoLoad then table.insert(result, name) end end
    return result
end
function ConfigManager:DeleteConfig(configName)
    if not Schema.Name(configName) then return false, "Invalid configuration name" end
    if ConfigManager.Configs[configName] then return ConfigManager.Configs[configName]:Delete() end
    return ConfigManager.Storage:Delete(ConfigManager.Path .. configName .. ".json")
end
function ConfigManager:AllConfigs()
    local result = {}
    local files, message = ConfigManager.Storage:List(ConfigManager.Path)
    for _, path in ipairs(files) do
        local name = path:match("([^/]+)%.json$")
        if name and Schema.Name(name) then table.insert(result, name) end
    end
    table.sort(result)
    return result, message
end
function ConfigManager:SavePreset(name, config)
    if not Schema.Name(name) then return false, "Invalid preset name" end
    if not (config or Window.CurrentConfig) then return false, "Select a configuration first" end
    local json, message = (config or Window.CurrentConfig):Export()
    if json == false then return false, message end
    return ConfigManager.Storage:Write(ConfigManager.BasePath .. "presets/" .. name .. ".json", json)
end
function ConfigManager:LoadPreset(name, config)
    if not Schema.Name(name) then return false, "Invalid preset name" end
    if not (config or Window.CurrentConfig) then return false, "Select a configuration first" end
    local json, message = ConfigManager.Storage:Read(ConfigManager.BasePath .. "presets/" .. name .. ".json")
    if not json then return false, message or "Preset does not exist" end
    return (config or Window.CurrentConfig):Import(json)
end
return ConfigManager
end

return CreateModule()
