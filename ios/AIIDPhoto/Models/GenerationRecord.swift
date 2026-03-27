import Foundation

struct GenerationRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let specRawValue: String
    let sizeLabel: String
    let thumbnailFilename: String
    let isCustomSize: Bool

    var thumbnailURL: URL {
        Self.historyDirectory.appendingPathComponent(thumbnailFilename)
    }

    static var historyDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = docs.appendingPathComponent("history", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
