import Foundation

enum ServerIDCodec {
    private static let categoryPrefix = "CA7E6000"
    private static let expensePrefix = "E9FE6000"
    private static let accountPrefix = "ACCE6000"
    private static let budgetPrefix = "B0D66000"

    static func categoryUUID(id: Int, userID: Int?) -> UUID {
        makeUUID(prefix: categoryPrefix, id: id, userID: userID ?? 0)
    }

    static func expenseUUID(id: Int, userID: Int) -> UUID {
        makeUUID(prefix: expensePrefix, id: id, userID: userID)
    }

    static func accountUUID(id: Int, userID: Int) -> UUID {
        makeUUID(prefix: accountPrefix, id: id, userID: userID)
    }

    static func budgetUUID(id: Int, userID: Int) -> UUID {
        makeUUID(prefix: budgetPrefix, id: id, userID: userID)
    }

    static func categoryID(from uuid: UUID) -> Int? {
        decode(uuid, expectedPrefix: categoryPrefix)
    }

    static func expenseID(from uuid: UUID) -> Int? {
        decode(uuid, expectedPrefix: expensePrefix)
    }

    static func accountID(from uuid: UUID) -> Int? {
        decode(uuid, expectedPrefix: accountPrefix)
    }

    static func budgetID(from uuid: UUID) -> Int? {
        decode(uuid, expectedPrefix: budgetPrefix)
    }

    static func userID(from uuid: UUID) -> Int? {
        let components = uuid.uuidString.split(separator: "-")
        guard components.count == 5,
              components[0] == Substring(categoryPrefix)
                || components[0] == Substring(expensePrefix),
              let high = UInt32(components[1], radix: 16),
              let low = UInt32(components[2], radix: 16) else {
            return nil
        }
        let value = (high << 16) | low
        return value == 0 ? nil : Int(value)
    }

    private static func makeUUID(prefix: String, id: Int, userID: Int) -> UUID {
        let unsignedUser = UInt32(clamping: userID)
        let high = UInt16((unsignedUser >> 16) & 0xFFFF)
        let low = UInt16(unsignedUser & 0xFFFF)
        let unsignedID = UInt64(clamping: id) & 0xFFFFFFFFFFFF
        let value = String(
            format: "%@-%04X-%04X-0000-%012llX",
            prefix,
            high,
            low,
            unsignedID
        )
        guard let uuid = UUID(uuidString: value) else {
            assertionFailure("Unable to encode server ID as UUID")
            return UUID()
        }
        return uuid
    }

    private static func decode(_ uuid: UUID, expectedPrefix: String) -> Int? {
        let components = uuid.uuidString.split(separator: "-")
        guard components.count == 5,
              components[0] == Substring(expectedPrefix),
              let value = UInt64(components[4], radix: 16),
              value <= UInt64(Int.max) else {
            return nil
        }
        return Int(value)
    }
}
