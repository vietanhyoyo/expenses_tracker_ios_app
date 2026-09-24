import Foundation

final class MetadataStore {
    struct Appearance: Codable {
        let icon: String
        let colorHex: String
    }

    private let defaults: UserDefaults
    private let appearancesKey = "remoteCategoryAppearances"
    private let accountsKey = "remoteExpenseAccounts"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func appearance(userID: Int?, categoryID: Int) -> Appearance? {
        appearances()[categoryKey(userID: userID, id: categoryID)]
    }

    func saveAppearance(_ appearance: Appearance, userID: Int?, categoryID: Int) {
        var values = appearances()
        values[categoryKey(userID: userID, id: categoryID)] = appearance
        save(values, key: appearancesKey)
    }

    func accountID(userID: Int, expenseID: Int) -> UUID? {
        guard let value = accounts()[expenseKey(userID: userID, id: expenseID)] else {
            return nil
        }
        return UUID(uuidString: value)
    }

    func saveAccountID(_ accountID: UUID, userID: Int, expenseID: Int) {
        var values = accounts()
        values[expenseKey(userID: userID, id: expenseID)] = accountID.uuidString
        save(values, key: accountsKey)
    }

    func removeAccountID(userID: Int?, expenseID: Int) {
        var values = accounts()
        if let userID {
            values.removeValue(forKey: expenseKey(userID: userID, id: expenseID))
        } else {
            values = values.filter { !$0.key.hasSuffix(":\(expenseID)") }
        }
        save(values, key: accountsKey)
    }

    private func appearances() -> [String: Appearance] {
        load([String: Appearance].self, key: appearancesKey) ?? [:]
    }

    private func accounts() -> [String: String] {
        load([String: String].self, key: accountsKey) ?? [:]
    }

    private func categoryKey(userID: Int?, id: Int) -> String {
        "\(userID.map(String.init) ?? "system"):\(id)"
    }

    private func expenseKey(userID: Int, id: Int) -> String {
        "\(userID):\(id)"
    }

    private func load<Value: Decodable>(_ type: Value.Type, key: String) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<Value: Encodable>(_ value: Value, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
