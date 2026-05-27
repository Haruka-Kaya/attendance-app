# iOS ビルド — Claude 引継ぎドキュメント

> **このファイルは Mac 上で新しい Claude Code セッションを開始した際に、前の会話の全文脈を引き継ぐためのドキュメントです。** 人間向けの手順書ではなく、Claude が読んで自走するための情報源。

---

## ユーザー: 賀屋悠 (かや はるか)

- メール: kayaharuka@hotmail.com
- GitHub: Himanaraba
- Apple Developer Team ID: 7482F26LUS
- 役割: 個人開発者。部活動向け出欠管理システムを一人で開発・運用

### 作業スタイル (重要 — 必ず守ること)

- **言語**: ユーザーとのやり取り・コミットメッセージは **日本語**。コード・API 名は英語
- **自律動作**: 手順書を渡すのではなく自分で実行する。"You could try" ではなく "Implemented and validated"
- **確認不要なケース**: 安全な仮定が立つなら確認せず進める。仮定は結果報告に明記
- **自走**: 失敗したら原因調査 → 修正 → 再検証まで完了する。「問題を見つけた」で止まらない
- **出力形式**: 過剰な前置き・再確認・"AI ぽい" 締めは不要。報告は「何を変更 / 検証結果 / 残ブロッカー / 人間に必要なアクション」の構造で簡潔に
- **人間に聞いてよいのは**: シークレット提供、破壊的操作の承認、本番デプロイの最終承認
- **git コミットプレフィクス**: `feat:` `fix:` `refactor:` `perf:` `docs:` `test:` `chore:`
- **git 安全ルール**: 新ファイル作成後は `git status` で untracked 確認してから commit。シークレットは絶対にコミットしない

---

## プロジェクト全体像

部活動向け出欠管理システム。2つのリポジトリで構成。両方 public / Apache 2.0。

### バックエンド (運用中・Mac 作業不要)
- リポジトリ: `github.com/Himanaraba/attendance-system`
- スタック: Flask 3 / SQLAlchemy / Flask-JWT-Extended / SQLite
- 本番: https://zenshin9498.duckdns.org (Vultr VPS + Coolify + Traefik + Let's Encrypt)
- デプロイ: `git push` → Coolify 自動ビルド

### モバイル (このリポジトリ)
- リポジトリ: `github.com/Himanaraba/attendance-app`
- スタック: Flutter 3 / Provider / Dio / liquid_glass_widgets (iOS 26 Liquid Glass デザイン)
- Android 版: 運用中。`release-apk.ps1` (Windows) で APK ビルド → GitHub Releases → OTA 自動更新
- **iOS 版: これから初回ビルド & TestFlight 配布する ← 今回の作業**

### API 接続先
- 本番: `https://zenshin9498.duckdns.org` (`lib/config/api_config.dart` に設定済み)
- HTTPS なので iOS の ATS (App Transport Security) はデフォルトで問題なし

---

## 完了済みの準備 (Windows 側で実施済み)

以下は **すべて完了している**。Mac 側での再設定は不要。

- [x] **Apple Developer Program 加入** ($99/年、承認済み)
- [x] **Bundle ID 登録**: `jp.zenshin9498.attendance` (Certificates, Identifiers & Profiles で登録済み)
- [x] **App Store Connect アプリ枠**: `ZENSHIN-Attendance` で作成済み
- [x] **App Store Connect API キー**: `.p8` ファイル発行済み (ユーザーの手元にある)
- [x] **Bundle ID をコードに反映**: `ios/Runner.xcodeproj/project.pbxproj` で `jp.zenshin9498.attendance` に変更済み
- [x] **アプリ表示名**: `ios/Runner/Info.plist` の `CFBundleDisplayName` を「出欠管理」に変更済み
- [x] **OTA アップデート無効化**: `lib/services/update_service.dart` で `UpdateService.isSupported` が `Platform.isAndroid` を返す。iOS では `check()` が常に null を返し、アップデート画面は出ない
- [x] **プロフィール画面分岐**: `lib/screens/profile_screen.dart` の「アップデートを確認」ボタンが `Platform.isAndroid` で囲まれており、iOS では非表示
- [x] **`scripts/release-ipa.sh`**: CLI 自動化スクリプト雛形を配置済み

---

## Mac でやるべき作業

### Phase 1: 環境構築 (ワンタイム)

```bash
# 1. Xcode コマンドラインツール
sudo xcode-select --install
sudo xcodebuild -license accept

# 2. CocoaPods
sudo gem install cocoapods

# 3. Flutter (Homebrew 経由)
brew install --cask flutter
flutter doctor
# → iOS toolchain, Xcode, CocoaPods が全部 ✓ になること
```

### Phase 2: Xcode に Apple ID を追加

1. Xcode 起動 → **Settings (⌘,)** → **Accounts** タブ
2. 左下「+」→「Apple ID」→ 賀屋の Apple ID でサインイン
3. 追加されたら「Manage Certificates...」→「+」→「Apple Development」で開発証明書を発行

> 友達の Mac に友達の Apple ID がサインイン済みでも問題ない。Xcode は複数 Apple ID を並行管理できる。

### Phase 3: プロジェクト取得 & ビルド

```bash
git clone https://github.com/Himanaraba/attendance-app.git
cd attendance-app
flutter pub get
cd ios && pod install && cd ..
```

### Phase 4: 実機テスト (任意だが推奨)

iPhone をケーブル接続。iPhone 側で「このコンピュータを信頼」を許可。

```bash
flutter devices         # iPhone が表示されることを確認
flutter run --release   # 実機にインストール
```

iPhone の **設定 → 一般 → VPN とデバイス管理** で開発者プロファイルを信頼する必要がある場合あり。

### Phase 5: TestFlight 配布 (本命・全 CLI — Xcode GUI 不要)

> **重要**: Xcode の GUI 操作は Phase 2 の Apple ID サインインだけ。ビルドから TestFlight アップロードまで全部 CLI で実行可能。Claude が自走できる。

#### 手動 CLI (1回ずつ実行する場合)

```bash
# IPA ビルド (ExportOptions.plist で署名設定済み)
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

# TestFlight アップロード (環境変数に API キー情報が必要)
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/*.ipa \
  --apiKey "$APP_STORE_CONNECT_KEY_ID" \
  --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"
```

#### 自動化スクリプト (推奨)

ユーザーが `.p8` ファイルを持っている。環境変数を設定して `release-ipa.sh` で全工程を一発実行:

```bash
export APP_STORE_CONNECT_KEY_ID="<Key ID>"
export APP_STORE_CONNECT_ISSUER_ID="<Issuer ID>"
export APP_STORE_CONNECT_KEY_PATH="$HOME/.appstoreconnect/<ファイル名>.p8"

chmod +x scripts/release-ipa.sh   # 初回のみ
./scripts/release-ipa.sh 1.6.0 "iOS版初回リリース"
```

Key ID / Issuer ID / .p8 ファイルパスは **ユーザーに聞くこと** (秘密情報なのでこのファイルには書かない)。

#### TestFlight 配布確認

App Store Connect ([appstoreconnect.apple.com](https://appstoreconnect.apple.com)) → **TestFlight** タブ:
- ビルド処理: 約 15〜30分
- 処理完了したら内部テスターを追加 (Apple ID で招待)
- テスターは iPhone に **TestFlight** アプリを入れて招待リンクから参加

### Phase 5 補足: ExportOptions.plist

`ios/ExportOptions.plist` が署名・アップロード設定を持っている。Team ID `7482F26LUS`、automatic signing、app-store-connect method。変更不要。

### Phase 6: 後片付け (Mac を返す前)

友達の Mac に賀屋の情報を残さないように:

1. Xcode → Settings → Accounts → 賀屋の Apple ID を選択 → 左下「-」で削除
2. **Keychain Access** アプリ → 「Apple Development」「Apple Distribution」で検索 → 賀屋名義の秘密鍵を削除
3. `~/Library/MobileDevice/Provisioning Profiles/` の中身を削除
4. `attendance-app/` フォルダを削除
5. 環境変数に `.p8` パスを書いていた場合は `.env.ios` を削除

---

## 技術的な注意点

### iOS での動作が異なる機能
- **アップデート確認**: バージョンチェックは iOS でも実行する。新バージョン検知時に `UpdateScreen` を表示するが、ダウンロードボタンの代わりに **「TestFlight で更新」** ボタンを表示 (`url_launcher` で `itms-beta://` スキームを起動)。`UpdateService.canDirectInstall` が false の場合に分岐
- **プロフィールの「アップデートを確認」ボタン**: iOS でも表示。チェック結果に応じて UpdateScreen (TestFlight 誘導) またはスナックバー「最新バージョンです」
- **システムナビゲーションバー非表示** (`SystemChrome.setEnabledSystemUIMode(immersiveSticky)`): Android 専用の設定だが、iOS には元々ナビバーが無いので影響なし

### Liquid Glass (liquid_glass_widgets v0.10.9)
- iOS 26 デザイン言語ベースなので iOS の方がむしろ映える
- `GlassBottomBar` で画面下部のタブバー、`GradientBackground` で背景グラデーションを表示
- `GlassAppBar` は使っていない (上部が白く曇る問題で通常の透明 AppBar に戻した経緯あり)
- **ビルドエラーが出た場合**: `ios/Podfile` の `platform :ios` を `'14.0'` 以上に上げる

### flutter_secure_storage
- iOS では Keychain に JWT トークンを保存
- Keychain Sharing Capability は不要 (アプリ内のみ使用)

### バージョン番号
- `pubspec.yaml` の `version: X.Y.Z+N` が iOS (`CFBundleShortVersionString` + `CFBundleVersion`) にも反映
- TestFlight アップロードのたびに `+N` を上げる必要がある (同一番号での再アップロードは拒否される)
- 現在の最新バージョン: pubspec.yaml を `grep '^version:'` して確認

### i18n (国際化)
- `lib/services/i18n.dart` に ja/en の翻訳テーブル
- `LanguageProvider` で言語切替。デフォルト日本語
- アップデート画面含む全 UI が言語設定に追従する

---

## トラブルシューティング

| 症状 | 対処 |
|---|---|
| `No team found` | Apple Developer 承認済みなら Xcode → Settings → Accounts でログインし直す |
| `pod install` エラー | `cd ios && rm -rf Pods Podfile.lock && pod install --repo-update` |
| `code signing failed` | Xcode → Runner → Signing & Capabilities → Team 選択 + "Automatically manage signing" ON |
| TestFlight にビルドが出ない | 処理に 15〜30分。エラーは Apple ID 宛メールで通知される |
| `liquid_glass_widgets` ビルドエラー | `ios/Podfile` の iOS version を `'14.0'` 以上に |
| 「インターネット接続なし」 | ATS デフォルト = HTTPS のみ。本番 URL (DuckDNS + LE) は問題なし。開発で http://localhost を叩くなら Info.plist に ATS 例外追加 |
| `getExternalStorageDirectory` エラー | iOS では null 返却。OTA コードパスは `isSupported` ガードで到達しないはずだが、もし踏んでたら `UpdateService` の分岐を確認 |
| Archive 後の Upload で「Invalid Bundle」 | Bundle ID が `jp.zenshin9498.attendance` と App Store Connect 登録が一致しているか確認。project.pbxproj を grep |

---

## Android vs iOS の差異一覧

| 機能 | Android | iOS |
|---|---|---|
| OTA アップデート | ✅ APK 自動 DL/インストール (`release-apk.ps1`) | 「TestFlight で更新」ボタンで TestFlight アプリに誘導 |
| 「アップデートを確認」ボタン | 表示 (OTA) | 表示 (TestFlight 誘導) |
| システムナビバー非表示 | ✅ `immersiveSticky` | iOS にナビバー無し |
| Liquid Glass | 動作 | 動作 (iOS の方が映える) |
| プッシュ通知 | 未実装 | 未実装 |
| 署名 | Keystore (自動) | Apple Developer Certificate (Xcode 自動管理) |
| 配布 | GitHub Releases APK | TestFlight |
| リリーススクリプト | `attendance-tools/release-apk.ps1` (Windows) | `scripts/release-ipa.sh` (Mac) |

---

## この文書に書いていない秘密情報 (ユーザーに聞くこと)

以下はリポジトリに含めてはいけない。必要になったらユーザーに直接聞くこと:

- App Store Connect API Key ID
- App Store Connect Issuer ID
- `.p8` ファイルの内容・パス
- Apple ID のパスワード
- Discord Webhook URL / Bot Token (バックエンド側、iOS 作業には不要)
