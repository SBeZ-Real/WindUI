local Element = {}
function Element:New(Config)
    local config = table.clone(Config)
    config.Title = config.Title or "Commands"
    config.Callback = function() Config.Window:OpenCommandPalette() end
    local _, result = require("./Button"):New(config)
    result.__type = "CommandPalette"
    function result:Open(query) return Config.Window:OpenCommandPalette(query) end
    return result.__type, result
end
return Element
