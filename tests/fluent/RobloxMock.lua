local NativeTypeof = typeof
local function typeof(value) return type(value)=="table" and rawget(value,"_type") or NativeTypeof(value) end
local warnings={}
local function warn(...) table.insert(warnings, table.concat({...}," ")) end
local scheduled={}
local clock=0
local task={}
local function schedule(delay,callback,...)
    local thread=coroutine.create(callback)
    table.insert(scheduled,{Time=clock+delay,Thread=thread,Args=table.pack(...)})
    return thread
end
function task.spawn(callback,...) return schedule(0,callback,...) end
function task.defer(callback,...) return schedule(0,callback,...) end
function task.delay(delay,callback,...) return schedule(delay,callback,...) end
function task.wait(delay) return coroutine.yield(delay or 1/60) end
function task.cancel(thread) if coroutine.status(thread)~="dead" then coroutine.close(thread) end end
local function advance(seconds)
    local stop=clock+seconds
    local steps=0
    while true do
        table.sort(scheduled,function(a,b)return a.Time<b.Time end)
        local event=scheduled[1]
        if not event or event.Time>stop then break end
        table.remove(scheduled,1)
        clock=event.Time
        if coroutine.status(event.Thread)~="dead" then
            local ok,delay=coroutine.resume(event.Thread,table.unpack(event.Args,1,event.Args.n))
            assert(ok,tostring(delay))
            if coroutine.status(event.Thread)~="dead" then table.insert(scheduled,{Time=clock+(delay or 1/60),Thread=event.Thread,Args={n=0}}) end
        end
        steps+=1
        assert(steps<20000,"Scheduler runaway")
    end
    clock=stop
end
local function signal()
    local self={Connections={}}
    function self:Connect(callback)
        local conn={Connected=true,Callback=callback,_type="RBXScriptConnection"}
        function conn:Disconnect()self.Connected=false end
        table.insert(self.Connections,conn)
        return conn
    end
    function self:Once(callback)
        local conn
        conn=self:Connect(function(...)conn:Disconnect();callback(...)end)
        return conn
    end
    function self:Fire(...)
        for _,conn in ipairs(table.clone(self.Connections))do if conn.Connected then conn.Callback(...)end end
    end
    function self:Wait() return task.wait() end
    return self
end
local Enum=setmetatable({},{__index=function(self,key)
    local enum=setmetatable({},{__index=function(tbl,name)
        local value=setmetatable({Name=name,Value=0,EnumType=key,_type="EnumItem"},{__tostring=function()return "Enum."..key.."."..name end})
        rawset(tbl,name,value);return value
    end})
    rawset(self,key,enum);return enum
end})
local Vector2={}
local Vector3={}
local function vector(x,y,z)
    local value={X=x or 0,Y=y or 0,Z=z,_type=z==nil and "Vector2" or "Vector3"}
    return setmetatable(value,{
        __add=function(a,b)return vector(a.X+b.X,a.Y+b.Y,a.Z and a.Z+b.Z)end,
        __sub=function(a,b)return vector(a.X-b.X,a.Y-b.Y,a.Z and a.Z-b.Z)end,
        __mul=function(a,b)if type(a)=="number"then a,b=b,a end;return vector(a.X*b,a.Y*b,a.Z and a.Z*b)end,
        __div=function(a,b)return vector(a.X/b,a.Y/b,a.Z and a.Z/b)end,
        __index=function(a,k)if k=="Magnitude"then return math.sqrt(a.X*a.X+a.Y*a.Y+(a.Z or 0)^2)end end,
        __eq=function(a,b)return a.X==b.X and a.Y==b.Y and a.Z==b.Z end,
    })
end
function Vector2.new(x,y)return vector(x,y)end
function Vector3.new(x,y,z)return vector(x,y,z or 0)end
Vector2.zero=Vector2.new();Vector3.zero=Vector3.new()
local UDim={new=function(scale,offset)return {Scale=scale or 0,Offset=offset or 0,_type="UDim"}end}
local UDim2={}
function UDim2.new(x,xo,y,yo)
    if type(x)=="table"then return {X=x,Y=xo,_type="UDim2"}end
    return {X=UDim.new(x,xo),Y=UDim.new(y,yo),_type="UDim2"}
end
function UDim2.fromScale(x,y)return UDim2.new(x,0,y,0)end
function UDim2.fromOffset(x,y)return UDim2.new(0,x,0,y)end
local Color3={}
function Color3.new(r,g,b)
    return setmetatable({R=r or 0,G=g or 0,B=b or 0,_type="Color3"},{__index=Color3})
end
function Color3.fromRGB(r,g,b)return Color3.new(r/255,g/255,b/255)end
function Color3.fromHex(value)
    value=value:gsub("#","")
    assert(value:match("^%x%x%x%x%x%x$"),"Invalid hex color")
    return Color3.fromRGB(tonumber(value:sub(1,2),16),tonumber(value:sub(3,4),16),tonumber(value:sub(5,6),16))
end
function Color3:ToHex()return string.format("%02x%02x%02x",math.floor(self.R*255+0.5),math.floor(self.G*255+0.5),math.floor(self.B*255+0.5))end
function Color3.fromHSV(h,s,v)
    local i=math.floor(h*6);local f=h*6-i;local p=v*(1-s);local q=v*(1-f*s);local t=v*(1-(1-f)*s)
    local c=({{v,t,p},{q,v,p},{p,v,t},{p,q,v},{t,p,v},{v,p,q}})[i%6+1]
    return Color3.new(table.unpack(c))
end
function Color3:ToHSV()
    local max,min=math.max(self.R,self.G,self.B),math.min(self.R,self.G,self.B)
    local d=max-min;local h=0
    if d>0 then if max==self.R then h=(self.G-self.B)/d%6 elseif max==self.G then h=(self.B-self.R)/d+2 else h=(self.R-self.G)/d+4 end end
    return h/6,max==0 and 0 or d/max,max
end
Color3.toHSV=Color3.ToHSV
function Color3:Lerp(other,t)return Color3.new(self.R+(other.R-self.R)*t,self.G+(other.G-self.G)*t,self.B+(other.B-self.B)*t)end
local Font={new=function(family,weight,style)return {Family=family,Weight=weight or Enum.FontWeight.Regular,Style=style or Enum.FontStyle.Normal,_type="Font"}end}
local Rect={new=function(a,b,c,d)return {Min=type(a)=="table"and a or Vector2.new(a,b),Max=type(b)=="table"and b or Vector2.new(c,d),_type="Rect"}end}
local ColorSequenceKeypoint={new=function(time,value)return {Time=time,Value=value}end}
local NumberSequenceKeypoint={new=function(time,value)return {Time=time,Value=value}end}
local ColorSequence={new=function(value)return {Keypoints=typeof(value)=="Color3"and {{Time=0,Value=value},{Time=1,Value=value}}or value,_type="ColorSequence"}end}
local NumberSequence={new=function(value)return {Keypoints=type(value)=="number"and {{Time=0,Value=value},{Time=1,Value=value}}or value,_type="NumberSequence"}end}
local TweenInfo={new=function(time,...)return {Time=time}end}
local MockViewport=Vector2.new(1280,800)
local Instance={}
local methods={}
local signals={Destroying=true,ChildAdded=true,ChildRemoved=true,Changed=true,InputBegan=true,InputChanged=true,InputEnded=true,MouseEnter=true,MouseLeave=true,MouseMoved=true,MouseButton1Click=true,MouseButton1Down=true,MouseButton1Up=true,Activated=true,SelectionGained=true,SelectionLost=true,FocusLost=true,Focused=true,Completed=true,Event=true}
function methods:IsA(class)
    if self.ClassName==class or class=="Instance"then return true end
    if class=="GuiObject"then return table.find({"Frame","TextLabel","TextButton","TextBox","ImageLabel","ImageButton","ScrollingFrame","CanvasGroup","ViewportFrame","VideoFrame"},self.ClassName)~=nil end
    if class=="GuiButton"then return self.ClassName=="TextButton"or self.ClassName=="ImageButton"end
    if class=="LayerCollector"then return self.ClassName=="ScreenGui"end
    return false
end
function methods:GetChildren()return table.clone(self._children)end
function methods:GetDescendants()
    local result={}
    for _,child in ipairs(self._children)do table.insert(result,child);for _,desc in ipairs(child:GetDescendants())do table.insert(result,desc)end end
    return result
end
function methods:FindFirstChild(name,recursive)
    for _,child in ipairs(self._children)do if child.Name==name then return child end end
    if recursive then for _,child in ipairs(self._children)do local result=child:FindFirstChild(name,true);if result then return result end end end
end
function methods:FindFirstAncestorWhichIsA(class)local parent=self.Parent;while parent do if parent:IsA(class)then return parent end;parent=parent.Parent end end
function methods:FindFirstChildOfClass(class)for _,child in ipairs(self._children)do if child.ClassName==class then return child end end end
function methods:FindFirstChildWhichIsA(class)return self:FindFirstChildOfClass(class)end
function methods:WaitForChild(name)return assert(self:FindFirstChild(name),"Missing child "..name.." in "..self.Name)end
function methods:GetPropertyChangedSignal(name)self._signals[name]=self._signals[name]or signal();return self._signals[name]end
function methods:SetAttribute(name,value)self._attributes[name]=value end
function methods:GetAttribute(name)return self._attributes[name]end
function methods:IsDescendantOf(parent)local cur=self.Parent;while cur do if cur==parent then return true end;cur=cur.Parent end;return false end
function methods:Destroy()
    if self._destroyed then return end
    self._destroyed=true
    self.Destroying:Fire()
    for _,child in ipairs(self:GetChildren())do child:Destroy()end
    self.Parent=nil
    for _,event in pairs(self._signals)do for _,conn in ipairs(event.Connections)do conn:Disconnect()end end
end
function methods:CaptureFocus()self.Focused:Fire()end
function methods:ReleaseFocus()self.FocusLost:Fire(false)end
function methods:Clone()
    local copy=Instance.new(self.ClassName)
    for k,v in pairs(self._properties)do if k~="Parent"then copy[k]=v end end
    for _,child in ipairs(self:GetChildren())do child:Clone().Parent=copy end
    return copy
end
function methods:GetFullName()return self.Name end
function methods:ClearAllChildren()for _,child in ipairs(self:GetChildren())do child:Destroy()end end
function methods:Play()self.Playing=true end
function methods:Pause()self.Playing=false end
function methods:Stop()self.Playing=false end
function Instance.new(class)
    local self={_type="Instance",_children={},_signals={},_attributes={},_properties={ClassName=class,Name=class,Size=UDim2.fromOffset(100,40),Position=UDim2.new(),AnchorPoint=Vector2.new(),CanvasPosition=Vector2.new(),BackgroundTransparency=0,ImageTransparency=0,TextTransparency=0,Text="",TextSize=14,FontFace=Font.new("default"),Visible=true,LayoutOrder=0,PaddingTop=UDim.new(),PaddingLeft=UDim.new(),PaddingRight=UDim.new(),PaddingBottom=UDim.new(),CornerRadius=UDim.new(),Rotation=0,Enabled=true,ViewportSize=Vector2.new(1280,800),AbsoluteContentSize=Vector2.new(100,40)}}
    return setmetatable(self,{
        __index=function(obj,key)
            if methods[key]then return methods[key]end
            if signals[key]then obj._signals[key]=obj._signals[key]or signal();return obj._signals[key]end
            if key=="AbsoluteSize"then
                if obj.ClassName=="ScreenGui"then return MockViewport end
                local parent=obj.Parent;local size=parent and parent:IsA("GuiObject")and parent.AbsoluteSize or Vector2.new(1280,800)
                return Vector2.new(math.max(1,obj.Size.X.Scale*size.X+obj.Size.X.Offset),math.max(1,obj.Size.Y.Scale*size.Y+obj.Size.Y.Offset))
            end
            if key=="AbsolutePosition"then return Vector2.new(100,100)end
            if key=="TextBounds"then return Vector2.new(#obj.Text*7,18)end
            local child=methods.FindFirstChild(obj,key)
            if child then return child end
            return obj._properties[key]
        end,
        __newindex=function(obj,key,value)
            if key:sub(1,1)=="_"then rawset(obj,key,value);return end
            if key:find("Transparency")and value~=nil then assert(type(value)=="number" or obj.ClassName=="UIGradient" and typeof(value)=="NumberSequence",obj.ClassName.."."..key.." invalid transparency "..tostring(value))end
            if key=="Parent"then
                local old=obj._properties.Parent
                if old==value then return end
                if old then local index=table.find(old._children,obj);if index then table.remove(old._children,index)end;old.ChildRemoved:Fire(obj)end
                obj._properties.Parent=value
                if value then table.insert(value._children,obj);value.ChildAdded:Fire(obj)end
            else
                obj._properties[key]=value
            end
        end,
    })
end
local services={}
local game={}
function game:GetService(name)
    if not services[name]then services[name]=Instance.new(name)end
    return services[name]
end
local workspace=game:GetService("Workspace")
workspace.CurrentCamera=Instance.new("Camera")
local run=game:GetService("RunService")
run.IsStudio=function()return true end
run.IsClient=function()return true end
run.Heartbeat=signal();run.RenderStepped=signal()
local input=game:GetService("UserInputService")
input.TouchEnabled=false;input.KeyboardEnabled=true;input.MouseEnabled=true;input.GamepadEnabled=false
input.TouchPinch=signal()
input.GetFocusedTextBox=function()return nil end
input.IsKeyDown=function()return false end
input.GetMouseLocation=function()return Vector2.new(200,200)end
input.GetLastInputType=function()return Enum.UserInputType.MouseMovement end
local player=Instance.new("Player")
player.UserId=1;player.Name="Test";player.DisplayName="Test"
Instance.new("PlayerGui").Parent=player
player.GetMouse=function()return {Move=signal(),X=200,Y=200}end
game:GetService("Players").LocalPlayer=player
game:GetService("Players").GetUserThumbnailAsync=function()return "rbxassetid://0",true end
local localization=game:GetService("LocalizationService")
localization.SystemLocaleId="en-us"
local tweenService=game:GetService("TweenService")
tweenService.Create=function(_,object,info,properties)
    local tween={Completed=signal(),PlaybackState=Enum.PlaybackState.Begin,_type="Instance"}
    function tween:Play()for key,value in pairs(properties)do object[key]=value end;self.PlaybackState=Enum.PlaybackState.Completed;self.Completed:Fire(Enum.PlaybackState.Completed)end
    function tween:Cancel()self.Completed:Fire(Enum.PlaybackState.Cancelled)end
    function tween:Destroy()end
    return tween
end
local http=game:GetService("HttpService")
local serial=0
http.GenerateGUID=function()serial+=1;return "guid-"..serial end
local JSONStore={}
http.JSONEncode=function(_,value)
    serial+=1
    local token="json:"..serial
    local function copy(data)if type(data)~="table"then return data end;local out={};for k,v in pairs(data)do out[k]=copy(v)end;return out end
    JSONStore[token]=copy(value)
    return token
end
http.JSONDecode=function(_,value)
    if value:find('"name": "windui"',1,true)then return {version="1.6.66"}end
    assert(JSONStore[value],"Mock JSON decode failure")
    return JSONStore[value]
end
local loadstring=loadstring
