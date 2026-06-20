import SwiftUI

struct SustenanceAddButton: View {
    enum Style {
        case toolbar
        case inline
        case prominent
    }

    let accessibilityLabel: String
    var style: Style = .toolbar
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            switch style {
            case .toolbar:
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
            case .inline:
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .background(SustenanceTheme.background)
                    .overlay {
                        Circle().strokeBorder(SustenanceTheme.border, lineWidth: 1)
                    }
                    .clipShape(Circle())
            case .prominent:
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .frame(width: 48, height: 48)
                    .background(SustenanceTheme.accent)
                    .foregroundStyle(SustenanceTheme.selectedLabelOnAccent)
                    .clipShape(Circle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
