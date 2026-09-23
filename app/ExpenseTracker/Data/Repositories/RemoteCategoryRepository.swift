import Foundation

@MainActor
final class RemoteCategoryRepository: CategoryRepository {
    private let api: APIClient
    private let metadata: RemoteMetadataStore

    init(api: APIClient, metadata: RemoteMetadataStore) {
        self.api = api
        self.metadata = metadata
    }

    func getCategories() async throws -> [ExpenseCategory] {
        do {
            let values: [RemoteCategoryDTO] = try await api.get("/categories")
            return try values.map(map)
        } catch {
            throw RemoteErrorMapper.map(error)
        }
    }

    func addCategory(_ category: ExpenseCategory) async throws {
        do {
            let created: RemoteCategoryDTO = try await api.post(
                "/categories",
                body: CreateCategoryRequest(
                    name: category.name,
                    type: category.type.rawValue,
                    colorHex: category.colorHex
                )
            )
            saveAppearance(of: category, for: created)
        } catch {
            throw RemoteErrorMapper.map(error)
        }
    }

    func updateCategory(_ category: ExpenseCategory) async throws {
        guard category.isEditable else { throw DomainError.categoryNotEditable }
        guard let id = ServerIDCodec.categoryID(from: category.id) else {
            throw DomainError.categoryNotFound
        }
        do {
            let updated: RemoteCategoryDTO = try await api.patch(
                "/categories/\(id)",
                body: UpdateCategoryRequest(
                    name: category.name,
                    colorHex: category.colorHex
                )
            )
            saveAppearance(of: category, for: updated)
        } catch {
            throw RemoteErrorMapper.map(error)
        }
    }

    func deleteCategory(id: UUID) async throws {
        guard let serverID = ServerIDCodec.categoryID(from: id) else {
            throw DomainError.categoryNotFound
        }
        do {
            let _: APIEmpty? = try await api.delete("/categories/\(serverID)")
        } catch {
            throw RemoteErrorMapper.map(error)
        }
    }

    private func map(_ dto: RemoteCategoryDTO) throws -> ExpenseCategory {
        guard let type = TransactionType(rawValue: dto.type) else {
            throw DomainError.invalidTransactionType
        }
        let appearance = metadata.appearance(userID: dto.userId, categoryID: dto.id)
        return ExpenseCategory(
            id: ServerIDCodec.categoryUUID(id: dto.id, userID: dto.userId),
            name: dto.name,
            icon: appearance?.icon ?? defaultIcon(for: dto.name),
            type: type,
            colorHex: dto.colorHex
                ?? appearance?.colorHex
                ?? defaultColor(for: dto.id, type: type),
            isEditable: !dto.isDefault
        )
    }

    private func saveAppearance(of category: ExpenseCategory, for dto: RemoteCategoryDTO) {
        metadata.saveAppearance(
            .init(icon: category.icon, colorHex: category.colorHex),
            userID: dto.userId,
            categoryID: dto.id
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
