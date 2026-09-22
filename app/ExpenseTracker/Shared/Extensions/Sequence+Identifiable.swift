extension Sequence where Element: Identifiable {
    /// Builds an ID lookup table. Keeps the first element when IDs are duplicated
    /// instead of trapping like `Dictionary(uniqueKeysWithValues:)`.
    func keyedByID() -> [Element.ID: Element] {
        Dictionary(map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
}
