//
//  DashboardView.swift
//  Gladiator
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        header
                        headlineCard
                        statGrid
                        recentSessions
                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.driverName)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.textSecondary)
                Text("GLADIATOR")
                    .font(.system(size: 28, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.textPrimary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.surface)
                    .frame(width: 44, height: 44)
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

    private var headlineCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("NEXT SESSION", systemImage: "location.north.line.fill")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(Theme.accent)
                Spacer()
                Text("LIVE")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.accent.opacity(0.15))
                    .overlay(
                        Capsule().stroke(Theme.accent.opacity(0.5), lineWidth: 1)
                    )
                    .clipShape(Capsule())
            }

            Text(viewModel.nextEvent)
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(Theme.textPrimary)

            Divider().background(Theme.hairline)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.headlineStat.label)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(Theme.textSecondary)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(viewModel.headlineStat.value)
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        Text(".\(viewModel.headlineStat.unit)")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(Theme.accent)
                    }
                }
                Spacer()
                if let delta = viewModel.headlineStat.delta {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Δ")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textSecondary)
                        Text(delta)
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(viewModel.headlineStat.deltaPositive ? Theme.accent : .red)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Theme.accent.opacity(0.18), radius: 18, x: 0, y: 0)
    }

    private var statGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TELEMETRY")
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
                .foregroundColor(Theme.textSecondary)
                .padding(.leading, 4)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(viewModel.tiles) { tile in
                    StatTileView(tile: tile)
                }
            }
        }
    }

    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT SESSIONS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text("\(viewModel.sessionCount) TOTAL")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(Theme.accent)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.recent.enumerated()), id: \.element.id) { index, session in
                    RecentSessionRow(session: session)
                    if index < viewModel.recent.count - 1 {
                        Divider().background(Theme.hairline).padding(.leading, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surface)
            )
        }
    }
}

private struct StatTileView: View {
    let tile: DashboardViewModel.StatTile

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tile.label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(tile.value)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text(tile.unit)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
            }

            if let delta = tile.delta {
                HStack(spacing: 4) {
                    Image(systemName: tile.deltaPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                    Text(delta)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(tile.deltaPositive ? Theme.accent : .red.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
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

private struct RecentSessionRow: View {
    let session: DashboardViewModel.RecentSession

    var body: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(Theme.accent)
                .frame(width: 3, height: 36)
                .shadow(color: Theme.accent.opacity(0.5), radius: 4)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.track)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                Text("\(session.date) · \(session.laps) LAPS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(session.bestLap)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.accent)
                Text("BEST")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.textTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(16)
    }
}

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
