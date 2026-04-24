//
//  TutorialView.swift
//  Gladiator
//

import SwiftUI

struct TutorialView: View {
    @Binding var isPresented: Bool
    @Binding var selectedTab: Int
    @State private var stage: Stage = .welcome
    // Sub-phase within the Sessions step: 0 = tab icon, 1 = top-right plus button.
    @State private var sessionsSubPhase: Int = 0

    private enum Stage: Equatable {
        case welcome
        case step(Int)
    }

    private let sessionsStepIndex: Int = 2

    private let steps: [FirstLaunchTutorialStep] = [
        FirstLaunchTutorialStep(
            title: "Dashboard",
            description: "Your Dashboard gives you a live overview of your racing data, recent sessions, and racing news.",
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
            description: "In Settings, use Session Customization to manage your tracks, vehicles, and metrics. Replay this tutorial anytime by going to Reset in your Settings",
            tabIndex: 4
        )
    ]

    private let sessionsAddButtonDescription = "Tap the + button to log a new session. The more sessions you record, the more powerful your analytics become."

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
                description: descriptionFor(step: step, index: index),
                spotlight: spotlightFor(step: step, index: index),
                stepIndex: index,
                totalSteps: steps.count,
                isLastStep: index == steps.count - 1,
                onNext: { advance() },
                onSkip: { complete() }
            )
        }
    }

    private func descriptionFor(step: FirstLaunchTutorialStep, index: Int) -> String {
        if index == sessionsStepIndex && sessionsSubPhase == 1 {
            return sessionsAddButtonDescription
        }
        return step.description
    }

    private func spotlightFor(step: FirstLaunchTutorialStep, index: Int) -> TutorialSpotlight {
        if index == sessionsStepIndex && sessionsSubPhase == 1 {
            return .topRightPlusButton
        }
        return .tab(index: step.tabIndex, total: 5)
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
            setStage(.step(0))
        case .step(let i):
            // Within the Sessions step, advance through the sub-phase before moving on.
            if i == sessionsStepIndex && sessionsSubPhase == 0 {
                sessionsSubPhase = 1
                return
            }
            sessionsSubPhase = 0
            if i + 1 >= steps.count {
                complete()
            } else {
                setStage(.step(i + 1))
            }
        }
    }

    private func setStage(_ newStage: Stage) {
        stage = newStage
        if case .step(let i) = newStage, let step = steps[safe: i] {
            selectedTab = step.tabIndex
        }
    }

    private func complete() {
        selectedTab = 0
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
    TutorialView(isPresented: .constant(true), selectedTab: .constant(0))
        .preferredColorScheme(.dark)
}
