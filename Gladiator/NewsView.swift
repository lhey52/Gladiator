//
//  NewsView.swift
//  Gladiator
//

import SwiftUI

struct NewsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var news = NewsService.shared
    @State private var browserURL: URL?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if news.articles.isEmpty {
                    emptyState
                } else {
                    articleList
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
            .refreshable {
                await news.refresh()
            }
            .sheet(item: $browserURL) { url in
                SafariBrowserView(url: url)
                    .ignoresSafeArea()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "newspaper")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.6))
            Text("NO ARTICLES AVAILABLE")
                .font(.system(size: 13, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var articleList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(news.articles.enumerated()), id: \.element.id) { index, article in
                    Button {
                        browserURL = article.url
                    } label: {
                        articleRow(article)
                    }
                    .buttonStyle(.plain)

                    if index < news.articles.count - 1 {
                        Divider()
                            .background(Theme.hairline)
                            .padding(.leading, 14)
                    }
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func articleRow(_ article: NewsArticle) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(article.source.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                    Text("·")
                    Text(Self.dateFormatter.string(from: article.date).uppercased())
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
}

#Preview {
    NewsView()
        .preferredColorScheme(.dark)
}
