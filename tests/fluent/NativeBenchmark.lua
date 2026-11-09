return function(WindUI,Count,Kind)
    assert(table.find({50,200,500,1000},Count),"Use a specified benchmark size")
    Kind=Kind or "Toggle"
    local RunService=game:GetService("RunService")
    local samples={}
    local started=os.clock()
    local Window=WindUI:CreateWindow({Title="WindUI benchmark",Size=UDim2.fromOffset(580,460)})
    local Tab=Window:Tab({Title="Benchmark"})
    local controls={}
    if Kind=="DataTable"then
        local rows={}
        for index=1,Count do rows[index]={ID=index,Title="Row "..index}end
        controls[1]=Tab:DataTable({Columns={"ID","Title"},Rows=rows})
    else
        for index=1,Count do controls[index]=Tab:Toggle({Title="Toggle "..index,Value=false,Callback=function()end})end
    end
    local creation=(os.clock()-started)*1000
    for index=1,120 do samples[index]=RunService.Heartbeat:Wait()*1000 end
    table.sort(samples)
    local result={Count=Count,Kind=Kind,CreateMilliseconds=creation,MedianHeartbeatMilliseconds=samples[60],WorstHeartbeatMilliseconds=samples[120],Descendants=#Window.UIElements.Main:GetDescendants(),Diagnostics=Window.GetDiagnostics and Window:GetDiagnostics()or nil}
    if Kind=="DataTable"then result.PooledRows=#controls[1].List.Pool end
    print(game:GetService("HttpService"):JSONEncode(result))
    Window:Destroy()
    return result
end
