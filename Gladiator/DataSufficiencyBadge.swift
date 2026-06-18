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
        case .poor: return Theme.danger.blended(with: Theme.accent, by: 0.4)
        case .fair: return Theme.warning
        case .good: return Theme.success
        case .excellent: return Theme.success.blended(with: Theme.background, by: 0.35)
        }
    }
}

private extension Color {
    // iOS 17-compatible stand-in for `Color.mix(with:by:)` (iOS 18+). Resolves
    // both colors to sRGB components via UIColor and linearly interpolates.
    // `fraction` 0 returns self, 1 returns `other`.
    func blended(with other: Color, by fraction: Double) -> Color {
        let t = min(max(fraction, 0), 1)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(other).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(
            red: Double(r1 + (r2 - r1) * t),
            green: Double(g1 + (g2 - g1) * t),
            blue: Double(b1 + (b2 - b1) * t),
            opacity: Double(a1 + (a2 - a1) * t)
        )
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
