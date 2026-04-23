//
//  ContentView.swift
//  Gladiator
//
//  Created by Daniel Hey on 3/17/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection: Int = 0
    @State private var sessionsTypeFilter: SessionType?
    @State private var pendingImportURL: URL?
    @State private var showingImportConfirm: Bool = false
    @State private var showingImportError: Bool = false
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    @State private var isShowingTutorial: Bool = false
    @Environment(\.modelContext) private var modelContext

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.background)
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.08)

        let itemAppearance = appearance.stackedLayoutAppearance
        itemAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.45)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.45),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        itemAppearance.selected.iconColor = UIColor(Theme.accent)
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.accent),
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(Theme.background)
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .heavy)
        ]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
    }

    var body: some View {
        TabView(selection: $selection) {
            DashboardView(onSelectType: { type in
                    sessionsTypeFilter = type
                    selection = 2
                })
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.open.with.lines.needle.33percent")
                }
                .tag(0)

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.xyaxis.line")
                }
                .tag(1)

            SessionsView(externalTypeFilter: $sessionsTypeFilter)
                .tabItem {
                    Label("Sessions", systemImage: "flag.checkered")
                }
                .tag(2)

            PitView()
                .tabItem {
                    Label("The Pit", systemImage: "wrench.and.screwdriver.fill")
                }
                .tag(3)
//MARK setting icon was slider.horizontal.3
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
        .overlay {
            if isShowingTutorial {
                TutorialView(isPresented: $isShowingTutorial, selectedTab: $selection)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isShowingTutorial)
        .onAppear {
            if !hasSeenTutorial && !isShowingTutorial {
                isShowingTutorial = true
            }
        }
        .onChange(of: hasSeenTutorial) { _, newValue in
            if !newValue { isShowingTutorial = true }
        }
        .onChange(of: isShowingTutorial) { _, newValue in
            if !newValue { hasSeenTutorial = true }
        }
        .onOpenURL { url in
            guard url.pathExtension.lowercased() == GladiatorDataExport.fileExtension else { return }
            pendingImportURL = url
            showingImportConfirm = true
        }
        .alert(
            "Import Gladiator data?",
            isPresented: $showingImportConfirm,
            presenting: pendingImportURL
        ) { url in
            Button("Cancel", role: .cancel) {
                pendingImportURL = nil
            }
            Button("Import") {
                performImport(url: url)
            }
        } message: { _ in
            Text("Note: duplicate sessions will not be excluded and may result in duplicate entries. This cannot be undone.")
        }
        .alert("Import failed", isPresented: $showingImportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The file may be corrupted or incompatible.")
        }
    }

    private func performImport(url: URL) {
        defer { pendingImportURL = nil }
        do {
            try GladiatorDataExport.importData(from: url, into: modelContext)
        } catch {
            showingImportError = true
        }
    }
}

#Preview {
    ContentView()
}
