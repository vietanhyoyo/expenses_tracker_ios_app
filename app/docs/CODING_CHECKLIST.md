# Checklist khi code — Sổ Thu Chi

Dùng trước khi mở PR hoặc tự review. Giải thích chi tiết về kiến trúc: [ARCHITECTURE.md](ARCHITECTURE.md).

---

## 1. Trước khi viết code

- [ ] Xác định thay đổi thuộc tầng nào: Domain, Data, Presentation, Shared hay App.
- [ ] Quy tắc nghiệp vụ mới được viết ở **Domain trước**, rồi mới tới Data và UI.
- [ ] Kiểm tra đã có helper/component tương tự chưa (`Shared/`, `Presentation/Shared/`, helper trong `ExpenseTransaction.swift`) trước khi viết mới.

---

## 2. Domain

- [ ] Chỉ `import Foundation`. Không có `SwiftUI`, `SwiftData`, `UIKit`.
- [ ] Entity là `struct` với thuộc tính `let`, conform `Identifiable, Equatable, Sendable`.
- [ ] Liên kết giữa entity bằng `UUID`, không lưu tham chiếu tới entity khác.
- [ ] Mọi validate nghiệp vụ nằm trong use case (số tiền > 0, tên không rỗng, đúng loại danh mục, không trùng ngân sách…), **không** chỉ dựa vào việc nút Lưu bị disable.
- [ ] Chuỗi người dùng nhập (tên, ghi chú) được trim trước khi lưu.
- [ ] Lỗi ném ra là `DomainError` với case đúng nghĩa (không dùng `categoryNotFound` cho tên rỗng).
- [ ] Case `DomainError` mới đã có thông báo trong `Presentation/Shared/Extensions/Error+UserMessage.swift`.
- [ ] Logic tính toán thuần tách thành `static func` để test không cần mock.
- [ ] Hàm phụ thuộc ngày tháng nhận tham số `calendar: Calendar = .current`.
- [ ] Dùng `totalAmount`, `ofType(_:)`, `inMonth(_:calendar:)` thay vì tự viết `filter`/`reduce`.
- [ ] Tránh lồng `filter` trong vòng lặp (O(n·m)); nhóm trước bằng `Dictionary(grouping:by:)`.
- [ ] Không có ngưỡng số "magic": đặt tên hằng số (`BudgetUseCases.warningThreshold`).

---

## 3. Data

- [ ] `@Model` chỉ xuất hiện trong `Data/` và `AppContainer`; View không dùng `.modelContainer`, `@Query` hay `@Environment(\.modelContext)`.
- [ ] Model mới có `@Attribute(.unique) var id: UUID` và đã được thêm vào `Schema` trong `AppContainer`.
- [ ] Thuộc tính mới trên model đã có sẵn dữ liệu cũ phải là optional hoặc có giá trị mặc định (tránh lỗi migration).
- [ ] Enum lưu dưới dạng `rawValue`; mapper `toDomain` ném lỗi khi rawValue không hợp lệ.
- [ ] Data source dùng `SwiftDataLocalDataSource<Entity>`: thêm `typealias` + extension có sort mặc định và `fetch(id:)` bằng `#Predicate`.
- [ ] Tra cứu một bản ghi dùng `fetchFirst(where:)`, **không** `fetchAll().first { … }`.
- [ ] Mapper đủ ba hàm `toDomain`, `toEntity`, `update(_:from:)` và cập nhật **tất cả** thuộc tính (trừ `id`).
- [ ] Mọi method của repository impl bọc trong `PersistenceErrorMapper.execute`.
- [ ] Update/delete ném `xxxNotFound` khi không tìm thấy bản ghi.

---

## 4. Presentation

### ViewModel

- [ ] `@MainActor @Observable final class`, dependency là use case, nhận qua `init`.
- [ ] Không `import SwiftData`, không giữ repository hay data source.
- [ ] Có hàm `makeXxxViewModel(...)` trong protocol `ViewModelFactory` (`Presentation/Shared/`) và được hiện thực trong `AppContainer+ViewModelFactory.swift`.
- [ ] Mỗi form thêm/sửa có `XxxFormViewModel` riêng giữ input, `canSave`, `isSaving`, `errorMessage`, `save() -> Bool`; màn danh sách không chứa logic lưu của form.
- [ ] Mọi `catch` gán `errorMessage = error.userMessage`; không nuốt lỗi im lặng.
- [ ] Hàm `save` trả về `Bool` để View quyết định `dismiss()`.
- [ ] Không để state chết (thuộc tính không View nào đọc).
- [ ] Đặt tên thống nhất với feature khác: `selectedMonth`, `moveMonth(_ offset:)`, `load()`, `delete(_:)`.
- [ ] Dùng `Date.addingMonths(_:)`, `Sequence.keyedByID()` thay vì viết lại.
- [ ] Computed property nặng (lọc, sắp xếp, nhóm) không bị gọi nhiều lần trong một lần render; đọc một lần vào biến `let` trong `body`.

### View

- [ ] View chỉ render state và gửi action; không tính nghiệp vụ, không gọi use case trực tiếp.
- [ ] View không tham chiếu `AppContainer` (trừ `#Preview`); cần tạo ViewModel con thì nhận `factory: any ViewModelFactory`.
- [ ] View không `filter`/`sorted`, không parse tiền, trim chuỗi, validate hay tính giá trị mặc định; ViewModel expose sẵn (`categories(of:)`, `sortedAccounts`, `canSave`…).
- [ ] Gọi hàm async bằng `.task {}`, `.refreshable {}` hoặc `Task { await … }` trong action.
- [ ] Sheet thêm/sửa dùng `formToolbar(isSaveDisabled:onSave:)`, title `inline`, và `appFormStyle()`.
- [ ] Màn danh sách tải lại dữ liệu sau khi đóng sheet (`onDismiss`).
- [ ] Có đủ trạng thái **loading / empty / error**.
- [ ] Hành động xoá dùng `swipeActions` với `role: .destructive`.
- [ ] `body` ngắn; phần lớn tách thành `private var`/`private func` hoặc component trong `Components/`.
- [ ] Mỗi View/ViewModel/component có trách nhiệm rõ ràng nằm ở file riêng; không để struct lớn `private` trong file của màn khác.
- [ ] `ForEach` dùng ID ổn định (`Identifiable`), tránh `\.offset` trừ khi phần tử không có ID (ô trống trong lịch).

### Hiển thị & design system

- [ ] Màu dùng `AppTheme` hoặc extension ngữ nghĩa (`TransactionType.color`, `BudgetStatus.color`, `category.color`), không viết `Color(red:…)` hay lặp lại `type == .income ? … : …`.
- [ ] Khoảng cách/bo góc/font dùng `AppSpacing`, `AppRadius`, `AppTypography`.
- [ ] Tiền dùng `AppFormatters.money` / `compactMoney`; ô nhập tiền dùng `VietnameseMoneyTextField` và `AppFormatters.vietnameseMoneyInput(from:)` khi điền giá trị có sẵn.
- [ ] Không so sánh hoặc tính toán tiền bằng `Double`; chỉ chuyển sang `Double` để vẽ chart/ProgressView.
- [ ] Ngày hiển thị qua `AppFormatters` hoặc `FormatStyle` với locale `vi_VN`.
- [ ] Nút chỉ có icon có `accessibilityLabel`; icon trang trí đã `accessibilityHidden` (mặc định của `AppIconBadge`).
- [ ] Hiển thị ổn với Dark Mode và Dynamic Type lớn (`lineLimit`, `minimumScaleFactor` với số tiền dài).
- [ ] Thuộc tính chỉ phục vụ UI khai báo bằng extension trong `Presentation/Shared/Extensions/`, không thêm vào Domain.
- [ ] Code trong `Shared/` không tham chiếu kiểu của Domain/Presentation; component cần biết entity Domain đặt ở `Presentation/Shared/Components/`.

---

## 5. Concurrency & an toàn

- [ ] Kiểu mới trong pipeline dữ liệu đánh dấu `@MainActor` giống các kiểu hiện có.
- [ ] Không dùng force unwrap (`!`) hay `try!` trong code app; `fatalError` chỉ ở `ExpenseTrackerApp` khi không mở được store. (`try!` trong `#Preview` chấp nhận được.)
- [ ] Không dùng `Dictionary(uniqueKeysWithValues:)` với dữ liệu có thể trùng key; dùng `keyedByID()` hoặc `uniquingKeysWith`.
- [ ] Không đặt `try`/`await` bên trong đối số của lời gọi khác; gán ra biến trước cho dễ đọc.

---

## 6. Clean code

- [ ] Tên nói rõ ý định; tiếng Anh cho code, tiếng Việt cho chuỗi hiển thị.
- [ ] Không có code chết, `print`, code bị comment lại.
- [ ] Không copy-paste khối logic/UI lần thứ hai: tách helper, extension hoặc component.
- [ ] Comment giải thích **tại sao**, không mô tả lại code.
- [ ] Hàm làm một việc; `guard` sớm thay vì lồng `if`.
- [ ] Giữ đúng style hiện có: indent 4 space, tham số xuống dòng khi dài, trailing closure.

---

## 7. Test

- [ ] Quy tắc nghiệp vụ mới có unit test trong `DomainUseCaseTests` (cả trường hợp hợp lệ và lỗi, kiểm tra đúng `DomainError`).
- [ ] Mock repository mới là `private final class` trong file test, theo mẫu `Mock*Repository`.
- [ ] Test ngày tháng dùng `Calendar(identifier: .gregorian)` và ngày cố định, không phụ thuộc hôm nay.
- [ ] Thay đổi model/mapper/data source có test round-trip trong `PersistenceTests` với `AppContainer(inMemory: true)`.
- [ ] Toàn bộ test pass:
  ```sh
  xcodebuild -project ExpenseTracker.xcodeproj -scheme ExpenseTracker \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
  ```

---

## 8. Project & PR

- [ ] File Swift mới đã được thêm vào đúng target trong `ExpenseTracker.xcodeproj` (thêm bằng Xcode, hoặc chạy `ruby scripts/generate_project.rb`).
- [ ] File nằm đúng thư mục theo tầng và feature.
- [ ] Build không có warning mới.
- [ ] Đã chạy app trên Simulator: thao tác chính, empty state, lỗi, Dark Mode.
- [ ] Cập nhật `README.md` / `docs/ARCHITECTURE.md` nếu thay đổi cấu trúc, luồng dữ liệu hoặc quy ước.
- [ ] Commit nhỏ, message mô tả thay đổi.
