//
//  TutorialView.swift
//  Gladiator
//

import SwiftUI

struct TutorialView: View {
    @Binding var isPresented: Bool
    @State private var stage: Stage = .welcome

    private enum Stage: Equatable {
        case welcome
        case step(Int)
    }

    private let steps: [FirstLaunchTutorialStep] = [
        FirstLaunchTutorialStep(
            title: "Dashboard",
            description: "Your Dashboard gives you a live overview of your racing data, recent sessions, and AI insights.",
            tabIndex: 0
        ),
        FirstLaunchTutorialStep(
            title: "Analytics",
            description: "The Analytics tab contains powerful tools to identify correlations, trends, and performance patterns in your data.",
            tabIndex: 1
        ),
        FirstLaunchTutorialStep(
            title: "Sessions",
            description: "Log your race sessions here. The more sessions you record, the more powerful your analytics become.",
            tabIndex: 2
        ),
        FirstLaunchTutorialStep(
            title: "The Pit",
            description: "The Pit is your personal space for notes, checklists, goals and reminders.",
            tabIndex: 3
        ),
        FirstLaunchTutorialStep(
            title: "Settings",
            description: "In Settings, use Session Customization to manage your tracks, vehicles, and metrics.",
            tabIndex: 4
        )
    ]

    var body: some View {
        ZStack {
            switch stage {
            case .welcome:
                welcomeLayer
                    .transition(.opacity)
            case .step(let index):
                stepOverlay(for: index)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: stage)
    }

    @ViewBuilder
    private func stepOverlay(for index: Int) -> some View {
        if let step = steps[safe: index] {
            TutorialOverlayView(
                title: step.title,
                description: step.description,
                tabIndex: step.tabIndex,
                totalTabs: 5,
                stepIndex: index,
                totalSteps: steps.count,
                isLastStep: index == steps.count - 1,
                onNext: { advance() },
                onSkip: { complete() }
            )
        }
    }

    private var welcomeLayer: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 0) {
                welcomeTopBar
                Spacer()
                welcomeHero
                Spacer()
                welcomeActions
            }
        }
    }

    private var welcomeTopBar: some View {
        HStack {
            Spacer()
            Button { complete() } label: {
                Text("SKIP")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }

    private var welcomeHero: some View {
        VStack(spacing: 18) {
            Image(systemName: "flag.checkered.2.crossed")
                .font(.system(size: 52, weight: .bold))
                .foregroundColor(Theme.accent)
                .shadow(color: Theme.accent.opacity(0.5), radius: 16)

            Text("GLADIATOR")
                .font(.system(size: 32, weight: .heavy))
                .tracking(6)
                .foregroundColor(Theme.textPrimary)

            VStack(spacing: 8) {
                Text("Welcome to Gladiator")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                Text("Your personal racing analytics platform")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Text("QUICK TOUR — LESS THAN 30 SECONDS")
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textTertiary)
                .padding(.top, 6)
        }
        .padding(.horizontal, 32)
    }

    private var welcomeActions: some View {
        VStack(spacing: 10) {
            Button { advance() } label: {
                Text("LET'S GO")
                    .font(.system(size: 14, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Theme.accent))
                    .shadow(color: Theme.accent.opacity(0.5), radius: 14)
            }
            .buttonStyle(.plain)

            Button { complete() } label: {
                Text("Skip Tour")
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }

    private func advance() {
        switch stage {
        case .welcome:
            stage = .step(0)
        case .step(let i):
            if i + 1 >= steps.count {
                complete()
            } else {
                stage = .step(i + 1)
            }
        }
    }

    private func complete() {
        isPresented = false
    }
}

private struct FirstLaunchTutorialStep {
    let title: String
    let description: String
    let tabIndex: Int
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    TutorialView(isPresented: .constant(true))
        .preferredColorScheme(.dark)
}
