//
//  AddSessionView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

private let addSessionCoordSpace = "add-session"

private struct AddSessionFieldFramesKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private enum SessionFormField: Hashable {
    case notes
    case metricText(String)
}

struct AddSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var customFields: [CustomField]
    @Query(sort: [SortDescriptor(\Track.name)])
    private var tracks: [Track]
    @Query(sort: [SortDescriptor(\Vehicle.name)])
    private var vehicles: [Vehicle]
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]
    @ObservedObject private var iap = IAPManager.shared

    @AppStorage("sessionFormTipDismissed") private var tipDismissed: Bool = false
    @AppStorage("sessionProgressBarEnabled") private var progressBarEnabled: Bool = true
    @State private var date: Date = .now
    @State private var trackName: String = ""
    @State private var vehicleName: String = ""
    @State private var didLoadDefault: Bool = false
    @State private var sessionType: SessionType = .practice
    @State private var notes: String = ""
    @State private var fieldEntries: [String: String] = [:]
    @State private var expandedZone: CarZone?
    @State private var activeNumberField: String?
    @State private var fieldFrames: [String: CGRect] = [:]
    @State private var showingPaywall: Bool = false
    @Namespace private var zoneNamespace
    @State private var showingResetConfirm: Bool = false
    @State private var toastIcon: String = ""
    @State private var toastText: String = ""
    @State private var showToast: Bool = false
    @State private var isPitBoxExpanded: Bool = false
    @State private var isNotesExpanded: Bool = false
    @FocusState private var focusedField: SessionFormField?

    private var canSave: Bool {
        !trackName.isEmpty
    }

    private var allFields: [SessionFormField] {
        // While a zone is expanded, the chevrons walk only that zone's
        // text fields so focus doesn't jump out of the focused card. In
        // the resting state, pit-box text fields walk into Notes.
        if let zone = expandedZone {
            return customFields
                .filter { $0.zone == zone && $0.fieldType == .text }
                .map { .metricText($0.name) }
        }
        var fields: [SessionFormField] = generalFields
            .filter { $0.fieldType == .text }
            .map { .metricText($0.name) }
        fields.append(.notes)
        return fields
    }

    private var expandedZoneFields: [CustomField] {
        guard let zone = expandedZone else { return [] }
        return customFields.filter { $0.zone == zone }
    }

    private var generalFields: [CustomField] {
        customFields.filter { $0.zone == .general }
    }

    private var zoneStates: [CarZone: ZoneFillState] {
        var result: [CarZone: ZoneFillState] = [:]
        for zone in CarZone.carZones {
            let zoneFields = customFields.filter { $0.zone == zone }
            let filled = zoneFields.reduce(0) { count, field in
                count + (isFieldFilled(field) ? 1 : 0)
            }
            result[zone] = ZoneFillState(filled: filled, total: zoneFields.count)
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                    .dismissKeyboardOnTap()
                VStack(spacing: 0) {
                    if progressBarEnabled {
                        progressBar
                    }
                    formScroll
                }

                if showToast {
                    VStack {
                        Spacer()
                        ToastView(icon: toastIcon, text: toastText)
                            .transition(.opacity)
                            .padding(.bottom, 16)
                    }
                    .allowsHitTesting(false)
                }

                if expandedZone != nil {
                    Color.black.opacity(0.65)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture { collapseExpandedZone() }
                }

                if let zone = expandedZone {
                    expandedZoneCard(zone: zone)
                        .matchedGeometryEffect(id: zone, in: zoneNamespace, isSource: true)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 60)
                }

                if let activeName = activeNumberField,
                   let field = customFields.first(where: { $0.name == activeName }),
                   let frame = fieldFrames[activeName] {
                    NumberPadBubbleOverlay(
                        anchorFrame: frame,
                        text: bindingForField(field),
                        onDismiss: { activeNumberField = nil }
                    )
                    .transition(.opacity)
                }
            }
            .coordinateSpace(name: addSessionCoordSpace)
            .onPreferenceChange(AddSessionFieldFramesKey.self) { fieldFrames = $0 }
            .animation(.easeInOut(duration: 0.25), value: showToast)
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navToolbar }
            .keyboardToolbar(focusedField: $focusedField, fields: allFields)
            .confirmationDialog(
                "Reset this session?",
                isPresented: $showingResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) { resetForm() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("All entered data will be cleared.")
            }
            .fullScreenCover(isPresented: $showingPaywall) {
                PaywallView(limitMessage: "You have reached the free limit of \(IAPManager.sessionLimit) sessions. Upgrade to Pro for unlimited sessions.")
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if !didLoadDefault {
                didLoadDefault = true
                loadDefaults()
            }
            if !iap.checkSessionLimit(currentCount: sessions.count) {
                showingPaywall = true
            }
        }
    }

    private func loadDefaults() {
        if let defaultTrack = tracks.first(where: { $0.isDefault }) {
            trackName = defaultTrack.name
        }
        if let defaultVehicle = vehicles.first(where: { $0.isDefault }) {
            vehicleName = defaultVehicle.name
        }
    }

    private func resetForm() {
        focusedField = nil
        activeNumberField = nil
        expandedZone = nil
        date = .now
        trackName = ""
        vehicleName = ""
        sessionType = .practice
        notes = ""
        fieldEntries = [:]
        isPitBoxExpanded = false
        isNotesExpanded = false
        loadDefaults()
    }

    private func collapseExpandedZone() {
        focusedField = nil
        activeNumberField = nil
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            expandedZone = nil
        }
    }

    // Walk-around-the-car order for prev/next navigation. Wraps in both
    // directions so users can keep stepping forward without thinking
    // about edges.
    private static let zoneNavigationOrder: [CarZone] = [
        .front, .flTire, .frTire, .cockpit, .engine, .blTire, .brTire, .rear
    ]

    private func zoneNeighbor(of zone: CarZone, offset: Int) -> CarZone {
        let order = Self.zoneNavigationOrder
        guard let idx = order.firstIndex(of: zone), !order.isEmpty else { return zone }
        let count = order.count
        let target = ((idx + offset) % count + count) % count
        return order[target]
    }

    private func navigateZone(by offset: Int) {
        guard let current = expandedZone else { return }
        let target = zoneNeighbor(of: current, offset: offset)
        focusedField = nil
        activeNumberField = nil
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            expandedZone = target
        }
    }

    private func showToastBriefly(icon: String, text: String) {
        toastIcon = icon
        toastText = text
        showToast = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            showToast = false
        }
    }

    private func isFieldFilled(_ field: CustomField) -> Bool {
        let raw = fieldEntries[field.name, default: ""].trimmingCharacters(in: .whitespaces)
        if raw.isEmpty { return false }
        if field.fieldType == .time, let val = Double(raw), val == 0 { return false }
        return true
    }

    private var completionProgress: Double {
        let total = 3 + customFields.count
        guard total > 0 else { return 0 }
        var filled = 1 // session type always has a value
        if !trackName.trimmingCharacters(in: .whitespaces).isEmpty { filled += 1 }
        if !vehicleName.trimmingCharacters(in: .whitespaces).isEmpty { filled += 1 }
        for field in customFields where isFieldFilled(field) {
            filled += 1
        }
        return Double(filled) / Double(total)
    }

    private var progressBar: some View {
        VStack(alignment: .trailing, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.surfaceElevated)
                        .frame(height: 5)
                    Capsule()
                        .fill(Theme.accent)
                        .frame(width: max(geo.size.width * completionProgress, completionProgress > 0 ? 4 : 0), height: 5)
                        .shadow(color: Theme.accent.opacity(0.4), radius: 4)
                }
            }
            .frame(height: 5)

            Text("\(Int((completionProgress * 100).rounded()))% COMPLETE")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.2)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .animation(.easeInOut(duration: 0.25), value: completionProgress)
    }

    private var formScroll: some View {
        ScrollView {
            VStack(spacing: 18) {
                setupCard
                if !tipDismissed {
                    sessionFormTip
                }
                raceCarSection
            }
            .padding(20)
        }
        .scrollDisabled(activeNumberField != nil)
    }

    private var sessionFormTip: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.accent)
            Text("Tap any zone on the car to enter its metrics. Customize fields in Settings.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button { tipDismissed = true } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Theme.accent.opacity(0.12), radius: 10, y: 4)
    }

    @ToolbarContentBuilder
    private var navToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                showingResetConfirm = true
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(Theme.accent)
            }
            .accessibilityLabel("Reset session")
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save", action: save)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(canSave ? Theme.accent : Theme.textTertiary)
                .disabled(!canSave)
        }
    }

    // MARK: - Race car section

    private var raceCarSection: some View {
        VStack(spacing: 0) {
            cardHeader("ZONES")
            RaceCarDiagramView(
                zoneStates: zoneStates,
                expandedZone: expandedZone,
                matchedNamespace: zoneNamespace,
                onTapZone: { zone in
                    focusedField = nil
                    activeNumberField = nil
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                        expandedZone = zone
                    }
                }
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func cardHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Setup card (Pit Box + Notes)

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            pitBoxSection
            Divider().background(Theme.hairline)
            notesSection
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func collapsibleHeader(
        title: String,
        systemImage: String,
        isExpanded: Bool,
        toggle: @escaping () -> Void
    ) -> some View {
        Button(action: toggle) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.accent)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(Theme.accent)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var pitBoxSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            collapsibleHeader(
                title: "PIT BOX",
                systemImage: "shippingbox.fill",
                isExpanded: isPitBoxExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isPitBoxExpanded { activeNumberField = nil }
                    isPitBoxExpanded.toggle()
                }
            }

            if isPitBoxExpanded {
                pitBoxFields
            }
        }
    }

    private var pitBoxFields: some View {
        VStack(spacing: 0) {
            typeChips
                .padding(.bottom, 6)
            pitInfoRow(label: "TRACK") {
                Picker("", selection: $trackName) {
                    Text("Select Track")
                        .foregroundColor(Theme.textTertiary)
                        .tag("")
                    ForEach(tracks) { track in
                        Text(track.name).tag(track.name)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
                .labelsHidden()
            }
            pitInfoRow(label: "VEHICLE") {
                Picker("", selection: $vehicleName) {
                    Text("Select Vehicle")
                        .foregroundColor(Theme.textTertiary)
                        .tag("")
                    ForEach(vehicles) { vehicle in
                        Text(vehicle.name).tag(vehicle.name)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
                .labelsHidden()
            }
            pitInfoRow(label: "DATE") {
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(Theme.accent)
                .colorScheme(.dark)
            }
            ForEach(generalFields) { field in
                pitMetricRow(field: field)
            }
        }
    }

    private var typeChips: some View {
        HStack(spacing: 8) {
            ForEach(SessionType.allCases) { type in
                typeChip(type)
            }
        }
    }

    private func typeChip(_ type: SessionType) -> some View {
        let isSelected = sessionType == type
        return Button {
            sessionType = type
        } label: {
            HStack(spacing: 5) {
                Image(systemName: type.systemImage)
                    .font(.system(size: 11, weight: .bold))
                Text(type.rawValue.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
            }
            .foregroundColor(isSelected ? Theme.accent : Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(isSelected ? Theme.accent.opacity(0.15) : Theme.surface)
            )
            .overlay(
                Capsule().stroke(isSelected ? Theme.accent.opacity(0.5) : Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func pitInfoRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
            Spacer()
            content()
        }
        .padding(.vertical, 12)
    }

    private func pitMetricRow(field: CustomField) -> some View {
        let parts = CustomField.split(name: field.name)
        return HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(parts.name.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.textSecondary)
                if !parts.unit.isEmpty {
                    Text(parts.unit)
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.8)
                        .foregroundColor(Theme.textTertiary)
                }
            }
            Spacer()
            pitMetricInput(field: field)
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func pitMetricInput(field: CustomField) -> some View {
        switch field.fieldType {
        case .time:
            let timeBinding = Binding<Double>(
                get: { Double(fieldEntries[field.name, default: ""]) ?? 0 },
                set: { fieldEntries[field.name] = String($0) }
            )
            TimePickerInput(totalSeconds: timeBinding)
        case .text:
            TextField(
                "",
                text: bindingForField(field),
                prompt: Text("Enter text").foregroundColor(Theme.textTertiary)
            )
            .font(.system(size: 15, weight: .heavy))
            .foregroundColor(Theme.textPrimary)
            .keyboardType(.default)
            .multilineTextAlignment(.trailing)
            .autocorrectionDisabled()
            .focused($focusedField, equals: .metricText(field.name))
        case .number:
            pitNumberFieldButton(field: field)
        }
    }

    private func pitNumberFieldButton(field: CustomField) -> some View {
        let raw = fieldEntries[field.name, default: ""]
        let isActive = activeNumberField == field.name
        return Button {
            focusedField = nil
            activeNumberField = field.name
        } label: {
            Text(raw.isEmpty ? "Enter number" : raw)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(raw.isEmpty ? Theme.textTertiary : Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(minWidth: 80, alignment: .trailing)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isActive ? Theme.accent.opacity(0.15) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            isActive ? Theme.accent.opacity(0.6) : Theme.hairline,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: AddSessionFieldFramesKey.self,
                        value: [field.name: geo.frame(in: .named(addSessionCoordSpace))]
                    )
            }
        )
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            collapsibleHeader(
                title: "NOTES",
                systemImage: "note.text",
                isExpanded: isNotesExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isNotesExpanded.toggle()
                }
            }

            if isNotesExpanded {
                ZStack(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("Setup, conditions, thoughts…")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.textTertiary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $notes)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                        .focused($focusedField, equals: .notes)
                }
            }
        }
    }

    private func bindingForField(_ field: CustomField) -> Binding<String> {
        Binding(
            get: { fieldEntries[field.name, default: ""] },
            set: { fieldEntries[field.name] = $0 }
        )
    }

    // MARK: - Expanded zone card

    private func expandedZoneCard(zone: CarZone) -> some View {
        VStack(spacing: 0) {
            expandedZoneHeader(zone: zone)
            if expandedZoneFields.isEmpty {
                expandedZoneEmptyState(zone: zone)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(expandedZoneFields) { field in
                            pitMetricRow(field: field)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                .scrollDisabled(activeNumberField != nil)
            }
            expandedZoneFooter
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.accent.opacity(0.55), lineWidth: 1.5)
        )
    }

    private var expandedZoneFooter: some View {
        HStack(spacing: 12) {
            zoneNavButton(label: "PREVIOUS", systemImage: "chevron.left", isLeading: true) {
                navigateZone(by: -1)
            }
            zoneNavButton(label: "NEXT", systemImage: "chevron.right", isLeading: false) {
                navigateZone(by: 1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 18)
    }

    private func zoneNavButton(
        label: String,
        systemImage: String,
        isLeading: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLeading {
                    Image(systemName: systemImage)
                        .font(.system(size: 11, weight: .heavy))
                }
                Text(label)
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.5)
                if !isLeading {
                    Image(systemName: systemImage)
                        .font(.system(size: 11, weight: .heavy))
                }
            }
            .foregroundColor(Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(Theme.surfaceElevated)
            )
            .overlay(
                Capsule().stroke(Theme.accent.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func expandedZoneHeader(zone: CarZone) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ZONE")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.textSecondary)
                Text(zone.displayName.uppercased())
                    .font(.system(size: 22, weight: .heavy))
                    .tracking(1.2)
                    .foregroundColor(Theme.accent)
            }
            Spacer()
            Button(action: collapseExpandedZone) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Theme.accent)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(Theme.surfaceElevated)
                    )
                    .overlay(
                        Circle().stroke(Theme.accent.opacity(0.45), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close zone")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    private func expandedZoneEmptyState(zone: CarZone) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.textTertiary)
            Text("NO METRICS IN THIS ZONE")
                .font(.system(size: 12, weight: .heavy))
                .tracking(1.6)
                .foregroundColor(Theme.textSecondary)
            Text("Assign metrics to \(zone.displayName) in Settings → Session Customization → Metrics")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private func save() {
        guard iap.checkSessionLimit(currentCount: sessions.count) else {
            showingPaywall = true
            return
        }
        let session = Session(
            date: date,
            trackName: trackName.trimmingCharacters(in: .whitespaces),
            vehicleName: vehicleName.trimmingCharacters(in: .whitespaces),
            sessionType: sessionType,
            notes: notes
        )
        modelContext.insert(session)

        for field in customFields {
            let raw = fieldEntries[field.name, default: ""].trimmingCharacters(in: .whitespaces)
            if raw.isEmpty { continue }
            if field.fieldType == .time, let val = Double(raw), val == 0 { continue }
            let fv = FieldValue(fieldName: field.name, fieldType: field.fieldType, value: raw, session: session)
            modelContext.insert(fv)
        }

        resetForm()
        showToastBriefly(icon: "checkmark.circle.fill", text: "Session Saved")
    }
}

#Preview {
    AddSessionView()
        .modelContainer(for: [CustomField.self, FieldValue.self, Session.self], inMemory: true)
}
