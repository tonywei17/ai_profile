# 紹介キャンペーン(リファラル)— ドキュメント索引

本ディレクトリは「AI証明写真」アプリの紹介プログラム(招待コード→Pro品質生成の無料付与 / 3人招待で3日間Pro体験)に関する、**規約・コンプライアンス系ドキュメント**を格納する。実装コード(バックエンド `backend/src/routes/referral.ts`、iOS `ios/AIIDPhoto/Managers/ReferralManager.swift` 等)はこのディレクトリの対象外。

## ファイル一覧

| ファイル | 内容 | 想定読者 |
|---|---|---|
| [REFERRAL-SPEC.md](REFERRAL-SPEC.md) | 規約の数字・条件の事実根拠(特典内容/不正防止/取得データ)。仕様変更時は規約と同時更新 | エンジニア・Wei |
| [CAMPAIGN-TERMS-ja.md](CAMPAIGN-TERMS-ja.md) | キャンペーン規約・日本語準拠テキスト(草案) | Wei・法務レビュー・エンドユーザー(公開後) |
| [CAMPAIGN-TERMS-zh.md](CAMPAIGN-TERMS-zh.md) | キャンペーン規約・中国語参考訳(草案、日文版と齟齬があれば日文版が優先) | Wei(社内確認用) |

## 位置づけ

- 本ディレクトリのドキュメントは**規約の草案(ソーステキスト)**であり、エンドユーザー向け公開ページ(`backend/public/legal/{lang}/referral-terms.html` 相当、現状未作成)そのものではない。HTML化・アプリ内リンク設置は別タスクで対応する。
- 景表法(景品表示法)・特商法(特定商取引法)・ステマ规制(2023年10月施行)の3法規を根拠に、jp-ad-compliance skill のチェックリストに沿って作成した。詳細な条文根拠は各 `CAMPAIGN-TERMS-*.md` 冒頭の TODO 注記および `REFERRAL-SPEC.md` を参照。

## 公開前に必須の対応(未解決)

1. ~~運営者名義の確認・統一~~ **【解決済み・2026-07-22】** 個人名義「Wei Wenxin」/ `nexuswei.dev@gmail.com` に統一確定(個人アプリのため)。規約 ja/zh 修正済み。
2. 紹介コード単位の総兌換上限(MAX_REDEEMS_PER_CODE)の数値確定。
3. 公開前に `/jp-compliance-scan` で日本語規約の最終スキャンを実施(景表法/特商法/ステマ)。可能であれば弁護士レビュー。
4. プライバシーポリシー(`backend/public/legal/privacy/{lang}.html`)へ、端末識別子・IPハッシュの取得目的を追記(本タスクのスコープ外・別途対応要)。
