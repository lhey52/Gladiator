//
//  DashboardView.swift
//  Gladiator
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    var onSelectType: ((SessionType) -> Void)?

    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]

    @AppStorage("dashboardTipDismissed") private var tipDismissed: Bool = false
    @AppStorage("dashboardDeviceTipDismissed") private var deviceTipDismissed: Bool = false
    @AppStorage("driverFirstName") private var firstName: String = ""
    @AppStorage("driverTeamName") private var teamName: String = ""
    @AppStorage("driverRacingNumber") private var racingNumber: String = ""

    @State private var greeting: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        NewsTickerView()
                        if sessions.isEmpty, !tipDismissed {
                            dashboardTip
                        }
                        if !deviceTipDismissed {
                            deviceTip
                        }
                        header
                        OverviewSection(sessions: sessions, onSelectType: onSelectType)
                        ActivityChartSection(sessions: sessions)
                        RecentSessionsSection(sessions: Array(sessions.prefix(5)))
                        LatestNewsSection()
                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Snapshot Sendable inputs on the main actor (we are
                // here), then compute the greeting in a detached task
                // so the SwiftData @Model array (`sessions`) doesn't
                // cross the actor boundary. DashboardMessages only
                // reads `session.date`, so the snapshot is just dates.
                let dates = sessions.map(\.date)
                let profile = DashboardMessages.DriverProfile(
                    firstName: firstName,
                    teamName: teamName,
                    racingNumber: racingNumber
                )
                Task {
                    let computed = await Task.detached(priority: .userInitiated) {
                        DashboardMessages.generate(sessionDates: dates, profile: profile)
                    }.value
                    greeting = computed
                }
                Task { await NewsService.shared.refresh() }
            }
        }
    }

    private var dashboardTip: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.accent)
            Text("Add new sessions to begin tracking and analyzing data.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Button { tipDismissed = true } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Theme.accent.opacity(0.12), radius: 10, y: 4)
    }

    private var deviceTip: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.accent)
            Text(deviceTipMessage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Button { deviceTipDismissed = true } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Theme.accent.opacity(0.12), radius: 10, y: 4)
    }

    private var deviceTipMessage: String {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return "Gladiator also works on iPhone."
        }
        return "Gladiator also works on iPad."
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("DASHBOARD")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Theme.textSecondary)
                    ProBadgeIfNeeded()
                }
                Text(greeting.isEmpty ? "GLADIATOR" : greeting)
                    .font(.system(size: 28, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.textPrimary)
            }
            Spacer()
            NavigationLink {
                SettingsView()
            } label: {
                ZStack {
                    Circle().fill(Theme.surface).frame(width: 44, height: 44)
                    Circle()
                        .stroke(Theme.accent.opacity(0.6), lineWidth: 1)
                        .frame(width: 44, height: 44)
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.top, 8)
    }
}

// MARK: - Overview

// Combined overview + type breakdown + most recent session. Total count
// is the hero on the left; most-recent track/date sits compact on the
// right of the same row. Per-type breakdown spans the full width below.
// Every label and number is lineLimit(1) + minimumScaleFactor so the
// section never wraps regardless of name length or count magnitude.
private struct OverviewSection: View {
    let sessions: [Session]
    var onSelectType: ((SessionType) -> Void)?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd"
        return f
    }()

    private func count(_ type: SessionType) -> Int {
        sessions.filter { $0.sessionType == type }.count
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("OVERVIEW")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.8)
                    .foregroundColor(Theme.accent)
                Spacer()
            }

            HStack(alignment: .center, spacing: 12) {
                totalBlock
                Spacer(minLength: 8)
                recentBlock
            }

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)

            HStack(spacing: 8) {
                ForEach(SessionType.allCases) { type in
                    Button {
                        onSelectType?(type)
                    } label: {
                        OverviewTypeChip(type: type, count: count(type))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .squarePanel()
    }

    private var totalBlock: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(sessions.count)")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("TOTAL SESSIONS")
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .layoutPriority(1)
    }

    @ViewBuilder
    private var recentBlock: some View {
        if let latest = sessions.first {
            VStack(alignment: .trailing, spacing: 2) {
                Text("MOST RECENT")
                    .font(.system(size: 8, weight: .heavy))
                    .tracking(1.4)
                    .foregroundColor(Theme.textTertiary)
                    .lineLimit(1)
                Text(latest.trackName.isEmpty ? "Untitled" : latest.trackName)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .truncationMode(.tail)
                Text(Self.dateFormatter.string(from: latest.date).uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(Theme.accent)
                    .lineLimit(1)
            }
        } else {
            VStack(alignment: .trailing, spacing: 2) {
                Text("MOST RECENT")
                    .font(.system(size: 8, weight: .heavy))
                    .tracking(1.4)
                    .foregroundColor(Theme.textTertiary)
                    .lineLimit(1)
                Text("—")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
                Text("NO SESSIONS")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(Theme.textTertiary)
                    .lineLimit(1)
            }
        }
    }
}

private struct OverviewTypeChip: View {
    let type: SessionType
    let count: Int

    var body: some View {
        VStack(spacing: 3) {
            Text("\(count)")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(type.shortLabel)
                .font(.system(size: 9, weight: .heavy))
                .tracking(1.2)
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

// MARK: - Activity chart

private struct ActivityChartSection: View {
    let sessions: [Session]

    @State private var showingDetail: Bool = false

    private struct DayBucket: Identifiable {
        let id: Date
        let date: Date
        let count: Int
    }

    private var buckets: [DayBucket] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.date)
        }
        return grouped
            .map { DayBucket(id: $0.key, date: $0.key, count: $0.value.count) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACTIVITY")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(sessions.count) SESSIONS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(Theme.accent)
            }
            .padding(.horizontal, 4)

            Button { showingDetail = true } label: {
                chartCard
            }
            .buttonStyle(.plain)
        }
        .fullScreenCover(isPresented: $showingDetail) {
            ActivityChartView()
        }
    }

    @ViewBuilder
    private var chartCard: some View {
        VStack {
            if buckets.isEmpty {
                Text("LOG A SESSION TO SEE ACTIVITY")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
            } else {
                chart
                    .frame(height: 180)
            }
        }
        .padding(16)
        .squarePanel()
    }

    private var chart: some View {
        Chart(buckets) { bucket in
            BarMark(
                x: .value("Date", bucket.date, unit: .day),
                y: .value("Sessions", bucket.count)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Theme.accent, Theme.accent.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel()
                    .foregroundStyle(Theme.textTertiary)
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(Theme.textTertiary)
                    .font(.system(size: 10, weight: .bold))
            }
        }
    }
}

// MARK: - Recent sessions

private struct RecentSessionsSection: View {
    let sessions: [Session]

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT SESSIONS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 4)

            if sessions.isEmpty {
                emptyCard
            } else {
                list
            }
        }
    }

    private var emptyCard: some View {
        Text("NO RECENT SESSIONS")
            .font(.system(size: 11, weight: .bold))
            .tracking(1.5)
            .foregroundColor(Theme.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .squarePanel()
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    RecentSessionRow(
                        session: session,
                        dateText: Self.dateFormatter.string(from: session.date).uppercased()
                    )
                }
                .buttonStyle(.plain)
                if index < sessions.count - 1 {
                    Divider().background(Theme.hairline).padding(.leading, 16)
                }
            }
        }
        .squarePanel()
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

private struct RecentSessionRow: View {
    let session: Session
    let dateText: String

    var body: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(Theme.accent)
                .frame(width: 3, height: 36)
                .shadow(color: Theme.accent.opacity(0.5), radius: 4)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.trackName.isEmpty ? "Untitled Track" : session.trackName)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                HStack(spacing: 6) {
                    Image(systemName: session.sessionType.systemImage)
                        .font(.system(size: 9, weight: .bold))
                    Text("\(dateText) · \(session.sessionType.rawValue.uppercased())")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.8)
                }
                .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(16)
    }
}

// MARK: - Latest news

private struct LatestNewsSection: View {
    @AppStorage("newsFeedEnabled") private var newsEnabled: Bool = true
    @ObservedObject private var service = NewsService.shared
    @State private var showingAllNews: Bool = false
    @State private var selectedArticle: NewsArticle?

    private var articles: [NewsArticle] {
        Array(service.articles.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            content
        }
        .fullScreenCover(isPresented: $showingAllNews) {
            NewsView()
        }
        .sheet(item: $selectedArticle) { article in
            SafariBrowserView(url: article.url)
        }
    }

    private var header: some View {
        HStack {
            Text("LATEST NEWS")
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
                .foregroundColor(Theme.textSecondary)
            Spacer()
            if newsEnabled, !articles.isEmpty {
                Button { showingAllNews = true } label: {
                    HStack(spacing: 4) {
                        Text("SEE ALL")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(Theme.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var content: some View {
        if !newsEnabled {
            disclaimer(icon: "bell.slash", text: "News refresh disabled")
        } else if !articles.isEmpty {
            list
        } else if service.isLoading {
            loadingCard
        } else {
            disclaimer(icon: "wifi.slash", text: "No news available. Check your internet connection.")
        }
    }

    private func disclaimer(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .squarePanel()
    }

    private var loadingCard: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(Theme.accent)
            Spacer()
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .squarePanel()
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                Button {
                    selectedArticle = article
                } label: {
                    NewsRow(article: article, showsAccentBar: false)
                }
                .buttonStyle(.plain)
                if index < articles.count - 1 {
                    Divider().background(Theme.hairline).padding(.leading, 14)
                }
            }
        }
        .squarePanel()
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self], inMemory: true)
        .preferredColorScheme(.dark)
}
