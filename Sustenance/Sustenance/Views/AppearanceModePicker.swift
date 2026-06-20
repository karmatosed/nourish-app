import SwiftUI

struct AppearanceModePicker: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AppearanceMode.allCases) { mode in
                appearanceButton(mode)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Appearance")
    }

    private func appearanceButton(_ mode: AppearanceMode) -> some View {
        let isSelected = selection == mode.rawValue

        return Button {
            selection = mode.rawValue
        } label: {
            Text(mode.displayName)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(
                    isSelected
                        ? AnyShapeStyle(SustenanceTheme.selectedLabelOnAccent)
                        : AnyShapeStyle(Color.primary)
                )
                .background(isSelected ? SustenanceTheme.accent : SustenanceTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isSelected ? SustenanceTheme.accent : SustenanceTheme.border, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
