local Performance = {}

function Performance.new(scope)
    local self = { Scope = scope, Samples = {}, Timings = {}, Quality = "Balanced", ReducedMotion = false, Adaptive = false, Elapsed = 0, Slow = 0, Fast = 0 }
    function self:Record(name, seconds)
        self.Timings[name] = seconds * 1000
    end
    function self:Sample(seconds)
        if seconds <= 0 or seconds > 1 then return end
        table.insert(self.Samples, seconds)
        if #self.Samples > 120 then table.remove(self.Samples, 1) end
        self.Elapsed += seconds
        if self.Elapsed < 2 then return end
        self.Elapsed = 0
        local total = 0
        for _, sample in ipairs(self.Samples) do total += sample end
        local average = total / #self.Samples
        self.Slow = average > 1 / 35 and self.Slow + 1 or 0
        self.Fast = average < 1 / 55 and self.Fast + 1 or 0
        if self.Adaptive and self.Slow >= 3 and self.Quality ~= "Off" then
            self.Quality = "Low"
            self.Slow = 0
        elseif self.Adaptive and self.Fast >= 6 and self.Quality == "Low" then
            self.Quality = "Balanced"
            self.Fast = 0
        end
    end
    function self:Snapshot()
        local result = scope:Stats()
        result.TimingsMilliseconds = table.clone(self.Timings)
        result.Quality = self.Quality
        result.SampleCount = #self.Samples
        local total = 0
        for _, value in ipairs(self.Samples) do total += value end
        result.HeartbeatMilliseconds = #self.Samples > 0 and total * 1000 / #self.Samples or nil
        return result
    end
    return self
end

return Performance
