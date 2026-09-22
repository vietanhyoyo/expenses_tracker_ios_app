# Expense Tracker iOS App — Clean Architecture Implementation Plan

## 1. Project Objective

Build an iOS personal expense-tracking application that stores all user data **locally on the device** and follows **Clean Architecture**, with **MVVM** used in the Presentation layer.

The application must not require a backend, account system, login flow, or cloud synchronization.

### Primary goals

- Track income and expenses.
- Manage transaction categories.
- Manage multiple accounts/wallets.
- Track account balances and total balance.
- Create and monitor monthly budgets.
- Display statistics by time period and category.
- Store all data locally on the device.
- Require no user authentication.
- Have no backend dependency.
- Keep the codebase testable, maintainable, and easy to extend.

---

# 2. Agent Implementation Rules

These rules are mandatory for implementation.

1. The app must be **local-only**.
2. Do not add Firebase, CloudKit, Supabase, REST APIs, GraphQL, or any other backend.
3. Use **SwiftUI** for the UI.
4. Use **SwiftData** for local persistence.
5. Use **Clean Architecture** with the following layers:
   - Presentation
   - Domain
   - Data
6. Use **MVVM** inside the Presentation layer.
7. The Domain layer must not import:
   - SwiftUI
   - SwiftData
8. SwiftData models must never be exposed directly to the Presentation layer.
9. Domain entities and SwiftData entities must be separate types.
10. Use repository protocols defined in the Domain layer.
11. Repository implementations belong in the Data layer.
12. ViewModels must depend on Use Cases, not SwiftData or concrete repositories.
13. Dependencies must be injected through initializers whenever practical.
14. Business logic belongs in Use Cases or Domain types, not in Views.
15. Views should only render state and forward user actions.
16. Prefer `Decimal` for monetary values.
17. Use Swift Concurrency (`async/await`) where asynchronous boundaries are useful.
18. Write unit tests for important business rules.
19. Avoid unnecessary third-party dependencies.
20. Do not introduce additional architectural layers unless there is a clear requirement.

---

# 3. Technology Stack

| Area | Technology |
|---|---|
| Language | Swift |
| UI Framework | SwiftUI |
| Architecture | Clean Architecture |
| Presentation Pattern | MVVM |
| Local Database | SwiftData |
| Charts | Swift Charts |
| State Observation | Observation (`@Observable`) |
| Concurrency | Swift Concurrency (`async/await`) |
| Dependency Injection | Constructor / Initializer Injection |
| Unit Testing | Swift Testing and/or XCTest |
| UI Testing | XCUITest |

---

# 4. High-Level Architecture

The application is divided into three main layers:

```text
┌─────────────────────────────┐
│        Presentation         │
│                             │
│ SwiftUI Views               │
│ ViewModels                  │
└──────────────┬──────────────┘
               │
               ↓
┌─────────────────────────────┐
│           Domain            │
│                             │
│ Entities                    │
│ Use Cases                   │
│ Repository Protocols        │
│ Business Rules              │
└──────────────┬──────────────┘
               ↑
               │
┌─────────────────────────────┐
│            Data             │
│                             │
│ Repository Implementations  │
│ SwiftData Models            │
│ Mappers                     │
│ Local Data Sources          │
└──────────────┬──────────────┘
               │
               ↓
        ┌──────────────┐
        │  SwiftData   │
        └──────────────┘
```

## Dependency rule

```text
Presentation
     ↓
   Domain
     ↑
    Data
```

The **Domain layer must not depend on SwiftUI, SwiftData, or any specific persistence framework**.

The Data layer depends on Domain abstractions and implements them.

The Presentation layer communicates with the Domain layer through Use Cases.

---

# 5. Clean Architecture Layers

## 5.1 Domain Layer

The Domain layer is the core of the application.

It contains:

- Domain Entities
- Repository Protocols
- Use Cases
- Domain Errors
- Business Rules

The Domain layer must not know whether data is stored with SwiftData, Core Data, SQLite, a remote API, or another persistence mechanism.

### Suggested structure

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
│   ├── Transactions/
│   ├── Categories/
│   ├── Accounts/
│   ├── Budgets/
│   └── Statistics/
│
└── Errors/
    └── DomainError.swift
```

---

## 5.2 Data Layer

The Data layer is responsible for persistence and translating stored data into Domain entities.

Responsibilities include:

- SwiftData integration
- CRUD operations
- Local data sources
- Repository implementations
- Mapping between persistence models and Domain entities
- Local persistence errors

### Suggested structure

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

## 5.3 Presentation Layer

The Presentation layer uses:

```text
SwiftUI + MVVM
```

### Suggested structure

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
│   ├── AddTransactionViewModel.swift
│   ├── EditTransactionView.swift
│   └── EditTransactionViewModel.swift
│
├── Statistics/
│   ├── StatisticsView.swift
│   └── StatisticsViewModel.swift
│
├── Budgets/
│   ├── BudgetListView.swift
│   ├── BudgetViewModel.swift
│   └── Components/
│
├── Accounts/
│   ├── AccountListView.swift
│   ├── AccountListViewModel.swift
│   └── Components/
│
└── Settings/
    └── SettingsView.swift
```

Views are responsible only for:

- Rendering UI.
- Observing ViewModel state.
- Forwarding user actions to ViewModels.

Views must not contain persistence logic or important business logic.

---

# 6. Core Domain Entities

## 6.1 Transaction

```swift
struct Transaction: Identifiable, Equatable, Sendable {
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
enum TransactionType: String, Equatable, Sendable {
    case income
    case expense
}
```

### Rules

- `amount` must be greater than zero.
- A transaction must belong to one category.
- A transaction must belong to one account.
- Transaction type should be compatible with the selected category type.

---

## 6.2 Category

```swift
struct Category: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let icon: String
    let type: TransactionType
}
```

Example categories:

```text
Food
Transportation
Shopping
Entertainment
Bills
Salary
Bonus
Other
```

The UI may later localize these labels to Vietnamese.

---

## 6.3 Account

```swift
struct Account: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let initialBalance: Decimal
}
```

Example accounts:

```text
Cash
Bank Account
E-Wallet
Personal Wallet
```

An account balance should be derived from its initial balance plus transaction history.

---

## 6.4 Budget

```swift
struct Budget: Identifiable, Equatable, Sendable {
    let id: UUID
    let categoryID: UUID
    let amount: Decimal
    let month: Date
}
```

### Rules

- Budget amount must be greater than zero.
- A budget belongs to one expense category.
- Budget comparison should be based on transactions for the selected month.
- Avoid storing derived budget usage if it can be calculated reliably from transactions.

---

# 7. Repository Protocols

Repository protocols must be defined in the Domain layer.

Example:

```swift
protocol TransactionRepository: Sendable {
    func getTransactions() async throws -> [Transaction]

    func getTransaction(id: UUID) async throws -> Transaction?

    func addTransaction(_ transaction: Transaction) async throws

    func updateTransaction(_ transaction: Transaction) async throws

    func deleteTransaction(id: UUID) async throws
}
```

Implementation belongs in the Data layer:

```text
Domain
    ↓
TransactionRepository

Data
    ↓
TransactionRepositoryImpl
```

The same pattern should be used for:

```text
CategoryRepository
AccountRepository
BudgetRepository
```

---

# 8. Use Cases

Each important application action should be represented by a focused Use Case.

Do not create a Use Case for trivial UI-only operations.

## 8.1 Transaction Use Cases

```text
GetTransactionsUseCase
GetTransactionDetailUseCase
AddTransactionUseCase
UpdateTransactionUseCase
DeleteTransactionUseCase
FilterTransactionsUseCase
```

## 8.2 Account Use Cases

```text
GetAccountsUseCase
CreateAccountUseCase
UpdateAccountUseCase
DeleteAccountUseCase
GetAccountBalanceUseCase
```

## 8.3 Category Use Cases

```text
GetCategoriesUseCase
CreateCategoryUseCase
UpdateCategoryUseCase
DeleteCategoryUseCase
GetDefaultCategoriesUseCase
```

## 8.4 Budget Use Cases

```text
GetBudgetsUseCase
CreateBudgetUseCase
UpdateBudgetUseCase
DeleteBudgetUseCase
CheckBudgetLimitUseCase
GetBudgetProgressUseCase
```

## 8.5 Statistics Use Cases

```text
GetMonthlySummaryUseCase
GetIncomeSummaryUseCase
GetExpenseSummaryUseCase
GetExpenseByCategoryUseCase
GetDailyExpenseUseCase
GetBalanceUseCase
GetRecentTransactionsUseCase
```

---

# 9. Data Flow

## Adding a transaction

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

## Reading transactions

```text
SwiftData
   ↓
TransactionLocalDataSource
   ↓
TransactionRepositoryImpl
   ↓
Mapper
   ↓
Domain Transaction
   ↓
Use Case
   ↓
ViewModel
   ↓
SwiftUI View
```

The Presentation layer must never receive a SwiftData `@Model` object.

---

# 10. Dependency Injection

Do not create concrete persistence dependencies directly inside ViewModels.

## Incorrect

```swift
@Observable
final class TransactionListViewModel {
    private let repository = TransactionRepositoryImpl()
}
```

## Correct

```swift
@Observable
final class TransactionListViewModel {

    private let getTransactionsUseCase: GetTransactionsUseCase

    init(
        getTransactionsUseCase: GetTransactionsUseCase
    ) {
        self.getTransactionsUseCase = getTransactionsUseCase
    }
}
```

Dependencies should be constructed at the composition root and injected downward.

---

# 11. AppContainer / Composition Root

Create one composition root responsible for assembling application dependencies.

```text
App/
└── AppContainer.swift
```

Conceptual dependency graph:

```text
ModelContainer
     ↓
Local Data Sources
     ↓
Repository Implementations
     ↓
Use Cases
     ↓
ViewModels
```

`AppContainer` may keep long-lived repository implementations and factories for feature-specific ViewModels.

Example responsibilities:

```text
Create ModelContainer
Create Data Sources
Create Repository Implementations
Create Use Cases
Create ViewModels / ViewModel Factories
```

Do not turn `AppContainer` into a service locator used from arbitrary Views.

Prefer explicit injection.

---

# 12. Recommended Project Structure

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

If the project is a single Xcode target, use groups/folders to enforce these boundaries logically.

If the project grows significantly, the layers may later be split into local Swift packages, but this is not required for the MVP.

---

# 13. Navigation

Use `TabView` for top-level navigation.

```text
┌─────────────────────────────┐
│                             │
│        Current View         │
│                             │
└─────────────────────────────┘

 Dashboard   Transactions   Statistics   Settings
```

Primary tabs:

```text
Dashboard
Transactions
Statistics
Settings
```

Account and Budget screens may be accessible from Dashboard, Settings, or their own navigation destinations depending on UX decisions.

The add-transaction action can be placed in:

```text
Toolbar
```

or as a clearly visible action in Dashboard / Transaction List.

Use `NavigationStack` for feature navigation.

---

# 14. Dashboard Feature

The Dashboard should display:

```text
Current Balance

Monthly Income
Monthly Expenses

Expenses by Category

Monthly Budget Progress

Recent Transactions
```

Example:

```text
┌──────────────────────────┐
│ Current Balance          │
│ 8,500,000 ₫              │
│                          │
│ Income       Expenses    │
│ 12,000,000   3,500,000   │
└──────────────────────────┘
```

Recommended ViewModel dependencies:

```text
GetBalanceUseCase
GetMonthlySummaryUseCase
GetExpenseByCategoryUseCase
GetRecentTransactionsUseCase
GetBudgetsUseCase
```

---

# 15. Transactions Feature

The transaction list should show records grouped or sorted by date.

Example:

```text
September 13, 2026

☕ Coffee
Food
-50,000 ₫

🍜 Lunch
Food
-70,000 ₫

💼 Salary
Income
+12,000,000 ₫
```

Supported actions:

- Search
- Filter
- Sort
- Add
- Edit
- Delete

Recommended filters:

```text
Date range
Category
Account
Transaction type
```

Recommended sorting:

```text
Newest first
Oldest first
Highest amount
Lowest amount
```

---

# 16. Add / Edit Transaction Feature

Suggested form:

```text
Type

[ Expense | Income ]

Amount

[ 100,000 ]

Category

[ Food ]

Account

[ Cash ]

Date

[ September 13, 2026 ]

Note

[ Lunch ]

[ Save ]
```

Validation rules:

```text
amount > 0

category != nil

account != nil
```

Additional validation:

- Category type should match transaction type.
- Empty notes are allowed.
- Avoid floating-point money calculations; use `Decimal`.

The ViewModel should expose validation state instead of implementing validation directly inside the View.

---

# 17. Statistics Feature

Use **Swift Charts**.

Statistics may include:

```text
Monthly Income

Monthly Expenses

Expenses by Category

Expenses by Day

Spending Trend

Month-to-Month Comparison
```

Example category distribution:

```text
Food            40%
Shopping        25%
Transportation  15%
Bills           12%
Other            8%
```

The Statistics ViewModel should receive already processed Domain data from Use Cases whenever the transformation represents business logic.

Pure chart formatting may remain in Presentation.

---

# 18. Budget Feature

Users can create a monthly budget for an expense category.

Example:

```text
Food Budget

3,000,000 ₫ / month
```

Progress:

```text
Used

2,100,000 / 3,000,000

██████████████------ 70%
```

Important Use Cases:

```text
CreateBudgetUseCase
UpdateBudgetUseCase
DeleteBudgetUseCase
GetBudgetProgressUseCase
CheckBudgetLimitUseCase
```

Example warning rule:

```text
spent >= budget * 0.8
```

When the user reaches 80% of the monthly budget, the UI may show a warning.

When the user reaches or exceeds 100%, the UI should show an over-budget state.

The exact thresholds may later be configurable, but that is not required for the MVP.

---

# 19. SwiftData Persistence Models

SwiftData `@Model` types must exist only in the Data layer.

Example:

```swift
import SwiftData

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

Do not pass `TransactionEntity` into a ViewModel.

Always convert persistence models into Domain models.

```text
TransactionEntity
        ↓
      Mapper
        ↓
Transaction
```

The same rule applies to:

```text
CategoryEntity
AccountEntity
BudgetEntity
```

---

# 20. Mapper Layer

Mappers translate between Data and Domain representations.

Example:

```swift
extension TransactionEntity {

    func toDomain() throws -> Transaction {
        guard let transactionType = TransactionType(rawValue: type) else {
            throw DomainError.invalidTransactionType
        }

        return Transaction(
            id: id,
            amount: amount,
            type: transactionType,
            date: date,
            note: note,
            categoryID: categoryID,
            accountID: accountID
        )
    }
}
```

A reverse mapper should also exist when storing Domain objects:

```swift
extension Transaction {

    func toEntity() -> TransactionEntity {
        TransactionEntity(
            id: id,
            amount: amount,
            type: type.rawValue,
            date: date,
            note: note,
            categoryID: categoryID,
            accountID: accountID
        )
    }
}
```

If updating an existing SwiftData object, prefer an explicit update method rather than blindly creating another object with the same identifier.

---

# 21. Local Data Sources

Local Data Sources should isolate direct SwiftData operations.

Example protocol:

```swift
protocol TransactionLocalDataSource {
    func fetchAll() throws -> [TransactionEntity]
    func fetch(id: UUID) throws -> TransactionEntity?
    func insert(_ entity: TransactionEntity) throws
    func update(_ entity: TransactionEntity) throws
    func delete(id: UUID) throws
}
```

A concrete implementation may use `ModelContext`.

Conceptually:

```text
Repository Implementation
          ↓
 Local Data Source
          ↓
    ModelContext
          ↓
      SwiftData
```

This keeps persistence details out of repositories and makes the Data layer easier to test.

---

# 22. Error Handling

Define Domain-facing errors that communicate meaningful business failures.

Example:

```swift
enum DomainError: Error, Equatable {
    case invalidAmount
    case invalidTransactionType
    case accountNotFound
    case categoryNotFound
    case transactionNotFound
    case budgetNotFound
    case persistenceError
}
```

Data-specific errors may exist inside the Data layer but should be mapped to Domain errors before crossing the repository boundary.

ViewModels should translate errors into user-facing state.

Recommended UI states:

```text
idle

loading

content

empty

error
```

Avoid showing raw persistence or framework error descriptions directly to users.

---

# 23. ViewModel State

Each feature ViewModel should expose explicit state.

Example:

```swift
@MainActor
@Observable
final class TransactionListViewModel {

    enum State {
        case idle
        case loading
        case loaded([Transaction])
        case empty
        case error(String)
    }

    private(set) var state: State = .idle

    private let getTransactionsUseCase: GetTransactionsUseCase

    init(
        getTransactionsUseCase: GetTransactionsUseCase
    ) {
        self.getTransactionsUseCase = getTransactionsUseCase
    }
}
```

Use `@MainActor` for ViewModels that mutate UI-observed state.

Avoid storing duplicate sources of truth in both View and ViewModel.

---

# 24. Account Balance Rules

Account balance should be calculated as:

```text
accountBalance =
initialBalance
+ totalIncomeForAccount
- totalExpensesForAccount
```

Total application balance:

```text
totalBalance =
sum(all account balances)
```

Prefer calculating balances from transactions instead of storing a mutable balance field that can become inconsistent.

If performance later becomes a problem, derived values may be cached, but that is not part of the MVP.

---

# 25. Default Categories

On first launch, create default categories only if no category data exists.

Suggested expense categories:

```text
Food
Transportation
Shopping
Entertainment
Bills
Health
Education
Other
```

Suggested income categories:

```text
Salary
Bonus
Investment
Gift
Other Income
```

The seeding process should be idempotent.

Running it multiple times must not create duplicate categories.

---

# 26. Search and Filtering

Transaction search should support:

```text
Note
Category name
```

Filtering should support:

```text
Date range
Category
Account
Transaction type
```

For small local datasets, filtering may initially happen in memory after fetching.

If the dataset grows enough to affect performance, move filtering predicates closer to SwiftData queries inside the Data layer while preserving Domain boundaries.

---

# 27. Formatting

Create shared formatters rather than duplicating formatting logic.

Suggested utilities:

```text
CurrencyFormatter
DateFormatter
PercentageFormatter
```

Currency target:

```text
Vietnamese Dong (VND)
```

Example output:

```text
1,200,000 ₫
```

The app should support Vietnamese locale formatting where appropriate.

Formatting belongs in Presentation / Shared code, not in Domain entities.

---

# 28. Testing Strategy

Clean Architecture should allow business logic to be tested without SwiftData.

Create test doubles such as:

```text
MockTransactionRepository
MockAccountRepository
MockBudgetRepository
```

These mocks implement the Domain repository protocols.

## Priority Domain tests

```text
AddTransactionUseCaseTests
UpdateTransactionUseCaseTests
DeleteTransactionUseCaseTests
GetAccountBalanceUseCaseTests
GetBalanceUseCaseTests
GetMonthlySummaryUseCaseTests
GetExpenseByCategoryUseCaseTests
CheckBudgetLimitUseCaseTests
```

## Data tests

Test:

```text
Entity ↔ Domain mapping

Repository mapping behavior

SwiftData CRUD

Default category seeding

Persistence error mapping
```

Where possible, use an in-memory SwiftData configuration for persistence tests.

## Presentation tests

Test:

```text
ViewModel initial state

Loading state

Success state

Empty state

Error state

Validation state
```

UI tests should cover only critical user flows.

---

# 29. Development Roadmap

## Phase 1 — Foundation

### Tasks

- Create the Xcode project.
- Configure SwiftUI application entry point.
- Create project folder structure.
- Configure SwiftData.
- Create the `ModelContainer`.
- Create `AppContainer`.
- Establish Clean Architecture boundaries.
- Configure Dependency Injection.
- Add initial test targets / folders.

### Completion criteria

```text
App builds successfully

SwiftData container initializes

Dependency graph works

A simple local persistence smoke test passes
```

---

## Phase 2 — Transactions

### Implement

- `Transaction` Domain entity.
- `TransactionEntity` SwiftData model.
- Transaction mapper.
- `TransactionRepository` protocol.
- `TransactionLocalDataSource`.
- `TransactionRepositoryImpl`.
- Transaction CRUD Use Cases.
- `TransactionListViewModel`.
- `TransactionListView`.
- `AddTransactionViewModel`.
- `AddTransactionView`.
- Edit transaction flow.
- Delete confirmation.

### Completion criteria

```text
Create
Read
Update
Delete
```

must work end-to-end with local persistence.

---

## Phase 3 — Categories

### Implement

```text
Category Domain entity

CategoryEntity

Category Mapper

CategoryRepository

CategoryLocalDataSource

CategoryRepositoryImpl

Category CRUD Use Cases

Default Category Seeder
```

Default categories must be created only once.

---

## Phase 4 — Accounts

### Implement

```text
Account Domain entity

AccountEntity

Account Mapper

AccountRepository

Account CRUD

GetAccountBalanceUseCase
```

Business rule:

```text
balance =
initialBalance
+ income
- expenses
```

---

## Phase 5 — Dashboard

### Implement

Use Cases:

```text
GetBalanceUseCase

GetMonthlySummaryUseCase

GetMonthlyIncomeUseCase

GetMonthlyExpenseUseCase

GetRecentTransactionsUseCase
```

Build the Dashboard UI after the necessary Domain APIs are stable.

---

## Phase 6 — Statistics

### Implement

Use Cases:

```text
GetExpenseByCategoryUseCase

GetMonthlySummaryUseCase

GetDailyExpenseUseCase
```

Use:

```text
Swift Charts
```

Keep chart-specific formatting in Presentation.

---

## Phase 7 — Budgets

### Implement

```text
Budget Domain Entity

BudgetEntity

Budget Mapper

BudgetRepository

Budget CRUD

Budget Progress

Budget Warning
```

Include unit tests for budget warning thresholds.

---

## Phase 8 — Search and Filters

Implement filters for:

```text
Date

Category

Account

Transaction Type
```

Implement search for:

```text
Note

Category Name
```

---

## Phase 9 — UX Polish

Improve:

- Dark Mode
- Empty states
- Loading states
- Error states
- Animations
- Swipe to delete
- Confirmation dialogs
- Haptic feedback
- Currency formatting
- Vietnamese locale support
- Date formatting
- Accessibility labels
- Dynamic Type support

---

## Phase 10 — Testing and Refactoring

Add / complete:

```text
Domain Unit Tests

Repository Tests

Persistence Tests

ViewModel Tests

Critical UI Tests
```

Target:

```text
High coverage for Domain business logic
```

A useful goal is more than 80% coverage for critical Domain logic, but correctness is more important than chasing an arbitrary percentage.

Refactor only after major flows are covered by tests.

---

# 30. Implementation Priority

Do not build every feature at the same time.

Recommended order:

```text
1. Architecture Foundation
      ↓
2. Transaction CRUD
      ↓
3. Categories
      ↓
4. Accounts
      ↓
5. Dashboard
      ↓
6. Statistics
      ↓
7. Budgets
      ↓
8. Search / Filters
      ↓
9. UX Polish
      ↓
10. Testing / Refactoring
```

Testing should still be added incrementally during each phase; Phase 10 is for completing coverage and refactoring.

---

# 31. MVP Scope

Version 1.0 should include:

```text
Transaction CRUD

Categories

Accounts

Dashboard

Statistics

SwiftData Local Storage
```

Optional for version 1.0 if time allows:

```text
Budgets

Search

Advanced Filters
```

Do not include in the MVP:

```text
Login

Backend

CloudKit

Firebase

Remote API

AI

OCR

iCloud Sync

Cross-device Sync
```

---

# 32. Final MVP Architecture

```text
                  SwiftUI View
                       │
                       ↓
                   ViewModel
                       │
                       ↓
                    Use Case
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

# 33. Coding Rules by Layer

## View

A View may:

```text
Render UI

Observe UI State

Send User Actions

Handle purely visual formatting
```

A View must not:

```text
Query SwiftData

Use ModelContext directly

Contain business calculations

Call Repositories

Instantiate Use Cases

Implement persistence logic
```

---

## ViewModel

A ViewModel may:

```text
Manage UI State

Call Use Cases

Validate presentation input when appropriate

Coordinate user interactions

Map Domain results into display state
```

A ViewModel must not:

```text
Import SwiftData

Use ModelContext

Query persistence directly

Know about SwiftData entities
```

---

## Use Case

A Use Case contains application-specific business logic.

Examples:

```text
AddTransactionUseCase

GetMonthlyExpenseUseCase

GetAccountBalanceUseCase

CheckBudgetLimitUseCase
```

Use Cases depend on Domain repository protocols.

---

## Repository Protocol

A repository defines how the Domain requests data.

Domain knows:

```text
TransactionRepository
```

Domain does not know:

```text
TransactionRepositoryImpl

SwiftData

ModelContext
```

---

## Repository Implementation

A repository implementation belongs to Data.

It may:

```text
Call Local Data Sources

Map Data models into Domain entities

Map Domain entities into Data models

Translate persistence errors
```

It must satisfy the corresponding Domain repository protocol.

---

## Local Data Source

A Local Data Source is the lowest application-owned persistence abstraction.

It may:

```text
Use SwiftData

Use ModelContext

Use FetchDescriptor

Insert models

Delete models

Save changes
```

It must not expose SwiftData entities outside the Data layer.

---

# 34. Import / Dependency Rules

## Domain

Allowed:

```swift
import Foundation
```

Do not import:

```swift
import SwiftUI
import SwiftData
```

---

## Data

Expected:

```swift
import Foundation
import SwiftData
```

Data also depends on Domain types.

---

## Presentation

Expected:

```swift
import SwiftUI
import Observation
```

Presentation depends on Domain APIs.

Presentation must not depend on Data implementation details.

---

# 35. Money Handling

Use:

```swift
Decimal
```

for monetary values.

Avoid:

```swift
Double
Float
```

for financial calculations.

Example:

```swift
let amount: Decimal = 125_000
```

Create dedicated formatting utilities for UI display.

Do not store formatted strings as monetary values.

---

# 36. Date Handling

Use `Date` for persisted dates.

For monthly calculations:

- Define a consistent calendar.
- Determine the start and end of the selected month.
- Filter transactions within that range.
- Do not compare formatted date strings.

Date formatting is a Presentation concern.

---

# 37. Concurrency Rules

Use Swift Concurrency where it improves API consistency and future flexibility.

Repository interfaces may use:

```swift
async throws
```

even though the first persistence implementation is local.

UI-observed ViewModels should generally be:

```swift
@MainActor
```

Avoid unnecessary `Task.detached`.

Do not introduce actors unless shared mutable state requires them.

---

# 38. Data Integrity Rules

The implementation should protect against:

- Transactions referencing missing accounts.
- Transactions referencing missing categories.
- Negative or zero transaction amounts.
- Duplicate seeded categories.
- Budgets referencing invalid categories.
- Deleting accounts or categories that are still required by transactions without a defined policy.

Before implementing destructive deletion for categories/accounts, choose one explicit policy:

```text
A. Prevent deletion while referenced

or

B. Reassign existing transactions to a fallback category/account
```

For the MVP, prefer:

```text
Prevent deletion while referenced
```

because it is simpler and safer.

---

# 39. Suggested Domain Error Cases

```swift
enum DomainError: Error, Equatable {
    case invalidAmount
    case invalidTransactionType
    case accountNotFound
    case categoryNotFound
    case transactionNotFound
    case budgetNotFound
    case accountIsInUse
    case categoryIsInUse
    case duplicateBudget
    case persistenceError
}
```

Add more cases only when they represent meaningful application behavior.

---

# 40. Definition of Done for a Feature

A feature is considered complete when:

- The UI works for the intended flow.
- Business logic is implemented in Domain / Use Cases.
- The ViewModel does not access persistence directly.
- Dependencies are injected.
- SwiftData models remain inside Data.
- Errors are handled.
- Empty state is handled where relevant.
- Loading state is handled where relevant.
- Important business behavior has unit tests.
- The feature works after relaunching the app when persistence is expected.
- The project builds without serious warnings.
- No architectural dependency rules are violated.

---

# 41. Suggested First Implementation Milestone

The first implementation milestone should be intentionally small.

Build only:

```text
AppContainer

SwiftData setup

Transaction Domain Entity

TransactionEntity

Transaction Mapper

Transaction Repository Protocol

Transaction Local Data Source

Transaction Repository Implementation

AddTransactionUseCase

GetTransactionsUseCase

AddTransactionViewModel

TransactionListViewModel

AddTransactionView

TransactionListView
```

Goal:

```text
User can add an expense locally

App can be closed and reopened

The expense is still available

The View layer never accesses SwiftData directly
```

Do not implement Dashboard, Charts, Budgets, or advanced filters until this vertical slice works.

---

# 42. Recommended Vertical Slice Strategy

Implement features as complete vertical slices instead of creating all entities first.

Example:

```text
Transaction Domain Model
        ↓
Repository Protocol
        ↓
Data Model
        ↓
Local Data Source
        ↓
Repository Implementation
        ↓
Use Case
        ↓
ViewModel
        ↓
View
        ↓
Tests
```

Then repeat the same pattern for:

```text
Category
Account
Budget
```

This approach allows the architecture to be validated early.

---

# 43. Non-Goals

The following are explicitly outside the current project scope:

- User registration.
- User login.
- Cloud synchronization.
- Multi-device synchronization.
- Social features.
- Shared family accounts.
- Bank API integrations.
- Receipt OCR.
- AI categorization.
- Web application.
- Android application.
- Remote analytics backend.
- Push notifications from a server.

These may be considered in future versions but must not influence the MVP architecture unnecessarily.

---

# 44. Expected Final Technology Combination

The final application should use:

```text
Swift
+
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

The application should remain:

- 100% local.
- Backend-free.
- Authentication-free.
- Easy to unit test.
- Explicitly separated by responsibility.
- Independent of SwiftData at the Domain level.
- Structured so that persistence could be replaced later without rewriting the Domain or Presentation layers.
- Suitable as a real-world iOS architecture learning project.
- Suitable as a portfolio project.

---

# 45. Final Instruction to the Coding Agent

Implement this project incrementally.

Do not generate the entire application in one step.

For each feature:

1. Start with Domain models and repository contracts.
2. Add the Data implementation.
3. Add Use Cases.
4. Add ViewModels.
5. Add SwiftUI Views.
6. Add tests.
7. Build and verify the feature before moving to the next vertical slice.

Always preserve the dependency rule:

```text
Presentation → Domain ← Data
```

Never allow:

```text
Presentation → SwiftData
```

or:

```text
Domain → SwiftData
```

The first priority is architectural correctness and a working local transaction CRUD flow. Advanced UI and secondary features should come later.
