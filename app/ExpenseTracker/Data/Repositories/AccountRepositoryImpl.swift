import Foundation

@MainActor
final class AccountRepositoryImpl: AccountRepository {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func getAccounts() async throws -> [Account] {
        do {
            let values: [AccountResponse] = try await api.get(APIEndpoints.Accounts.collection)
            return try values.map(map)
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    func addAccount(_ account: Account) async throws {
        do {
            let _: AccountResponse = try await api.post(
                APIEndpoints.Accounts.collection,
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
            let _: AccountResponse = try await api.patch(
                APIEndpoints.Accounts.detail(id: serverID),
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
            let _: APIEmptyResponse? = try await api.delete(APIEndpoints.Accounts.detail(id: serverID))
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    private func map(_ response: AccountResponse) throws -> Account {
        guard let initialBalance = Decimal(
            string: response.initialBalance,
            locale: Locale(identifier: "en_US_POSIX")
        ) else {
            throw DomainError.remoteError("Dữ liệu tài khoản từ máy chủ không hợp lệ.")
        }
        return Account(
            id: ServerIDCodec.accountUUID(id: response.id, userID: response.userId),
            name: response.name,
            initialBalance: initialBalance
        )
    }
}
