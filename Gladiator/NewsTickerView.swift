//
//  NewsTickerView.swift
//  Gladiator
//

import SwiftUI

struct NewsTickerView: View {
    let text: String
    let onTap: (Int) -> Void

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let totalWidth = textWidth > 0 ? textWidth : geo.size.width * 2

            HStack(spacing: 0) {
                tickerText
                    .background(
                        GeometryReader { textGeo in
                            Color.clear.onAppear {
                                textWidth = textGeo.size.width
                                containerWidth = geo.size.width
                                startAnimation()
                            }
                        }
                    )
                tickerText
            }
            .offset(x: offset)
        }
        .frame(height: 32)
        .clipped()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onTapGesture {
            onTap(0)
        }
    }

    private var tickerText: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Theme.textSecondary)
            .fixedSize()
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
