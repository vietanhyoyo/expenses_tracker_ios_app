import SwiftUI

@main
struct ExpenseTrackerApp: App {
    private let container: AppContainer

    init() {
        do { container = try AppContainer() }
        catch { fatalError("Unable to initialize local store: \(error)") }
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
