//
//  VehicleSilhouetteView.swift
//  Gladiator
//

import SwiftUI

// Silhouette-only preview of a VehicleStyle, reusing the same rendering
// approach as RaceCarDiagramView but with no zone overlays or interaction.
// Formula renders the procedural fill/stroke shapes; Late Model uses the
// LateModelBlueprint SVG asset (Preserve Vector Data must be enabled).
struct VehicleSilhouetteView: View {
    let style: VehicleStyle

    var body: some View {
        silhouette
            .aspectRatio(0.55, contentMode: .fit)
    }

    @ViewBuilder
    private var silhouette: some View {
        switch style {
        case .formula:
            ZStack {
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
            }
        case .lateModel:
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
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        HStack(spacing: 12) {
            VehicleSilhouetteView(style: .formula).frame(width: 80)
            VehicleSilhouetteView(style: .lateModel).frame(width: 80)
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
