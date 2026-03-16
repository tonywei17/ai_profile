import SwiftUI

/// Shown once before the user's first AI generation.
/// Discloses that the photo is sent to Google Gemini API and asks for consent.
struct AIConsentView: View {
    @EnvironmentObject var langManager: LanguageManager
    @Environment(\.colorScheme) private var colorScheme

    let onAgree: () -> Void
    let onDecline: () -> Void

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

    var body: some View {
        ZStack {
            GlassBackground.gradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 64, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 16, y: 6)

                    // Title
                    Text(titleText)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(GlassBackground.titleGradient(for: colorScheme))
                        .multilineTextAlignment(.center)

                    // Data disclosure card
                    VStack(alignment: .leading, spacing: 16) {
                        disclosureRow(icon: "photo.fill",
                                      color: .blue,
                                      title: dataTypeTitle,
                                      detail: dataTypeDetail)
                        Divider()
                        disclosureRow(icon: "server.rack",
                                      color: .purple,
                                      title: recipientTitle,
                                      detail: recipientDetail)
                        Divider()
                        disclosureRow(icon: "trash.fill",
                                      color: .green,
                                      title: retentionTitle,
                                      detail: retentionDetail)
                    }
                    .padding(20)
                    .glassEffect(.regular, in: .rect(cornerRadius: 20))

                    Text(footerNote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        onAgree()
                    } label: {
                        Text(agreeLabel)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundStyle(.white)
                    }
                    .glassEffect(.regular.tint(.blue).interactive(), in: .rect(cornerRadius: 16))

                    Button {
                        onDecline()
                    } label: {
                        Text(declineLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Row

    private func disclosureRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.callout.bold())
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Localized Strings

    private var titleText: String {
        l("照片数据使用说明",
          "How We Use Your Photo",
          "写真データの利用について",
          "사진 데이터 사용 안내",
          vi: "Cách chúng tôi dùng ảnh của bạn",
          id: "Cara Kami Menggunakan Foto Anda",
          pt: "Como Usamos Sua Foto")
    }

    private var dataTypeTitle: String {
        l("发送的数据",
          "Data Sent",
          "送信されるデータ",
          "전송되는 데이터",
          vi: "Dữ liệu được gửi",
          id: "Data yang Dikirim",
          pt: "Dados Enviados")
    }

    private var dataTypeDetail: String {
        l("您上传的照片（仅用于生成证件照）",
          "Your uploaded photo (used only to generate your ID photo)",
          "アップロードした写真（証明写真生成のみに使用）",
          "업로드한 사진 (증명사진 생성에만 사용됨)",
          vi: "Ảnh bạn tải lên (chỉ dùng để tạo ảnh thẻ)",
          id: "Foto yang Anda unggah (hanya untuk membuat foto ID)",
          pt: "Sua foto enviada (usada apenas para gerar sua foto de documento)")
    }

    private var recipientTitle: String {
        l("发送给谁",
          "Sent To",
          "送信先",
          "전송 대상",
          vi: "Gửi đến",
          id: "Dikirim Ke",
          pt: "Enviado Para")
    }

    private var recipientDetail: String {
        l("Google Gemini API（通过我们的安全后端代理，不会直接暴露API Key）",
          "Google Gemini API via our secure backend proxy — your photo is never stored",
          "Google Gemini API（当社のセキュアなバックエンド経由、写真は保存されません）",
          "Google Gemini API (보안 백엔드 경유, 사진은 저장되지 않음)",
          vi: "Google Gemini API qua backend bảo mật — ảnh không được lưu trữ",
          id: "Google Gemini API melalui backend aman kami — foto tidak disimpan",
          pt: "Google Gemini API via backend seguro — sua foto nunca é armazenada")
    }

    private var retentionTitle: String {
        l("数据保留",
          "Data Retention",
          "データ保持",
          "데이터 보존",
          vi: "Lưu giữ dữ liệu",
          id: "Retensi Data",
          pt: "Retenção de Dados")
    }

    private var retentionDetail: String {
        l("处理完成后立即删除，不做任何存储",
          "Deleted immediately after processing — not stored anywhere",
          "処理完了後すぐに削除、一切保存しません",
          "처리 완료 후 즉시 삭제 — 어디에도 저장되지 않음",
          vi: "Xóa ngay sau khi xử lý — không lưu ở đâu cả",
          id: "Dihapus segera setelah pemrosesan — tidak disimpan di mana pun",
          pt: "Excluída imediatamente após o processamento — não armazenada em lugar algum")
    }

    private var footerNote: String {
        l("继续即表示您同意我们的隐私政策。您可在设置中随时撤回同意。",
          "By continuing, you agree to our Privacy Policy. You can withdraw consent in Settings at any time.",
          "続行することで、プライバシーポリシーに同意したことになります。設定からいつでも同意を撤回できます。",
          "계속하면 개인정보 처리방침에 동의하는 것입니다. 언제든지 설정에서 동의를 철회할 수 있습니다.",
          vi: "Bằng cách tiếp tục, bạn đồng ý với Chính sách Bảo mật của chúng tôi. Bạn có thể rút lại đồng ý trong Cài đặt.",
          id: "Dengan melanjutkan, Anda menyetujui Kebijakan Privasi kami. Anda dapat menarik persetujuan di Pengaturan.",
          pt: "Ao continuar, você concorda com nossa Política de Privacidade. Você pode retirar o consentimento em Configurações.")
    }

    private var agreeLabel: String {
        l("我同意，继续生成",
          "I Agree — Continue",
          "同意して続ける",
          "동의하고 계속",
          vi: "Tôi đồng ý — Tiếp tục",
          id: "Saya Setuju — Lanjutkan",
          pt: "Concordo — Continuar")
    }

    private var declineLabel: String {
        l("不同意",
          "Decline",
          "同意しない",
          "거부",
          vi: "Từ chối",
          id: "Tolak",
          pt: "Recusar")
    }
}
