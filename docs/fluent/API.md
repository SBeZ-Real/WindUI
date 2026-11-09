# API bổ sung và tương thích

## Khởi tạo

Trong project Studio gallery:

```lua
local WindUI = require(game:GetService("ReplicatedStorage"):WaitForChild("WindUI"))
local Window = WindUI:CreateWindow({
    ID = "Settings",
    Title = "Settings",
    Style = "Premium",
    Mode = "Dark",
    Accent = "#60cdff",
    Layout = "Adaptive",
    Effects = "Balanced",
    ReducedMotion = false,
    AdaptiveQuality = true,
    Folder = "MyScript",
})
local Tab = Window:Tab({Title = "General", Icon = "settings"})
Tab:Toggle({Title = "Enabled", Flag = "enabled", Value = true, Callback = function(value) print(value) end})
```

`ID` nên ổn định giữa các lần chạy để khôi phục cùng workspace/config. ID, tên profile/preset/config chỉ nhận chữ, số, dấu cách, `_` và `-`. Không truyền ID thì thư viện tự cấp Window1, Window2… trong phiên. Cửa sổ đầu tiên không có ID giữ đường dẫn cấu hình cũ; ID tường minh và các cửa sổ tiếp theo có namespace riêng.

Không truyền `Style` thì dùng theme và thiết kế mặc định cũ. `WindUI.Window` vẫn là đối tượng Window: cửa sổ được tạo gần nhất còn sống, hoặc cửa sổ còn lại có focus gần nhất khi nó bị hủy. Nó không trở thành dictionary. Dùng `WindUI:GetWindow(id)` hoặc `WindUI:GetWindows()` để tra registry.

KeySystem vẫn kiểm tra khóa bằng logic cũ. Khi người dùng bấm Exit ở màn hình khóa, `CreateWindow` trả `nil, "Window creation cancelled"`; lời gọi không còn chờ vô hạn. Luồng khóa hợp lệ vẫn trả Window.

## Window và layout

| API | Hành vi |
|---|---|
| `Window:Focus()` | Đưa cửa sổ lên trước các cửa sổ WindUI khác |
| `Window:Hide()` | Ẩn, giữ state, ẩn nút khôi phục; mở lại bằng API |
| `Window:Minimize()` | Ẩn và hiện nút khôi phục |
| `Window:Close()` | Giữ cửa sổ và state; giá trị trả về vẫn hỗ trợ `:Destroy()` |
| `Window:Destroy()` | Hủy đúng cửa sổ, popup, cấu hình autosave và tài nguyên của nó |
| `Window:Restore()` | Khôi phục hình học đã lưu trước snap/fullscreen và mở cửa sổ |
| `Window:Maximize()` / `:Fullscreen()` | Phóng cửa sổ trong GUI Roblox |
| `Window:ToggleFullscreen()` | API cũ được phối hợp với Restore |
| `Window:Snap(preset)` | Left, Right, Center, TopLeft, TopRight, BottomLeft, BottomRight |
| `Window:SetLayout(layout)` | Settings, Compact, Adaptive; giữ object và giá trị control |
| `Window:FitViewport()` | Đưa hình học về vùng hiển thị; Adaptive giới hạn kích thước |
| `WindUI:Destroy()` | Hủy tất cả owner rồi hủy root; nạp lại thư viện để sử dụng tiếp |

Settings giữ sidebar đầy đủ. Compact thu sidebar còn 64 đơn vị, có tooltip tên tab và tên viết ngắn khi không có icon. Adaptive chuyển sang Compact khi vùng khả dụng nhỏ hơn 640 đơn vị. Với style mới, menu Navigation trên topbar cung cấp Back/Forward, search, notification center và các preset Snap cho touch.

Các API cũ `SetSize`, `SetUIScale`, `SetTitle`, `SetAuthor`, `Toggle`, `EditOpenButton` và phần tử Set/Update/Lock/Unlock vẫn tồn tại. UIScale phải là số hữu hạn dương. Không hỗ trợ cửa sổ hệ điều hành hoặc native Mica của Windows.

## Theme, effects và Theme Studio

| API | Đầu vào |
|---|---|
| `Window:SetStyle(style)` | Classic, Premium, Glass |
| `Window:SetMode(mode)` | Dark, Light |
| `Window:SetAccent(color)` | `#RRGGBB` hoặc Color3 |
| `Window:SetTokens(overrides)` | Override phân tầng; từ chối token lạ, sai kiểu, màu sai hoặc số ngoài giới hạn |
| `Window:SetTheme(name)` | Theme cũ trong `WindUI.Themes`, riêng cửa sổ |
| `Window:ExportTheme()` / `:ImportTheme(json)` | JSON theme; import lỗi trả `false, reason` |
| `Window:RollbackTheme()` | Khôi phục checkpoint trước import hoặc Theme Studio |
| `Window:SaveThemePreset(name)` / `:LoadThemePreset(name)` | Dùng storage adapter của cửa sổ |
| `Window:ThemeStudio()` | Tạo tab chỉnh style, mode, accent, effects, reduced motion, adaptive quality, JSON và preset |
| `Window:SetEffects(level)` | Off, Low, Balanced, High |
| `Window:SetReducedMotion(value)` | Tắt motion độc lập chất lượng |
| `Window:SetAdaptiveQuality(value)` | Bật/tắt đo Heartbeat và điều chỉnh Low/Balanced có hysteresis |
| `Window:SetAdaptiveTheme(resolver)` | Resolver của ứng dụng; `false` để tắt |

Window không có theme/style riêng tiếp tục theo `WindUI:SetTheme(name)`. Window có `Theme`, style riêng hoặc theme import giữ lựa chọn riêng. `WindUI:GetThemes()` và `GetCurrentTheme()` tiếp tục nói về theme toàn cục.

Token groups: Color, Typography, Radius, Spacing, Elevation, Opacity, Motion, Density, InteractionState. Font là asset Font Roblox. Ví dụ override:

```lua
Window:SetTokens({Color = {Text = "#f5f5f5"}, Radius = {Window = 16, Control = 8}, Typography = {Body = 15}})
Window:SetAdaptiveTheme(function(capabilities, viewport)
    return {Style = viewport.X < 640 and "Classic" or "Premium", Mode = capabilities.Touch and "Light" or "Dark"}
end)
```

Resolver chạy khi bật, khi LastInputTypeChanged và khi viewport đổi; ứng dụng có thể gọi lại khi preference của mình đổi. Đây không phải dò theme của hệ điều hành. Resolver không được lưu vào JSON; ứng dụng đăng ký lại sau khi nạp.

Off áp trạng thái ngay; Low rút ngắn tween và giảm shadow; Balanced dùng motion thông thường; High tăng shadow. ReducedMotion dừng tween, indeterminate progress vẫn có dấu trạng thái tĩnh và tiếp tục chuyển động khi bật lại. Glass mặc định là bề mặt translucent trong native GUI. Acrylic hậu kỳ chỉ bật khi đặt `Acrylic = true`, có owner và cleanup; Low/Off/ReducedMotion tắt hiệu ứng đó.

## Component

Tất cả component mới được tạo từ `Tab`, Group/HStack/VStack bằng registry hiện có. Component tương tác có `SetState`, `SetDisabled`, `SetLoading`; các state hợp lệ là idle, hover, pressed, focused, disabled, loading, invalid. `Input` nhận `Validator(value)` trả boolean và thông báo; giá trị không hợp lệ không thay thế giá trị hiện tại.

| Component | Config chính | API/Callback |
|---|---|---|
| DataTable | Columns: chuỗi hoặc `{Key, Title}`; Rows: array các object; Multi, Height, RowHeight, Flag | Set(rows), Filter(query), Sort(key, descending), Select(index), GetSelection(), GetState(), ApplyState(state); callback(row, originalIndex, selectionMap) |
| TreeView | Nodes: `{ID, Title, Children}`; Height, Flag | Set(nodes), Expand(id, expanded), Select(id), GetState(), ApplyState(state); callback(node, id) khi bấm hàng |
| Breadcrumb | Items: chuỗi hoặc `{Title}` | Set(items); callback(item, index) |
| ContextMenu | Items: `{Title, Callback, Disabled}` | Open(position); vị trí tính trong viewport của popup |
| DatePicker | Value: `{Year, Month, Day}`; Min, Max, Flag | Set(value), Open(); callback(value); năm 1900–9999, kiểm ngày nhuận và giới hạn |
| TimePicker | Value: `{Hour, Minute}`; Flag | Set(value), Open(); hai cột cuộn giờ/phút; callback(value) |
| CommandPalette | Title | Open(query) |
| SearchBox | Title, Value, Height, Flag | Kế thừa Input:Set, kết quả đến từ index của Window |

DataTable dùng row pool theo vùng nhìn thấy; sort/filter giữ chỉ số hàng gốc. Selection map có key là chỉ số hàng; GetState chuyển thành array để JSON không mất selection. TreeView dùng row pool và chỉ duyệt nhánh mở; giới hạn sâu 63, từ chối vòng lặp khi duyệt. Dùng ID chuỗi duy nhất cho node cần lưu state.

Dropdown cũ giữ search và multi-select; Slider giữ nhập số; Colorpicker giữ Update/Set. Virtualization áp dụng DataTable/TreeView, command/search/notification list và TimePicker; Dropdown cũ vẫn tạo các option truyền vào, nên tránh dùng nó làm bảng hàng nghìn mục.

`WindUI:RegisterComponent(name, factory)` đăng ký factory trả module có `New(Config)`, trả `typeName, content`. Đăng ký trước khi tạo container cần dùng component. Tên đã có không bị ghi đè. Không tự tải extension từ URL. `content` có thể cung cấp Destroy; registry gắn Scope, state, index và cleanup.

## Navigation

`Back`, `Forward`, `Search(query)`, `ActivateSearchResult(entry)` dùng route/tab và history riêng từng Window. Kết quả search cập nhật từ Title/Desc hiện tại, xóa khi component bị hủy. `RegisterCommand({ID, Title, Callback, Enabled})` chỉ nhận callback do ứng dụng đăng ký; `UnregisterCommand(id)` loại bỏ command. Ctrl+K hoặc ButtonY mở palette; Alt+Left/Right lùi/tiến. Shortcut bỏ qua TextBox đang focus, input đã được xử lý và cửa sổ không có focus. Menu topbar cung cấp thao tác tương đương bằng chuột/touch.

Breadcrumb nhận Items và Callback để ứng dụng ánh xạ các cấp nội dung tới route mong muốn; nó không suy đoán cấu trúc đường dẫn từ tên tab.

## Notification và Dialog

```lua
local notification = WindUI:Notify({
    Window = Window,
    Title = "Import",
    Content = "Processing",
    Progress = 0,
    DedupeKey = "import",
    Actions = {{Title = "Cancel", Callback = function(item) item:Close("cancelled") end}},
})
notification:SetProgress(0.5)
notification:Update({Title = "Completed", Progress = 1})
Window:NotificationCenter()
Window:Dialog({Title = "Continue?", Content = "Choose an action", Buttons = {{Title = "Continue", Result = "accepted"}}, OnResult = function(result) print(result) end})
```

Notify giữ `Buttons`, `Duration`, `CanClose`, `Icon`, `IconThemed`, `Background` và giá trị trả về có Close. `Actions` là alias mới. `Duration = false`, `Persistent = true` hoặc Progress tạo toast không tự hết hạn. Update nhận Title/Content/Progress. `OnClose(reason)` được gọi khi đóng. DedupeKey/Group được phân vùng theo Window; title có số lần gộp. Giới hạn mặc định: tối đa 3 toast hiển thị, tự giảm theo viewport, 50 chờ, 100 lịch sử. Burst quá giới hạn được ghi rate-limited, không tạo GUI vô hạn.

`Window:SaveNotificationHistory(name)` / `LoadNotificationHistory(name)` dùng adapter. `WindUI:Popup(config)` cũ có scope riêng và thêm `Popup:Close()`. Notification center hiển thị thông báo chung và thông báo của Window; Clear this window chỉ xóa owner hiện tại. Lịch sử lưu không giữ callback/action closure. Dialog phối hợp popup, Escape/ButtonB, kết quả khi đóng/hủy; nhiều cửa sổ không cùng chiếm một popup.

## Configuration

```lua
local Config = Window.ConfigManager:CreateConfig("Default")
Config:StartAutoSave(0.5)
Config:Set("custom", {Enabled = true})
local data, metadata = Config:Save()
if data == false then warn(metadata) else print(metadata.Storage, metadata.Persistent, metadata.Atomic) end
local json = Config:Export()
local result, reason = Config:Import(json)
if result == false then warn(reason) end
```

`CreateConfig`, `Config`, `SetAsCurrent`, `Register`, `Set`, `Get`, `SetAutoLoad`, `GetData`, `Save`, `Load`, `Delete`, `GetConfig`, `DeleteConfig`, `AllConfigs` và `GetAutoLoadConfigs` được giữ. API mới: Export, Import, RecoverBackup, StartAutoSave, StopAutoSave, MarkDirty; ConfigManager:SetProfile, SavePreset, LoadPreset; Window:SaveWorkspace, LoadWorkspace.

SetProfile chuyển namespace và dừng autosave config cũ; tạo/nạp config tương ứng sau khi chuyển. Workspace lưu hình học Window, layout, tab và theme. Giá trị component được lưu trong config, không tự gộp vào workspace.

Memory là mặc định khi thiếu file API: Persistent=false, chỉ tồn tại trong lần nạp thư viện. File adapter yêu cầu readfile/writefile/isfile/isfolder/makefolder; .bak trước khi ghi, .tmp + rename nếu runtime hỗ trợ. Không có rename thì Atomic=false. Lỗi đọc/ghi trả lỗi. JSON hỏng bị chặn ghi đè cho tới khi phục hồi backup hoặc chọn tên khác. Không bảo đảm fsync khi executor không có API tương ứng.

Custom adapter truyền qua `Storage`, gồm Name, Persistent, Atomic và các method Read(path), Write(path, text), Delete(path), List(prefix). Read trả text hoặc nil, error; Write/Delete trả boolean, error; List trả array đường dẫn, error. Ứng dụng chịu trách nhiệm quyền truy cập và server storage thật; thư viện không giả lập DataStore phía client.

Schema giữ `__version = 1.2`, `__elements`, `__custom`, `__autoload`; map legacy không có wrapper được migrate. Parser bổ sung DatePicker, TimePicker, SearchBox, ProgressBar, DataTable, TreeView. Callback vẫn có thể chạy khi Load gọi setter như API cũ; import không phải transaction cho side effect bên ngoài của callback.

## Diagnostics

`Window:GetDiagnostics()` trả số Scope, Instance, Connection, Tween, Task do WindUI quản lý; thời gian tạo Window/Tab/chuyển theme; Quality, số mẫu Heartbeat và trung bình khi bật đo. Không phải số GPU/RAM hệ thống. Bộ đo Heartbeat chỉ chạy khi bật AdaptiveQuality; ngưỡng nhiều khoảng 2 giây chống đổi quality liên tục. Off không tự bị nâng lên.
