//
//  NewsService.swift
//  Gladiator
//

import Foundation
import Combine

struct NewsArticle: Identifiable, Hashable {
    let id: String
    let title: String
    let source: String
    let date: Date
    let url: URL
}

@MainActor
final class NewsService: ObservableObject {
    static let shared = NewsService()
    static let enabledKey = "newsFeedEnabled"

    @Published private(set) var articles: [NewsArticle] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var hasError: Bool = false

    private static let sources: [(name: String, urlString: String)] = [
        ("Motorsport.com", "https://www.motorsport.com/rss/all/news/"),
        ("Racecar Engineering", "https://www.racecar-engineering.com/feed/")
    ]

    private init() {}

    var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: Self.enabledKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    func refresh() async {
        guard isEnabled else {
            articles = []
            isLoading = false
            hasError = false
            return
        }

        isLoading = true
        hasError = false

        let result = await Self.fetchAll()

        articles = result.articles
        isLoading = false
        hasError = !result.anySucceeded
    }

    private static func fetchAll() async -> (articles: [NewsArticle], anySucceeded: Bool) {
        await withTaskGroup(of: (articles: [NewsArticle], ok: Bool).self) { group in
            for src in sources {
                guard let url = URL(string: src.urlString) else { continue }
                group.addTask {
                    await fetchFeed(source: src.name, url: url)
                }
            }

            var all: [NewsArticle] = []
            var anyOk = false
            for await result in group {
                if result.ok { anyOk = true }
                all.append(contentsOf: result.articles)
            }
            return (all.sorted { $0.date > $1.date }, anyOk)
        }
    }

    private static func fetchFeed(source: String, url: URL) async -> (articles: [NewsArticle], ok: Bool) {
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                return ([], false)
            }
            let parser = RSSParser(source: source)
            return (parser.parse(data: data), true)
        } catch {
            return ([], false)
        }
    }
}

private final class RSSParser: NSObject, XMLParserDelegate {
    private let source: String
    private var articles: [NewsArticle] = []
    private var currentElement: String = ""
    private var currentTitle: String = ""
    private var currentLink: String = ""
    private var currentDate: String = ""
    private var insideItem: Bool = false

    init(source: String) {
        self.source = source
    }

    func parse(data: Data) -> [NewsArticle] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return articles
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        if elementName == "item" {
            insideItem = true
            currentTitle = ""
            currentLink = ""
            currentDate = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        switch currentElement {
        case "title":
            currentTitle += string
        case "link":
            currentLink += string
        case "pubDate":
            currentDate += string
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard insideItem, let string = String(data: CDATABlock, encoding: .utf8) else { return }
        switch currentElement {
        case "title":
            currentTitle += string
        case "link":
            currentLink += string
        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "item" {
            insideItem = false
            let trimmedLink = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedTitle = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedDate = currentDate.trimmingCharacters(in: .whitespacesAndNewlines)

            if let url = URL(string: trimmedLink), !trimmedTitle.isEmpty {
                let date = Self.parseDate(trimmedDate) ?? .now
                articles.append(NewsArticle(
                    id: trimmedLink,
                    title: trimmedTitle,
                    source: source,
                    date: date,
                    url: url
                ))
            }
        }
        currentElement = ""
    }

    private static func parseDate(_ string: String) -> Date? {
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss zzz",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        ]
        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }
}
