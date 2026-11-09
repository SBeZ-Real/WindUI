local Capabilities = {}

function Capabilities.Detect()
    local RunService = game:GetService("RunService")
    return {
        Studio = RunService:IsStudio(),
        File = type(readfile) == "function" and type(writefile) == "function" and type(isfile) == "function" and type(isfolder) == "function" and type(makefolder) == "function",
        ListFiles = type(listfiles) == "function",
        DeleteFile = type(delfile) == "function",
        AtomicRename = type(renamefile) == "function",
        Request = type(http_request or (syn and syn.request) or request) == "function",
        Clipboard = type(setclipboard or toclipboard) == "function",
        CustomAsset = type(getcustomasset or getsynasset) == "function",
        Touch = game:GetService("UserInputService").TouchEnabled,
        Keyboard = game:GetService("UserInputService").KeyboardEnabled,
        Gamepad = game:GetService("UserInputService").GamepadEnabled,
    }
end

function Capabilities.Parent()
    if type(gethui) == "function" then
        local success, parent = pcall(gethui)
        if success and typeof(parent) == "Instance" then return parent end
    end
    local player = game:GetService("Players").LocalPlayer
    assert(player, "WindUI must run on a Roblox client")
    return player:WaitForChild("PlayerGui")
end

function Capabilities.Protect(gui)
    local protect = protectgui or (syn and syn.protect_gui)
    if type(protect) == "function" then
        local success, message = pcall(protect, gui)
        if not success then warn("[WindUI GUI protection] " .. tostring(message)) end
    end
end

function Capabilities.ValidPath(path)
    return type(path) == "string" and #path > 0 and #path <= 180 and not path:find("..", 1, true) and not path:find("[%c:%\\]") and path:sub(1, 1) ~= "/"
end

function Capabilities.MakeFolder(path)
    if not Capabilities.ValidPath(path) then return false, "Invalid folder path" end
    if type(isfolder) ~= "function" or type(makefolder) ~= "function" then return false, "Folder storage unavailable" end
    return pcall(function()
        local current = ""
        for segment in path:gmatch("[^/]+") do
            current = current == "" and segment or current .. "/" .. segment
            if not isfolder(current) then makefolder(current) end
        end
    end)
end

return Capabilities
