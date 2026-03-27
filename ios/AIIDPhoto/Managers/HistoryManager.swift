import Foundation
import UIKit

@MainActor
final class HistoryManager: ObservableObject {
    @Published private(set) var records: [GenerationRecord] = []

    private let maxRecords = 50
    private var loaded = false
    private let metadataURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return docs.appendingPathComponent("history_metadata.json")
    }()

    init() {}

    /// Ensure records are loaded from disk (lazy, called on first access).
    func ensureLoaded() {
        guard !loaded else { return }
        loaded = true
        loadRecords()
    }

    func addRecord(image: UIImage, specRawValue: String, sizeLabel: String, isCustomSize: Bool) {
        ensureLoaded()
        let id = UUID()
        let filename = "\(id.uuidString).jpg"
        let fileURL = GenerationRecord.historyDirectory.appendingPathComponent(filename)

        // Save compressed thumbnail (max 512px, JPEG 0.7 quality) with data protection
        if let thumbnail = resized(image, maxDimension: 512),
           let data = thumbnail.jpegData(compressionQuality: 0.7) {
            do {
                try data.write(to: fileURL, options: .completeFileProtection)
            } catch {
                #if DEBUG
                print("[HistoryManager] Failed to save thumbnail: \(error)")
                #endif
            }
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
        ensureLoaded()
        do {
            try FileManager.default.removeItem(at: record.thumbnailURL)
        } catch {
            #if DEBUG
            print("[HistoryManager] Failed to delete thumbnail: \(error)")
            #endif
        }
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
        do {
            let data = try Data(contentsOf: metadataURL)
            records = try JSONDecoder().decode([GenerationRecord].self, from: data)
        } catch {
            #if DEBUG
            if (error as NSError).domain != NSCocoaErrorDomain || (error as NSError).code != NSFileReadNoSuchFileError {
                print("[HistoryManager] Failed to load records: \(error)")
            }
            #endif
        }
    }

    private func saveRecords() {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: metadataURL, options: .completeFileProtection)
        } catch {
            #if DEBUG
            print("[HistoryManager] Failed to save records: \(error)")
            #endif
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
