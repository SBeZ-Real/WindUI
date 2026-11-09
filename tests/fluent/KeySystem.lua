local baseline=WindUI.Creator.RootScope:Stats()
local window
local thread=task.spawn(function()
    window=WindUI:CreateWindow({ID="KeyTest",Title="Key test",Effects="Off",KeySystem={Key="approved",SaveKey=false}})
end)
advance(0.1)
assert(window==nil,"Key gate was bypassed")
local context=WindUI.WindowManager.Contexts.KeyTest
assert(context and context.ScreenGui.KeySystem,"Missing key context")
local textbox,submit
for _,object in ipairs(context.ScreenGui.KeySystem:GetDescendants())do
    if object:IsA("TextBox")and object.PlaceholderText=="Enter Key"then textbox=object end
    if object:IsA("TextLabel")and object.Text=="Submit"then
        local parent=object.Parent
        while parent and not parent:IsA("GuiButton")do parent=parent.Parent end
        submit=parent
    end
end
assert(textbox and submit,"Key UI missing input or submit")
textbox.Text="wrong"
textbox.FocusLost:Fire(false)
submit.Activated:Fire()
advance(0.1)
assert(window==nil,"Wrong key accepted")
textbox.Text="approved"
textbox.FocusLost:Fire(false)
task.spawn(function()submit.Activated:Fire()end)
advance(0.6)
assert(window and not window.Destroyed,"Valid key did not open window")
assert(#context.ScreenGui.KeySystem:GetChildren()==0,"Key UI retained after validation")
window:Destroy()
advance(1)
local final=WindUI.Creator.RootScope:Stats()
assert(final.Scopes==baseline.Scopes and final.Instances==baseline.Instances and final.Connections==baseline.Connections,"Key scope leaked")
assert(#warnings==0,table.concat(warnings,"\n"))
print("KEYSYSTEM PASS: invalid key blocked, valid key accepted, independent GUI and cleanup")
local cancelled,reason,finished
local pending=task.spawn(function()
    cancelled,reason=WindUI:CreateWindow({ID="CancelKey",Title="Cancel",KeySystem={Key="secret"}})
    finished=true
end)
advance(0.1)
local exitButton
for _,object in ipairs(WindUI.WindowManager.Contexts.CancelKey.ScreenGui.KeySystem:GetDescendants())do
    if object:IsA("TextLabel")and object.Text=="Exit"then
        local parent=object.Parent
        while parent and not parent:IsA("GuiButton")do parent=parent.Parent end
        exitButton=parent
    end
end
assert(exitButton)
exitButton.Activated:Fire()
advance(0.5)
assert(finished and cancelled==nil and reason=="Window creation cancelled","Key cancel left a waiting creation")
assert(WindUI.WindowManager.Contexts.CancelKey==nil,"Cancelled key context leaked")
print("KEYSYSTEM CANCEL PASS: exit aborts pending creation without accepting the key")
