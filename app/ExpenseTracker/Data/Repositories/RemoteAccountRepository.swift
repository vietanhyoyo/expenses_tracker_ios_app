import Foundation

@MainActor
final class RemoteAccountRepository: AccountRepository {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func getAccounts() async throws -> [Account] {
        do {
            let values: [RemoteAccountDTO] = try await api.get("/accounts")
            return try values.map(map)
        } catch {
            throw RemoteErrorMapper.map(error)
        }
    }

    func addAccount(_ account: Account) async throws {
        do {
            let _: RemoteAccountDTO = try await api.post(
                "/accounts",
                body: CreateAccountRequest(
                    name: account.name,
                    type: "cash",
                    initialBalance: account.initialBalance
                )
            )
        } catch {
            throw RemoteErrorMapper.map(error)
        }
    }

    func updateAccount(_ account: Account) async throws {
        guard let serverID = ServerIDCodec.accountID(from: account.id) else {
            throw DomainError.accountNotFound
        }
        do {
            let _: RemoteAccountDTO = try await api.patch(
                "/accounts/\(serverID)",
                body: UpdateAccountRequest(
                    name: account.name,
                    initialBalance: account.initialBalance
                )
            )
        } catch {
            throw RemoteErrorMapper.map(error)
        }
    }

    func deleteAccount(id: UUID) async throws {
        guard let serverID = ServerIDCodec.accountID(from: id) else {
            throw DomainError.accountNotFound
        }
        do {
            let _: APIEmpty? = try await api.delete("/accounts/\(serverID)")
        } catch {
            throw RemoteErrorMapper.map(error)
        }
    }

    private func map(_ dto: RemoteAccountDTO) throws -> Account {
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
