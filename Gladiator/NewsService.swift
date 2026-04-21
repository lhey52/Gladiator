//
//  NewsService.swift
//  Gladiator
//

import Foundation

struct NewsArticle: Identifiable, Codable {
    let id: UUID
    let title: String
    let source: String
    let date: Date
    let url: URL
}

@MainActor
final class NewsService: ObservableObject {
    static let shared = NewsService()

    @Published var articles: [NewsArticle] = []
    @Published var isLoading: Bool = false

    private let feeds: [(url: String, source: String)] = [
        ("https://www.motorsport.com/rss/all/news", "Motorsport.com"),
        ("https://www.racecar-engineering.com/feed", "Racecar Engineering")
    ]

    private static let cacheKey = "cachedNewsArticles"

    private init() {
        loadCache()
    }

    func refresh() async {
        isLoading = true
        var allArticles: [NewsArticle] = []

        for feed in feeds {
            guard let url = URL(string: feed.url) else { continue }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let parsed = RSSParser.parse(data: data, source: feed.source)
                allArticles.append(contentsOf: parsed)
            } catch {
                continue
            }
        }

        if !allArticles.isEmpty {
            articles = allArticles.sorted { $0.date > $1.date }
            saveCache()
        }
        isLoading = false
    }

    private func loadCache() {
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey),
              let cached = try? JSONDecoder().decode([NewsArticle].self, from: data) else { return }
        articles = cached
    }

    private func saveCache() {
        guard let data = try? JSONEncoder().encode(articles) else { return }
        UserDefaults.standard.set(data, forKey: Self.cacheKey)
    }
}

private enum RSSParser {
    static func parse(data: Data, source: String) -> [NewsArticle] {
        let delegate = RSSParserDelegate(source: source)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.articles
    }
}

private final class RSSParserDelegate: NSObject, XMLParserDelegate {
    let source: String
    var articles: [NewsArticle] = []

    private var currentElement: String = ""
    private var currentTitle: String = ""
    private var currentLink: String = ""
    private var currentPubDate: String = ""
    private var insideItem: Bool = false

    private static let dateFormatters: [DateFormatter] = {
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss zzz",
            "yyyy-MM-dd'T'HH:mm:ssZ"
        ]
        return formats.map { format in
            let f = DateFormatter()
            f.dateFormat = format
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }
    }()

    init(source: String) {
        self.source = source
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "item" || elementName == "entry" {
            insideItem = true
            currentTitle = ""
            currentLink = ""
            currentPubDate = ""
        }
        if insideItem, elementName == "link", let href = attributes["href"] {
            currentLink = href
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "pubDate", "published", "updated": currentPubDate += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        guard elementName == "item" || elementName == "entry" else { return }
        insideItem = false

        let title = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let link = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
        let pubDate = currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty, let url = URL(string: link) else { return }

        let date = Self.dateFormatters.compactMap { $0.date(from: pubDate) }.first ?? .now

        articles.append(NewsArticle(
            id: UUID(),
            title: title,
            source: source,
            date: date,
            url: url
        ))
    }
}
