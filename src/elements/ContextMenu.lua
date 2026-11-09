local Element = {}
function Element:New(Config)
    local config = table.clone(Config)
    config.Callback = function() Config.Window:ContextMenu(Config.Items or {}) end
    local _, result = require("./Button"):New(config)
    result.__type = "ContextMenu"
    function result:Open(position) return Config.Window:ContextMenu(Config.Items or {}, position) end
    return result.__type, result
end
return Element
