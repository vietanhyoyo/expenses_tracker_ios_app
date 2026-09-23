# Sổ Thu Chi — Expense Tracker

Ứng dụng quản lý thu chi bằng SwiftUI, SwiftData, Swift Charts và REST API. Dự án tuân theo Clean Architecture (`Presentation → Domain ← Data`) với MVVM ở lớp Presentation.

## Kiến trúc

```text
ExpenseTracker/
├── App/                    # Composition root, dependency injection, bootstrap
├── Domain/
│   ├── Entities/           # Model nghiệp vụ thuần Swift
│   ├── Repositories/       # Contract mà Domain yêu cầu
│   ├── UseCases/           # Quy tắc và thao tác nghiệp vụ
│   └── Errors/             # Lỗi nghiệp vụ
├── Data/
│   ├── Local/Models/       # SwiftData persistence models
│   ├── Local/DataSources/  # Đọc/ghi ModelContext
│   ├── Remote/             # API client, DTO, Keychain và ánh xạ ID server
│   ├── Mappers/            # Chuyển đổi Domain ↔ persistence
│   └── Repositories/       # Hiện thực repository contract
├── Presentation/           # View + ViewModel, nhóm theo feature
└── Shared/                 # Design system, component và utility dùng chung
```

Hướng phụ thuộc là `Presentation → Domain ← Data`. `AppContainer` là nơi duy nhất khởi tạo implementation và nối dependency. View không truy cập SwiftData trực tiếp; local data source không nhận Domain model; việc chuyển đổi dữ liệu nằm trong mapper và repository.

Khi thêm feature mới, ưu tiên tạo một thư mục riêng trong `Presentation`, một file cho mỗi View/ViewModel/component có trách nhiệm rõ ràng, và thêm nghiệp vụ vào `Domain` trước khi hiện thực lưu trữ ở `Data`.

Tài liệu chi tiết:

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — kiến trúc, luồng dữ liệu, đánh đổi đã biết.
- [docs/CODING_CHECKLIST.md](docs/CODING_CHECKLIST.md) — checklist khi code và review.

## Chức năng

- Dashboard: tổng số dư, thu/chi tháng, danh mục, ngân sách và giao dịch gần đây.
- CRUD giao dịch; tìm kiếm, lọc theo loại/danh mục/tài khoản và sắp xếp.
- Quản lý tài khoản, danh mục và ngân sách tháng.
- Thống kê chi tiêu theo ngày và danh mục bằng Swift Charts.
- Đăng ký, đăng nhập, tự refresh token và đăng xuất; token lưu trong Keychain.
- Khoản thu, khoản chi, danh mục, tài khoản và số liệu Tổng quan dùng REST API; ngân sách và metadata chưa có API tiếp tục lưu cục bộ.
- Định dạng VND và giao diện tiếng Việt, hỗ trợ Dark Mode/Dynamic Type.

## Chạy dự án

Khởi động backend trong `../server` bằng `docker compose up --build -d`. Sau đó mở `ExpenseTracker.xcodeproj`, chọn scheme `ExpenseTracker`, chọn iOS Simulator và Run. Simulator dùng API mặc định tại `http://localhost:3000/api/v1`.

```sh
xcodebuild -project ExpenseTracker.xcodeproj -scheme ExpenseTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Nếu thêm hoặc xoá file Swift, có thể tái tạo project bằng `ruby scripts/generate_project.rb`.
