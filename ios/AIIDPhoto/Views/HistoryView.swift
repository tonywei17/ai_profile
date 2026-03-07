import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var langManager: LanguageManager
    @EnvironmentObject var historyManager: HistoryManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var lang: String { langManager.effectiveCode }

    private func l(_ zh: String, _ en: String, _ ja: String, _ ko: String,
                   vi: String? = nil, id: String? = nil, pt: String? = nil) -> String {
        switch lang {
        case "zh": return zh
        case "ja": return ja
        case "ko": return ko
        case "vi": return vi ?? en
        case "id": return id ?? en
        case "pt": return pt ?? en
        default:   return en
        }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 160), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground.gradient.ignoresSafeArea()

                if historyManager.records.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(historyManager.records) { record in
                                historyCell(record)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Cell

    private func historyCell(_ record: GenerationRecord) -> some View {
        VStack(spacing: 6) {
            if let data = try? Data(contentsOf: record.thumbnailURL),
               let uiImage = UIImage(data: data) {
                Color.clear
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Color.clear
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.secondary.opacity(0.15))
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Text(record.sizeLabel)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)

            Text(record.date, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .contextMenu {
            Button {
                if let data = try? Data(contentsOf: record.thumbnailURL),
                   let img = UIImage(data: data) {
                    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                }
            } label: {
                Label(saveLabel, systemImage: "square.and.arrow.down")
            }
            Button(role: .destructive) {
                withAnimation { historyManager.deleteRecord(record) }
            } label: {
                Label(deleteLabel, systemImage: "trash")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(.secondary.opacity(0.5))
            Text(emptyTitle)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(emptySubtitle)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Strings

    private var navTitle:      String { l("历史记录", "History", "履歴", "히스토리", vi: "Lịch sử", id: "Riwayat", pt: "Histórico") }
    private var deleteLabel:   String { l("删除", "Delete", "削除", "삭제", vi: "Xóa", id: "Hapus", pt: "Excluir") }
    private var saveLabel:     String { l("保存到相册", "Save to Photos", "写真を保存", "사진 저장", vi: "Lưu vào Ảnh", id: "Simpan ke Foto", pt: "Salvar em Fotos") }
    private var emptyTitle:    String { l("暂无记录", "No History Yet", "履歴なし", "기록 없음", vi: "Chưa có lịch sử", id: "Belum Ada Riwayat", pt: "Sem Histórico") }
    private var emptySubtitle: String { l("生成的证件照将显示在这里", "Generated ID photos will appear here", "生成した証明写真がここに表示されます", "생성된 증명사진이 여기에 표시됩니다",
                                          vi: "Ảnh thẻ đã tạo sẽ hiển thị tại đây", id: "Foto ID yang dibuat akan muncul di sini", pt: "Fotos geradas aparecerão aqui") }
}
