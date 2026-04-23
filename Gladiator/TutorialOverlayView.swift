//
//  TutorialOverlayView.swift
//  Gladiator
//

import SwiftUI
import UIKit

struct TutorialOverlayView: View {
    let title: String
    let description: String
    let tabIndex: Int
    let totalTabs: Int
    let stepIndex: Int
    let totalSteps: Int
    let isLastStep: Bool
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        GeometryReader { geo in
            let cutout = cutoutRect(in: geo)
            ZStack {
                SpotlightShape(cutoutRect: cutout, cornerRadius: 16)
                    .fill(Color.black.opacity(0.78), style: FillStyle(eoFill: true))
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.32), value: tabIndex)

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.accent.opacity(0.9), lineWidth: 2)
                    .frame(width: cutout.width, height: cutout.height)
                    .position(x: cutout.midX, y: cutout.midY)
                    .shadow(color: Theme.accent.opacity(0.7), radius: 14)
                    .shadow(color: Theme.accent.opacity(0.4), radius: 24)
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.32), value: tabIndex)

                skipButton(in: geo)
                tooltipLayer(in: geo, cutout: cutout)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
        }
        .ignoresSafeArea()
    }

    private func cutoutRect(in geo: GeometryProxy) -> CGRect {
        let tabWidth = geo.size.width / CGFloat(totalTabs)
        let centerX = tabWidth * CGFloat(tabIndex) + tabWidth / 2
        // Because this overlay uses .ignoresSafeArea, geo.safeAreaInsets returns zero.
        // Read the real bottom inset from the key window — gives the home-indicator gap (0 or ~34pt).
        let safeBottom = keyWindowBottomInset()
        // The tab icon sits in the upper portion of the ~49pt bar content with the label beneath.
        // Centering further down and making the cutout taller covers both icon and label cleanly.
        let iconCenterFromBarBottom: CGFloat = 20
        let centerY = geo.size.height - safeBottom - iconCenterFromBarBottom
        let cutoutWidth: CGFloat = min(tabWidth - 8, 90)
        let cutoutHeight: CGFloat = 64
        return CGRect(
            x: centerX - cutoutWidth / 2,
            y: centerY - cutoutHeight / 2,
            width: cutoutWidth,
            height: cutoutHeight
        )
    }

    private func keyWindowBottomInset() -> CGFloat {
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.bottom ?? 34
    }

    private func skipButton(in geo: GeometryProxy) -> some View {
        VStack {
            HStack {
                Spacer()
                Button(action: onSkip) {
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
            Spacer()
        }
        .padding(.top, geo.safeAreaInsets.top + 8)
        .padding(.trailing, 12)
    }

    private func tooltipLayer(in geo: GeometryProxy, cutout: CGRect) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: geo.safeAreaInsets.top + 60)
            tooltipCard
                .padding(.horizontal, 24)
                .id(stepIndex)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            Color.clear
                .frame(height: geo.size.height - cutout.minY + 22)
        }
        .frame(width: geo.size.width)
        .animation(.easeInOut(duration: 0.28), value: stepIndex)
    }

    private var tooltipCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STEP \(stepIndex + 1) OF \(totalSteps)")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)

            Text(title)
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(Theme.textPrimary)

            Text(description)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                progressDots
                Spacer()
                nextButton
            }
            .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Theme.accent.opacity(0.2), radius: 20)
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Circle()
                    .fill(i == stepIndex ? Theme.accent : Theme.textTertiary.opacity(0.4))
                    .frame(width: 7, height: 7)
            }
        }
    }

    private var nextButton: some View {
        Button(action: onNext) {
            Text(isLastStep ? "GET STARTED" : "NEXT")
                .font(.system(size: 13, weight: .heavy))
                .tracking(1.2)
                .foregroundColor(Theme.background)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(Theme.accent))
                .shadow(color: Theme.accent.opacity(0.5), radius: 10)
        }
        .buttonStyle(.plain)
    }
}

private struct SpotlightShape: Shape {
    var cutoutRect: CGRect
    let cornerRadius: CGFloat

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(
                AnimatablePair(cutoutRect.origin.x, cutoutRect.origin.y),
                AnimatablePair(cutoutRect.size.width, cutoutRect.size.height)
            )
        }
        set {
            cutoutRect = CGRect(
                x: newValue.first.first,
                y: newValue.first.second,
                width: newValue.second.first,
                height: newValue.second.second
            )
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addRoundedRect(in: cutoutRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        return path
    }
}

#Preview {
    TutorialOverlayView(
        title: "Dashboard",
        description: "Your Dashboard gives you a live overview of your racing data, recent sessions, and AI insights.",
        tabIndex: 0,
        totalTabs: 5,
        stepIndex: 0,
        totalSteps: 5,
        isLastStep: false,
        onNext: { },
        onSkip: { }
    )
    .preferredColorScheme(.dark)
}
