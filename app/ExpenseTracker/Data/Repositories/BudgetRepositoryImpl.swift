import Foundation

@MainActor
final class BudgetRepositoryImpl: BudgetRepository {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func getBudgets() async throws -> [Budget] {
        do {
            let values: [BudgetDTO] = try await api.get("/budgets")
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
            let _: BudgetDTO = try await api.post(
                "/budgets",
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
            let _: BudgetDTO = try await api.patch(
                "/budgets/\(budgetID)",
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
            let _: APIEmpty? = try await api.delete("/budgets/\(budgetID)")
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    private func map(_ dto: BudgetDTO) throws -> Budget {
        guard let amount = Decimal(
            string: dto.amount,
            locale: Locale(identifier: "en_US_POSIX")
        ), let month = DateParser.date(from: dto.month) else {
            throw DomainError.remoteError("Dữ liệu ngân sách từ máy chủ không hợp lệ.")
        }
        return Budget(
            id: ServerIDCodec.budgetUUID(id: dto.id, userID: dto.userId),
            categoryID: ServerIDCodec.categoryUUID(
                id: dto.categoryId,
                userID: dto.category.isDefault ? nil : dto.category.userId
            ),
            amount: amount,
            month: month
        )
    }
}
