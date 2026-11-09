local Element = {}
function Element:New(Config) return require("../components/ui/Picker").New(Config, "DatePicker") end
return Element
