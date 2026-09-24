import Foundation

struct APIEnvelope<Payload: Decodable>: Decodable {
    let statusCode: Int
    let message: String
    let data: Payload
}

struct APIErrorPayload: Decodable {
    let statusCode: Int?
    let errorCode: String?
    let message: String?
}

struct AuthUserDTO: Decodable {
    let id: Int
    let email: String
    let createdAt: String
}

struct CurrentUserDTO: Decodable {
    let id: Int
    let email: String
    let createdAt: String
    let updatedAt: String
}

struct TokenPairDTO: Decodable {
    let accessToken: String
    let refreshToken: String
}

struct AuthResultDTO: Decodable {
    let user: AuthUserDTO
    let accessToken: String
    let refreshToken: String
}

struct CredentialsRequest: Encodable {
    let email: String
    let password: String
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

struct CategoryDTO: Decodable {
    let id: Int
    let name: String
    let colorHex: String?
    let isDefault: Bool
    let type: String
    let userId: Int?
    let createdAt: String
    let updatedAt: String
}

struct CreateCategoryRequest: Encodable {
    let name: String
    let type: String
    let colorHex: String
}

struct UpdateCategoryRequest: Encodable {
    let name: String
    let colorHex: String
}

struct ExpenseCategoryDTO: Decodable {
    let id: Int
    let name: String
    let isDefault: Bool
    let type: String
}

struct ExpenseDTO: Decodable {
    let id: Int
    let userId: Int
    let categoryId: Int
    let type: String
    let title: String
    let amount: String
    let transactionDate: String
    let location: String?
    let notes: String?
    let createdAt: String
    let updatedAt: String
    let category: ExpenseCategoryDTO
}

struct ExpensePageDTO: Decodable {
    struct Pagination: Decodable {
        let page: Int
        let limit: Int
        let total: Int
        let totalPages: Int
    }

    let items: [ExpenseDTO]
    let pagination: Pagination
}

struct ExpenseTrendItemDTO: Decodable {
    let date: String
    let amount: String
}

struct ExpenseTrendDTO: Decodable {
    let type: String
    let period: String
    let granularity: String
    let from: String
    let to: String
    let items: [ExpenseTrendItemDTO]
}

struct SaveExpenseRequest: Encodable {
    let type: String
    let title: String
    let amount: Decimal
    let transactionDate: String
    let categoryId: Int
    let location: String?
    let notes: String?
}

struct DashboardSummaryDTO: Decodable {
    let month: String
    let totalBalance: String
    let monthlyIncome: String
    let monthlyExpense: String
    let monthlyBalance: String
}

struct AccountDTO: Decodable {
    let id: Int
    let userId: Int
    let name: String
    let type: String
    let initialBalance: String
    let isDefault: Bool
    let createdAt: String
    let updatedAt: String
}

struct CreateAccountRequest: Encodable {
    let name: String
    let type: String
    let initialBalance: Decimal
}

struct UpdateAccountRequest: Encodable {
    let name: String
    let initialBalance: Decimal
}

struct BudgetDTO: Decodable {
    struct Category: Decodable {
        let userId: Int?
        let isDefault: Bool
    }

    let id: Int
    let userId: Int
    let categoryId: Int
    let amount: String
    let month: String
    let category: Category
    let createdAt: String
    let updatedAt: String
}

struct SaveBudgetRequest: Encodable {
    let categoryId: Int
    let amount: Decimal
    let month: String
}

struct APIEmpty: Decodable {}
