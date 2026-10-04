import Foundation

struct APIEnvelopeResponse<Payload: Decodable>: Decodable {
    let statusCode: Int
    let message: String
    let data: Payload
}

struct APIErrorResponse: Decodable {
    let statusCode: Int?
    let errorCode: String?
    let message: String?
}

struct AuthUserResponse: Decodable {
    let id: Int
    let email: String
    let createdAt: String
}

struct CurrentUserResponse: Decodable {
    let id: Int
    let email: String
    let createdAt: String
    let updatedAt: String
}

struct TokenPairResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}

struct AuthResultResponse: Decodable {
    let user: AuthUserResponse
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

struct CategoryResponse: Decodable {
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

struct ExpenseCategoryResponse: Decodable {
    let id: Int
    let name: String
    let isDefault: Bool
    let type: String
}

struct ExpenseResponse: Decodable {
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
    let category: ExpenseCategoryResponse
}

struct ExpensePageResponse: Decodable {
    struct Pagination: Decodable {
        let page: Int
        let limit: Int
        let total: Int
        let totalPages: Int
    }

    let items: [ExpenseResponse]
    let pagination: Pagination
}

struct ExpenseTrendItemResponse: Decodable {
    let date: String
    let amount: String
}

struct ExpenseTrendResponse: Decodable {
    let type: String
    let period: String
    let granularity: String
    let from: String
    let to: String
    let items: [ExpenseTrendItemResponse]
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

struct DashboardSummaryResponse: Decodable {
    let month: String
    let totalBalance: String
    let monthlyIncome: String
    let monthlyExpense: String
    let monthlyBalance: String
}

struct AccountResponse: Decodable {
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

struct BudgetResponse: Decodable {
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

struct APIEmptyResponse: Decodable {}
