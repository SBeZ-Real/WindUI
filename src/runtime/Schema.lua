local Calendar = require("./Calendar")
local Schema = {}

function Schema.Name(value)
    return type(value) == "string" and #value > 0 and #value <= 80 and value:match("^[%w_%- ]+$") ~= nil
end

function Schema.Config(value)
    if type(value) ~= "table" then return nil, "Configuration must be an object" end
    if value.__version == nil then value = { __version = 1.2, __elements = value, __custom = {} } end
    if type(value.__version) ~= "number" or value.__version ~= value.__version or value.__version <= 0 or value.__version > 1.2 then return nil, "Unsupported configuration schema" end
    if type(value.__elements) ~= "table" or (value.__custom ~= nil and type(value.__custom) ~= "table") then return nil, "Invalid configuration fields" end
    if value.__autoload ~= nil and type(value.__autoload) ~= "boolean" then return nil, "Invalid autoload value" end
    for name, entry in pairs(value.__elements) do
        if type(name) ~= "string" or type(entry) ~= "table" or type(entry.__type) ~= "string" then return nil, "Invalid element entry" end
        local kind, data = entry.__type, entry.value
        if kind == "Toggle" and type(data) ~= "boolean" then return nil, "Invalid toggle value" end
        if (kind == "Slider" or kind == "ProgressBar") and (tonumber(data) == nil or tonumber(data) ~= tonumber(data) or math.abs(tonumber(data)) == math.huge) then return nil, "Invalid numeric value" end
        if (kind == "Input" or kind == "Keybind" or kind == "SearchBox") and type(data) ~= "string" then return nil, "Invalid text value" end
        if kind == "Colorpicker" and (type(data) ~= "string" or not data:match("^%x%x%x%x%x%x$")) then return nil, "Invalid color value" end
        if entry.transparency ~= nil and (type(entry.transparency) ~= "number" or entry.transparency < 0 or entry.transparency > 1) then return nil, "Invalid transparency" end
        if kind == "DatePicker" and not Calendar.Valid(data) then return nil, "Invalid date value" end
        if kind == "TimePicker" and not Calendar.Time(data) then return nil, "Invalid time value" end
        if kind == "DataTable" then
            if type(data) ~= "table" or type(data.Query) ~= "string" or type(data.Selection) ~= "table" or type(data.Descending) ~= "boolean" or (data.SortKey ~= nil and type(data.SortKey) ~= "string") then return nil, "Invalid table state" end
            for _, index in ipairs(data.Selection) do if type(index) ~= "number" or index < 1 or index % 1 ~= 0 then return nil, "Invalid row selection" end end
        elseif kind == "TreeView" then
            if type(data) ~= "table" or type(data.Expanded) ~= "table" or (data.Value ~= nil and type(data.Value) ~= "string") then return nil, "Invalid tree state" end
            for key, expanded in pairs(data.Expanded) do if type(key) ~= "string" or type(expanded) ~= "boolean" then return nil, "Invalid tree expansion" end end
        end
    end
    return value
end

return Schema
