//
//  NewsView.swift
//  Gladiator
//

import SwiftUI

struct NewsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("newsFeedEnabled") private var newsEnabled: Bool = true
    @ObservedObject private var service = NewsService.shared
    @State private var selectedArticle: NewsArticle?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    attributionNote
                    content
                }
            }
            .navigationTitle("News")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .sheet(item: $selectedArticle) { article in
                SafariBrowserView(url: article.url)
            }
            .task {
                if newsEnabled {
                    await service.refresh()
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var attributionNote: some View {
        Text("News feed provided by Motorsport.com and Racecar Engineering.")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
    }

    @ViewBuilder
    private var content: some View {
        if !newsEnabled {
            messageState(icon: "bell.slash", message: "News refresh disabled")
        } else if !service.articles.isEmpty {
            articleList
        } else if service.isLoading {
            loadingState
        } else {
            messageState(icon: "wifi.slash", message: "No news available. Check your internet connection.")
        }
    }

    private func messageState(icon: String, message: String) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.7))
            Text(message.uppercased())
                .font(.system(size: 12, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView()
                .tint(Theme.accent)
                .scaleEffect(1.2)
            Text("LOADING NEWS")
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var articleList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(service.articles.enumerated()), id: \.element.id) { index, article in
                    Button {
                        selectedArticle = article
                    } label: {
                        NewsRow(article: article)
                    }
                    .buttonStyle(.plain)
                    if index < service.articles.count - 1 {
                        Divider().background(Theme.hairline).padding(.leading, 29)
                    }
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .refreshable {
            if newsEnabled {
                await service.refresh()
            }
        }
    }
}

struct NewsRow: View {
    let article: NewsArticle
    var showsAccentBar: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            if showsAccentBar {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Theme.accent)
                    .frame(width: 3, height: 40)
                    .padding(.leading, 14)
                    .padding(.trailing, 12)
                    .shadow(color: Theme.accent.opacity(0.5), radius: 4)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 5) {
                    Text(article.source.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                    Text("·")
                    Text(NewsRowFormatting.relative(from: article.date))
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                }
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
            }
            .padding(.leading, showsAccentBar ? 0 : 14)

            Spacer()

            Image(systemName: "safari")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.textTertiary)
                .padding(.trailing, 14)
                .padding(.leading, 10)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

enum NewsRowFormatting {
    static func relative(from date: Date) -> String {
        let interval = Date.now.timeIntervalSince(date)
        if interval < 60 { return "JUST NOW" }
        if interval < 3600 {
            return "\(Int(interval / 60))M AGO"
        }
        if interval < 86400 {
            return "\(Int(interval / 3600))H AGO"
        }
        if interval < 86400 * 7 {
            return "\(Int(interval / 86400))D AGO"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date).uppercased()
    }
}

#Preview {
    NewsView()
        .preferredColorScheme(.dark)
}
