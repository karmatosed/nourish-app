import SwiftUI

struct SafetyStatusBadge: View {
    let status: SafetyStatus

    var body: some View {
        Label(status.displayName, systemImage: iconName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(SustenanceTheme.color(for: status))
            .background(SustenanceTheme.color(for: status).opacity(0.12))
            .clipShape(Capsule())
            .accessibilityLabel("Safety: \(status.displayName)")
    }

    private var iconName: String {
        switch status {
        case .safe: "checkmark.shield"
        case .caution: "exclamationmark.triangle"
        case .unsafe: "xmark.shield"
        }
    }
}
