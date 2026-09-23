import Foundation

@MainActor
final class RemoteTransactionRepository: TransactionRepository {
    private let api: APIClient
    private let accounts: any AccountRepository
    private let metadata: RemoteMetadataStore

    init(
        api: APIClient,
        accounts: any AccountRepository,
        metadata: RemoteMetadataStore
    ) {
        self.api = api
        self.accounts = accounts
        self.metadata = metadata
    }

    func getTransactions() async throws -> [ExpenseTransaction] {
        do {
            var page = 1
            var values: [RemoteExpenseDTO] = []
            var totalPages = 1

            repeat {
                let result: ExpensePageDTO = try await api.get(
                    "/transactions",
                    queryItems: [
                        URLQueryItem(name: "page", value: String(page)),
                        URLQueryItem(name: "limit", value: "100"),
                        URLQueryItem(name: "sortBy", value: "transactionDate"),
                        URLQueryItem(name: "sortOrder", value: "desc")
                    ]
                )
                values.append(contentsOf: result.items)
                totalPages = result.pagination.totalPages
                page += 1
            } while page <= totalPages

            let fallbackAccountID = try await defaultAccountID()
            return try values.map { try map($0, fallbackAccountID: fallbackAccountID) }
        } catch {
            throw RemoteErrorMapper.map(error)
        }
    }

    func getTransaction(id: UUID) async throws -> ExpenseTransaction? {
        guard let serverID = ServerIDCodec.expenseID(from: id) else { return nil }
        do {
            let value: RemoteExpenseDTO = try await api.get("/transactions/\(serverID)")
            return try map(value, fallbackAccountID: try await defaultAccountID())
        } catch {
            let mapped = RemoteErrorMapper.map(error)
            if mapped == .transactionNotFound { return nil }
            throw mapped
        }
    }

    func addTransaction(_ transaction: ExpenseTransaction) async throws {
        do {
            let created: RemoteExpenseDTO = try await api.post(
                "/transactions",
                body: try request(from: transaction)
            )
            metadata.saveAccountID(
                transaction.accountID,
                userID: created.userId,
                expenseID: created.id
            )
        } catch {
            throw RemoteErrorMapper.map(error)
        }
    }

    func updateTransaction(_ transaction: ExpenseTransaction) async throws {
        guard let serverID = ServerIDCodec.expenseID(from: transaction.id) else {
            throw DomainError.transactionNotFound
        }
        do {
            let updated: RemoteExpenseDTO = try await api.patch(
                "/transactions/\(serverID)",
                body: try request(from: transaction)
            )
            metadata.saveAccountID(
                transaction.accountID,
                userID: updated.userId,
                expenseID: updated.id
            )
        } catch {
            throw RemoteErrorMapper.map(error)
        }
    }

    func deleteTransaction(id: UUID) async throws {
        guard let serverID = ServerIDCodec.expenseID(from: id) else {
            throw DomainError.transactionNotFound
        }
        do {
            let _: APIEmpty? = try await api.delete("/transactions/\(serverID)")
            metadata.removeAccountID(
                userID: ServerIDCodec.userID(from: id),
                expenseID: serverID
            )
        } catch {
            throw RemoteErrorMapper.map(error)
        }
    }

    private func map(
        _ dto: RemoteExpenseDTO,
        fallbackAccountID: UUID
    ) throws -> ExpenseTransaction {
        guard let amount = Decimal(
            string: dto.amount,
            locale: Locale(identifier: "en_US_POSIX")
        ), let date = RemoteDateParser.date(from: dto.transactionDate),
           let type = TransactionType(rawValue: dto.type),
           dto.category.type == dto.type else {
            throw DomainError.remoteError("Dữ liệu giao dịch từ máy chủ không hợp lệ.")
        }
        let categoryUserID = dto.category.isDefault ? nil : dto.userId
        return ExpenseTransaction(
            id: ServerIDCodec.expenseUUID(id: dto.id, userID: dto.userId),
            amount: amount,
            type: type,
            date: date,
            note: dto.notes ?? dto.title,
            categoryID: ServerIDCodec.categoryUUID(
                id: dto.categoryId,
                userID: categoryUserID
            ),
            accountID: metadata.accountID(userID: dto.userId, expenseID: dto.id)
                ?? fallbackAccountID
        )
    }

    private func request(from transaction: ExpenseTransaction) throws -> SaveExpenseRequest {
        guard let categoryID = ServerIDCodec.categoryID(from: transaction.categoryID) else {
            throw DomainError.categoryNotFound
        }
        let trimmedNote = transaction.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = trimmedNote?.isEmpty == false ? trimmedNote : nil
        return SaveExpenseRequest(
            type: transaction.type.rawValue,
            title: note ?? (transaction.type == .income ? "Khoản thu" : "Khoản chi"),
            amount: transaction.amount,
            transactionDate: RemoteDateParser.calendarDate(from: transaction.date),
            categoryId: categoryID,
            location: nil,
            // The API uses an empty string to clear an existing optional note.
            notes: note ?? ""
        )
    }

    private func defaultAccountID() async throws -> UUID {
        let availableAccounts = try await accounts.getAccounts()
        guard let id = availableAccounts.first(where: { $0.name == "Tiền mặt" })?.id
                ?? availableAccounts.first?.id else {
            throw DomainError.accountNotFound
        }
        return id
    }
}
