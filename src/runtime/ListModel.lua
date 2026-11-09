local ListModel = {}

function ListModel.new(rows)
    local self = { Rows = rows or {}, Visible = {}, Selection = {}, Query = "", SortKey = nil, Descending = false }
    function self:Refresh()
        self.Visible = {}
        for index, row in ipairs(self.Rows) do
            local match = self.Query == ""
            for _, value in pairs(row) do
                if type(value) ~= "table" and tostring(value):lower():find(self.Query, 1, true) then match = true; break end
            end
            if match then table.insert(self.Visible, { Row = row, Index = index }) end
        end
        if self.SortKey then
            table.sort(self.Visible, function(a, b)
                local av, bv = a.Row[self.SortKey], b.Row[self.SortKey]
                if av == bv then return a.Index < b.Index end
                if type(av) ~= type(bv) or type(av) ~= "number" then av, bv = tostring(av), tostring(bv) end
                return self.Descending and av > bv or not self.Descending and av < bv
            end)
        end
    end
    function self:Filter(query) self.Query = tostring(query or ""):lower(); self:Refresh() end
    function self:Sort(key, descending) self.SortKey, self.Descending = key, descending == true; self:Refresh() end
    function self:Set(rows) self.Rows = rows; self.Selection = {}; self:Refresh() end
    function self:Range(offset, height, rowHeight)
        local first = math.max(1, math.floor(offset / rowHeight) + 1)
        return first, math.min(#self.Visible, first + math.ceil(height / rowHeight) + 1)
    end
    function self:Select(index, multi)
        if not self.Rows[index] then return false end
        local selected = self.Selection[index]
        if not multi then self.Selection = {} end
        self.Selection[index] = not selected or nil
        return self.Selection[index] == true
    end
    self:Refresh()
    return self
end

return ListModel
