import SwiftUI

extension EnergyLevel {
    var trafficLightColor: Color {
        switch self {
        case .low:
            Color(red: 0.86, green: 0.28, blue: 0.24)
        case .okay:
            Color(red: 0.93, green: 0.72, blue: 0.10)
        case .good:
            Color(red: 0.24, green: 0.66, blue: 0.38)
        }
    }
}
