//
//  AnalyticsView.swift
//  Gladiator
//

import SwiftUI

struct AnalyticsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        AnalyticsCard(
                            icon: "chart.dots.scatter",
                            title: "Scatter Plot",
                            description: "Plot any two metrics against each other"
                        ) {
                            ScatterPlotView()
                        }

                        AnalyticsCard(
                            icon: "function",
                            title: "Correlation Analysis",
                            description: "Find statistical relationships between metrics"
                        ) {
                            CorrelationView()
                        }
                    }
                    .padding(20)
                    .padding(.top, 4)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct AnalyticsCard<Destination: View>: View {
    let icon: String
    let title: String
    let description: String
    @ViewBuilder let destination: () -> Destination

    @State private var showingFullScreen: Bool = false

    var body: some View {
        Button { showingFullScreen = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.accent.opacity(0.12))
                        .frame(width: 42, height: 42)
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text(description)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingFullScreen) {
            destination()
        }
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self], inMemory: true)
        .preferredColorScheme(.dark)
}
