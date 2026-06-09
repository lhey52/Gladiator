//
//  GladiatorApp.swift
//  Gladiator
//
//  Created by Daniel Hey on 3/17/26.
//

import SwiftUI
import SwiftData

@main
struct GladiatorApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Start the StoreKit transaction listener at launch so it
                    // runs for the whole app lifetime (Ask-to-Buy approvals,
                    // renewals, refunds, cross-device purchases).
                    IAPManager.shared.start()
                    // Revoke any active track code whose expiry has passed, so
                    // a code grant (Pro / admin) can't outlive the code itself.
                    TrackCodes.revokeActiveCodeIfExpired()
                }
                .onChange(of: scenePhase) { _, phase in
                    // Re-validate entitlements when returning to the foreground.
                    // A subscription that simply expired produces no
                    // Transaction.updates event, so the listener won't catch it
                    // — this foreground check (reading currentEntitlements) does.
                    if phase == .active {
                        Task { await IAPManager.shared.checkSubscriptionStatus() }
                    }
                }
        }
        .modelContainer(for: [
            Session.self,
            CustomField.self,
            FieldValue.self,
            Track.self,
            Vehicle.self,
            PitNote.self,
            PitChecklistTemplate.self,
            PitChecklistItem.self,
            PitGoal.self,
            PitReminder.self
        ])
    }
}
