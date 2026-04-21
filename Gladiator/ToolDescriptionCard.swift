//
//  ToolDescriptionCard.swift
//  Gladiator
//

import SwiftUI

struct ToolDescriptionCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.accent)
                Text("HOW IT WORKS")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.8)
                    .foregroundColor(Theme.accent)
            }
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        ToolDescriptionCard(
            text: "Measure the statistical relationship between two metrics across your sessions."
        )
        .padding(20)
    }
    .preferredColorScheme(.dark)
}
