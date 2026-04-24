//
//  DataSufficiencyBadge.swift
//  Gladiator
//

import SwiftUI

struct DataSufficiencyBadge: View {
    let level: DataSufficiencyLevel

    var body: some View {
        HStack(spacing: 8) {
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

    // Poor's orange-red is derived by mixing Theme.danger (red) toward Theme.accent (orange)
    // rather than hardcoding a new RGB — keeps the palette rooted in Theme.swift.
    private var color: Color {
        switch level {
        case .bad: return Theme.danger
        case .poor: return Theme.danger.mix(with: Theme.accent, by: 0.4)
        case .fair: return Theme.warning
        case .good: return Theme.accent
        case .excellent: return Theme.success
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
