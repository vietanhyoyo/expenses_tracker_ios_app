import SwiftUI

extension BudgetStatus {
    var color: Color {
        switch self {
        case .safe: AppTheme.teal
        case .warning: AppTheme.gold
        case .exceeded: AppTheme.coral
        }
    }
}

extension BudgetProgress {
    var percentage: Int {
        Int(ratio.doubleValue * 100)
    }

    /// Ratio clamped to `0...1` for `ProgressView`.
    var progressValue: Double {
        min(max(ratio.doubleValue, 0), 1)
    }
}
