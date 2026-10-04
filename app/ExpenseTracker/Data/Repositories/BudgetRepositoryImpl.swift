import Foundation

@MainActor
final class BudgetRepositoryImpl: BudgetRepository {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func getBudgets() async throws -> [Budget] {
        do {
            let values: [BudgetResponse] = try await api.get(APIEndpoints.Budgets.collection)
            return try values.map(map)
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    func addBudget(_ budget: Budget) async throws {
        guard let categoryID = ServerIDCodec.categoryID(from: budget.categoryID) else {
            throw DomainError.categoryNotFound
        }
        do {
            let _: BudgetResponse = try await api.post(
                APIEndpoints.Budgets.collection,
                body: SaveBudgetRequest(
                    categoryId: categoryID,
                    amount: budget.amount,
                    month: DateParser.calendarDate(from: budget.month)
                )
            )
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    func updateBudget(_ budget: Budget) async throws {
        guard let budgetID = ServerIDCodec.budgetID(from: budget.id) else {
            throw DomainError.budgetNotFound
        }
        guard let categoryID = ServerIDCodec.categoryID(from: budget.categoryID) else {
            throw DomainError.categoryNotFound
        }
        do {
            let _: BudgetResponse = try await api.patch(
                APIEndpoints.Budgets.detail(id: budgetID),
                body: SaveBudgetRequest(
                    categoryId: categoryID,
                    amount: budget.amount,
                    month: DateParser.calendarDate(from: budget.month)
                )
            )
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    func deleteBudget(id: UUID) async throws {
        guard let budgetID = ServerIDCodec.budgetID(from: id) else {
            throw DomainError.budgetNotFound
        }
        do {
            let _: APIEmptyResponse? = try await api.delete(APIEndpoints.Budgets.detail(id: budgetID))
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    private func map(_ response: BudgetResponse) throws -> Budget {
        guard let amount = Decimal(
            string: response.amount,
            locale: Locale(identifier: "en_US_POSIX")
        ), let month = DateParser.date(from: response.month) else {
            throw DomainError.remoteError("Dữ liệu ngân sách từ máy chủ không hợp lệ.")
        }
        return Budget(
            id: ServerIDCodec.budgetUUID(id: response.id, userID: response.userId),
            categoryID: ServerIDCodec.categoryUUID(
                id: response.categoryId,
                userID: response.category.isDefault ? nil : response.category.userId
            ),
            amount: amount,
            month: month
        )
    }
}
