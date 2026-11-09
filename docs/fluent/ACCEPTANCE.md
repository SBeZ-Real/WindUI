# Đối chiếu 20 quyết định

Ngày đối chiếu: 09/11/2026. “Có mã” không đồng nghĩa đã nghiệm thu trên thiết bị. Luau CLI chạy code thật; phần integration dùng mô hình API Roblox giới hạn được ghi rõ trong TEST_REPORT.md.

| Quyết định | Phần đã triển khai | Bằng chứng và phần còn mở |
|---|---|---|
| 01 Phong cách | Tokens và SetStyle cho Classic/Premium/Glass | Test đổi style/mode/accent giữ value; hình thức thực tế chưa kiểm chứng |
| 02 Bố cục | Settings/Compact/Adaptive, sidebar, tooltip, viewport fit | Kiểm tra geometry mô phỏng 360×740 và xoay 740×360; chưa đo trên điện thoại |
| 03 Hiệu ứng | Off/Low/Balanced/High, ReducedMotion, hủy/thay tween, progress tĩnh | Test chuyển motion và phục hồi; tween native/độ mượt chưa đo |
| 04 Component | Giữ component cũ, thêm 8 module nâng cao, state và validation | Smoke control/advanced, compile gallery; chưa chạy visual gallery trong Roblox |
| 05 Theme | Theme Engine, Studio, token override, preset, JSON, rollback, adaptive resolver | Test schema lỗi, preset, input-change adaptive; OS theme không tự dò |
| 06 Window | ID/context/GUI riêng, focus, snap, resize, minimize, maximize/fullscreen/restore | 5 cửa sổ, hủy một giữ các cửa sổ khác, fullscreen restore, cancellation; drag thật chưa kiểm chứng |
| 07 Notification | Queue, dedupe theo owner, action/progress/update, history, center, dialog result | Burst 80, giới hạn active/queue, cleanup; layout toast thật còn phải xem |
| 08 Performance | Scope, lazy factories, pooled rows, smart theme updates, metrics, hysteresis | 1.000 hàng có pool dưới 50 trong mô phỏng; model benchmark 50/200/500/1000; chưa có so sánh FPS Roblox |
| 09 Compatibility | PlayerGui/gethui, file capability, clipboard/HTTP capability, asset fallback | Studio-like mock và simulated executor file APIs; chưa chạy executor thật |
| 10 Navigation | History, index, Back/Forward, SearchBox, palette, commands, breadcrumb callbacks | Unit history branching/locked route/search rename/remove; shortcut và focus native chưa kiểm chứng |
| 11 Architecture | Scope/context, registry mở rộng, facade API cũ, module/icon lazy | 370 khai báo hàm giữ lại, lifecycle stress; declaration check không chứng minh toàn bộ semantics |
| 12 Configuration | Memory/File/custom, migration, autosave, profile/preset/workspace, backup | State restore, corrupt preservation, rename path, denied IO, recovery; native JSON/filesystem runtime chưa chạy |
| 13 Rendering | Native GUI và các asset hiện có; adapter icon MIT, không có UI screenshot giả | DarkLua/Luau/Rojo build; quyền tải asset trong game cần runtime thật |
| 14 Adaptive UX | Touch target, compact menu, tooltip/popups bounds, Activated, Escape/ButtonB, focus | Geometry/input events mô phỏng; Android/tablet/gamepad thật chưa kiểm chứng |
| 15 QA | API inventory, unit/integration/storage/key/lifecycle, CI sửa lỗi trạng thái | Kiểm thử local qua; GitHub Actions chưa chạy do chưa push được |
| 16 DX | API docs, kiến trúc, gallery, Theme Studio, diagnostics, native benchmark | Snippet Lua compile; gallery đóng gói thành place; demo chưa chạy native |
| 17 GitHub | Nhánh fluent-integration, commit local, source/git bundle, mô tả PR | Chặn: chưa tìm thấy WindUI writable trong tài khoản SBeZ-Real; chưa có PR |
| 18 Ưu tiên chất lượng | Chặn build/test lỗi, Off không phụ thuộc animation, giữ API | Build failure propagation và automation pass; native gates còn mở |
| 19 Giai đoạn | Baseline → core/theme/window/components → engines → QA/docs | Các phần source đã làm; feature PR theo gate chưa thể tạo vì chưa có đích ghi |
| 20 Nghiệm thu | Báo cáo bằng chứng, giới hạn và rollback rõ ràng | Chưa đạt nghiệm thu cuối khi thiếu native QA và PR review; không tự merge/release |

## Các gate chưa được tuyên bố đạt

Gate 0 thiếu xác nhận repository writable. Gate 1–5 có kiểm tra logic và cleanup tự động, nhưng không thay thế runtime gate trong Roblox. Gate 6 còn thiếu visual/device/performance baseline thực và chạy CI từ xa. Không dùng kết quả CLI để đánh dấu các ô đó thành pass.

## Kiểm tra cần chạy trên Roblox

1. Mở place gallery, kiểm tra tất cả tab/control ở Classic/Premium/Glass, Dark/Light và cả bốn mức effects.
2. Thử 1/3/5 cửa sổ, drag/resize/snap/minimize/restore, nhập liệu khi cửa sổ khác có shortcut trùng.
3. Dùng Studio Device Emulator rồi thiết bị Android/tablet thật: 320/360 px, landscape, bàn phím ảo, calendar và colorpicker; kiểm tra nội dung modal dài không làm mất nút thao tác.
4. Dùng gamepad thật để kiểm tra selection, kích hoạt và đóng popup. Chỉ tuyên bố tương đương chuột cho các control đã thực sự kiểm tra.
5. Bật Acrylic có chủ đích trong game có DOF/camera effects khác; tạo/hủy nhiều lần, xác nhận DOF của game không bị thay đổi.
6. Chạy benchmark cùng game/thiết bị/đồ họa và cùng số control giữa upstream baseline và nhánh này; quan sát MicroProfiler. DataTable mới không có đối chứng cùng component ở upstream.
7. Chạy từng provider KeySystem được sử dụng với khóa thử hợp lệ của chủ dự án và capability thật; không cần gửi khóa/bí mật vào source.
8. Thử File adapter trên runtime được phép, kể cả lỗi quyền, thiếu rename/delete/list và import file cấu hình thực từ bản cũ.
