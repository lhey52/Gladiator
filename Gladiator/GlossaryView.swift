//
//  GlossaryView.swift
//  Gladiator
//

import SwiftUI

struct GlossaryView: View {
    @State private var searchText: String = ""

    private var results: [GlossaryTerm] {
        GlossaryData.search(query: searchText)
    }

    private var groupedResults: [(letter: String, terms: [GlossaryTerm])] {
        let grouped = Dictionary(grouping: results) { term in
            String(term.name.prefix(1)).uppercased()
        }
        return grouped
            .sorted { $0.key < $1.key }
            .map { (letter: $0.key, terms: $0.value.sorted { $0.name < $1.name }) }
    }

var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                searchBar
                if results.isEmpty {
                    emptyState
                } else {
                    indexedList
                }
            }
        }
        .navigationTitle("Glossary")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.textSecondary)
            TextField("", text: $searchText, prompt: Text("Search terms").foregroundColor(Theme.textTertiary))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .autocorrectionDisabled()
                .submitLabel(.done)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.textTertiary)
            Text("NO MATCHING TERMS")
                .font(.system(size: 12, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var indexedList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(groupedResults, id: \.letter) { group in
                    sectionHeader(group.letter)

                    VStack(spacing: 0) {
                        ForEach(Array(group.terms.enumerated()), id: \.element.id) { index, term in
                            NavigationLink {
                                GlossaryDetailView(term: term)
                            } label: {
                                termRow(term)
                            }
                            .buttonStyle(.plain)

                            if index < group.terms.count - 1 {
                                Divider()
                                    .background(Theme.hairline)
                                    .padding(.leading, 14)
                            }
                        }
                    }
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 20)
                }

                Color.clear.frame(height: 20)
            }
        }
    }

    private func sectionHeader(_ letter: String) -> some View {
        Text(letter)
            .font(.system(size: 13, weight: .heavy))
            .tracking(2)
            .foregroundColor(Theme.accent)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }

    private func termRow(_ term: GlossaryTerm) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(term.name)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    if !term.children.isEmpty {
                        Text("(\(term.children.count))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textTertiary)
                    }
                }

                if !searchText.isEmpty {
                    let matched = GlossaryData.matchingChildIDs(in: term, query: searchText)
                    if !matched.isEmpty {
                        let names = term.children.filter { matched.contains($0.id) }.map(\.name)
                        Text("Includes: \(names.joined(separator: ", "))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.accent)
                            .lineLimit(1)
                    }
                }

                Text(term.definition)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        GlossaryView()
    }
    .preferredColorScheme(.dark)
}
