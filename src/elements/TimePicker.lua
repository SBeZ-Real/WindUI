local Element = {}
function Element:New(Config) return require("../components/ui/Picker").New(Config, "TimePicker") end
return Element
