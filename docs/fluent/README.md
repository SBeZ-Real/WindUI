# WindUI Fluent

Bản triển khai trên nhánh `fluent-integration`, phát triển trực tiếp từ WindUI của Footagesus. Không đổi tên entrypoint, không đổi phiên bản package, không merge hoặc release.

## Chạy thử

File phân phối là `dist/main.lua`, được tạo từ `src/Init.lua`. Không sửa trực tiếp file phân phối. Gallery thật nằm ở `tests/fluent/Gallery.lua`; Theme Studio là một tab tương tác trong gallery.

Với Roblox Studio, mở `WindUI-Gallery.rbxlx` trong gói bàn giao rồi chọn Play. Place này có ModuleScript thư viện, ModuleScript gallery và LocalScript khởi chạy. Place đã được Rojo build; chưa được mở hoặc chạy trong Roblox Studio tại môi trường triển khai.

Để build lại từ source trên Linux:

```bash
aftman install
bash build/setup-test-tools.sh
export PATH="$PWD/.test-tools:$PATH"
npm run build
npm test
rojo build tests/fluent/studio.project.json --output WindUI-Gallery.rbxlx
```

Build cần Node.js, Python 3, DarkLua 0.17.1; test cần Luau 0.746. Rojo 7.3.0 được giữ theo `aftman.toml`. Script cài Luau kiểm SHA-256 của gói tải. `npm install` chỉ cần cho các tiện ích watch/live đã có, không cần cho build và test này.

Mã nguồn dùng đường dẫn require cho DarkLua. Trong Studio hãy dùng bundle qua project gallery ở trên; không đặt nguyên cây source dùng `require("./...")` vào Studio rồi kỳ vọng Roblox tự hiểu đường dẫn đó. `default.project.json`, `main.client.lua`, `main_example.lua` và `main.lua` cũ vẫn giữ nguyên.

## Phạm vi đã có mã

- Multi-window, scope tài nguyên, focus, drag/resize, minimize/restore, fullscreen, snap và bố cục thích ứng.
- Classic/Premium/Glass, Light/Dark, accent, tokens, Theme Studio, preset JSON và adaptive theme bằng resolver của ứng dụng.
- Component cũ cùng DataTable, TreeView, Breadcrumb, ContextMenu, DatePicker, TimePicker, CommandPalette và SearchBox.
- Navigation history/search/commands; toast, action, progress, hàng đợi và notification center.
- Cấu hình Memory/File/custom adapter, autosave, profile, preset, workspace, migration, backup/recovery.
- Chẩn đoán tài nguyên, lazy module/icon pack, danh sách dùng lại hàng hiển thị, adaptive quality có hysteresis.

`API.md` mô tả cách gọi. `ARCHITECTURE.md` mô tả ownership và fallback. `ACCEPTANCE.md` đối chiếu 20 quyết định. `TEST_REPORT.md` phân biệt phần đã kiểm tra với phần chưa chạy trên Roblox.

## Giới hạn bàn giao

Không có Roblox Studio, Roblox client hay executor thật trong môi trường Linux này. Vì vậy chưa có kết luận về hình thức hiển thị, FPS, cảm ứng hoặc gamepad trên thiết bị thật. Test mô phỏng không thay thế các kiểm tra đó. Không tạo ảnh giả để làm bằng chứng giao diện.

Mã nguồn đã được đưa lên [SBeZ-Real/WindUI](https://github.com/SBeZ-Real/WindUI/tree/fluent-integration), nhánh `fluent-integration`, và [PR #1](https://github.com/SBeZ-Real/WindUI/pull/1) đang ở trạng thái draft. Nội dung bốn mốc triển khai trên GitHub khớp từng Git tree với bản local đã kiểm thử. Bảng ánh xạ commit nằm trong `TEST_REPORT.md`.

GitHub Actions chưa có lượt chạy khi bàn giao; API danh sách workflows và runs trả về rỗng. Kết nối hiện tại không có thao tác bật Actions hoặc dispatch workflow; cần chủ repository kiểm tra mục Actions để chạy CI từ xa. PR giữ draft chờ CI và nghiệm thu Roblox thật. Không merge, tạo tag hoặc release.
