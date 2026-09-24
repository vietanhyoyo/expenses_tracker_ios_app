import Foundation

@MainActor
final class TransactionRepositoryImpl: TransactionRepository {
    private let api: APIClient
    private let accounts: any AccountRepository
    private let metadata: MetadataStore

    init(
        api: APIClient,
        accounts: any AccountRepository,
        metadata: MetadataStore
    ) {
        self.api = api
        self.accounts = accounts
        self.metadata = metadata
    }

    func getTransactions() async throws -> [ExpenseTransaction] {
        try await getTransactions(from: nil, to: nil, type: nil, categoryID: nil)
    }

    func getTransactions(
        from startDate: Date?,
        to endDate: Date?,
        type: TransactionType?,
        categoryID: UUID?
    ) async throws -> [ExpenseTransaction] {
        do {
            var page = 1
            var values: [ExpenseDTO] = []
            var totalPages = 1

            var queryItems = [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "sortBy", value: "transactionDate"),
                URLQueryItem(name: "sortOrder", value: "desc")
            ]
            if let startDate {
                queryItems.append(URLQueryItem(
                    name: "from",
                    value: DateParser.calendarDate(from: startDate)
                ))
            }
            if let endDate {
                queryItems.append(URLQueryItem(
                    name: "to",
                    value: DateParser.calendarDate(from: endDate)
                ))
            }
            if let type {
                queryItems.append(URLQueryItem(name: "type", value: type.rawValue))
            }
            if let categoryID,
               let serverCategoryID = ServerIDCodec.categoryID(from: categoryID) {
                queryItems.append(URLQueryItem(
                    name: "categoryId",
                    value: String(serverCategoryID)
                ))
            }

            repeat {
                queryItems[0] = URLQueryItem(name: "page", value: String(page))
                let result: ExpensePageDTO = try await api.get(
                    "/transactions",
                    queryItems: queryItems
                )
                values.append(contentsOf: result.items)
                totalPages = result.pagination.totalPages
                page += 1
            } while page <= totalPages

            let fallbackAccountID = try await defaultAccountID()
            return try values.map { try map($0, fallbackAccountID: fallbackAccountID) }
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    func getSpendingTrend(
        period: String,
        type: TransactionType,
        date: Date,
        calendar: Calendar
    ) async throws -> [DailySpending] {
        do {
            let result: ExpenseTrendDTO = try await api.get(
                "/transactions/trend",
                queryItems: [
                    URLQueryItem(name: "period", value: period),
                    URLQueryItem(name: "type", value: type.rawValue),
                    URLQueryItem(
                        name: "date",
                        value: DateParser.calendarDate(from: date)
                    )
                ]
            )
            return try result.items.map { item in
                guard let amount = Decimal(
                    string: item.amount,
                    locale: Locale(identifier: "en_US_POSIX")
                ), let date = DateParser.calendarDateValue(from: item.date) else {
                    throw DomainError.remoteError("Dữ liệu xu hướng giao dịch không hợp lệ.")
                }
                return DailySpending(date: date, amount: amount)
            }
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    func getTransaction(id: UUID) async throws -> ExpenseTransaction? {
        guard let serverID = ServerIDCodec.expenseID(from: id) else { return nil }
        do {
            let value: ExpenseDTO = try await api.get("/transactions/\(serverID)")
            return try map(value, fallbackAccountID: try await defaultAccountID())
        } catch {
            let mapped = ErrorMapper.map(error)
            if mapped == .transactionNotFound { return nil }
            throw mapped
        }
    }

    func addTransaction(_ transaction: ExpenseTransaction) async throws {
        do {
            let created: ExpenseDTO = try await api.post(
                "/transactions",
                body: try request(from: transaction)
            )
            metadata.saveAccountID(
                transaction.accountID,
                userID: created.userId,
                expenseID: created.id
            )
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    func updateTransaction(_ transaction: ExpenseTransaction) async throws {
        guard let serverID = ServerIDCodec.expenseID(from: transaction.id) else {
            throw DomainError.transactionNotFound
        }
        do {
            let updated: ExpenseDTO = try await api.patch(
                "/transactions/\(serverID)",
                body: try request(from: transaction)
            )
            metadata.saveAccountID(
                transaction.accountID,
                userID: updated.userId,
                expenseID: updated.id
            )
        } catch {
            throw ErrorMapper.map(error)
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
            throw ErrorMapper.map(error)
        }
    }

    private func map(
        _ dto: ExpenseDTO,
        fallbackAccountID: UUID
    ) throws -> ExpenseTransaction {
        guard let amount = Decimal(
            string: dto.amount,
            locale: Locale(identifier: "en_US_POSIX")
        ), let date = DateParser.date(from: dto.transactionDate),
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
            transactionDate: DateParser.calendarDate(from: transaction.date),
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
