//
//  VehicleView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct VehicleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Vehicle.name)])
    private var vehicles: [Vehicle]

    @State private var showingAdd: Bool = false
    @State private var vehicleToEdit: Vehicle?
    @State private var vehicleToDelete: Vehicle?
    @State private var showingPaywall: Bool = false
    @ObservedObject private var iap = IAPManager.shared

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                content
                vehicleLimitBanner
            }
        }
        .navigationTitle("Vehicles & Drivers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if iap.checkVehicleLimit(currentCount: vehicles.count) {
                        showingAdd = true
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            VehicleFormSheet(
                title: "New Vehicle",
                buttonLabel: "Add",
                initialName: "",
                existingNames: vehicles.map(\.name),
                excludeName: nil
            ) { name in
                let vehicle = Vehicle(name: name)
                modelContext.insert(vehicle)
            }
        }
        .sheet(item: $vehicleToEdit) { vehicle in
            VehicleFormSheet(
                title: "Edit Vehicle",
                buttonLabel: "Save",
                initialName: vehicle.name,
                existingNames: vehicles.map(\.name),
                excludeName: vehicle.name
            ) { newName in
                vehicle.name = newName
            }
        }
        .alert("Delete Vehicle", isPresented: Binding(
            get: { vehicleToDelete != nil },
            set: { if !$0 { vehicleToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { vehicleToDelete = nil }
            Button("Delete", role: .destructive) { confirmDelete() }
        } message: {
            if let vehicle = vehicleToDelete {
                Text("Are you sure you want to delete \"\(vehicle.name)\"?")
            }
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView(limitMessage: "You have reached the free limit of \(IAPManager.vehicleLimit) vehicles. Upgrade to Pro for unlimited vehicles.")
        }
    }

    @ViewBuilder
    private var content: some View {
        if vehicles.isEmpty {
            emptyState
        } else {
            vehicleList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "car.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text("NO VEHICLES")
                .font(.system(size: 16, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text("Add vehicles to quickly select them when logging sessions")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var vehicleList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(vehicles.enumerated()), id: \.element.id) { index, vehicle in
                    vehicleRow(vehicle)

                    if index < vehicles.count - 1 {
                        Divider()
                            .background(Theme.hairline)
                            .padding(.leading, 14)
                    }
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.top, 4)

            Text("Tap a vehicle to set or remove it as default. The default vehicle is pre-selected in new sessions.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
        }
    }

    private func vehicleRow(_ vehicle: Vehicle) -> some View {
        HStack(spacing: 12) {
            Button {
                toggleDefault(vehicle)
            } label: {
                HStack(spacing: 12) {
                    if vehicle.isDefault {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.accent)
                    } else {
                        Circle()
                            .stroke(Theme.textTertiary, lineWidth: 1.5)
                            .frame(width: 18, height: 18)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(vehicle.name)
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Theme.textPrimary)
                        if vehicle.isDefault {
                            Text("DEFAULT")
                                .font(.system(size: 9, weight: .heavy))
                                .tracking(1.2)
                                .foregroundColor(Theme.accent)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Menu {
                Button {
                    vehicleToEdit = vehicle
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    vehicleToDelete = vehicle
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func confirmDelete() {
        guard let vehicle = vehicleToDelete else { return }
        modelContext.delete(vehicle)
        vehicleToDelete = nil
    }

    private func toggleDefault(_ vehicle: Vehicle) {
        if vehicle.isDefault {
            vehicle.isDefault = false
        } else {
            for v in vehicles { v.isDefault = false }
            vehicle.isDefault = true
        }
    }

    @ViewBuilder
    private var vehicleLimitBanner: some View {
        if iap.isAtVehicleLimit(currentCount: vehicles.count) {
            Button { showingPaywall = true } label: {
                HStack(spacing: 8) {
                    Text("You've reached the free limit. Upgrade to Pro for unlimited vehicles.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                    Text("Upgrade to Pro")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Theme.accent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Theme.surface)
                .overlay(
                    Rectangle().frame(height: 1).foregroundColor(Theme.hairline),
                    alignment: .top
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct VehicleFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let buttonLabel: String
    let initialName: String
    let existingNames: [String]
    let excludeName: String?
    let onSave: (String) -> Void

    @State private var name: String = ""
    @State private var driver: String = ""

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private var combinedName: String {
        Vehicle.combine(name: name, driver: driver)
    }

    private var isDuplicate: Bool {
        let candidate = combinedName.lowercased()
        guard !candidate.isEmpty else { return false }
        return existingNames.contains { existing in
            let isExcluded = excludeName.map { $0.lowercased() == existing.lowercased() } ?? false
            return !isExcluded && existing.lowercased() == candidate
        }
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && !isDuplicate
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                    .dismissKeyboardOnTap()
                ScrollView {
                    VStack(spacing: 18) {
                        nameCard
                        driverCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(buttonLabel) {
                        onSave(combinedName)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(canSave ? Theme.accent : Theme.textTertiary)
                    .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            let parts = Vehicle.split(name: initialName)
            name = parts.name
            driver = parts.driver
        }
    }

    private var nameCard: some View {
        fieldCard(label: "VEHICLE NAME") {
            VStack(alignment: .leading, spacing: 8) {
                TextField(
                    "",
                    text: $name,
                    prompt: Text("e.g. Porsche 911 GT3").foregroundColor(Theme.textTertiary)
                )
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                if isDuplicate {
                    Text("A vehicle with this name and driver already exists.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
        }
    }

    private var driverCard: some View {
        fieldCard(label: "DRIVER (OPTIONAL)") {
            TextField(
                "",
                text: $driver,
                prompt: Text("e.g. John Smith, Driver 1").foregroundColor(Theme.textTertiary)
            )
            .font(.system(size: 18, weight: .heavy))
            .foregroundColor(Theme.textPrimary)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
        }
    }

    @ViewBuilder
    private func fieldCard<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        VehicleView()
    }
    .modelContainer(for: [Vehicle.self], inMemory: true)
    .preferredColorScheme(.dark)
}
