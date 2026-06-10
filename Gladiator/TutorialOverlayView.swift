//
//  TutorialOverlayView.swift
//  Gladiator
//

import SwiftUI
import UIKit

enum TutorialSpotlight: Hashable {
    case tab(index: Int, total: Int)
    case topRightPlusButton
}

struct TutorialOverlayView: View {
    let title: String
    let description: String
    let spotlight: TutorialSpotlight
    let stepIndex: Int
    let totalSteps: Int
    let isLastStep: Bool
    let onNext: () -> Void
    let onSkip: () -> Void

    @State private var arrowBounce: Bool = false
    // Bumped shortly after appear to force a re-measure once the system tab bar
    // has finished its initial layout (the first body pass can run pre-layout).
    @State private var layoutRefresh: Int = 0

    var body: some View {
        GeometryReader { geo in
            let _ = layoutRefresh
            let cutout = cutoutRect(in: geo)
            ZStack {
                SpotlightShape(cutoutRect: cutout, cornerRadius: 16)
                    .fill(Color.black.opacity(0.78), style: FillStyle(eoFill: true))
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.32), value: spotlight)

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.accent.opacity(0.9), lineWidth: 2)
                    .frame(width: cutout.width, height: cutout.height)
                    .position(x: cutout.midX, y: cutout.midY)
                    .shadow(color: Theme.accent.opacity(0.7), radius: 14)
                    .shadow(color: Theme.accent.opacity(0.4), radius: 24)
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.32), value: spotlight)

                if case .topRightPlusButton = spotlight {
                    animatedArrow
                        .position(x: cutout.midX, y: cutout.maxY + 44)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                skipButton(in: geo)
                tooltipLayer(in: geo, cutout: cutout)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .onAppear {
                Task {
                    try? await Task.sleep(for: .milliseconds(120))
                    layoutRefresh += 1
                    #if DEBUG
                    debugDumpTabBarHierarchy()
                    #endif
                }
            }
        }
        .ignoresSafeArea()
    }

    private func cutoutRect(in geo: GeometryProxy) -> CGRect {
        switch spotlight {
        case .tab(let index, let total):
            return tabCutout(in: geo, index: index, total: total)
        case .topRightPlusButton:
            return plusButtonCutout(in: geo)
        }
    }

    private func tabCutout(in geo: GeometryProxy, index: Int, total: Int) -> CGRect {
        // Prefer the live, measured tab-button frame so the highlight tracks the
        // system tab bar regardless of how its metrics change between iOS versions.
        // (The iOS 26 tab bar is taller and lays out its icons differently than
        // iOS 18, which broke the old hardcoded estimate.)
        if let button = measuredTabButtonRect(index: index, total: total) {
            let cutoutWidth = min(button.width - 4, 96)
            let cutoutHeight = min(button.height + 6, 64)
            return CGRect(
                x: button.midX - cutoutWidth / 2,
                y: button.midY - cutoutHeight / 2,
                width: cutoutWidth,
                height: cutoutHeight
            )
        }
        return estimatedTabCutout(in: geo, index: index, total: total)
    }

    /// Fallback used only when the real tab bar cannot be measured (e.g. not yet
    /// laid out). Estimates the icon position from screen geometry.
    private func estimatedTabCutout(in geo: GeometryProxy, index: Int, total: Int) -> CGRect {
        let tabWidth = geo.size.width / CGFloat(total)
        let centerX = tabWidth * CGFloat(index) + tabWidth / 2
        // Because this overlay uses .ignoresSafeArea, geo.safeAreaInsets returns zero.
        // Read the real bottom inset from the key window — gives the home-indicator gap (0 or ~34pt).
        let safeBottom = keyWindowBottomInset()
        // The tab icon sits in the upper portion of the bar content with the label beneath.
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

    /// Walks the key window to the live `UITabBar` and returns the frame of the
    /// tab button at `index`, in window coordinates. Because this overlay ignores
    /// the safe area, window coordinates map 1:1 to the GeometryReader space.
    private func measuredTabButtonRect(index: Int, total: Int) -> CGRect? {
        guard let window = keyWindow(),
              let tabBar = firstTabBar(in: window) else { return nil }

        let rects = tabBarButtonRects(in: tabBar, window: window)
        guard rects.count == total, rects.indices.contains(index) else { return nil }
        return rects[index]
    }

    /// Returns each tab button's frame in window coordinates, left-to-right.
    ///
    /// Found by recursive descent because the iOS 26 Liquid Glass tab bar nests
    /// its buttons (class `_UITabButton`) inside container views rather than as
    /// direct subviews of `UITabBar`. It also renders each button in two stacked
    /// layers (selected / unselected), so the same button is found twice at the
    /// same x — we dedupe by horizontal position. Falls back to leaf `UIControl`s
    /// if the class name ever changes.
    private func tabBarButtonRects(in tabBar: UITabBar, window: UIWindow) -> [CGRect] {
        let byClassName = descendants(of: tabBar) {
            String(describing: type(of: $0)).contains("TabButton")
        }
        let candidates = byClassName.isEmpty
            ? descendants(of: tabBar) { view in
                (view is UIControl) && !view.subviews.contains(where: { $0 is UIControl })
              }
            : byClassName

        var seenX = Set<Int>()
        var rects: [CGRect] = []
        for view in candidates {
            let rect = view.convert(view.bounds, to: window)
            guard rect.width > 1, rect.height > 1 else { continue }
            // Round to merge the duplicated stacked layers at the same position.
            if seenX.insert(Int(rect.minX.rounded())).inserted {
                rects.append(rect)
            }
        }
        return rects.sorted { $0.minX < $1.minX }
    }

    private func descendants(of view: UIView, matching: (UIView) -> Bool) -> [UIView] {
        var result: [UIView] = []
        for sub in view.subviews {
            if matching(sub) { result.append(sub) }
            result.append(contentsOf: descendants(of: sub, matching: matching))
        }
        return result
    }

    private func firstTabBar(in view: UIView) -> UITabBar? {
        if let tabBar = view as? UITabBar { return tabBar }
        for sub in view.subviews {
            if let found = firstTabBar(in: sub) { return found }
        }
        return nil
    }

    #if DEBUG
    /// One-time console dump of the live tab bar hierarchy so the spotlight match
    /// can be tuned to the real (per-iOS-version) view structure. Remove once the
    /// highlight is confirmed aligned.
    private static var didDumpTabBar = false
    private func debugDumpTabBarHierarchy() {
        guard !Self.didDumpTabBar else { return }
        Self.didDumpTabBar = true
        guard let window = keyWindow(), let tabBar = firstTabBar(in: window) else {
            print("🧭 [Tutorial] No UITabBar found in key window — TabView may not be UIKit-backed on this OS.")
            return
        }
        print("🧭 [Tutorial] UITabBar frame=\(tabBar.frame)")
        func dump(_ v: UIView, depth: Int) {
            let pad = String(repeating: "  ", count: depth)
            let win = v.convert(v.bounds, to: window)
            print("🧭 \(pad)\(type(of: v)) control=\(v is UIControl) win=\(win)")
            v.subviews.forEach { dump($0, depth: depth + 1) }
        }
        tabBar.subviews.forEach { dump($0, depth: 1) }
    }
    #endif

    private func plusButtonCutout(in geo: GeometryProxy) -> CGRect {
        let safeTop = keyWindowTopInset()
        // Inline-title nav bar height is 44pt; primary-action item sits centered vertically.
        let navBarHeight: CGFloat = 44
        let iconCenterFromRight: CGFloat = 28
        let centerX = geo.size.width - iconCenterFromRight
        let centerY = safeTop + navBarHeight / 2
        let cutoutWidth: CGFloat = 52
        let cutoutHeight: CGFloat = 44
        return CGRect(
            x: centerX - cutoutWidth / 2,
            y: centerY - cutoutHeight / 2,
            width: cutoutWidth,
            height: cutoutHeight
        )
    }

    private func keyWindow() -> UIWindow? {
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    private func keyWindowBottomInset() -> CGFloat {
        keyWindow()?.safeAreaInsets.bottom ?? 34
    }

    private func keyWindowTopInset() -> CGFloat {
        keyWindow()?.safeAreaInsets.top ?? 47
    }

    private var animatedArrow: some View {
        Image(systemName: "arrow.up")
            .font(.system(size: 34, weight: .heavy))
            .foregroundColor(Theme.accent)
            .shadow(color: Theme.accent.opacity(0.7), radius: 10)
            .shadow(color: Theme.accent.opacity(0.4), radius: 18)
            .offset(y: arrowBounce ? -6 : 6)
            .scaleEffect(arrowBounce ? 1.08 : 0.94)
            .animation(
                .easeInOut(duration: 0.65).repeatForever(autoreverses: true),
                value: arrowBounce
            )
            .onAppear { arrowBounce = true }
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
        // Hide the top-right Skip button while the plus-button spotlight is active
        // so it doesn't overlap the highlighted area.
        .opacity(spotlight == .topRightPlusButton ? 0 : 1)
        .allowsHitTesting(spotlight != .topRightPlusButton)
    }

    @ViewBuilder
    private func tooltipLayer(in geo: GeometryProxy, cutout: CGRect) -> some View {
        let cutoutIsAtTop = cutout.midY < geo.size.height / 2
        if cutoutIsAtTop {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: cutout.maxY + 96)
                tooltipCard
                    .padding(.horizontal, 24)
                    .id(tooltipId)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                Spacer(minLength: 24)
            }
            .frame(width: geo.size.width)
            .animation(.easeInOut(duration: 0.28), value: tooltipId)
        } else {
            VStack(spacing: 0) {
                Spacer(minLength: geo.safeAreaInsets.top + 60)
                tooltipCard
                    .padding(.horizontal, 24)
                    .id(tooltipId)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                Color.clear
                    .frame(height: geo.size.height - cutout.minY + 22)
            }
            .frame(width: geo.size.width)
            .animation(.easeInOut(duration: 0.28), value: tooltipId)
        }
    }

    private var tooltipId: String {
        "\(stepIndex)-\(spotlight)"
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
        spotlight: .tab(index: 0, total: 5),
        stepIndex: 0,
        totalSteps: 5,
        isLastStep: false,
        onNext: { },
        onSkip: { }
    )
    .preferredColorScheme(.dark)
}
