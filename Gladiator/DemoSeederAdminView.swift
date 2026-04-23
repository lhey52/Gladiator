//
//  DemoSeederAdminView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct DemoSeederAdminView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var pendingSeeder: SeederOption?
    @State private var showingConfirmation: Bool = false
    @State private var showingSuccess: Bool = false

    private enum SeederOption: String, Identifiable {
        case demo1
        case demo2

        var id: String { rawValue }

        var title: String {
            switch self {
            case .demo1: return "Demo 1"
            case .demo2: return "Demo 2"
            }
        }

        var icon: String {
            switch self {
            case .demo1: return "1.circle.fill"
            case .demo2: return "2.circle.fill"
            }
        }

        var subtitle: String {
            switch self {
            case .demo1:
                return "Populates basic sessions, metrics and tracks to demonstrate core app functionality."
            case .demo2:
                return "Populates tire pressure and race time data across 5 sessions to showcase the Performance Predictor tool."
            }
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    header
                    seederButton(.demo1)
                    seederButton(.demo2)
                }
                .padding(20)
            }
        }
        .navigationTitle("Demo Seeder")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Seed Demo Data",
            isPresented: $showingConfirmation,
            presenting: pendingSeeder
        ) { seeder in
            Button("Cancel", role: .cancel) {
                pendingSeeder = nil
            }
            Button("Seed") {
                runSeeder(seeder)
            }
        } message: { _ in
            Text("This will add demo data to your app. Existing data will not be removed. Continue?")
        }
        .alert("Demo data seeded successfully", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) { }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Theme.accent)
            Text("PRELOADED DATASETS")
                .font(.system(size: 11, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }

    private func seederButton(_ option: SeederOption) -> some View {
        Button {
            pendingSeeder = option
            showingConfirmation = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.accent.opacity(0.15))
                        .frame(width: 52, height: 52)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.accent.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 52, height: 52)
                    Image(systemName: option.icon)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title.uppercased())
                        .font(.system(size: 15, weight: .heavy))
                        .tracking(1.1)
                        .foregroundColor(Theme.textPrimary)
                    Text(option.subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.accent.opacity(0.25), lineWidth: 1.5)
            )
            .shadow(color: Theme.accent.opacity(0.1), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func runSeeder(_ seeder: SeederOption) {
        switch seeder {
        case .demo1:
            DemoDataSeeder.seed(into: modelContext)
        case .demo2:
            DemoDataSeeder.seedDemo2(into: modelContext)
        }
        pendingSeeder = nil
        showingSuccess = true
    }
}

#Preview {
    NavigationStack {
        DemoSeederAdminView()
    }
    .preferredColorScheme(.dark)
}
