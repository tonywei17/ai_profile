import Foundation
import UIKit

@MainActor
final class HistoryManager: ObservableObject {
    @Published private(set) var records: [GenerationRecord] = []

    private let maxRecords = 50
    private let metadataURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("history_metadata.json")
    }()

    init() { loadRecords() }

    func addRecord(image: UIImage, specRawValue: String, sizeLabel: String, isCustomSize: Bool) {
        let id = UUID()
        let filename = "\(id.uuidString).jpg"
        let fileURL = GenerationRecord.historyDirectory.appendingPathComponent(filename)

        // Save compressed thumbnail (max 512px, JPEG 0.7 quality)
        if let thumbnail = resized(image, maxDimension: 512),
           let data = thumbnail.jpegData(compressionQuality: 0.7) {
            try? data.write(to: fileURL)
        }

        let record = GenerationRecord(
            id: id, date: Date(),
            specRawValue: specRawValue,
            sizeLabel: sizeLabel,
            thumbnailFilename: filename,
            isCustomSize: isCustomSize
        )

        records.insert(record, at: 0)
        pruneIfNeeded()
        saveRecords()
    }

    func deleteRecord(_ record: GenerationRecord) {
        try? FileManager.default.removeItem(at: record.thumbnailURL)
        records.removeAll { $0.id == record.id }
        saveRecords()
    }

    // MARK: - Private

    private func pruneIfNeeded() {
        while records.count > maxRecords {
            let oldest = records.removeLast()
            try? FileManager.default.removeItem(at: oldest.thumbnailURL)
        }
    }

    private func loadRecords() {
        guard let data = try? Data(contentsOf: metadataURL),
              let loaded = try? JSONDecoder().decode([GenerationRecord].self, from: data) else { return }
        records = loaded
    }

    private func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            try? data.write(to: metadataURL)
        }
    }

    private func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }
        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
