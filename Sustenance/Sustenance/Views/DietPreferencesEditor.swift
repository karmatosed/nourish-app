import SwiftUI

struct DietPreferencesEditor: View {
    @Binding var selected: Set<DietPreference>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Diet preferences")
                    .font(.headline)

                Text("Vegan is on by default. Recipes with non-matching ingredients won’t be suggested.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(DietPreference.allCases) { preference in
                    preferenceChip(preference)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SustenanceTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func preferenceChip(_ preference: DietPreference) -> some View {
        let isSelected = selected.contains(preference)

        return Button {
            if isSelected {
                selected.remove(preference)
            } else {
                selected.insert(preference)
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(preference.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(SustenanceTheme.selectedLabelOnAccent)
                            : AnyShapeStyle(Color.primary)
                    )

                Text(preference.caption)
                    .font(.caption2)
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(SustenanceTheme.selectedLabelOnAccent.opacity(0.85))
                            : AnyShapeStyle(Color.secondary)
                    )
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(isSelected ? SustenanceTheme.accent : SustenanceTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? SustenanceTheme.accent : SustenanceTheme.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(preference.displayName)
        .accessibilityHint(preference.caption)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
