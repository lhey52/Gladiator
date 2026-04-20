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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self, Track.self])
    }
}
