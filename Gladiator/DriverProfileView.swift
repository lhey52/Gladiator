//
//  DriverProfileView.swift
//  Gladiator
//

import SwiftUI

struct DriverProfileView: View {
    @AppStorage("driverFirstName") private var firstName: String = ""
    @AppStorage("driverLastName") private var lastName: String = ""
    @AppStorage("driverRacingNumber") private var racingNumber: String = ""
    @AppStorage("driverRacingCategory") private var racingCategory: String = ""
    @AppStorage("driverTeamName") private var teamName: String = ""

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case first, last, number, category, team
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
                .dismissKeyboardOnTap()

            ScrollView {
                VStack(spacing: 18) {
                    profileField(label: "FIRST NAME", text: $firstName, prompt: "e.g. Max", focus: .first)
                    profileField(label: "LAST NAME", text: $lastName, prompt: "e.g. Verstappen", focus: .last)
                    profileField(label: "RACING NUMBER", text: $racingNumber, prompt: "e.g. 33", focus: .number, keyboard: .numberPad)
                    profileField(label: "RACING CATEGORY", text: $racingCategory, prompt: "e.g. GT3, Formula 4, Karting", focus: .category)
                    profileField(label: "TEAM NAME", text: $teamName, prompt: "e.g. Red Bull Racing", focus: .team)
                }
                .padding(20)
                .padding(.top, 4)
            }

        }
        .navigationTitle("Driver Profile")
        .navigationBarTitleDisplayMode(.inline)
        .keyboardToolbar(focusedField: $focusedField, fields: [.first, .last, .number, .category, .team])
    }

    private func profileField(
        label: String,
        text: Binding<String>,
        prompt: String,
        focus: Field,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)
            TextField(
                "",
                text: text,
                prompt: Text(prompt).foregroundColor(Theme.textTertiary)
            )
            .font(.system(size: 18, weight: .heavy))
            .foregroundColor(Theme.textPrimary)
            .keyboardType(keyboard)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .focused($focusedField, equals: focus)
        }
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

#Preview {
    NavigationStack {
        DriverProfileView()
    }
    .preferredColorScheme(.dark)
}
