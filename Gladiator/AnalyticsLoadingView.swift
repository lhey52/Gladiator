//
//  AnalyticsLoadingView.swift
//  Gladiator
//

import SwiftUI

struct AnalyticsLoadingView: View {
    let toolName: String
    let sessionCount: Int
    let onComplete: () -> Void

    @State private var progress: Double = 0
    @State private var stageIndex: Int = 0

    private let stages: [String] = [
        "Loading sessions...",
        "Applying filters...",
        "Running calculations...",
        "Preparing results..."
    ]

    private var stageDuration: Double {
        min(1.5, 0.3 + 0.01 * Double(sessionCount))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Text(toolName.uppercased())
                    .font(.system(size: 18, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                progressBar

                Text(stages[stageIndex])
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(Theme.textSecondary)
                    .id(stageIndex)
                    .transition(.opacity)
            }
            .padding(.horizontal, 48)
        }
        .task {
            await runStages()
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Theme.surface)
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Theme.accent)
                    .frame(width: max(geo.size.width * CGFloat(progress), 0), height: 6)
                    .shadow(color: Theme.accent.opacity(0.6), radius: 8)
            }
        }
        .frame(height: 6)
    }

    private func runStages() async {
        let duration = stageDuration
        for i in 0..<stages.count {
            withAnimation(.easeInOut(duration: 0.15)) {
                stageIndex = i
            }
            withAnimation(.linear(duration: duration)) {
                progress = Double(i + 1) / Double(stages.count)
            }
            try? await Task.sleep(for: .seconds(duration))
        }
        try? await Task.sleep(for: .milliseconds(80))
        onComplete()
    }
}

#Preview {
    AnalyticsLoadingView(
        toolName: "Scatter Plot",
        sessionCount: 40,
        onComplete: { }
    )
    .preferredColorScheme(.dark)
}
