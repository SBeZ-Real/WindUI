# Báo cáo build và kiểm thử

Ngày: 09/11/2026. Source gốc: `d2c9bac5f96f997418d680d19cb759892542e492`; icons: `46d30c19ba7bc601d6ec794a48dc3a89568b1eec`. Nhánh: `fluent-integration`. Commit triển khai đầu: `6b4e9bb`; commit hoàn thiện được ghi trong manifest của gói bàn giao.

## Kết quả đã chạy

| Kiểm tra | Kết quả |
|---|---|
| Build upstream baseline bằng DarkLua 0.17.1 | Pass, 1.318 KiB, 423 ms ở lượt ghi nhận |
| Build source nâng cấp | Pass, khoảng 1.389 KiB; hai lượt kiểm reproducibility 386/454 ms |
| Build lặp cùng SOURCE_DATE_EPOCH | Hai lần build từ archive sạch cùng SHA-256 với dist/main.lua đã commit |
| Lỗi DarkLua giả lập exit 42 | Build trả đúng 42; không ghi đè distribution trước đó |
| Luau 0.746 compile | Pass distribution và 99 file source/test; snippet Lua trong tài liệu cũng compile |
| Inventory API | Pass 370 khai báo hàm ở 63 file; tên và prefix tham số cũ còn tồn tại |
| Unit tests | 11 nhóm pass |
| Integration | Pass luồng 5 cửa sổ, component cũ/mới, flags, tìm kiếm, notify/cleanup |
| Configuration | Pass autosave/setters, advanced state, profiles/presets/workspace, dữ liệu sai bị từ chối |
| KeySystem | Pass khóa sai không mở cửa sổ, khóa đúng mở; Exit hủy chờ tạo và thu hồi context |
| File adapter | Pass nhánh rename, backup/recover, lỗi đọc/ghi, kiểm đường dẫn/delete bằng simulated APIs |
| Lifecycle | Pass tạo/hủy trước deferred task, 10 popup toàn cục, 20 vòng dropdown/color/dialog/palette/theme, fullscreen restore, mô phỏng touch/rotation |
| Rojo 7.3.0 build gallery | Pass tạo .rbxlx; XML có 3 ModuleScript và 1 LocalScript |
| git diff --check | Pass trước đóng gói |

Kích thước dùng KiB = 1024 byte; đây là chi phí file bundle, không phải bộ nhớ trong Roblox. Thời gian build không chứng minh hiệu năng UI.

## Unit và integration thực sự kiểm tra gì

Unit tests chạy trực tiếp các module Scope, Calendar, ListModel, Navigation, Schema, Tokens và Performance bằng Luau CLI. Chúng kiểm tra ownership/coroutine, ngày nhuận, sort/filter/selection/range, history branching, registry/search, schema, token isolation và quality hysteresis.

Integration chạy bundle production đã build, không chép implementation riêng cho test. RobloxMock chỉ cung cấp các service/value/Instance/event cần cho kịch bản. Tween mock áp ngay, scheduler được điều khiển, hình học xấp xỉ, nhiều thuộc tính native không được engine kiểm tra. JSON mock giữ object theo token, không thực thi JSONEncoder/Decoder native. File tests mô phỏng executor file API; không phải IO của executor thật. Các giới hạn này có thể che lỗi rendering, property security, layout, timing, JSON thực và device input.

Số resource trở về baseline trong các kịch bản cleanup đã chạy: scope, instance, connection, tween/task được quản lý. Kết quả này không phải chứng minh không có mọi loại leak của engine. Chưa có ảnh/video visual QA vì không chạy Roblox.

`main.client.lua` cũ chưa được thực thi toàn bộ. Regression suite dùng các API/component tương ứng có assertions; declaration inventory và compile không đủ thay thế ví dụ cũ chạy thật.

## Benchmark model

Một lượt ghi nhận, 30 lần mỗi kích thước; median và worst của tạo model, sort, filter và tính vùng nhìn thấy trên máy Linux hiện tại:

| Hàng | Median ms | Worst ms |
|---|---:|---:|
| 50 | 0,0596 | 0,0843 |
| 200 | 0,3207 | 0,4617 |
| 500 | 0,8172 | 1,0121 |
| 1000 | 1,6958 | 2,0457 |

Đây là benchmark model thuần Luau, không tạo GUI Roblox, không phải FPS và không phải so sánh tăng tốc với upstream. Thời gian biến thiên theo tải máy. Integration xác nhận 1.000 hàng DataTable không tạo 1.000 row button trong vùng nhìn thấy mô phỏng.

`tests/fluent/NativeBenchmark.lua` là benchmark Roblox để chạy tiếp. Mỗi lần dùng một thư viện được nạp mới, cùng game, thiết bị, đồ họa, viewport và số lượng 50/200/500/1000. Chế độ Toggle dùng config cũ chung cho upstream/candidate. Ghi nhiều lần để so median/worst; chế độ DataTable chỉ có ở candidate. Đo CreateMilliseconds, 120 mẫu Heartbeat, descendants và diagnostics khi API có sẵn. Không gọi số descendants là RAM.

## Ma trận môi trường

| Môi trường | Trạng thái |
|---|---|
| Linux + DarkLua/Luau/Rojo | Tested, pass các kịch bản ghi trên |
| Roblox Studio renderer/client | Not tested |
| Windows Roblox desktop | Not tested |
| Android Roblox/executor | Not tested |
| Tablet/hybrid | Not tested |
| Gamepad thật | Not tested |
| Provider KeySystem qua mạng thật | Not tested |
| GitHub Actions của fork | Not run; chưa có đích push |

## Giới hạn còn tồn tại

- Chưa kiểm chứng font/asset tải được trong game đích, text clipping, modal dài, bàn phím ảo, tọa độ inset/scale và cảm giác Fluent trên thiết bị thật.
- Acrylic là mô phỏng Roblox opt-in, không phải Windows native blur; cần kiểm tra camera/Lighting thực.
- Dropdown cũ vẫn dựng toàn bộ option; các control thông thường chưa tự virtualize để giữ khả năng truy cập Instance/API cũ. Dùng DataTable/TreeView/palette cho danh sách dài.
- Gamepad có Activated/focus/Escape/ButtonB/command shortcut; chưa chứng minh mọi thao tác của slider/color/viewport tương đương chuột.
- Memory storage không sống qua lần nạp thư viện; File persistence/atomic phụ thuộc API thật. Custom storage cần backend do ứng dụng cấp quyền.
- Import có kiểm schema và báo lỗi setter, nhưng callback có side effect bên ngoài không được rollback như một transaction.
- Không có kết luận cải thiện FPS/RAM hoặc tương thích mọi executor.

## Bằng chứng và lệnh tái tạo

Trong gói bàn giao có `artifacts/build-validation.txt`, `artifacts/tests.txt`, `artifacts/manifest.json`, source và git bundle. Lượt reproducibility dùng `SOURCE_DATE_EPOCH=1794265200`. Chạy `npm test` với Luau/Luau-compile trong PATH. Build source trước test khi có sửa mã.

PR/push đang bị chặn: connector xác định tài khoản SBeZ-Real; truy vấn WindUI trong các repo đã cấp quyền trả rỗng, truy cập SBeZ-Real/WindUI trả 404. Công cụ hiện có không tạo fork/repository, CLI và trình duyệt không có đăng nhập GitHub sử dụng được. Không ghi vào repository không liên quan hoặc upstream của người khác.
