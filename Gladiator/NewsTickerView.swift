//
//  NewsTickerView.swift
//  Gladiator
//

import SwiftUI

struct NewsTickerView: View {
    @AppStorage("newsTickerEnabled") private var newsTickerEnabled: Bool = true
    @ObservedObject private var service = NewsService.shared
    @State private var selectedArticle: NewsArticle?

    var body: some View {
        if newsTickerEnabled, !service.articles.isEmpty {
            TickerRunning(articles: service.articles) { article in
                selectedArticle = article
            }
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .sheet(item: $selectedArticle) { article in
                SafariBrowserView(url: article.url)
            }
        }
    }
}

private struct TickerRunning: View {
    let articles: [NewsArticle]
    let onSelect: (NewsArticle) -> Void

    @State private var startDate: Date = .now
    @State private var cells: [Cell] = []
    @State private var totalWidth: CGFloat = 0

    private static let speed: CGFloat = 40
    private static let uiFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
    private static let separator = " · "

    private struct Cell {
        let id: String
        let article: NewsArticle
        let startX: CGFloat
        let width: CGFloat
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { context in
                HStack(spacing: 0) {
                    stream
                    stream
                }
                .fixedSize()
                .offset(x: offset(at: context.date))
                .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture {
                handleTap(viewportWidth: geo.size.width)
            }
        }
        .onAppear { recomputeCells() }
        .onChange(of: articles) { _, _ in recomputeCells() }
    }

    private var stream: some View {
        HStack(spacing: 0) {
            ForEach(cells, id: \.id) { cell in
                Text(cell.article.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                    .fixedSize()
                Text(Self.separator)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.accent)
                    .fixedSize()
            }
        }
    }

    private func offset(at date: Date) -> CGFloat {
        guard totalWidth > 0 else { return 0 }
        let elapsed = date.timeIntervalSince(startDate)
        let travel = CGFloat(elapsed) * Self.speed
        var rem = travel.truncatingRemainder(dividingBy: totalWidth)
        if rem < 0 { rem += totalWidth }
        return -rem
    }

    private func handleTap(viewportWidth: CGFloat) {
        guard totalWidth > 0 else { return }
        let currentOffset = offset(at: .now)
        let centerInContent = -currentOffset + viewportWidth / 2
        var wrapped = centerInContent.truncatingRemainder(dividingBy: totalWidth)
        if wrapped < 0 { wrapped += totalWidth }
        if let hit = cells.first(where: { wrapped >= $0.startX && wrapped < $0.startX + $0.width }) {
            onSelect(hit.article)
        } else if let first = articles.first {
            onSelect(first)
        }
    }

    private func recomputeCells() {
        let sepWidth = (Self.separator as NSString).size(withAttributes: [.font: Self.uiFont]).width
        var result: [Cell] = []
        var x: CGFloat = 0
        for (index, article) in articles.enumerated() {
            let titleWidth = (article.title as NSString).size(withAttributes: [.font: Self.uiFont]).width
            let cellWidth = titleWidth + sepWidth
            result.append(Cell(id: "\(article.id)-\(index)", article: article, startX: x, width: cellWidth))
            x += cellWidth
        }
        cells = result
        totalWidth = x
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        NewsTickerView()
            .padding(.horizontal, 20)
    }
    .preferredColorScheme(.dark)
}
