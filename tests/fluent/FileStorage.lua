local window=WindUI:CreateWindow({ID="FileTest",Title="Storage",Folder="FileTests",Effects="Off"})
local toggle=window:Tab({Title="Value"}):Toggle({Flag="toggle",Value=false,Callback=function()end})
local config=window.ConfigManager:CreateConfig("persistent")
assert(config.Persistent and window.ConfigManager.Storage.Name=="File")
local saved,meta=config:Save()
assert(saved and meta.Persistent and meta.Atomic and renames==1)
local original=disk[config.Path]
toggle:Set(true)
assert(config:Save()~=false and disk[config.Path..".bak"]==original)
assert(config:Load()~=false and toggle.Value)
disk[config.Path]="corrupt"
assert(config:Load()==false and config:Save()==false and disk[config.Path]=="corrupt")
assert(config:RecoverBackup() and toggle.Value==false)
assert(config:Load()~=false and toggle.Value==false)
writeFailure=true
local previous=disk[config.Path]
assert(config:Save()==false and disk[config.Path]==previous)
writeFailure=false
readFailure=true
assert(config:Load()==false)
readFailure=false
assert(window.ConfigManager.Storage:Write("../escape","bad")==false)
assert(window.ConfigManager.Storage:Delete("../escape")==false)
local found=window.ConfigManager:AllConfigs()
assert(#found==1 and found[1]=="persistent")
assert(config:Delete() and disk[config.Path]==nil)
window:Destroy()
advance(1)
assert(#warnings==0,table.concat(warnings,"\n"))
print("FILE ADAPTER PASS: atomic rename path, backups, recovery, denied IO, path checks, delete using simulated executor APIs")
