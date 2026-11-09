-- Credits: Fluent - Dawid

local Acrylic = {
    AcrylicBlur = require("./Blur"),
    AcrylicPaint = require("./Paint"),
}
local baseEffect
local owners = {}
local function register(object)
    object.FarIntensity = 0
    object.InFocusRadius = 0.1
    object.NearIntensity = 1
end
local function registerDefaults() register(baseEffect) end
function Acrylic.init()
    if baseEffect then return end
    baseEffect = Instance.new("DepthOfFieldEffect")
    baseEffect.Name = "WindUIAcrylic"
    registerDefaults()
end
function Acrylic.Enable(owner)
    Acrylic.init()
    owners[owner or "legacy"] = true
    baseEffect.Parent = game:GetService("Lighting")
end
function Acrylic.Disable(owner)
    owners[owner or "legacy"] = nil
    if not next(owners) and baseEffect then
        baseEffect:Destroy()
        baseEffect = nil
    end
end
return Acrylic
