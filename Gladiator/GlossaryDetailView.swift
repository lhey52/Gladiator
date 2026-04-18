//
//  GlossaryDetailView.swift
//  Gladiator
//

import SwiftUI

struct GlossaryDetailView: View {
    let term: GlossaryTerm

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    definitionCard
                    if !term.children.isEmpty {
                        childrenSection
                    }
                    if !term.seeAlso.isEmpty {
                        seeAlsoSection
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(term.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var definitionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DEFINITION")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)
            Text(term.definition)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
        )
    }

    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RELATED TERMS")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 10) {
                ForEach(term.children) { child in
                    childCard(child)
                }
            }
        }
    }

    private func childCard(_ child: GlossaryChild) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(child.name.uppercased())
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.2)
                .foregroundColor(Theme.accent)
            Text(child.definition)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private var seeAlsoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SEE ALSO")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 6) {
                ForEach(term.seeAlso, id: \.self) { ref in
                    if let target = GlossaryData.find(byName: ref) {
                        NavigationLink {
                            GlossaryDetailView(term: target)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.turn.down.right")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.accent)
                                Text(ref)
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(Theme.accent)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.textTertiary)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Theme.accent.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        GlossaryDetailView(term: GlossaryData.allTerms[0])
    }
    .preferredColorScheme(.dark)
}
