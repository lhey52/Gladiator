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
    @AppStorage("driverFirstName") private var firstName: String = ""
    @AppStorage("driverTeamName") private var teamName: String = ""
    @AppStorage("driverRacingNumber") private var racingNumber: String = ""
    @AppStorage("showNewsTicker") private var showNewsTicker: Bool = true
    @ObservedObject private var news = NewsService.shared

    @State private var greeting: String = ""
    @State private var showingNews: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        if showNewsTicker, !news.articles.isEmpty {
                            newsTicker
                        }
                        if sessions.isEmpty, !tipDismissed {
                            dashboardTip
                        }
                        header
                        SummarySection(sessions: sessions)
                        TypeBreakdownSection(sessions: sessions, onSelectType: onSelectType)
                        ActivityChartSection(sessions: sessions)
                        RecentSessionsSection(sessions: Array(sessions.prefix(5)))
                        if !news.articles.isEmpty {
                            latestNewsSection
                        }
                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                let profile = DashboardMessages.DriverProfile(
                    firstName: firstName,
                    teamName: teamName,
                    racingNumber: racingNumber
                )
                greeting = DashboardMessages.generate(sessions: sessions, profile: profile)
                Task { await news.refresh() }
            }
            .fullScreenCover(isPresented: $showingNews) {
                NewsView()
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

    private var newsTicker: some View {
        let tickerText = news.articles.prefix(10).map { "\($0.title)  ·  \($0.source)" }.joined(separator: "     ")
        return NewsTickerView(text: tickerText) { index in
            let articles = Array(news.articles.prefix(10))
            guard index < articles.count else { return }
            UIApplication.shared.open(articles[index].url)
        }
    }

    private static let newsDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd"
        return f
    }()

    private var latestNewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("LATEST NEWS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Button { showingNews = true } label: {
                    HStack(spacing: 4) {
                        Text("SEE ALL")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(Theme.accent)
                }
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(news.articles.prefix(5).enumerated()), id: \.element.id) { index, article in
                    Button {
                        UIApplication.shared.open(article.url)
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(article.title)
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(Theme.textPrimary)
                                    .lineLimit(2)
                                HStack(spacing: 6) {
                                    Text(article.source.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(1)
                                    Text("·")
                                    Text(Self.newsDateFormatter.string(from: article.date).uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(0.8)
                                }
                                .foregroundColor(Theme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.textTertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < min(news.articles.count, 5) - 1 {
                        Divider()
                            .background(Theme.hairline)
                            .padding(.leading, 14)
                    }
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DASHBOARD")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.textSecondary)
                Text(greeting.isEmpty ? "GLADIATOR" : greeting)
                    .font(.system(size: 28, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.textPrimary)
            }
            Spacer()
            ZStack {
                Circle().fill(Theme.surface).frame(width: 44, height: 44)
                Circle()
                    .stroke(Theme.accent.opacity(0.6), lineWidth: 1)
                    .frame(width: 44, height: 44)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.accent)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Summary

private struct SummarySection: View {
    let sessions: [Session]

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd · HH:mm"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("OVERVIEW", systemImage: "square.grid.2x2.fill")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(Theme.accent)
                Spacer()
            }

            HStack(alignment: .top, spacing: 14) {
                totalTile
                latestTile
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Theme.accent.opacity(0.18), radius: 18)
    }

    private var totalTile: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TOTAL SESSIONS")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
            Text("\(sessions.count)")
                .font(.system(size: 54, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var latestTile: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("MOST RECENT")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
            if let latest = sessions.first {
                Text(latest.trackName.isEmpty ? "Untitled Track" : latest.trackName)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text(Self.dayFormatter.string(from: latest.date).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.accent)
            } else {
                Text("—")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
                Text("NO SESSIONS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Type breakdown

private struct TypeBreakdownSection: View {
    let sessions: [Session]
    var onSelectType: ((SessionType) -> Void)?

    private func count(_ type: SessionType) -> Int {
        sessions.filter { $0.sessionType == type }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BY TYPE")
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
                .foregroundColor(Theme.textSecondary)
                .padding(.leading, 4)

            HStack(spacing: 12) {
                ForEach(SessionType.allCases) { type in
                    Button {
                        onSelectType?(type)
                    } label: {
                        TypeTile(type: type, count: count(type))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct TypeTile: View {
    let type: SessionType
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: type.systemImage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.accent)
                Spacer()
                Text(type.shortLabel)
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.textTertiary)
            }
            Text("\(count)")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text(type.rawValue.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(1.2)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
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
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
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
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface)
            )
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
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface)
        )
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

#Preview {
    DashboardView()
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self], inMemory: true)
        .preferredColorScheme(.dark)
}
