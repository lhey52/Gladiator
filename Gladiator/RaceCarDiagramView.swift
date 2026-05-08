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
    var style: VehicleStyle = .formula
    let onTapZone: (CarZone) -> Void

    // Hidden via Settings → Session Customization → Setup Zones. The
    // diagram simply skips disabled zones — their data, analytics, and
    // tap routing elsewhere in the app are untouched.
    @AppStorage("disabledSetupZones") private var disabledZonesRaw: String = "Engine"

    private var visibleZones: [CarZone] {
        let disabled = Set(disabledZonesRaw.split(separator: ",").map(String.init))
        return CarZone.carZones.filter { !disabled.contains($0.rawValue) }
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                blueprintLayer

                ForEach(visibleZones) { zone in
                    let layout = RaceCarDiagramView.layout(for: zone, style: style)
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

    // Per-style silhouette layer behind the zone overlays. Formula stays as
    // SwiftUI shapes (chassis silhouette + tires + axle stubs rendered as
    // one fill + one stroke pass). Late Model uses the LateModelBlueprint
    // SVG asset so a hand-drawn silhouette can replace the procedural one
    // — Preserve Vector Data must be enabled on the asset for crisp scaling.
    @ViewBuilder
    private var blueprintLayer: some View {
        switch style {
        case .formula:
            CarChassisFillShape(style: style)
                .fill(
                    LinearGradient(
                        colors: [Theme.chassisFillTop, Theme.chassisFillBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            CarChassisStrokeShape(style: style)
                .stroke(Theme.chassisLine, lineWidth: 1)
        case .lateModel:
            // SVG is black lines on transparent at landscape orientation
            // (car facing sideways). Sizing the image to a transposed
            // (landscape) frame *before* rotating means scaledToFit fills
            // the long axis cleanly, then the 90° rotation lands a
            // portrait-oriented car covering the full diagram area —
            // without this swap, scaledToFit on the portrait container
            // letterboxes the SVG and the rotated result reads small.
            GeometryReader { geo in
                Image("LateModelBlueprint")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Theme.chassisLine)
                    .frame(width: geo.size.height, height: geo.size.width)
                    .rotationEffect(.degrees(90))
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
    }

    @ViewBuilder
    private func zoneCellView(for zone: CarZone) -> some View {
        let cell = ZoneCell(
            zone: zone,
            state: zoneStates[zone] ?? ZoneFillState(filled: 0, total: 0),
            style: style,
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

    // Tire positions vary per style — Formula keeps the open-wheel layout
    // at the canvas edges, Late Model tucks smaller wheels next to the
    // body. Chassis / engine swap front-to-back on Late Model so the
    // engine sits at the front of the silhouette (where it lives on a
    // stock car) and the chassis sits behind it.
    static func layout(for zone: CarZone, style: VehicleStyle = .formula) -> (center: CGPoint, size: CGSize) {
        switch zone {
        case .flTire, .frTire, .blTire, .brTire:
            return tireLayout(for: zone, style: style)
        case .chassis:
            switch style {
            case .formula:
                return (CGPoint(x: 0.50, y: 0.39), CGSize(width: 0.34, height: 0.17))
            case .lateModel:
                return (CGPoint(x: 0.50, y: 0.58), CGSize(width: 0.34, height: 0.17))
            }
        case .engine:
            switch style {
            case .formula:
                return (CGPoint(x: 0.50, y: 0.62), CGSize(width: 0.40, height: 0.20))
            case .lateModel:
                return (CGPoint(x: 0.50, y: 0.225), CGSize(width: 0.34, height: 0.17))
            }
        case .general:
            return (CGPoint.zero, CGSize.zero)
        }
    }

    private static func tireLayout(for zone: CarZone, style: VehicleStyle) -> (center: CGPoint, size: CGSize) {
        switch style {
        case .formula:
            let size = CGSize(width: 0.20, height: 0.13)
            switch zone {
            case .flTire: return (CGPoint(x: 0.13, y: 0.22), size)
            case .frTire: return (CGPoint(x: 0.87, y: 0.22), size)
            case .blTire: return (CGPoint(x: 0.13, y: 0.78), size)
            case .brTire: return (CGPoint(x: 0.87, y: 0.78), size)
            default: return (CGPoint.zero, CGSize.zero)
            }
        case .lateModel:
            let size = CGSize(width: 0.20, height: 0.13)
            switch zone {
            case .flTire: return (CGPoint(x: 0.20, y: 0.32), size)
            case .frTire: return (CGPoint(x: 0.80, y: 0.32), size)
            case .blTire: return (CGPoint(x: 0.20, y: 0.68), size)
            case .brTire: return (CGPoint(x: 0.80, y: 0.68), size)
            default: return (CGPoint.zero, CGSize.zero)
            }
        }
    }
}

// MARK: - Unified blueprint geometry

enum BlueprintGeometry {
    // Tire rects per style. Must stay aligned with RaceCarDiagramView.layout
    // so per-zone overlays in ZoneCell sit exactly on top of the drawn
    // tires. Formula keeps open-wheel positions; Late Model uses smaller
    // tires tucked next to the body.
    static func tireRects(for style: VehicleStyle) -> [CGRect] {
        switch style {
        case .formula:
            return [
                CGRect(x: 0.03, y: 0.155, width: 0.20, height: 0.13), // FL
                CGRect(x: 0.77, y: 0.155, width: 0.20, height: 0.13), // FR
                CGRect(x: 0.03, y: 0.715, width: 0.20, height: 0.13), // BL
                CGRect(x: 0.77, y: 0.715, width: 0.20, height: 0.13)  // BR
            ]
        case .lateModel:
            return [
                CGRect(x: 0.10, y: 0.255, width: 0.20, height: 0.13), // FL
                CGRect(x: 0.70, y: 0.255, width: 0.20, height: 0.13), // FR
                CGRect(x: 0.10, y: 0.615, width: 0.20, height: 0.13), // BL
                CGRect(x: 0.70, y: 0.615, width: 0.20, height: 0.13)  // BR
            ]
        }
    }
    static let tireCorner: CGFloat = 6

    static let axleStubHeight: CGFloat = 0.014
    static let leftTireInnerX: CGFloat = 0.23
    static let rightTireInnerX: CGFloat = 0.77

    // Formula-only — front and rear wings drawn as separate rounded rects.
    static let frontBumper = CGRect(x: 0.07, y: 0.0225, width: 0.86, height: 0.055)
    static let rearBumper = CGRect(x: 0.02, y: 0.9225, width: 0.96, height: 0.065)
    static let bumperCorner: CGFloat = 4

    // Per-style chassis edge x-coords at each axle y. Empty array means no
    // axle stub bridge is drawn — used for body styles where the silhouette
    // and tires sit independently or already share an edge.
    static func axles(for style: VehicleStyle) -> [(yRatio: CGFloat, chassisLeftX: CGFloat, chassisRightX: CGFloat)] {
        switch style {
        case .formula:
            return [(0.22, 0.305, 0.695), (0.78, 0.281, 0.719)]
        case .lateModel:
            return []
        }
    }

    // Adds the chassis (and wings, if any) for the requested style.
    static func addChassis(to p: inout Path, w: CGFloat, h: CGFloat, style: VehicleStyle) {
        switch style {
        case .formula:
            addFormulaBumpers(to: &p, w: w, h: h)
            addFormulaChassis(to: &p, w: w, h: h)
        case .lateModel:
            addLateModelBody(to: &p, w: w, h: h)
        }
    }

    static func addTires(to p: inout Path, w: CGFloat, h: CGFloat, style: VehicleStyle) {
        for tire in tireRects(for: style) {
            p.addRoundedRect(
                in: CGRect(x: w * tire.minX, y: h * tire.minY,
                           width: w * tire.width, height: h * tire.height),
                cornerSize: CGSize(width: tireCorner, height: tireCorner)
            )
        }
    }

    // MARK: - Formula

    static func addFormulaChassis(to p: inout Path, w: CGFloat, h: CGFloat) {
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

    static func addFormulaBumpers(to p: inout Path, w: CGFloat, h: CGFloat) {
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

    // MARK: - Late Model

    // Same family as the F1 chassis silhouette but symmetric front-to-rear,
    // with a flatter / more oval flare and no wings or axle stubs. Tires
    // sit slightly inboard from the F1 positions so the body reads with
    // realistic stock-car overhang at the front and rear.
    static func addLateModelBody(to p: inout Path, w: CGFloat, h: CGFloat) {
        p.move(to: CGPoint(x: w * 0.40, y: h * 0.05))
        p.addLine(to: CGPoint(x: w * 0.60, y: h * 0.05))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.73, y: h * 0.50),
            control: CGPoint(x: w * 0.66, y: h * 0.27)
        )
        p.addQuadCurve(
            to: CGPoint(x: w * 0.60, y: h * 0.95),
            control: CGPoint(x: w * 0.66, y: h * 0.73)
        )
        p.addLine(to: CGPoint(x: w * 0.40, y: h * 0.95))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.27, y: h * 0.50),
            control: CGPoint(x: w * 0.34, y: h * 0.73)
        )
        p.addQuadCurve(
            to: CGPoint(x: w * 0.40, y: h * 0.05),
            control: CGPoint(x: w * 0.34, y: h * 0.27)
        )
        p.closeSubpath()
    }
}

// MARK: - Blueprint shapes (fill + stroke)

// Filled regions for the entire blueprint. Stubs are drawn as full rectangles
// so the gradient fills the gap between chassis edge and tire inner edge.
struct CarChassisFillShape: Shape {
    let style: VehicleStyle

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        BlueprintGeometry.addChassis(to: &p, w: w, h: h, style: style)
        BlueprintGeometry.addTires(to: &p, w: w, h: h, style: style)

        let stubH = BlueprintGeometry.axleStubHeight
        for axle in BlueprintGeometry.axles(for: style) {
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
// (no left/right) so the tire's inner edge and chassis edge aren't doubled
// where they meet the stub. Centerline divider lives here too.
struct CarChassisStrokeShape: Shape {
    let style: VehicleStyle

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        BlueprintGeometry.addChassis(to: &p, w: w, h: h, style: style)
        BlueprintGeometry.addTires(to: &p, w: w, h: h, style: style)

        // Centerline divider down the middle of the body
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.25))
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.75))

        let stubH = BlueprintGeometry.axleStubHeight
        for axle in BlueprintGeometry.axles(for: style) {
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
    let style: VehicleStyle
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
        let layout = RaceCarDiagramView.layout(for: zone, style: style)
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
        case .chassis: return 22
        case .engine: return 14
        case .general: return 6
        }
    }

    private var content: some View {
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
                .chassis: ZoneFillState(filled: 1, total: 4)
            ],
            onTapZone: { _ in }
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
