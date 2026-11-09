local Scope = {}
Scope.__index = Scope
Scope.Current = setmetatable({}, { __mode = "k" })
Scope.Owners = setmetatable({}, { __mode = "k" })
Scope.Live = setmetatable({}, { __mode = "k" })

function Scope.new(parent, context)
    local self = setmetatable({ Parent = parent, Context = context or (parent and parent.Context), Resources = {}, Children = {}, Destroyed = false }, Scope)
    Scope.Live[self] = true
    if parent then
        assert(not parent.Destroyed, "Cannot create resources in a destroyed scope")
        parent.Children[self] = true
    end
    return self
end

function Scope.Get()
    return Scope.Current[coroutine.running()]
end

function Scope:Run(callback, ...)
    if self.Destroyed then return nil end
    local thread = coroutine.running()
    local previous = Scope.Current[thread]
    Scope.Current[thread] = self
    local result = table.pack(pcall(callback, ...))
    Scope.Current[thread] = previous
    if not result[1] then error(result[2], 0) end
    return table.unpack(result, 2, result.n)
end

function Scope:Give(resource, cleanup, kind)
    if self.Destroyed then
        cleanup(resource)
        return resource
    end
    self.Resources[resource] = { Cleanup = cleanup, Kind = kind or "Other" }
    return resource
end

function Scope:Forget(resource)
    self.Resources[resource] = nil
end

function Scope:Connect(signal, callback)
    local connection = signal:Connect(function(...)
        if not self.Destroyed then return self:Run(callback, ...) end
    end)
    return self:Give(connection, function(value) value:Disconnect() end, "Connections")
end

function Scope:Bind(object)
    for name, callback in pairs(object) do
        if type(callback) == "function" then
            object[name] = function(...)
                return self:Run(callback, ...)
            end
        end
    end
    return object
end

function Scope:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    if self.Parent then self.Parent.Children[self] = nil end
    local children = {}
    for child in pairs(self.Children) do table.insert(children, child) end
    for _, child in ipairs(children) do child:Destroy() end
    for resource, entry in pairs(self.Resources) do
        self.Resources[resource] = nil
        local success, message = pcall(entry.Cleanup, resource)
        if not success then warn("[WindUI cleanup] " .. tostring(message)) end
    end
    Scope.Live[self] = nil
end

function Scope:Stats()
    local result = { Scopes = 1, Instances = 0, Connections = 0, Tweens = 0, Tasks = 0, Other = 0 }
    for resource, entry in pairs(self.Resources) do
        if entry.Kind ~= "Connections" or resource.Connected then
            result[entry.Kind] = (result[entry.Kind] or 0) + 1
        end
    end
    for child in pairs(self.Children) do
        for key, value in pairs(child:Stats()) do result[key] = (result[key] or 0) + value end
    end
    return result
end

return Scope
