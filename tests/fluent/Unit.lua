local Scope = require("../../src/runtime/Scope")
local Calendar = require("../../src/runtime/Calendar")
local ListModel = require("../../src/runtime/ListModel")
local Navigation = require("../../src/runtime/Navigation")
local Schema = require("../../src/runtime/Schema")
local Tokens = require("../../src/runtime/Tokens")
local Performance = require("../../src/runtime/Performance")
local passed = 0
local function test(name, callback)
    local success, message = pcall(callback)
    assert(success, name .. ": " .. tostring(message))
    passed += 1
    print("PASS " .. name)
end

test("scopes isolate ownership and recursively clean once", function()
    local root, count = Scope.new(), 0
    local a, b = Scope.new(root), Scope.new(root)
    a:Give({}, function() count += 1 end)
    b:Give({}, function() count += 10 end)
    a:Destroy(); a:Destroy()
    assert(count == 1 and not b.Destroyed)
    root:Destroy()
    assert(count == 11 and b.Destroyed)
end)
test("scope restores context after exceptions and nested calls", function()
    local a, b = Scope.new(), Scope.new()
    a:Run(function()
        assert(Scope.Get() == a)
        assert(not pcall(function() b:Run(function() error("expected") end) end))
        assert(Scope.Get() == a)
    end)
    assert(Scope.Get() == nil)
    a:Destroy(); b:Destroy()
end)
test("resource cleanup continues after a disconnected sibling", function()
    local root, n = Scope.new(), 0
    for index = 1, 25 do root:Give(index, function() n += 1 end, "Other") end
    root:Destroy()
    assert(n == 25)
end)
test("calendar leap century and valid boundaries", function()
    assert(Calendar.Leap(2000) and not Calendar.Leap(1900) and Calendar.Leap(2024))
    assert(Calendar.Valid({Year=2024,Month=2,Day=29}))
    assert(not Calendar.Valid({Year=2025,Month=2,Day=29}))
    assert(not Calendar.Valid({Year=2025,Month=13,Day=1}))
    assert(Calendar.Weekday(2026,11,8) == 0)
    assert(Calendar.Time({Hour=23,Minute=59}) and not Calendar.Time({Hour=24,Minute=0}))
end)
test("table filtering sorting selection and virtual range", function()
    local rows = {}
    for index=1,1000 do rows[index] = {ID=index,Name="Row "..index,Score=1001-index} end
    local model = ListModel.new(rows)
    model:Sort("Score", false)
    assert(model.Visible[1].Index == 1000)
    model:Filter("Row 10")
    assert(#model.Visible == 12)
    model:Select(10,true); model:Select(11,true); model:Select(10,true)
    assert(not model.Selection[10] and model.Selection[11])
    model:Filter("")
    local a,b=model:Range(3600,360,36)
    assert(a==101 and b==112)
    model:Set({{ID=1}})
    assert(#model.Visible==1 and next(model.Selection)==nil)
end)
test("history branches after back and respects locked routes", function()
    local window={TabModule={Tabs={{},{},{},{Locked=true}}}}
    local navigation=Navigation.new(window)
    function window:SelectTab(route) navigation:Push(route) end
    navigation:Go(1); navigation:Go(2); navigation:Go(3)
    assert(navigation:Back() and navigation.Selected==2)
    assert(navigation:Forward() and navigation.Selected==3)
    navigation:Back(); navigation:Go(1)
    assert(not navigation:Forward() and #navigation.History==3)
    assert(not navigation:Go(4) and not navigation:Go(99))
end)
test("search reflects renamed objects and removes destroyed items", function()
    local navigation=Navigation.new({})
    local item={Title="Alpha",Desc="setting"}
    navigation:Register(item,{Object=item,Route=1,Kind="Element"})
    assert(#navigation:Search("alpha")==1)
    item.Title="Beta"
    assert(#navigation:Search("alpha")==0 and #navigation:Search("beta")==1)
    navigation:Remove(item)
    assert(#navigation:Search("")==0)
end)
test("commands only execute registered callbacks", function()
    local navigation=Navigation.new({})
    local count=0
    assert(not navigation:RunCommand("remote-url"))
    assert(navigation:RegisterCommand({ID="test",Callback=function()count+=1 end}))
    assert(not navigation:RegisterCommand({ID="test",Callback=function()end}))
    assert(navigation:RunCommand("test") and count==1)
end)
test("configuration migrates legacy values and rejects corrupt schemas", function()
    local migrated=Schema.Config({toggle={__type="Toggle",value=true}})
    assert(migrated.__version==1.2 and migrated.__elements.toggle.value)
    assert(not Schema.Config({__version=99,__elements={}}))
    assert(not Schema.Config({__version=1.2,__elements={bad={__type="Toggle",value="yes"}}}))
    assert(not Schema.Config({__version=1.2,__elements={bad={__type="Slider",value=0/0}}}))
    assert(not Schema.Name("../escape") and Schema.Name("Profile A"))
end)
test("tokens separate styles modes accent and copy nested data", function()
    local glass=Tokens.Resolve("Glass","Dark","#ff8800")
    local classic=Tokens.Resolve("Classic","Light")
    assert(glass.Color.Accent=="#ff8800" and glass.Opacity.Surface>0)
    assert(classic.Opacity.Surface==0 and classic.Color.Text~=glass.Color.Text)
    glass.Radius.Control=99
    assert(Tokens.Resolve("Glass","Dark").Radius.Control~=99)
end)
test("adaptive performance applies hysteresis", function()
    local scope=Scope.new()
    local performance=Performance.new(scope)
    performance.Adaptive=true
    for _=1,210 do performance:Sample(1/30) end
    assert(performance.Quality=="Low")
    for _=1,100 do performance:Sample(1/60) end
    assert(performance.Quality=="Low")
    for _=1,1000 do performance:Sample(1/60) end
    assert(performance.Quality=="Balanced")
    performance.Quality="Off"
    for _=1,300 do performance:Sample(1/20) end
    assert(performance.Quality=="Off")
    scope:Destroy()
end)
print("UNIT PASS "..passed)
for _, count in ipairs({50,200,500,1000}) do
    local samples={}
    for iteration=1,30 do
        local rows={}
        for index=1,count do rows[index]={ID=index,Text="row "..index} end
        local start=os.clock()
        local model=ListModel.new(rows)
        model:Sort("ID",true);model:Filter("row 1");model:Range(0,360,36)
        samples[iteration]=(os.clock()-start)*1000
    end
    table.sort(samples)
    print(string.format("MODEL BENCH rows=%d median_ms=%.4f worst_ms=%.4f",count,samples[15],samples[30]))
end
