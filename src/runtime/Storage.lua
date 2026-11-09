local Capabilities = require("./Capabilities")
local Storage = {}
local Files = {}

function Storage.Memory()
    return {
        Name = "Memory", Persistent = false, Atomic = true,
        Read = function(_, path) return Files[path] end,
        Write = function(_, path, value) Files[path] = value; return true end,
        Delete = function(_, path) Files[path] = nil; return true end,
        List = function(_, path)
            local result = {}
            for name in pairs(Files) do if name:sub(1, #path) == path and not name:sub(#path + 1):find("/", 1, true) then table.insert(result, name) end end
            table.sort(result)
            return result
        end,
    }
end

function Storage.File()
    if not Capabilities.Detect().File then return nil, "File storage unavailable" end
    return {
        Name = "File", Persistent = true, Atomic = type(renamefile) == "function",
        Read = function(_, path)
            if not Capabilities.ValidPath(path) then return nil, "Invalid storage path" end
            local success, result = pcall(function() return isfile(path) and readfile(path) or nil end)
            if not success then return nil, tostring(result) end
            return result
        end,
        Write = function(_, path, value)
            if not Capabilities.ValidPath(path) then return false, "Invalid storage path" end
            return pcall(function()
                local folder = path:match("^(.*)/[^/]+$")
                if folder then assert(Capabilities.MakeFolder(folder)) end
                if isfile(path) then writefile(path .. ".bak", readfile(path)) end
                if type(renamefile) == "function" then
                    writefile(path .. ".tmp", value)
                    renamefile(path .. ".tmp", path)
                else
                    writefile(path, value)
                end
            end)
        end,
        Delete = function(_, path)
            if not Capabilities.ValidPath(path) then return false, "Invalid storage path" end
            if type(delfile) ~= "function" then return false, "File deletion unavailable" end
            return pcall(function() if isfile(path) then delfile(path) end end)
        end,
        List = function(_, path)
            if not Capabilities.ValidPath(path) then return {}, "Invalid storage path" end
            if type(listfiles) ~= "function" then return {}, "File listing unavailable" end
            local success, result = pcall(function() return isfolder(path) and listfiles(path) or {} end)
            return success and result or {}, not success and tostring(result) or nil
        end,
    }
end

function Storage.Resolve(adapter)
    if adapter then
        assert(type(adapter) == "table", "Storage must be an adapter table")
        for _, name in ipairs({ "Read", "Write", "Delete", "List" }) do assert(type(adapter[name]) == "function", "Storage missing " .. name) end
        return adapter
    end
    return Storage.File() or Storage.Memory()
end

return Storage
