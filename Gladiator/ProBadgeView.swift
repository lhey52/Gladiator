//
//  ProBadgeView.swift
//  Gladiator
//

import SwiftUI

struct ProBadgeView: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .heavy))
            .tracking(1.5)
            .foregroundColor(Theme.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Theme.accent))
    }
}

struct ProBadgeIfNeeded: View {
    @ObservedObject private var iap = IAPManager.shared

    var body: some View {
        Group {
            if iap.isProUser {
                ProBadgeView()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: iap.isProUser)
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        ProBadgeView()
    }
    .preferredColorScheme(.dark)
}
