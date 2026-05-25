//
//  DataSufficiencyBadge.swift
//  Gladiator
//

import SwiftUI

struct DataSufficiencyBadge: View {
    let level: DataSufficiencyLevel

    var body: some View {
        let color = level.color
        return HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
                .shadow(color: color.opacity(0.5), radius: 4)
            Text(level.levelName.uppercased())
                .font(.system(size: 12, weight: .heavy))
                .tracking(1.2)
                .foregroundColor(color)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(color.opacity(0.14)))
        .overlay(Capsule().stroke(color.opacity(0.45), lineWidth: 1))
    }
}

extension DataSufficiencyLevel {
    // Centralized so the Race Engineer slider's colored track and the badge
    // pull from the same source — segment colors must match what the badge
    // would show at the corresponding slider position.
    //
    // Poor's orange-red and Excellent's deep green are derived by mixing
    // existing Theme colors rather than introducing new RGB values, keeping
    // the palette rooted in Theme.swift.
    var color: Color {
        switch self {
        case .bad: return Theme.danger
        case .poor: return Theme.danger.mix(with: Theme.accent, by: 0.4)
        case .fair: return Theme.warning
        case .good: return Theme.success
        case .excellent: return Theme.success.mix(with: Theme.background, by: 0.35)
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        VStack(spacing: 12) {
            DataSufficiencyBadge(level: .bad)
            DataSufficiencyBadge(level: .poor)
            DataSufficiencyBadge(level: .fair)
            DataSufficiencyBadge(level: .good)
            DataSufficiencyBadge(level: .excellent)
        }
    }
    .preferredColorScheme(.dark)
}
