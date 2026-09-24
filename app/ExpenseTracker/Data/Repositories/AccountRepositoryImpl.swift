import Foundation

@MainActor
final class AccountRepositoryImpl: AccountRepository {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func getAccounts() async throws -> [Account] {
        do {
            let values: [AccountDTO] = try await api.get("/accounts")
            return try values.map(map)
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    func addAccount(_ account: Account) async throws {
        do {
            let _: AccountDTO = try await api.post(
                "/accounts",
                body: CreateAccountRequest(
                    name: account.name,
                    type: "cash",
                    initialBalance: account.initialBalance
                )
            )
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    func updateAccount(_ account: Account) async throws {
        guard let serverID = ServerIDCodec.accountID(from: account.id) else {
            throw DomainError.accountNotFound
        }
        do {
            let _: AccountDTO = try await api.patch(
                "/accounts/\(serverID)",
                body: UpdateAccountRequest(
                    name: account.name,
                    initialBalance: account.initialBalance
                )
            )
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    func deleteAccount(id: UUID) async throws {
        guard let serverID = ServerIDCodec.accountID(from: id) else {
            throw DomainError.accountNotFound
        }
        do {
            let _: APIEmpty? = try await api.delete("/accounts/\(serverID)")
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    private func map(_ dto: AccountDTO) throws -> Account {
        guard let initialBalance = Decimal(
            string: dto.initialBalance,
            locale: Locale(identifier: "en_US_POSIX")
        ) else {
            throw DomainError.remoteError("Dữ liệu tài khoản từ máy chủ không hợp lệ.")
        }
        return Account(
            id: ServerIDCodec.accountUUID(id: dto.id, userID: dto.userId),
            name: dto.name,
            initialBalance: initialBalance
        )
    }
}
