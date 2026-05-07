//
//  RaceCarDiagramView.swift
//  Gladiator
//

import SwiftUI

struct ZoneFillState: Equatable {
    let filled: Int
    let total: Int

    var hasMetrics: Bool { total > 0 }
    var isComplete: Bool { total > 0 && filled >= total }
    var isPartial: Bool { filled > 0 && filled < total }
}

struct RaceCarDiagramView: View {
    let zoneStates: [CarZone: ZoneFillState]
    var expandedZone: CarZone? = nil
    var matchedNamespace: Namespace.ID? = nil
    let onTapZone: (CarZone) -> Void

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                CarChassisShape()
                    .fill(
                        LinearGradient(
                            colors: [Theme.chassisFillTop, Theme.chassisFillBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                CarChassisShape()
                    .stroke(Theme.chassisLine, lineWidth: 1)

                centerlineDivider(size: size)

                // Axle stubs that read as the body outline continuing out
                // to each tire — only filling the gap between the chassis
                // curve and the tire's inner edge, so nothing crosses the
                // body interior. Same chassisLine color as the chassis
                // stroke for visual continuity.
                axleStubs(yRatio: 0.22, chassisRightX: 0.695, chassisLeftX: 0.305, in: size)
                axleStubs(yRatio: 0.78, chassisRightX: 0.719, chassisLeftX: 0.281, in: size)

                ForEach(CarZone.carZones) { zone in
                    let layout = RaceCarDiagramView.layout(for: zone)
                    zoneCellView(for: zone)
                        .frame(
                            width: size.width * layout.size.width,
                            height: size.height * layout.size.height
                        )
                        .position(
                            x: size.width * layout.center.x,
                            y: size.height * layout.center.y
                        )
                }
            }
        }
        .aspectRatio(0.55, contentMode: .fit)
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func zoneCellView(for zone: CarZone) -> some View {
        let cell = ZoneCell(
            zone: zone,
            state: zoneStates[zone] ?? ZoneFillState(filled: 0, total: 0),
            action: { onTapZone(zone) }
        )
        if let ns = matchedNamespace {
            cell
                .matchedGeometryEffect(id: zone, in: ns, isSource: expandedZone != zone)
                .opacity(expandedZone == zone ? 0 : 1)
        } else {
            cell
        }
    }

    private func centerlineDivider(size: CGSize) -> some View {
        Rectangle()
            .fill(Theme.chassisLine)
            .frame(width: 1, height: size.height * 0.50)
            .position(x: size.width * 0.5, y: size.height * 0.50)
    }

    @ViewBuilder
    private func axleStubs(
        yRatio: CGFloat,
        chassisRightX: CGFloat,
        chassisLeftX: CGFloat,
        in size: CGSize
    ) -> some View {
        // Right stub: chassis curve → FR/BR inner edge (x = 0.77)
        axleStub(fromX: chassisRightX, toX: 0.77, yRatio: yRatio, in: size)
        // Left stub: FL/BL inner edge (x = 0.23) → chassis curve
        axleStub(fromX: 0.23, toX: chassisLeftX, yRatio: yRatio, in: size)
    }

    private func axleStub(
        fromX: CGFloat,
        toX: CGFloat,
        yRatio: CGFloat,
        in size: CGSize
    ) -> some View {
        let leftX = size.width * fromX
        let rightX = size.width * toX
        let stubW = rightX - leftX
        let stubHRatio: CGFloat = 0.014
        let stubH = size.height * stubHRatio

        // Sample the body's full-height gradient at the stub's actual y by
        // extending the gradient axis past the stub's bounds. Without this
        // the stub would compress 0.04 → 0.10 into its own 0.014 of height
        // and read as a separate object stitched on.
        let stubTopRatio = yRatio - stubHRatio / 2
        let gradientStartY = -stubTopRatio / stubHRatio
        let gradientEndY = (1 - stubTopRatio) / stubHRatio
        let bodyMatchedFill = LinearGradient(
            colors: [Theme.chassisFillTop, Theme.chassisFillBottom],
            startPoint: UnitPoint(x: 0.5, y: gradientStartY),
            endPoint: UnitPoint(x: 0.5, y: gradientEndY)
        )

        return Rectangle()
            .fill(bodyMatchedFill)
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.chassisLine).frame(height: 1)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.chassisLine).frame(height: 1)
            }
            .frame(width: stubW, height: stubH)
            .position(x: (leftX + rightX) / 2, y: size.height * yRatio)
    }

    static func layout(for zone: CarZone) -> (center: CGPoint, size: CGSize) {
        switch zone {
        case .front:
            return (CGPoint(x: 0.50, y: 0.05), CGSize(width: 0.86, height: 0.055))
        case .flTire:
            return (CGPoint(x: 0.13, y: 0.22), CGSize(width: 0.20, height: 0.13))
        case .frTire:
            return (CGPoint(x: 0.87, y: 0.22), CGSize(width: 0.20, height: 0.13))
        case .cockpit:
            return (CGPoint(x: 0.50, y: 0.39), CGSize(width: 0.34, height: 0.17))
        case .engine:
            return (CGPoint(x: 0.50, y: 0.62), CGSize(width: 0.40, height: 0.20))
        case .blTire:
            return (CGPoint(x: 0.13, y: 0.78), CGSize(width: 0.20, height: 0.13))
        case .brTire:
            return (CGPoint(x: 0.87, y: 0.78), CGSize(width: 0.20, height: 0.13))
        case .rear:
            return (CGPoint(x: 0.50, y: 0.955), CGSize(width: 0.96, height: 0.065))
        case .general:
            return (CGPoint.zero, CGSize.zero)
        }
    }
}

// MARK: - Chassis path

private struct CarChassisShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // Narrow nose
        p.move(to: CGPoint(x: w * 0.36, y: h * 0.10))
        p.addLine(to: CGPoint(x: w * 0.64, y: h * 0.10))
        // Right side: flare around cockpit and engine bay
        p.addQuadCurve(
            to: CGPoint(x: w * 0.74, y: h * 0.55),
            control: CGPoint(x: w * 0.76, y: h * 0.32)
        )
        p.addQuadCurve(
            to: CGPoint(x: w * 0.62, y: h * 0.90),
            control: CGPoint(x: w * 0.80, y: h * 0.74)
        )
        // Tail
        p.addLine(to: CGPoint(x: w * 0.38, y: h * 0.90))
        // Left side: mirror back to nose
        p.addQuadCurve(
            to: CGPoint(x: w * 0.26, y: h * 0.55),
            control: CGPoint(x: w * 0.20, y: h * 0.74)
        )
        p.addQuadCurve(
            to: CGPoint(x: w * 0.36, y: h * 0.10),
            control: CGPoint(x: w * 0.24, y: h * 0.32)
        )
        p.closeSubpath()
        return p
    }
}

// MARK: - Zone cell

private struct ZoneCell: View {
    let zone: CarZone
    let state: ZoneFillState
    let action: () -> Void

    // Slice of the body's full-height chassisFillTop → chassisFillBottom
    // gradient, sampled at this zone's actual y range. Same UnitPoint
    // extension trick the axle stubs use, so each zone reads as part of
    // the body silhouette rather than a separate tile.
    private var fillStyle: LinearGradient {
        let layout = RaceCarDiagramView.layout(for: zone)
        let zoneH = layout.size.height
        guard zoneH > 0 else {
            return LinearGradient(
                colors: [Theme.chassisFillBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        let yTop = layout.center.y - zoneH / 2
        let startY = -yTop / zoneH
        let endY = (1 - yTop) / zoneH
        return LinearGradient(
            colors: [Theme.chassisFillTop, Theme.chassisFillBottom],
            startPoint: UnitPoint(x: 0.5, y: startY),
            endPoint: UnitPoint(x: 0.5, y: endY)
        )
    }

    private var strokeColor: Color { Theme.chassisLine }

    private var strokeWidth: CGFloat { 1 }

    private var glowColor: Color {
        if state.isComplete { return Theme.accent.opacity(0.55) }
        if state.isPartial { return Theme.accent.opacity(0.30) }
        return .clear
    }

    private var labelColor: Color {
        state.hasMetrics ? Theme.accent : Theme.textTertiary
    }

    private var counterColor: Color {
        state.isComplete ? Theme.accent : Theme.textSecondary
    }

    var body: some View {
        let cornerRadius = cornerRadius
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fillStyle)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(strokeColor, lineWidth: strokeWidth)
                tireTreads
                content
            }
            .shadow(color: glowColor, radius: state.hasMetrics ? 10 : 0)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!state.hasMetrics)
    }

    private var cornerRadius: CGFloat {
        switch zone {
        case .flTire, .frTire, .blTire, .brTire: return 6
        case .front, .rear: return 4
        case .cockpit: return 22
        case .engine: return 14
        case .general: return 6
        }
    }

    @ViewBuilder
    private var tireTreads: some View {
        // Subtle tread lines on tire zones for visual identity. Drawn
        // independent of the zone state so the car still reads as a car
        // even when no metrics are assigned anywhere.
        if zone == .flTire || zone == .frTire || zone == .blTire || zone == .brTire {
            GeometryReader { geo in
                let h = geo.size.height
                VStack(spacing: h * 0.18) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(Theme.chassisLine)
                            .frame(height: 1)
                    }
                }
                .padding(.horizontal, geo.size.width * 0.18)
                .padding(.vertical, geo.size.height * 0.20)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch zone {
        case .front, .rear:
            HStack(spacing: 6) {
                Text(zone.displayName.uppercased())
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1.2)
                    .foregroundColor(labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if state.hasMetrics {
                    counterPill
                }
            }
            .padding(.horizontal, 8)
        default:
            VStack(spacing: 3) {
                Text(zone.displayName.uppercased())
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(labelColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                if state.hasMetrics {
                    counterPill
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
    }

    private var counterPill: some View {
        Text("\(state.filled)/\(state.total)")
            .font(.system(size: 9, weight: .heavy))
            .foregroundColor(counterColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(state.isComplete ? Theme.accent.opacity(0.22) : Theme.surface.opacity(0.7))
            )
            .overlay(
                Capsule()
                    .stroke(state.isComplete ? Theme.accent.opacity(0.6) : Theme.hairline, lineWidth: 1)
            )
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        RaceCarDiagramView(
            zoneStates: [
                .flTire: ZoneFillState(filled: 2, total: 2),
                .frTire: ZoneFillState(filled: 1, total: 2),
                .blTire: ZoneFillState(filled: 0, total: 1),
                .engine: ZoneFillState(filled: 3, total: 3),
                .cockpit: ZoneFillState(filled: 1, total: 4),
                .front: ZoneFillState(filled: 0, total: 1)
            ],
            onTapZone: { _ in }
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
