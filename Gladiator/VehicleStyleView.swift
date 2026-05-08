//
//  VehicleStyleView.swift
//  Gladiator
//

import SwiftUI

struct VehicleStyleView: View {
    @AppStorage(VehicleStyle.storageKey) private var styleRaw: String = VehicleStyle.lateModel.rawValue

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(VehicleStyle.allCases) { style in
                        styleCard(style)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Vehicle Style")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func styleCard(_ style: VehicleStyle) -> some View {
        let isSelected = (style.rawValue == styleRaw)
        return Button {
            styleRaw = style.rawValue
        } label: {
            HStack(spacing: 16) {
                VehicleSilhouetteView(style: style)
                    .frame(width: 56, height: 102)

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.displayName)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text(style.description)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Theme.accent.opacity(0.1) : Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? Theme.accent.opacity(0.5) : Theme.hairline,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        VehicleStyleView()
    }
    .preferredColorScheme(.dark)
}
