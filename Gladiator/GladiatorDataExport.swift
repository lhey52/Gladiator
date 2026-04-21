//
//  GladiatorDataExport.swift
//  Gladiator
//

import Foundation
import SwiftData

struct GladiatorExportEnvelope: Codable {
    static let currentVersion = 1

    let version: Int
    let exportedAt: Date
    let sessions: [GladiatorSessionDTO]
    let customFields: [GladiatorCustomFieldDTO]
    let tracks: [GladiatorTrackDTO]
    let vehicles: [GladiatorVehicleDTO]
}

struct GladiatorSessionDTO: Codable {
    let date: Date
    let trackName: String
    let vehicleName: String
    let sessionType: String
    let notes: String
    let createdAt: Date
    let fieldValues: [GladiatorFieldValueDTO]
}

struct GladiatorFieldValueDTO: Codable {
    let fieldName: String
    let fieldType: String
    let value: String
}

struct GladiatorCustomFieldDTO: Codable {
    let name: String
    let fieldType: String
    let sortOrder: Int
    let createdAt: Date
}

struct GladiatorTrackDTO: Codable {
    let name: String
    let isDefault: Bool
    let createdAt: Date
}

struct GladiatorVehicleDTO: Codable {
    let name: String
    let isDefault: Bool
    let createdAt: Date
}

@MainActor
enum GladiatorDataExport {
    static let fileExtension = "gladiator"

    // MARK: - Export

    static func writeExport(context: ModelContext) throws -> URL {
        let sessions = try context.fetch(FetchDescriptor<Session>())
        let fields = try context.fetch(FetchDescriptor<CustomField>())
        let tracks = try context.fetch(FetchDescriptor<Track>())
        let vehicles = try context.fetch(FetchDescriptor<Vehicle>())

        let envelope = GladiatorExportEnvelope(
            version: GladiatorExportEnvelope.currentVersion,
            exportedAt: .now,
            sessions: sessions.map(makeSessionDTO),
            customFields: fields.map(makeCustomFieldDTO),
            tracks: tracks.map(makeTrackDTO),
            vehicles: vehicles.map(makeVehicleDTO)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(envelope)

        let filename = "Gladiator-\(filenameTimestamp()).\(fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Import

    static func importData(from url: URL, into context: ModelContext) throws {
        let needsScope = url.startAccessingSecurityScopedResource()
        defer {
            if needsScope { url.stopAccessingSecurityScopedResource() }
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(GladiatorExportEnvelope.self, from: data)

        for dto in envelope.customFields {
            let field = CustomField(
                name: dto.name,
                fieldType: FieldType(rawValue: dto.fieldType) ?? .text,
                sortOrder: dto.sortOrder
            )
            field.createdAt = dto.createdAt
            context.insert(field)
        }

        for dto in envelope.tracks {
            let track = Track(name: dto.name, isDefault: dto.isDefault)
            track.createdAt = dto.createdAt
            context.insert(track)
        }

        for dto in envelope.vehicles {
            let vehicle = Vehicle(name: dto.name, isDefault: dto.isDefault)
            vehicle.createdAt = dto.createdAt
            context.insert(vehicle)
        }

        for dto in envelope.sessions {
            let session = Session(
                date: dto.date,
                trackName: dto.trackName,
                vehicleName: dto.vehicleName,
                sessionType: SessionType(rawValue: dto.sessionType) ?? .practice,
                notes: dto.notes
            )
            session.createdAt = dto.createdAt
            context.insert(session)

            for fvDto in dto.fieldValues {
                let fv = FieldValue(
                    fieldName: fvDto.fieldName,
                    fieldType: FieldType(rawValue: fvDto.fieldType) ?? .text,
                    value: fvDto.value,
                    session: session
                )
                context.insert(fv)
            }
        }

        try context.save()
    }

    // MARK: - DTO builders

    private static func makeSessionDTO(_ s: Session) -> GladiatorSessionDTO {
        GladiatorSessionDTO(
            date: s.date,
            trackName: s.trackName,
            vehicleName: s.vehicleName,
            sessionType: s.sessionType.rawValue,
            notes: s.notes,
            createdAt: s.createdAt,
            fieldValues: s.fieldValues.map {
                GladiatorFieldValueDTO(
                    fieldName: $0.fieldName,
                    fieldType: $0.fieldType.rawValue,
                    value: $0.value
                )
            }
        )
    }

    private static func makeCustomFieldDTO(_ f: CustomField) -> GladiatorCustomFieldDTO {
        GladiatorCustomFieldDTO(
            name: f.name,
            fieldType: f.fieldType.rawValue,
            sortOrder: f.sortOrder,
            createdAt: f.createdAt
        )
    }

    private static func makeTrackDTO(_ t: Track) -> GladiatorTrackDTO {
        GladiatorTrackDTO(name: t.name, isDefault: t.isDefault, createdAt: t.createdAt)
    }

    private static func makeVehicleDTO(_ v: Vehicle) -> GladiatorVehicleDTO {
        GladiatorVehicleDTO(name: v.name, isDefault: v.isDefault, createdAt: v.createdAt)
    }

    private static func filenameTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: .now)
    }
}
