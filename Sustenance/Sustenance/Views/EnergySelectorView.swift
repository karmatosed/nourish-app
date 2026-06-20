import SwiftUI

struct EnergySelectorView: View {
    @Binding var selection: EnergyLevel
    var title: String = "How’s your energy today?"

    private var sliderPosition: Binding<Double> {
        Binding(
            get: { Double(selection.sortOrder) },
            set: { newValue in
                let order = min(EnergyLevel.good.sortOrder, max(EnergyLevel.low.sortOrder, Int(newValue.rounded())))
                guard let level = EnergyLevel.allCases.first(where: { $0.sortOrder == order }) else { return }
                selection = level
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 12) {
                ForEach(EnergyLevel.allCases) { level in
                    trafficLight(for: level)
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: 8) {
                Slider(value: sliderPosition, in: 0...2, step: 1)
                    .tint(selection.trafficLightColor)
                    .accessibilityLabel("Energy level")
                    .accessibilityValue(selection.displayName)

                HStack {
                    Text(EnergyLevel.low.displayName)
                    Spacer()
                    Text(EnergyLevel.okay.displayName)
                    Spacer()
                    Text(EnergyLevel.good.displayName)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func trafficLight(for level: EnergyLevel) -> some View {
        let isSelected = selection == level

        return Button {
            selection = level
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(level.trafficLightColor.opacity(isSelected ? 1 : 0.18))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                level.trafficLightColor.opacity(isSelected ? 1 : 0.4),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    }
                    .shadow(
                        color: isSelected ? level.trafficLightColor.opacity(0.35) : .clear,
                        radius: 8,
                        y: 2
                    )
                    .accessibilityHidden(true)

                Text(level.displayName)
                    .font(.caption.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? level.trafficLightColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(level.displayName) energy")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    EnergySelectorView(selection: .constant(.okay))
        .padding()
}
