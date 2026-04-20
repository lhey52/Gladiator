//
//  ResetView.swift
//  Gladiator
//

import SwiftUI

struct ResetView: View {
    @AppStorage("sessionFormTipDismissed") private var sessionFormTipDismissed: Bool = false
    @AppStorage("dashboardTipDismissed") private var dashboardTipDismissed: Bool = false
    @State private var showingConfirm: Bool = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            List {
                Button {
                    showingConfirm = true
                } label: {
                    Text("Reset Tooltips")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(.red)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Reset")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset Tooltips", isPresented: $showingConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                sessionFormTipDismissed = false
                dashboardTipDismissed = false
            }
        } message: {
            Text("This will restore all dismissed tips. Continue?")
        }
    }
}

#Preview {
    NavigationStack {
        ResetView()
    }
    .preferredColorScheme(.dark)
}
