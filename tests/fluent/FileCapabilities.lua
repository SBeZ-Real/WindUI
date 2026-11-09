local disk,folders={},{}
local reads,writes,renames=0,0,0
local readFailure,writeFailure=false,false
local function readfile(path) reads+=1;assert(not readFailure,"read denied");return assert(disk[path],"missing file")end
local function writefile(path,value)writes+=1;assert(not writeFailure,"write denied");disk[path]=value end
local function isfile(path)return disk[path]~=nil end
local function isfolder(path)return folders[path]or folders[path:gsub("/$","")]end
local function makefolder(path)folders[path]=true end
local function delfile(path)disk[path]=nil end
local function renamefile(from,to)renames+=1;disk[to]=assert(disk[from]);disk[from]=nil end
local function listfiles(path)local files={};for file in pairs(disk)do if file:sub(1,#path)==path then table.insert(files,file)end end;return files end
