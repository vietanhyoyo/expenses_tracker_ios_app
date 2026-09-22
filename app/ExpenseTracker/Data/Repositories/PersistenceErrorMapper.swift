enum PersistenceErrorMapper {
    static func execute<T>(_ operation: () throws -> T) throws -> T {
        do {
            return try operation()
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.persistenceError
        }
    }
}
