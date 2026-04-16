//
//  TimePickerInput.swift
//  Gladiator
//

import SwiftUI

struct TimePickerInput: View {
    @Binding var totalSeconds: Double

    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    @State private var millis: Int = 0
    @State private var didLoad: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Picker("", selection: $minutes) {
                ForEach(0..<60, id: \.self) { m in
                    Text("\(m)")
                        .foregroundColor(Theme.textPrimary)
                        .tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 60)
            .clipped()

            Text("m")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(Theme.textSecondary)

            Picker("", selection: $seconds) {
                ForEach(0..<60, id: \.self) { s in
                    Text(String(format: "%02d", s))
                        .foregroundColor(Theme.textPrimary)
                        .tag(s)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 60)
            .clipped()

            Text("s")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(Theme.textSecondary)

            Picker("", selection: $millis) {
                ForEach(0..<1000, id: \.self) { ms in
                    Text(String(format: "%03d", ms))
                        .foregroundColor(Theme.textPrimary)
                        .tag(ms)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 72)
            .clipped()

            Text("ms")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(height: 120)
        .onAppear { loadFromSeconds() }
        .onChange(of: minutes) { syncToBinding() }
        .onChange(of: seconds) { syncToBinding() }
        .onChange(of: millis) { syncToBinding() }
    }

    private func loadFromSeconds() {
        guard !didLoad else { return }
        didLoad = true
        let total = max(0, totalSeconds)
        minutes = Int(total) / 60
        seconds = Int(total) % 60
        millis = Int((total.truncatingRemainder(dividingBy: 1)) * 1000)
    }

    private func syncToBinding() {
        guard didLoad else { return }
        totalSeconds = Double(minutes * 60 + seconds) + Double(millis) / 1000.0
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        TimePickerInput(totalSeconds: .constant(92.456))
    }
    .preferredColorScheme(.dark)
}
