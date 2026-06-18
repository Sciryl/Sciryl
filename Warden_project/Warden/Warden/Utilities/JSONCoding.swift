import Foundation

extension JSONEncoder {
    /// Pretty-printed, ISO-8601-dated, key-sorted encoder so the JSON files
    /// Warden writes stay readable if a user opens them directly.
    static func wardenEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}

extension JSONDecoder {
    static func wardenDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
