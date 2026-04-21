//
//  NewsTickerView.swift
//  Gladiator
//

import SwiftUI

struct NewsTickerView: View {
    let text: String
    let onTap: () -> Void

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0

    var body: some View {
        HStack(spacing: 0) {
            tickerText
                .background(
                    GeometryReader { textGeo in
                        Color.clear.onAppear {
                            textWidth = textGeo.size.width
                            startAnimation()
                        }
                    }
                )
            tickerText
        }
        .offset(x: offset)
        .frame(height: 32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private var tickerText: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Theme.textSecondary)
            .fixedSize()
            .frame(height: 32)
            .padding(.horizontal, 20)
    }

    private func startAnimation() {
        guard textWidth > 0 else { return }
        offset = 0
        withAnimation(.linear(duration: Double(textWidth) / 40).repeatForever(autoreverses: false)) {
            offset = -textWidth
        }
    }
}
