//
//  NumberPadBubble.swift
//  Gladiator
//

import SwiftUI

// MARK: - Reusable bubble

/// A compact number-pad bubble that edits a string value in-place.
/// Designed to float over content as a popover-style entry surface, so the
/// host view should suppress the system keyboard and present this instead.
struct NumberPadBubble: View {
    @Binding var text: String
    let onDone: () -> Void

    static let preferredWidth: CGFloat = 220

    var body: some View {
        VStack(spacing: 6) {
            row(["7", "8", "9"])
            row(["4", "5", "6"])
            row(["1", "2", "3"])
            HStack(spacing: 6) {
                digitButton(".")
                digitButton("0")
                backspaceButton
            }
            doneButton
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.55), radius: 18, y: 8)
    }

    private func row(_ digits: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(digits, id: \.self) { d in
                digitButton(d)
            }
        }
    }

    private func digitButton(_ d: String) -> some View {
        Button {
            insert(d)
        } label: {
            Text(d)
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.surfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(NumberPadButtonStyle())
    }

    private var backspaceButton: some View {
        Button {
            backspace()
        } label: {
            Image(systemName: "delete.left.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.surfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(NumberPadButtonStyle())
    }

    private var doneButton: some View {
        Button {
            onDone()
        } label: {
            Text("DONE")
                .font(.system(size: 13, weight: .heavy))
                .tracking(1.6)
                .foregroundColor(Theme.background)
                .frame(maxWidth: .infinity, minHeight: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.accent)
                )
                .shadow(color: Theme.accent.opacity(0.4), radius: 6)
        }
        .buttonStyle(NumberPadButtonStyle())
    }

    private func insert(_ d: String) {
        if d == "." {
            // Only one decimal point allowed; auto-prefix a leading zero so
            // the value never starts with a bare ".".
            guard !text.contains(".") else { return }
            text = text.isEmpty ? "0." : text + "."
        } else {
            text += d
        }
    }

    private func backspace() {
        if !text.isEmpty {
            text.removeLast()
        }
    }
}

private struct NumberPadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - Positioning overlay

/// Floats a `NumberPadBubble` above (or below) an anchor frame and dims/blocks
/// taps on the rest of the screen. `anchorFrame` must be expressed in the
/// coordinate space provided by the host (typically a named coordinate space
/// on the screen or sheet container).
struct NumberPadBubbleOverlay: View {
    let anchorFrame: CGRect
    @Binding var text: String
    let onDismiss: () -> Void

    private let bubbleWidth: CGFloat = NumberPadBubble.preferredWidth
    private let estimatedHeight: CGFloat = 256
    private let gap: CGFloat = 10
    private let edgeMargin: CGFloat = 12

    @State private var measuredHeight: CGFloat = 256

    var body: some View {
        GeometryReader { geo in
            let containerSize = geo.size
            let bubbleHeight = max(measuredHeight, estimatedHeight)
            let placement = position(in: containerSize, bubbleHeight: bubbleHeight)

            ZStack(alignment: .topLeading) {
                // Backdrop catches taps (and drags) so the underlying sheet
                // stays still while the bubble is open. A near-zero opacity
                // colour is enough to register the hits.
                Color.black.opacity(0.0001)
                    .contentShape(Rectangle())
                    .onTapGesture { onDismiss() }

                NumberPadBubble(text: $text, onDone: onDismiss)
                    .frame(width: bubbleWidth)
                    .background(
                        GeometryReader { bubbleGeo in
                            Color.clear
                                .preference(
                                    key: NumberPadBubbleHeightKey.self,
                                    value: bubbleGeo.size.height
                                )
                        }
                    )
                    .position(
                        x: placement.x + bubbleWidth / 2,
                        y: placement.y + bubbleHeight / 2
                    )
            }
            .onPreferenceChange(NumberPadBubbleHeightKey.self) { measuredHeight = $0 }
        }
    }

    private func position(in container: CGSize, bubbleHeight: CGFloat) -> CGPoint {
        // Vertical: prefer above the field; fall back to below; clamp on
        // overflow so the bubble never leaves the screen.
        let aboveY = anchorFrame.minY - bubbleHeight - gap
        let belowY = anchorFrame.maxY + gap
        let yCandidate: CGFloat
        if aboveY >= edgeMargin {
            yCandidate = aboveY
        } else if belowY + bubbleHeight + edgeMargin <= container.height {
            yCandidate = belowY
        } else {
            yCandidate = max(edgeMargin, container.height - bubbleHeight - edgeMargin)
        }

        // Horizontal: centred on the anchor, clamped to the container.
        let preferredX = anchorFrame.midX - bubbleWidth / 2
        let maxX = container.width - bubbleWidth - edgeMargin
        let xCandidate = max(edgeMargin, min(preferredX, maxX))

        return CGPoint(x: xCandidate, y: yCandidate)
    }
}

private struct NumberPadBubbleHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        NumberPadBubble(text: .constant("28.5"), onDone: {})
            .frame(width: NumberPadBubble.preferredWidth)
    }
    .preferredColorScheme(.dark)
}
