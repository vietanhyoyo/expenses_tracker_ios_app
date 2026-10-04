import Foundation

@MainActor
final class CategoryRepositoryImpl: CategoryRepository {
    private let api: APIClient
    private let metadata: MetadataStore

    init(api: APIClient, metadata: MetadataStore) {
        self.api = api
        self.metadata = metadata
    }

    func getCategories() async throws -> [ExpenseCategory] {
        do {
            let values: [CategoryResponse] = try await api.get(APIEndpoints.Categories.collection)
            return try values.map(map)
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    func addCategory(_ category: ExpenseCategory) async throws {
        do {
            let created: CategoryResponse = try await api.post(
                APIEndpoints.Categories.collection,
                body: CreateCategoryRequest(
                    name: category.name,
                    type: category.type.rawValue,
                    colorHex: category.colorHex
                )
            )
            saveAppearance(of: category, for: created)
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    func updateCategory(_ category: ExpenseCategory) async throws {
        guard category.isEditable else { throw DomainError.categoryNotEditable }
        guard let id = ServerIDCodec.categoryID(from: category.id) else {
            throw DomainError.categoryNotFound
        }
        do {
            let updated: CategoryResponse = try await api.patch(
                APIEndpoints.Categories.detail(id: id),
                body: UpdateCategoryRequest(
                    name: category.name,
                    colorHex: category.colorHex
                )
            )
            saveAppearance(of: category, for: updated)
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    func deleteCategory(id: UUID, replacementID: UUID) async throws {
        guard let serverID = ServerIDCodec.categoryID(from: id) else {
            throw DomainError.categoryNotFound
        }
        guard let replacementServerID = ServerIDCodec.categoryID(from: replacementID) else {
            throw DomainError.invalidCategoryReplacement
        }
        do {
            let _: APIEmptyResponse? = try await api.delete(
                APIEndpoints.Categories.detail(id: serverID),
                queryItems: [
                    URLQueryItem(
                        name: "replacementCategoryId",
                        value: String(replacementServerID)
                    )
                ]
            )
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    private func map(_ response: CategoryResponse) throws -> ExpenseCategory {
        guard let type = TransactionType(rawValue: response.type) else {
            throw DomainError.invalidTransactionType
        }
        let appearance = metadata.appearance(userID: response.userId, categoryID: response.id)
        return ExpenseCategory(
            id: ServerIDCodec.categoryUUID(id: response.id, userID: response.userId),
            name: response.name,
            icon: appearance?.icon ?? defaultIcon(for: response.name),
            type: type,
            colorHex: response.colorHex
                ?? appearance?.colorHex
                ?? defaultColor(for: response.id, type: type),
            isEditable: !response.isDefault
        )
    }

    private func saveAppearance(of category: ExpenseCategory, for response: CategoryResponse) {
        metadata.saveAppearance(
            .init(icon: category.icon, colorHex: category.colorHex),
            userID: response.userId,
            categoryID: response.id
        )
    }

    private func defaultIcon(for name: String) -> String {
        let normalized = name.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "vi_VN")
        )
        if normalized.contains("food") || normalized.contains("an uong") { return "fork.knife" }
        if normalized.contains("transport") || normalized.contains("di chuyen") { return "car.fill" }
        if normalized.contains("shopping") || normalized.contains("mua sam") { return "bag.fill" }
        if normalized.contains("health") || normalized.contains("suc khoe") { return "cross.case.fill" }
        if normalized.contains("education") || normalized.contains("giao duc") { return "book.fill" }
        if normalized.contains("bill") || normalized.contains("hoa don") { return "doc.text.fill" }
        if normalized.contains("entertainment") || normalized.contains("giai tri") { return "gamecontroller.fill" }
        if normalized.contains("salary") || normalized.contains("luong") { return "banknote.fill" }
        if normalized.contains("bonus") || normalized.contains("thuong") { return "gift.fill" }
        if normalized.contains("investment") || normalized.contains("dau tu") { return "chart.line.uptrend.xyaxis" }
        return "square.grid.2x2.fill"
    }

    private func defaultColor(for id: Int, type: TransactionType) -> String {
        if type == .income {
            let palette = ["#10B981", "#F59E0B", "#0EA5E9", "#8B5CF6"]
            return palette[abs(id) % palette.count]
        }
        let palette = ["#FF5D73", "#3B82F6", "#A855F7", "#EC4899", "#F59E0B", "#EF4444", "#14B8A6", "#64748B"]
        return palette[abs(id) % palette.count]
    }
}
