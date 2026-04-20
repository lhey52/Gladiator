//
//  ToastView.swift
//  Gladiator
//

import SwiftUI

struct ToastView: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.accent)
            Text(text)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Capsule().fill(Theme.surface))
        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.4), radius: 12, y: 4)
    }
}
