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
                // Unified blueprint: chassis silhouette + tires + axle stubs +
                // bumpers, all rendered as one fill + one stroke pass so the
                // whole thing reads as a single drawing instead of stitched
                // tiles. Bumpers stay positionally separated by intent.
                CarChassisFillShape()
                    .fill(
                        LinearGradient(
                            colors: [Theme.chassisFillTop, Theme.chassisFillBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                CarChassisStrokeShape()
                    .stroke(Theme.chassisLine, lineWidth: 1)

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

// MARK: - Unified blueprint geometry

private enum BlueprintGeometry {
    // Front/rear bumper rects in normalized coords (match RaceCarDiagramView.layout).
    static let frontBumper = CGRect(x: 0.07, y: 0.0225, width: 0.86, height: 0.055)
    static let rearBumper = CGRect(x: 0.02, y: 0.9225, width: 0.96, height: 0.065)
    static let bumperCorner: CGFloat = 4

    // Tire rects (4) + corner radius. Aligned with layout(for:) so per-zone
    // accent overlays in ZoneCell sit exactly on top of these.
    static let tireRects: [CGRect] = [
        CGRect(x: 0.03, y: 0.155, width: 0.20, height: 0.13), // FL
        CGRect(x: 0.77, y: 0.155, width: 0.20, height: 0.13), // FR
        CGRect(x: 0.03, y: 0.715, width: 0.20, height: 0.13), // BL
        CGRect(x: 0.77, y: 0.715, width: 0.20, height: 0.13)  // BR
    ]
    static let tireCorner: CGFloat = 6

    // Axle stub bridges from chassis curve to tire inner edge. Inner tire
    // edges sit at x = 0.23 (left side) and x = 0.77 (right side).
    static let axleStubHeight: CGFloat = 0.014
    static let axles: [(yRatio: CGFloat, chassisLeftX: CGFloat, chassisRightX: CGFloat)] = [
        (0.22, 0.305, 0.695),
        (0.78, 0.281, 0.719)
    ]
    static let leftTireInnerX: CGFloat = 0.23
    static let rightTireInnerX: CGFloat = 0.77

    static func addChassisSilhouette(to p: inout Path, w: CGFloat, h: CGFloat) {
        p.move(to: CGPoint(x: w * 0.36, y: h * 0.10))
        p.addLine(to: CGPoint(x: w * 0.64, y: h * 0.10))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.74, y: h * 0.55),
            control: CGPoint(x: w * 0.76, y: h * 0.32)
        )
        p.addQuadCurve(
            to: CGPoint(x: w * 0.62, y: h * 0.90),
            control: CGPoint(x: w * 0.80, y: h * 0.74)
        )
        p.addLine(to: CGPoint(x: w * 0.38, y: h * 0.90))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.26, y: h * 0.55),
            control: CGPoint(x: w * 0.20, y: h * 0.74)
        )
        p.addQuadCurve(
            to: CGPoint(x: w * 0.36, y: h * 0.10),
            control: CGPoint(x: w * 0.24, y: h * 0.32)
        )
        p.closeSubpath()
    }

    static func addBumpers(to p: inout Path, w: CGFloat, h: CGFloat) {
        p.addRoundedRect(
            in: CGRect(x: w * frontBumper.minX, y: h * frontBumper.minY,
                       width: w * frontBumper.width, height: h * frontBumper.height),
            cornerSize: CGSize(width: bumperCorner, height: bumperCorner)
        )
        p.addRoundedRect(
            in: CGRect(x: w * rearBumper.minX, y: h * rearBumper.minY,
                       width: w * rearBumper.width, height: h * rearBumper.height),
            cornerSize: CGSize(width: bumperCorner, height: bumperCorner)
        )
    }

    static func addTires(to p: inout Path, w: CGFloat, h: CGFloat) {
        for tire in tireRects {
            p.addRoundedRect(
                in: CGRect(x: w * tire.minX, y: h * tire.minY,
                           width: w * tire.width, height: h * tire.height),
                cornerSize: CGSize(width: tireCorner, height: tireCorner)
            )
        }
    }
}

// MARK: - Blueprint shapes (fill + stroke)

// Filled regions for the entire blueprint. Stubs are drawn as full rectangles
// so the gradient fills the gap between chassis curve and tire inner edge.
private struct CarChassisFillShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        BlueprintGeometry.addBumpers(to: &p, w: w, h: h)
        BlueprintGeometry.addChassisSilhouette(to: &p, w: w, h: h)
        BlueprintGeometry.addTires(to: &p, w: w, h: h)

        // Axle stubs: full filled rectangles between chassis curve and tire.
        let stubH = BlueprintGeometry.axleStubHeight
        for axle in BlueprintGeometry.axles {
            // Right stub: chassis edge → right tire inner edge
            p.addRect(CGRect(
                x: w * axle.chassisRightX,
                y: h * (axle.yRatio - stubH / 2),
                width: w * (BlueprintGeometry.rightTireInnerX - axle.chassisRightX),
                height: h * stubH
            ))
            // Left stub: left tire inner edge → chassis edge
            p.addRect(CGRect(
                x: w * BlueprintGeometry.leftTireInnerX,
                y: h * (axle.yRatio - stubH / 2),
                width: w * (axle.chassisLeftX - BlueprintGeometry.leftTireInnerX),
                height: h * stubH
            ))
        }

        return p
    }
}

// Stroked outlines for the entire blueprint. Stubs use only top/bottom lines
// (no left/right) so the tire's inner edge and chassis curve aren't doubled
// where they meet the stub. Centerline divider lives here too.
private struct CarChassisStrokeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        BlueprintGeometry.addBumpers(to: &p, w: w, h: h)
        BlueprintGeometry.addChassisSilhouette(to: &p, w: w, h: h)
        BlueprintGeometry.addTires(to: &p, w: w, h: h)

        // Centerline divider down the middle of the body
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.25))
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.75))

        // Axle stubs: top and bottom horizontal lines only.
        let stubH = BlueprintGeometry.axleStubHeight
        for axle in BlueprintGeometry.axles {
            let yTop = h * (axle.yRatio - stubH / 2)
            let yBot = h * (axle.yRatio + stubH / 2)

            // Right side
            p.move(to: CGPoint(x: w * axle.chassisRightX, y: yTop))
            p.addLine(to: CGPoint(x: w * BlueprintGeometry.rightTireInnerX, y: yTop))
            p.move(to: CGPoint(x: w * axle.chassisRightX, y: yBot))
            p.addLine(to: CGPoint(x: w * BlueprintGeometry.rightTireInnerX, y: yBot))

            // Left side
            p.move(to: CGPoint(x: w * BlueprintGeometry.leftTireInnerX, y: yTop))
            p.addLine(to: CGPoint(x: w * axle.chassisLeftX, y: yTop))
            p.move(to: CGPoint(x: w * BlueprintGeometry.leftTireInnerX, y: yBot))
            p.addLine(to: CGPoint(x: w * axle.chassisLeftX, y: yBot))
        }

        return p
    }
}

// MARK: - Zone cell

// Per-zone overlay only: tap region, label, counter pill, tire treads, and
// the orange highlight border + glow when a zone has populated metrics. The
// underlying chassis fill/stroke is drawn once by the unified blueprint
// shapes above, so there's no per-cell rectangle fill/stroke here.
private struct ZoneCell: View {
    let zone: CarZone
    let state: ZoneFillState
    let action: () -> Void

    private var glowColor: Color {
        state.isComplete ? Theme.accent.opacity(0.55) : .clear
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
                interiorOverlay
                tireTreads
                content
            }
            .shadow(color: glowColor, radius: state.hasMetrics ? 10 : 0)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!state.hasMetrics)
    }

    // When a zone has metrics defined, draw a translucent fill that
    // alpha-stacks with the unified blueprint's gradient — that's what
    // gives the region a visibly distinct box. Empty zones (no metrics
    // configured) blend into the blueprint silhouette.
    @ViewBuilder
    private var interiorOverlay: some View {
        if state.hasMetrics {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(zoneFill)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    state.filled > 0 ? Theme.accent : Theme.chassisLine,
                    lineWidth: state.filled > 0 ? 1.5 : 1
                )
        }
    }

    // Slice of the body's chassisFillTop → chassisFillBottom gradient,
    // sampled at this zone's y range. Stacks on top of the blueprint
    // fill to produce the distinct active-zone box.
    private var zoneFill: LinearGradient {
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
