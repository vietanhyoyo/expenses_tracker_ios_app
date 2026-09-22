# Kế hoạch xây dựng ứng dụng Quản lý Chi tiêu bằng Swift

## 1. Mục tiêu dự án

Xây dựng một ứng dụng iOS quản lý thu chi cá nhân, lưu dữ liệu hoàn toàn trên thiết bị và áp dụng **Clean Architecture** kết hợp **MVVM** ở tầng Presentation.

### Mục tiêu chính

- Quản lý các khoản thu và chi.
- Quản lý danh mục giao dịch.
- Quản lý nhiều tài khoản/ví.
- Theo dõi số dư.
- Thiết lập ngân sách.
- Xem thống kê theo thời gian và danh mục.
- Lưu dữ liệu hoàn toàn ở local.
- Không yêu cầu đăng nhập.
- Không phụ thuộc backend.
- Code có khả năng test và mở rộng tốt.

---

## 2. Công nghệ sử dụng

| Thành phần | Công nghệ |
|---|---|
| Ngôn ngữ | Swift |
| UI Framework | SwiftUI |
| Kiến trúc | Clean Architecture |
| Presentation Pattern | MVVM |
| Local Database | SwiftData |
| Charts | Swift Charts |
| State Observation | Observation (`@Observable`) |
| Concurrency | Swift Concurrency (`async/await`) |
| Dependency Injection | Constructor Injection |
| Unit Test | XCTest / Swift Testing |
| UI Test | XCUITest |

---

## 3. Kiến trúc tổng thể

Ứng dụng được chia thành ba tầng chính:

```text
┌─────────────────────────────┐
│        Presentation         │
│                             │
│ SwiftUI View                │
│ ViewModel                   │
└──────────────┬──────────────┘
               │
               ↓
┌─────────────────────────────┐
│           Domain            │
│                             │
│ Entity                      │
│ UseCase                     │
│ Repository Protocol         │
└──────────────┬──────────────┘
               │
               ↓
┌─────────────────────────────┐
│            Data             │
│                             │
│ Repository Implementation   │
│ SwiftData Models            │
│ Mapper                      │
│ Local Data Source           │
└──────────────┬──────────────┘
               │
               ↓
        ┌──────────────┐
        │  SwiftData   │
        └──────────────┘
```

### Quy tắc dependency

```text
Presentation
     ↓
   Domain
     ↑
    Data
```

Tầng **Domain không được phụ thuộc SwiftUI, SwiftData hoặc framework lưu trữ cụ thể**.

---

# 4. Các tầng trong Clean Architecture

## 4.1 Domain Layer

Domain là phần quan trọng nhất của ứng dụng.

Bao gồm:

- Entity
- Repository Protocol
- Use Case
- Domain Error
- Business Rule

Domain không biết dữ liệu được lưu bằng SwiftData, Core Data hay API.

### Ví dụ cấu trúc

```text
Domain/
├── Entities/
│   ├── Transaction.swift
│   ├── Category.swift
│   ├── Account.swift
│   └── Budget.swift
│
├── Repositories/
│   ├── TransactionRepository.swift
│   ├── CategoryRepository.swift
│   ├── AccountRepository.swift
│   └── BudgetRepository.swift
│
├── UseCases/
│   ├── Transaction/
│   ├── Category/
│   ├── Account/
│   ├── Budget/
│   └── Statistics/
│
└── Errors/
    └── DomainError.swift
```

---

## 4.2 Data Layer

Data Layer chịu trách nhiệm:

- SwiftData
- CRUD
- Mapping
- Repository implementation
- Local persistence

```text
Data/
├── Local/
│   ├── Models/
│   │   ├── TransactionEntity.swift
│   │   ├── CategoryEntity.swift
│   │   ├── AccountEntity.swift
│   │   └── BudgetEntity.swift
│   │
│   └── DataSources/
│       ├── TransactionLocalDataSource.swift
│       ├── CategoryLocalDataSource.swift
│       ├── AccountLocalDataSource.swift
│       └── BudgetLocalDataSource.swift
│
├── Repositories/
│   ├── TransactionRepositoryImpl.swift
│   ├── CategoryRepositoryImpl.swift
│   ├── AccountRepositoryImpl.swift
│   └── BudgetRepositoryImpl.swift
│
└── Mappers/
    ├── TransactionMapper.swift
    ├── CategoryMapper.swift
    ├── AccountMapper.swift
    └── BudgetMapper.swift
```

---

## 4.3 Presentation Layer

Presentation sử dụng:

```text
SwiftUI + MVVM
```

```text
Presentation/
├── Dashboard/
│   ├── DashboardView.swift
│   ├── DashboardViewModel.swift
│   └── Components/
│
├── Transactions/
│   ├── TransactionListView.swift
│   ├── TransactionListViewModel.swift
│   ├── AddTransactionView.swift
│   └── AddTransactionViewModel.swift
│
├── Statistics/
│   ├── StatisticsView.swift
│   └── StatisticsViewModel.swift
│
├── Budgets/
│   ├── BudgetView.swift
│   └── BudgetViewModel.swift
│
├── Accounts/
│   ├── AccountListView.swift
│   └── AccountListViewModel.swift
│
└── Settings/
    └── SettingsView.swift
```

View chỉ chịu trách nhiệm hiển thị UI và gửi action sang ViewModel.

---

# 5. Các Entity chính

## 5.1 Transaction

```swift
struct Transaction {
    let id: UUID
    let amount: Decimal
    let type: TransactionType
    let date: Date
    let note: String?
    let categoryID: UUID
    let accountID: UUID
}
```

### TransactionType

```swift
enum TransactionType {
    case income
    case expense
}
```

---

## 5.2 Category

```swift
struct Category {
    let id: UUID
    let name: String
    let icon: String
    let type: TransactionType
}
```

Ví dụ:

```text
Ăn uống
Di chuyển
Mua sắm
Giải trí
Hóa đơn
Lương
Thưởng
Khác
```

---

## 5.3 Account

```swift
struct Account {
    let id: UUID
    let name: String
    let initialBalance: Decimal
}
```

Ví dụ:

```text
Tiền mặt
Vietcombank
Momo
Ví cá nhân
```

---

## 5.4 Budget

```swift
struct Budget {
    let id: UUID
    let categoryID: UUID
    let amount: Decimal
    let month: Date
}
```

---

# 6. Repository Protocol

Repository Protocol nằm trong Domain.

Ví dụ:

```swift
protocol TransactionRepository {
    func getTransactions() async throws -> [Transaction]

    func getTransaction(id: UUID) async throws -> Transaction?

    func addTransaction(_ transaction: Transaction) async throws

    func updateTransaction(_ transaction: Transaction) async throws

    func deleteTransaction(id: UUID) async throws
}
```

Implementation nằm trong Data Layer.

```text
Domain
    ↓
TransactionRepository

Data
    ↓
TransactionRepositoryImpl
```

---

# 7. Use Cases

Mỗi nghiệp vụ quan trọng nên được đóng gói thành Use Case.

## Transaction

```text
GetTransactionsUseCase
GetTransactionDetailUseCase
AddTransactionUseCase
UpdateTransactionUseCase
DeleteTransactionUseCase
FilterTransactionsUseCase
```

## Account

```text
GetAccountsUseCase
CreateAccountUseCase
UpdateAccountUseCase
DeleteAccountUseCase
GetAccountBalanceUseCase
```

## Budget

```text
GetBudgetsUseCase
CreateBudgetUseCase
UpdateBudgetUseCase
DeleteBudgetUseCase
CheckBudgetLimitUseCase
```

## Statistics

```text
GetMonthlySummaryUseCase
GetIncomeSummaryUseCase
GetExpenseSummaryUseCase
GetExpenseByCategoryUseCase
GetBalanceUseCase
```

---

# 8. Luồng dữ liệu

Ví dụ người dùng thêm một giao dịch:

```text
AddTransactionView
        ↓
AddTransactionViewModel
        ↓
AddTransactionUseCase
        ↓
TransactionRepository
        ↓
TransactionRepositoryImpl
        ↓
TransactionLocalDataSource
        ↓
SwiftData
```

Khi đọc dữ liệu:

```text
SwiftData
   ↓
Local Data Source
   ↓
Repository Implementation
   ↓
Mapper
   ↓
Domain Entity
   ↓
UseCase
   ↓
ViewModel
   ↓
SwiftUI View
```

---

# 9. Dependency Injection

Không tạo dependency trực tiếp bên trong ViewModel.

Không nên:

```swift
final class TransactionViewModel {
    let repository = TransactionRepositoryImpl()
}
```

Nên inject:

```swift
@Observable
final class TransactionViewModel {

    private let getTransactionsUseCase: GetTransactionsUseCase

    init(
        getTransactionsUseCase: GetTransactionsUseCase
    ) {
        self.getTransactionsUseCase = getTransactionsUseCase
    }
}
```

---

# 10. AppContainer

Tạo một nơi chịu trách nhiệm khởi tạo dependency.

```text
App/
└── AppContainer.swift
```

Ví dụ dependency graph:

```text
ModelContainer
     ↓
LocalDataSource
     ↓
Repository
     ↓
UseCase
     ↓
ViewModel
```

AppContainer có thể giữ các repository dùng chung.

---

# 11. Cấu trúc project đề xuất

```text
ExpenseTracker/
│
├── App/
│   ├── ExpenseTrackerApp.swift
│   ├── AppContainer.swift
│   └── RootView.swift
│
├── Domain/
│   │
│   ├── Entities/
│   │   ├── Transaction.swift
│   │   ├── Category.swift
│   │   ├── Account.swift
│   │   └── Budget.swift
│   │
│   ├── Repositories/
│   │   ├── TransactionRepository.swift
│   │   ├── CategoryRepository.swift
│   │   ├── AccountRepository.swift
│   │   └── BudgetRepository.swift
│   │
│   ├── UseCases/
│   │   ├── Transactions/
│   │   ├── Categories/
│   │   ├── Accounts/
│   │   ├── Budgets/
│   │   └── Statistics/
│   │
│   └── Errors/
│       └── DomainError.swift
│
├── Data/
│   │
│   ├── Local/
│   │   ├── Models/
│   │   └── DataSources/
│   │
│   ├── Repositories/
│   │
│   └── Mappers/
│
├── Presentation/
│   │
│   ├── Dashboard/
│   ├── Transactions/
│   ├── Accounts/
│   ├── Budgets/
│   ├── Statistics/
│   └── Settings/
│
├── Shared/
│   ├── Components/
│   ├── Extensions/
│   ├── Formatters/
│   └── Utilities/
│
└── Tests/
    ├── DomainTests/
    ├── DataTests/
    └── PresentationTests/
```

---

# 12. Navigation

App sử dụng TabView.

```text
┌─────────────────────────────┐
│                             │
│        Current View         │
│                             │
└─────────────────────────────┘

 Dashboard   Transactions   Statistics   Settings
```

Các tab:

```text
Dashboard
Transactions
Statistics
Settings
```

Nút thêm giao dịch có thể đặt ở:

```text
Toolbar
```

hoặc floating button trong Dashboard / Transaction List.

---

# 13. Dashboard

Dashboard hiển thị:

```text
Số dư hiện tại

Thu nhập tháng
Chi tiêu tháng

Chi tiêu theo danh mục

Ngân sách tháng

Giao dịch gần đây
```

Ví dụ:

```text
┌──────────────────────────┐
│ Số dư                    │
│ 8.500.000 ₫              │
│                          │
│ Thu nhập     Chi tiêu    │
│ 12.000.000   3.500.000   │
└──────────────────────────┘
```

---

# 14. Transaction Screen

Danh sách giao dịch:

```text
13/09/2026

☕ Cà phê
Ăn uống
-50.000 ₫

🍜 Ăn trưa
Ăn uống
-70.000 ₫

💼 Lương
Thu nhập
+12.000.000 ₫
```

Cho phép:

- Search
- Filter
- Sort
- Edit
- Delete

---

# 15. Add Transaction Screen

Form:

```text
Loại

[ Chi tiêu | Thu nhập ]

Số tiền

[ 100.000 ]

Danh mục

[ Ăn uống ]

Tài khoản

[ Tiền mặt ]

Ngày

[ 13/09/2026 ]

Ghi chú

[ Ăn trưa ]

[ Lưu ]
```

Validation:

```text
amount > 0

category != nil

account != nil
```

---

# 16. Statistics

Sử dụng Swift Charts.

Các thống kê:

```text
Thu nhập tháng

Chi tiêu tháng

Chi tiêu theo danh mục

Chi tiêu theo ngày

Xu hướng chi tiêu

So sánh tháng
```

Ví dụ:

```text
Ăn uống      40%
Mua sắm      25%
Di chuyển    15%
Hóa đơn      12%
Khác          8%
```

---

# 17. Budget

Người dùng có thể thiết lập:

```text
Ngân sách ăn uống

3.000.000 ₫ / tháng
```

Hiển thị:

```text
Đã sử dụng

2.100.000 / 3.000.000

██████████████------ 70%
```

Use Case:

```text
CheckBudgetLimitUseCase
```

Business rule:

```text
expense >= budget * 0.8
```

→ hiển thị cảnh báo.

---

# 18. SwiftData Models

SwiftData model chỉ tồn tại trong Data Layer.

Ví dụ:

```swift
@Model
final class TransactionEntity {

    @Attribute(.unique)
    var id: UUID

    var amount: Decimal

    var type: String

    var date: Date

    var note: String?

    var categoryID: UUID

    var accountID: UUID

    init(
        id: UUID,
        amount: Decimal,
        type: String,
        date: Date,
        note: String?,
        categoryID: UUID,
        accountID: UUID
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.date = date
        self.note = note
        self.categoryID = categoryID
        self.accountID = accountID
    }
}
```

Không truyền `TransactionEntity` lên ViewModel.

Luôn chuyển:

```text
TransactionEntity

        ↓ Mapper

Transaction
```

---

# 19. Mapper

Ví dụ:

```swift
extension TransactionEntity {

    func toDomain() -> Transaction {
        Transaction(
            id: id,
            amount: amount,
            type: type == "income" ? .income : .expense,
            date: date,
            note: note,
            categoryID: categoryID,
            accountID: accountID
        )
    }
}
```

---

# 20. Error Handling

Domain Error:

```swift
enum DomainError: Error {
    case invalidAmount
    case accountNotFound
    case categoryNotFound
    case transactionNotFound
    case persistenceError
}
```

ViewModel chuyển Error thành UI State.

```text
loading

success

empty

error
```

---

# 21. Testing Strategy

Clean Architecture giúp test business logic mà không cần SwiftData.

Ví dụ:

```text
MockTransactionRepository
```

sẽ implement:

```text
TransactionRepository
```

Test:

```text
AddTransactionUseCaseTests

DeleteTransactionUseCaseTests

GetBalanceUseCaseTests

GetMonthlySummaryUseCaseTests

CheckBudgetLimitUseCaseTests
```

Ưu tiên test Domain Layer trước.

---

# 22. Roadmap phát triển

## Phase 1 — Foundation

Mục tiêu:

- Tạo project.
- Setup folder.
- Setup SwiftData.
- Setup Clean Architecture.
- AppContainer.
- Dependency Injection.

Kết quả:

```text
App build thành công
Dependency graph hoạt động
SwiftData lưu được dữ liệu
```

---

## Phase 2 — Transaction

Xây dựng:

- Transaction Entity.
- TransactionEntity SwiftData.
- Mapper.
- Repository.
- LocalDataSource.
- CRUD UseCases.
- TransactionListViewModel.
- TransactionListView.
- AddTransactionView.

Kết quả:

```text
Create
Read
Update
Delete
```

hoạt động hoàn chỉnh.

---

## Phase 3 — Category

Xây dựng:

```text
Category Entity

CategoryRepository

Category CRUD

Default Categories
```

Tạo dữ liệu mặc định:

```text
Ăn uống
Di chuyển
Mua sắm
Giải trí
Hóa đơn
Lương
Thưởng
Khác
```

---

## Phase 4 — Account

Xây dựng:

```text
Account Entity

Account Repository

Account CRUD

Account Balance
```

Business rule:

```text
balance =
initialBalance
+ income
- expense
```

---

## Phase 5 — Dashboard

Use Cases:

```text
GetBalanceUseCase

GetMonthlyIncomeUseCase

GetMonthlyExpenseUseCase

GetRecentTransactionsUseCase
```

Xây Dashboard UI.

---

## Phase 6 — Statistics

Use Cases:

```text
GetExpenseByCategoryUseCase

GetMonthlySummaryUseCase

GetDailyExpenseUseCase
```

Sử dụng:

```text
Swift Charts
```

---

## Phase 7 — Budget

Xây dựng:

```text
Budget Entity

Budget Repository

Budget CRUD

Budget Progress

Budget Warning
```

---

## Phase 8 — Search và Filter

Filter theo:

```text
Date

Category

Account

Transaction Type
```

Search theo:

```text
Note

Category name
```

---

## Phase 9 — UX Polish

Hoàn thiện:

- Dark Mode
- Empty State
- Loading State
- Error State
- Animation
- Swipe Delete
- Confirmation Dialog
- Haptic Feedback
- Currency Formatter
- Vietnamese locale
- Date Formatter

---

## Phase 10 — Testing

Viết:

```text
Domain Unit Test

Repository Test

ViewModel Test

UI Test
```

Mục tiêu:

```text
Business logic test coverage > 80%
```

---

# 23. Thứ tự ưu tiên

Không nên xây tất cả tính năng cùng lúc.

Ưu tiên:

```text
1. Architecture
      ↓
2. Transaction CRUD
      ↓
3. Category
      ↓
4. Account
      ↓
5. Dashboard
      ↓
6. Statistics
      ↓
7. Budget
      ↓
8. Search / Filter
      ↓
9. UX Polish
      ↓
10. Testing
```

---

# 24. MVP

Version 1.0 chỉ nên bao gồm:

```text
Transaction CRUD

Category

Account

Dashboard

Statistics

SwiftData local storage
```

Chưa cần:

```text
Login

Backend

CloudKit

Firebase

API

AI

OCR

iCloud Sync
```

---

# 25. Kiến trúc MVP cuối cùng

```text
                  SwiftUI View
                       │
                       ↓
                   ViewModel
                       │
                       ↓
                    UseCase
                       │
                       ↓
             Repository Protocol
                       ↑
                       │
             Repository Impl
                       │
                       ↓
              Local Data Source
                       │
                       ↓
                   SwiftData
```

---

# 26. Nguyên tắc coding

## View

View chỉ:

```text
Render UI

Observe State

Send User Actions
```

View không:

```text
Query SwiftData

Tính business logic

Gọi Repository
```

---

## ViewModel

ViewModel:

```text
Quản lý UI State

Gọi UseCase

Xử lý interaction
```

ViewModel không:

```text
Import SwiftData

Query database trực tiếp
```

---

## UseCase

UseCase chứa:

```text
Business Logic
```

Một UseCase nên đại diện một nghiệp vụ rõ ràng.

Ví dụ:

```text
AddTransactionUseCase

GetMonthlyExpenseUseCase

TransferMoneyUseCase
```

---

## Repository

Repository định nghĩa cách Domain truy cập dữ liệu.

Domain chỉ biết:

```text
TransactionRepository
```

không biết:

```text
SwiftDataTransactionRepository
```

---

# 27. Nguyên tắc dependency

Domain:

```text
Foundation
```

Không import:

```text
SwiftUI

SwiftData
```

Data:

```text
import SwiftData
import Domain
```

Presentation:

```text
import SwiftUI
import Domain
```

---

# 28. Definition of Done

Một feature được xem là hoàn thành khi:

- UI hoạt động.
- Business logic nằm trong UseCase.
- ViewModel không truy cập database trực tiếp.
- Repository được inject.
- Có xử lý lỗi.
- Có empty state.
- Có unit test cho nghiệp vụ quan trọng.
- Không có SwiftData object bị truyền lên Presentation.
- App build không warning nghiêm trọng.

---

# 29. Kết quả cuối cùng

Sau khi hoàn thành roadmap, app sẽ có kiến trúc:

```text
SwiftUI
+
MVVM
+
Clean Architecture
+
Repository Pattern
+
Dependency Injection
+
SwiftData
+
Swift Charts
+
Swift Concurrency
```

Với đặc điểm:

- 100% local.
- Không cần backend.
- Dễ unit test.
- Có separation of concerns rõ ràng.
- Có thể thay SwiftData bằng giải pháp persistence khác mà ít ảnh hưởng Domain và Presentation.
- Phù hợp để học kiến trúc iOS thực tế.
- Có thể sử dụng làm portfolio project.
