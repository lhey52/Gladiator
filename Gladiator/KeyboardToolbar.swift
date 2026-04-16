//
//  KeyboardToolbar.swift
//  Gladiator
//

import SwiftUI

struct KeyboardToolbarModifier<Field: Hashable>: ViewModifier {
    @FocusState.Binding var focusedField: Field?
    let fields: [Field]

    private var currentIndex: Int? {
        guard let focused = focusedField else { return nil }
        return fields.firstIndex(of: focused)
    }

    private var hasPrevious: Bool {
        guard let index = currentIndex else { return false }
        return index > 0
    }

    private var hasNext: Bool {
        guard let index = currentIndex else { return false }
        return index < fields.count - 1
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button {
                        guard let index = currentIndex, index > 0 else { return }
                        focusedField = fields[index - 1]
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(hasPrevious ? Theme.accent : Theme.textTertiary)
                    }
                    .disabled(!hasPrevious)

                    Button {
                        guard let index = currentIndex, index < fields.count - 1 else { return }
                        focusedField = fields[index + 1]
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(hasNext ? Theme.accent : Theme.textTertiary)
                    }
                    .disabled(!hasNext)

                    Spacer()

                    Button {
                        focusedField = nil
                    } label: {
                        Text("Done")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Theme.accent)
                    }
                }
            }
    }
}

struct DismissKeyboardOnTapModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
    }
}

extension View {
    func keyboardToolbar<Field: Hashable>(
        focusedField: FocusState<Field?>.Binding,
        fields: [Field]
    ) -> some View {
        modifier(KeyboardToolbarModifier(focusedField: focusedField, fields: fields))
    }

    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTapModifier())
    }
}
