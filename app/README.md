# Sổ Thu Chi

Ứng dụng iOS quản lý các khoản thu, chi và số dư cá nhân. Ứng dụng được xây dựng bằng SwiftUI, SwiftData, Swift Charts và kết nối REST API cho tài khoản, giao dịch, danh mục và dữ liệu tổng quan. Giao diện và nội dung hiển thị bằng tiếng Việt.

## Kiến trúc

Dự án sử dụng Clean Architecture kết hợp MVVM:

```text
ExpenseTracker/
├── App/
│   ├── AppContainer.swift       # Khởi tạo dependency và nối các tầng
│   └── RootView.swift           # Điều hướng theo trạng thái phiên đăng nhập
├── Presentation/                # SwiftUI View, ViewModel và component theo feature
├── Domain/
│   ├── Entities/                 # Model nghiệp vụ thuần Swift
│   ├── Repositories/            # Protocol repository
│   ├── UseCases/                 # Quy tắc và luồng nghiệp vụ
│   └── Errors/                   # Lỗi nghiệp vụ
├── Data/
│   ├── Local/                    # SwiftData model và data source
│   ├── Remote/                   # API client, DTO, Keychain và xử lý token
│   ├── Mappers/                  # Chuyển đổi giữa các loại model
│   └── Repositories/             # Hiện thực repository
└── Shared/                       # Design system, component và tiện ích dùng chung
```

Luồng phụ thuộc chính là `Presentation → Domain ← Data`. `AppContainer` là composition root, chịu trách nhiệm tạo các repository/use case và inject vào ViewModel. View chỉ làm nhiệm vụ hiển thị và tương tác; nghiệp vụ nằm trong Domain, còn việc lưu trữ hoặc gọi API nằm trong Data.

## Chạy bằng Xcode

### Yêu cầu

- macOS và Xcode hỗ trợ iOS 17 trở lên.
- iOS Simulator hoặc iPhone thật đã được Xcode nhận diện.
- Backend REST API đang chạy tại `http://localhost:3000/api/v1` nếu cần đăng nhập và đồng bộ dữ liệu. Địa chỉ này được cấu hình trong `ExpenseTracker/Info.plist` bằng khóa `API_BASE_URL`.

### Các bước chạy

1. Mở file `ExpenseTracker.xcodeproj` trong thư mục `app` bằng Xcode.
2. Chọn scheme `ExpenseTracker` ở thanh công cụ.
3. Chọn thiết bị chạy, ví dụ `iPhone 17 Pro` trong danh sách Simulator.
4. Chọn **Product → Run** hoặc nhấn `⌘R`.

Xcode sẽ build ứng dụng, cài lên thiết bị đã chọn và mở ứng dụng. Nếu backend dùng địa chỉ khác, cập nhật giá trị `API_BASE_URL` trong `ExpenseTracker/Info.plist` trước khi chạy.
